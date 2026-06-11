import json
import logging
import uuid

from collections.abc import AsyncGenerator
from typing import Any

from sqlalchemy import String, cast, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.clients.strategy.llm_fallback_strategy import FilterStrategyContext
from app.models import FilterAction, Product

logger = logging.getLogger(__name__)


class FilterService:
    _action_write_errors = 0
    def __init__(self, llm_strategy=None, llm_client=None):
        self._strategy_context = FilterStrategyContext(llm_strategy)
        self._llm_client = llm_client

    async def filter_stream(
        self,
        session_id: str,
        filter_text: str,
        db: AsyncSession,
    ) -> AsyncGenerator[str, None]:
        try:
            sid = uuid.UUID(session_id)
        except ValueError:
            yield _sse_event({"type": "error", "message": "无效的session_id"})
            yield _sse_event({"type": "done"})
            return

        filters = await self._strategy_context.parse_filter(filter_text)
        yield _sse_event({"type": "parsing", "filters": filters})

        products = await self._execute_filter_query(sid, filters, db)

        platforms_count: dict[str, int] = {}
        for p in products:
            platforms_count[p.platform] = platforms_count.get(p.platform, 0) + 1
            yield _sse_event({"type": "product", "product": self._product_to_dict(p)})

        yield _sse_event({"type": "summary", "total": len(products), "platforms": platforms_count})
        yield _sse_event({"type": "done"})

        await self._record_filter_action(sid, filter_text, filters, len(products), db)

    async def filter_sync(
        self,
        session_id: str,
        filter_text: str,
        db: AsyncSession,
    ) -> list[Product]:
        try:
            sid = uuid.UUID(session_id)
        except ValueError:
            return []

        filters = await self._strategy_context.parse_filter(filter_text)
        products = await self._execute_filter_query(sid, filters, db)
        await self._record_filter_action(sid, filter_text, filters, len(products), db)
        return products

    async def _execute_filter_query(
        self, sid: uuid.UUID, filters: dict[str, Any], db: AsyncSession,
    ) -> list[Product]:
        query = select(Product).where(Product.session_id == sid)

        if filters.get("price_min") is not None:
            query = query.where(Product.price >= float(filters["price_min"]))
        if filters.get("price_max") is not None:
            query = query.where(Product.price <= float(filters["price_max"]))

        colors = filters.get("colors") or (
            [filters["color"]] if filters.get("color") else []
        )
        if colors:
            conditions = [
                cast(Product.attributes["color"], String).ilike(f"%{c.strip()}%")
                for c in colors if c and c.strip()
            ]
            if conditions:
                query = query.where(or_(*conditions))

        brands = filters.get("brands") or (
            [filters["brand"]] if filters.get("brand") else []
        )
        if brands:
            conditions = [
                cast(Product.attributes["brand"], String).ilike(f"%{b.strip()}%")
                for b in brands if b and b.strip()
            ]
            if conditions:
                query = query.where(or_(*conditions))

        platforms = filters.get("platforms") or (
            [filters["platform"]] if filters.get("platform") else []
        )
        if platforms:
            conditions = [
                Product.platform.ilike(f"%{p.strip()}%")
                for p in platforms if p and p.strip()
            ]
            if conditions:
                query = query.where(or_(*conditions))

        shop_types = filters.get("shop_types") or (
            [filters["shop_type"]] if filters.get("shop_type") else []
        )
        if shop_types:
            conditions = [
                Product.shop_type == t.strip()
                for t in shop_types if t and t.strip()
            ]
            if conditions:
                query = query.where(or_(*conditions))

        if filters.get("min_rating") is not None:
            query = query.where(Product.rating >= float(filters["min_rating"]))
        if filters.get("max_rating") is not None:
            query = query.where(Product.rating <= float(filters["max_rating"]))
        if filters.get("min_sales") is not None:
            query = query.where(Product.sales_count >= int(filters["min_sales"]))
        if filters.get("has_discount") is True:
            query = query.where(Product.original_price.isnot(None))
            query = query.where(Product.original_price > Product.price)

        result = await db.execute(query)
        return self._smart_rerank(list(result.scalars().all()), filters)

    @staticmethod
    def _product_to_dict(p: Product) -> dict:
        return {
            "id": str(p.id),
            "name": p.name,
            "price": float(p.price),
            "original_price": float(p.original_price) if p.original_price is not None else None,
            "platform": p.platform,
            "shop_name": p.shop_name,
            "shop_type": p.shop_type,
            "rating": float(p.rating) if p.rating is not None else None,
            "sales_count": p.sales_count,
            "image_url": p.image_url,
            "product_url": p.product_url or "",
            "is_mock": p.is_mock,
            "attributes": p.attributes or {},
            "tags": [],
        }

    async def _record_filter_action(
        self, sid: uuid.UUID, filter_text: str, filters: dict, count: int, db: AsyncSession,
    ):
        action = FilterAction(
            session_id=sid,
            action_type="text_filter",
            filter_text=filter_text,
            params=filters,
            result_count=count,
        )
        try:
            db.add(action)
            await db.commit()
        except Exception as e:
            FilterService._action_write_errors += 1
            logger.error(f"[FilterService] 写入FilterAction失败 (累计{FilterService._action_write_errors}次): {e}")

    async def parse_to_cards(self, filter_text: str) -> dict:
        """纯解析：将自然语言转为结构化 filters + UI 卡片，不查 DB"""
        filters = await self._strategy_context.parse_filter(filter_text)
        cards = self._filters_to_cards(filters)
        return {"filters": filters, "cards": cards}

    @staticmethod
    def _filters_to_cards(filters: dict[str, Any]) -> list[dict]:
        """将结构化 filters 转为前端可用的筛选卡片"""
        cards = []
        if filters.get("price_max") is not None:
            cards.append({"id": "price_max", "label": f"{int(filters['price_max'])}元以内", "key": "price_max", "value": filters["price_max"]})
        if filters.get("price_min") is not None:
            cards.append({"id": "price_min", "label": f"{int(filters['price_min'])}元以上", "key": "price_min", "value": filters["price_min"]})
        if filters.get("color"):
            cards.append({"id": "color", "label": filters["color"], "key": "color", "value": filters["color"]})
        if filters.get("brand"):
            cards.append({"id": "brand", "label": filters["brand"], "key": "brand", "value": filters["brand"]})
        if filters.get("shop_type"):
            from app.models import ShopType
            try:
                label = ShopType(filters["shop_type"]).label_zh
            except ValueError:
                label = filters["shop_type"]
            cards.append({"id": "shop_type", "label": label, "key": "shop_type", "value": filters["shop_type"]})
        if filters.get("min_rating") is not None:
            cards.append({"id": "min_rating", "label": f"{filters['min_rating']}分+", "key": "min_rating", "value": filters["min_rating"]})
        if filters.get("sort_by") and filters["sort_by"] != "none":
            sort_map = {"price_asc": "价格从低到高", "price_desc": "价格从高到低", "rating_desc": "好评优先", "sales_desc": "销量优先", "sales": "销量优先"}
            cards.append({"id": "sort", "label": sort_map.get(filters["sort_by"], filters["sort_by"]), "key": "sort_by", "value": filters["sort_by"]})
        return cards

    def _smart_rerank(self, products: list[Product], filters: dict[str, Any]) -> list[Product]:
        sort_by = filters.get("sort_by", "")

        def get_safe_rating(p: Product) -> float:
            return float(p.rating) if p.rating is not None else 0.0

        def get_safe_sales(p: Product) -> int:
            return p.sales_count if p.sales_count is not None else 0

        def get_discount_score(p: Product) -> float:
            if p.original_price and p.original_price > p.price:
                return (p.original_price - p.price) / p.original_price * 100
            return 0.0

        if sort_by == "price_asc":
            products.sort(key=lambda p: (p.price, -get_safe_rating(p), -get_safe_sales(p)))
        elif sort_by == "price_desc":
            products.sort(key=lambda p: (-p.price, -get_safe_rating(p), -get_safe_sales(p)))
        elif sort_by == "rating_desc":
            products.sort(key=lambda p: (-get_safe_rating(p), -get_safe_sales(p), p.price))
        elif sort_by == "sales_desc" or sort_by == "sales":
            products.sort(key=lambda p: (-get_safe_sales(p), -get_safe_rating(p), p.price))
        elif sort_by == "discount_desc":
            products.sort(key=lambda p: (-get_discount_score(p), -get_safe_rating(p), -get_safe_sales(p)))
        else:
            products.sort(
                key=lambda p: (
                    -get_safe_rating(p) * 2 +
                    min(get_safe_sales(p) / 1000.0, 5) +
                    get_discount_score(p) / 20.0
                )
            )

        return products


def _sse_event(data: dict[str, Any]) -> str:
    return f"data: {json.dumps(data, ensure_ascii=False)}\n\n"
