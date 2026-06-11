import asyncio
import hashlib
import logging
import time
import uuid

import httpx

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.clients.ark_vlm_client import VLMClientError
from app.core.cache import get_cache_manager
from app.core.exceptions import AIServiceUnavailableError, RecognitionFailedError, SessionNotFoundError
from app.models import RecognitionResult, SearchSession, SessionStatus
from app.services.comparison_service import ComparisonService
from app.services.search_service import SearchService
from app.services.suggestion_service import SuggestionService

logger = logging.getLogger(__name__)


def _label_map() -> dict:
    return {
        "category": "品类",
        "brand": "品牌",
        "color": "颜色",
        "style": "风格",
    }


class RecognitionService:
    def __init__(self, vlm_client=None, llm_client=None, search_service=None):
        self._vlm_client = vlm_client
        self._llm_client = llm_client
        self._search_service = search_service or SearchService()
        self._comparison_service = ComparisonService()
        self._suggestion_service = SuggestionService(llm_client)

    async def recognize(
        self,
        image_bytes: bytes,
        device_id: str,
        db: AsyncSession,
    ) -> dict:
        if self._vlm_client is None:
            raise AIServiceUnavailableError("VLM client not configured")

        t_start = time.time()
        session = SearchSession(
            device_id=device_id,
            search_type="image",
            status=SessionStatus.RECOGNIZING,
        )
        db.add(session)
        await db.flush()

        cache_mgr = get_cache_manager()
        cached = await cache_mgr.get_image_cache(image_bytes)
        if cached:
            logger.info(f"[识别] 图片缓存命中 sha256={hashlib.sha256(image_bytes).hexdigest()[:16]}...")
            vlm_result = cached
        else:
            try:
                t0 = time.time()
                vlm_result = await self._vlm_client.recognize(image_bytes)
                logger.info(f"[识别] VLM识别耗时={time.time()-t0:.2f}s, category={vlm_result.get('category')}, keywords={vlm_result.get('keywords')}")
                await cache_mgr.set_image_cache(image_bytes, vlm_result)
            except (VLMClientError, httpx.TimeoutException, httpx.ConnectError) as e:
                session.status = SessionStatus.FAILED
                await db.commit()
                logger.error(f"[识别] VLM调用失败: {e}, 耗时={time.time()-t_start:.2f}s")
                raise AIServiceUnavailableError()
            except Exception as e:
                session.status = SessionStatus.FAILED
                await db.commit()
                logger.error(f"[识别] VLM异常: {e}, 耗时={time.time()-t_start:.2f}s")
                raise RecognitionFailedError(str(e))

        if not vlm_result or not vlm_result.get("category"):
            session.status = SessionStatus.FAILED
            await db.commit()
            logger.warning(f"[识别] VLM返回空结果或无分类, 耗时={time.time()-t_start:.2f}s")
            raise RecognitionFailedError()

        category = vlm_result.get("category", "")
        raw_keywords = vlm_result.get("keywords", [category]) if vlm_result.get("keywords") else [category]
        keywords = [kw for kw in raw_keywords if kw and str(kw).strip()]
        if not keywords:
            keywords = [category]

        recognition = RecognitionResult(
            session_id=session.id,
            category=category,
            attributes=vlm_result,
            raw_response=vlm_result,
        )
        db.add(recognition)

        suggestions = SuggestionService.get_preset_suggestions()

        asyncio.create_task(self._background_search_and_persist(session, keywords))

        session.status = SessionStatus.COMPLETED
        await db.commit()

        core_keys = ("category", "brand", "color", "style")
        attributes_list = [
            {"key": k, "label": _label_map().get(k, k), "value": str(vlm_result.get(k, ""))}
            for k in core_keys
            if vlm_result.get(k)
        ]

        return {
            "session_id": str(session.id),
            "recognition": {
                "category": category,
                "attributes": attributes_list,
                "suggestions": suggestions,
            },
            "suggestions": suggestions,
            "products": [],
            "price_summary": [],
        }

    async def _background_search_and_persist(self, session, keywords):
        from app.core.database import get_db as _get_db
        try:
            async for bg_db in _get_db():
                products = await self._search_service.search_all(
                    keywords=keywords, session=session, db=bg_db, skip_persist=True,
                )
                filtered, _ = self._comparison_service.compare_and_rerank(products, keywords)
                await self._search_service._persist_products(filtered, session.id, bg_db)
                break
            logger.info(f"[识别后台] 商品搜索完成, 入仓结果数={len(filtered)}/{len(products)}")
        except Exception as e:
            logger.error(f"[识别后台] 商品搜索失败: {e}")

    async def update_attributes(
        self,
        session_id: str,
        attribute: str,
        new_value: str,
        db: AsyncSession,
    ) -> dict:
        """属性修正：更新识别属性后调用文字搜索完整链路"""
        try:
            sid = uuid.UUID(session_id)
        except ValueError:
            raise SessionNotFoundError(session_id)

        result = await db.execute(
            select(RecognitionResult).where(RecognitionResult.session_id == sid)
        )
        rec = result.scalar_one_or_none()
        if not rec:
            raise SessionNotFoundError(session_id)

        session_result = await db.execute(
            select(SearchSession).where(SearchSession.id == sid)
        )
        search_session = session_result.scalar_one_or_none()
        if not search_session:
            raise SessionNotFoundError(session_id)

        attrs = dict(rec.attributes)
        attrs[attribute] = new_value

        rec.attributes = attrs
        await db.commit()

        category = attrs.get("category", "")
        vlm_keywords = attrs.get("keywords", [])
        keywords_strs = [category] if category else []
        for field in ("brand", "color", "style", "material", "shape"):
            val = attrs.get(field)
            if val and isinstance(val, str) and val.strip():
                keywords_strs.append(val.strip())
        if isinstance(vlm_keywords, list):
            for kw in vlm_keywords:
                if kw and isinstance(kw, str) and kw.strip() and kw.strip() not in keywords_strs:
                    keywords_strs.append(kw.strip())
        if new_value and str(new_value).strip() not in keywords_strs:
            keywords_strs.append(str(new_value).strip())

        from app.services.text_search_service import TextSearchService
        text_search = TextSearchService(search_service=self._search_service)
        text_result = await text_search.search(
            keywords=keywords_strs,
            device_id=search_session.device_id,
            db=db,
        )

        core_keys = ("category", "brand", "color", "style")
        label_map = _label_map()
        updated_attributes = [
            {"key": k, "label": label_map.get(k, k), "value": str(attrs.get(k, ""))}
            for k in core_keys
            if attrs.get(k)
        ]

        return {
            "updated_attributes": updated_attributes,
            "products": text_result.get("products", []),
            "price_summary": text_result.get("price_summary", []),
        }
