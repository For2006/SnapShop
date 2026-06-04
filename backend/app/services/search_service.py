import uuid
import time
import logging
import asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.clients import create_platform_clients, BasePlatformClient
from app.clients.mock_product_generator import MockProductGenerator
from app.config import settings
from app.models import SearchSession, SessionStatus, Product
from app.core.database import async_session

logger = logging.getLogger(__name__)


class SearchService:
    def __init__(self):
        self._clients: list[BasePlatformClient] = create_platform_clients()

    async def search_all(
        self,
        keywords: list[str],
        session: SearchSession | None = None,
        db: AsyncSession | None = None,
    ) -> list[dict]:
        all_products: list[dict] = []

        if self._clients:
            # 为每个平台搜索添加超时控制 (8秒)
            tasks = [
                asyncio.wait_for(
                    client.search(keywords, page_size=settings.platform_page_size),
                    timeout=8.0
                ) for client in self._clients
            ]
            t0 = time.time()
            results_list = await asyncio.gather(*tasks, return_exceptions=True)
            elapsed = time.time() - t0
            logger.info(f"[SearchService] 平台搜索并行耗时={elapsed:.2f}s (客户端数={len(self._clients)})")

            failed_count = 0
            for i, result in enumerate(results_list):
                platform = self._clients[i].platform_name
                if isinstance(result, Exception):
                    failed_count += 1
                    logger.warning(f"[SearchService] {platform} 搜索异常: {result}")
                    continue
                for p in result:
                    p["platform"] = platform
                    all_products.append(p)
                logger.info(f"[SearchService] {platform} 返回 {len(result)} 条结果 (关键词: {keywords})")

            if failed_count == len(self._clients) and len(self._clients) > 0:
                if settings.use_mock_fallback:
                    logger.warning(f"[SearchService] 所有平台搜索均报错，启用 Mock 兜底 (关键词: {keywords})")
                    all_products = MockProductGenerator.get_products_by_keywords(keywords, "jd", count=20)
                    all_products += MockProductGenerator.get_products_by_keywords(keywords, "pdd", count=20)
                    all_products += MockProductGenerator.get_products_by_keywords(keywords, "taobao", count=20)
                    logger.info(f"[SearchService] Mock 生成 {len(all_products)} 条商品")
                else:
                    logger.warning(f"[SearchService] 所有平台搜索均报错，Mock 已禁用，返回空结果")
            elif not all_products:
                if settings.use_mock_fallback:
                    logger.info(f"[SearchService] 所有平台返回空结果，启用 Mock 兜底 (关键词: {keywords})")
                    all_products = MockProductGenerator.get_products_by_keywords(keywords, "jd", count=20)
                    all_products += MockProductGenerator.get_products_by_keywords(keywords, "pdd", count=20)
                    all_products += MockProductGenerator.get_products_by_keywords(keywords, "taobao", count=20)
                    logger.info(f"[SearchService] Mock 生成 {len(all_products)} 条商品")
                else:
                    logger.info(f"[SearchService] 所有平台返回空结果，Mock 已禁用 (关键词: {keywords})")

        if db is not None and session is not None:
            await self._persist_products(all_products, session.id, db)

        return all_products

    async def _persist_products(
        self,
        products: list[dict],
        session_id: str,
        db: AsyncSession,
    ):
        valid_products = []
        for p in products:
            try:
                valid_products.append(Product(
                    session_id=session_id,
                    name=p.get("name", ""),
                    price=float(p.get("price", 0)),
                    original_price=float(p["original_price"]) if p.get("original_price") is not None else None,
                    platform=p.get("platform", ""),
                    shop_name=p.get("shop_name", ""),
                    shop_type=p.get("shop_type", "third_party"),
                    rating=float(p["rating"]) if p.get("rating") is not None else None,
                    sales_count=int(p["sales_count"]) if p.get("sales_count") is not None else None,
                    image_url=p.get("image_url", ""),
                    product_url=p.get("product_url", ""),
                    is_mock=p.get("is_mock", False),
                    attributes=p.get("attributes", {}),
                ))
            except (ValueError, TypeError) as e:
                logger.warning(f"[SearchService] 产品序列化失败: {e}")
        if valid_products:
            db.add_all(valid_products)
            await db.commit()

    def get_clients(self) -> list[BasePlatformClient]:
        return self._clients
