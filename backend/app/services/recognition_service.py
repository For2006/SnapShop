import uuid
import time
import logging
import asyncio

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.clients.ark_llm_client import LLMClientError
from app.clients.ark_vlm_client import VLMClientError
from app.models import SearchSession, RecognitionResult, SessionStatus
from app.core.exceptions import RecognitionFailedError, AIServiceUnavailableError, SessionNotFoundError
from app.services.search_service import SearchService
from app.services.comparison_service import ComparisonService
from app.services.suggestion_service import SuggestionService
from app.services.product_serializer import serialize_product

logger = logging.getLogger(__name__)


class RecognitionService:
    def __init__(self, vlm_client=None, llm_client=None):
        self._vlm_client = vlm_client
        self._llm_client = llm_client
        self._search_service = SearchService()
        self._comparison_service = ComparisonService()
        self._suggestion_service = SuggestionService(llm_client)

    async def recognize(
        self,
        image_bytes: bytes,
        device_id: str,
        db: AsyncSession,
    ) -> dict:
        t_start = time.time()
        session = SearchSession(
            device_id=device_id,
            search_type="image",
            status=SessionStatus.RECOGNIZING,
        )
        db.add(session)
        await db.flush()

        try:
            t0 = time.time()
            vlm_result = await self._recognize_with_self_correction(image_bytes)
            logger.info(f"[识别] VLM识别耗时={time.time()-t0:.2f}s, category={vlm_result.get('category')}, keywords={vlm_result.get('keywords')}")
        except AIServiceUnavailableError:
            session.status = SessionStatus.FAILED
            await db.commit()
            logger.error(f"[识别] VLM服务不可用, 耗时={time.time()-t_start:.2f}s")
            raise
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
        keywords = vlm_result.get("keywords", [category]) if vlm_result.get("keywords") else [category]
        confidence = vlm_result.get("confidence", {})

        recognition = RecognitionResult(
            session_id=session.id,
            category=category,
            attributes=vlm_result,
            raw_response=vlm_result,
            confidence=confidence,
        )
        db.add(recognition)

        t0 = time.time()
        products = await self._search_service.search_all(
            keywords=keywords, session=session, db=db
        )
        logger.info(f"[识别] 商品搜索耗时={time.time()-t0:.2f}s, 结果数={len(products)}")

        filtered_products, price_summary = self._comparison_service.compare_and_rerank(
            products, keywords
        )

        from app.services.browse_recorder import record_browse_entries
        await record_browse_entries(filtered_products, device_id, db)

        recall_stats = {
            "total_count": len(filtered_products),
            "category": category,
            "platforms": {s["platform"]: {"min_price": s["min_price"], "count": s["count"]} for s in price_summary},
        }
        suggestions = await self._suggestion_service.generate(vlm_result, recall_stats)

        session.status = SessionStatus.COMPLETED
        await db.commit()

        attributes_list = [
            {"key": k, "label": _label_map().get(k, k), "value": str(v) if v else "", "confidence": float(confidence.get(k, 0))}
            for k, v in vlm_result.items()
            if k not in ("keywords", "confidence", "source") and v
        ]

        return {
            "session_id": str(session.id),
            "recognition": {
                "category": category,
                "attributes": attributes_list,
                "suggestions": suggestions,
            },
            "suggestions": suggestions,
            "products": [
                serialize_product(p)
                for p in filtered_products
            ],
            "price_summary": price_summary,
        }

    async def _recognize_with_self_correction(self, image_bytes: bytes, max_retries: int = 0) -> dict:
        result = None
        for attempt in range(max_retries + 1):
            try:
                result = await self._vlm_client.recognize(image_bytes)
            except (VLMClientError, httpx.TimeoutException, httpx.ConnectError):
                if attempt == max_retries:
                    raise AIServiceUnavailableError()

            if not result:
                if attempt == max_retries:
                    raise RecognitionFailedError()
                continue

            confidence = result.get("confidence", {})
            all_ok = True
            for key in ("category", "color", "style"):
                if confidence.get(key, 1.0) < 0.7:
                    all_ok = False
                    break

            if all_ok and result.get("category"):
                return result

            if attempt < max_retries and self._llm_client:
                try:
                    result = await self._llm_client.self_correct(result)
                except (LLMClientError, httpx.TimeoutException, httpx.ConnectError):
                    pass

        if result is None:
            raise RecognitionFailedError()
        result["source"] = "low_confidence"
        return result

    async def update_attributes(
        self,
        session_id: str,
        attribute: str,
        new_value: str,
        db: AsyncSession,
    ) -> dict:
        """属性修正：更新识别属性后纯结构化重检索"""
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
        confidence = dict(rec.confidence)
        confidence[attribute] = 1.0

        rec.attributes = attrs
        rec.confidence = confidence
        await db.commit()

        keywords = attrs.get("keywords", [attrs.get("category", "")])
        if not keywords:
            keywords = [attrs.get("category", "")] if attrs.get("category") else [new_value]

        products = await self._search_service.search_all(
            keywords=keywords, session=search_session, db=db
        )

        filtered_products, _ = self._comparison_service.compare_and_rerank(
            products, keywords
        )

        label_map = _label_map()
        updated_attributes = [
            {"key": k, "label": label_map.get(k, k), "value": str(v) if v else "", "confidence": float(confidence.get(k, 0))}
            for k, v in attrs.items()
            if k not in ("keywords", "source") and v
        ]

        return {
            "updated_attributes": updated_attributes,
            "products": [
                {
                    "id": p.get("id", str(uuid.uuid4())),
                    "name": p.get("name", ""),
                    "price": float(p.get("price", 0)),
                    "original_price": float(p["original_price"]) if p.get("original_price") else None,
                    "platform": p.get("platform", ""),
                    "shop_name": p.get("shop_name", ""),
                    "shop_type": p.get("shop_type", "third_party"),
                    "rating": float(p["rating"]) if p.get("rating") else None,
                    "sales_count": int(p["sales_count"]) if p.get("sales_count") else None,
                    "image_url": p.get("image_url", ""),
                    "attributes": p.get("attributes", {}),
                    "tags": p.get("tags", []),
                }
                for p in filtered_products
            ],
        }


def _label_map() -> dict:
    return {
        "category": "品类",
        "brand": "品牌",
        "color": "颜色",
        "style": "风格",
        "material": "材质",
        "shape": "造型",
    }
