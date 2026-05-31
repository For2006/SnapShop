import json
import uuid
from typing import AsyncGenerator, Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product, FilterAction
from app.clients.strategy.llm_fallback_strategy import FilterStrategyContext


class FilterService:
    def __init__(self, llm_strategy=None):
        self._strategy_context = FilterStrategyContext(llm_strategy)

    async def filter_stream(
        self,
        session_id: str,
        filter_text: str,
        db: AsyncSession,
    ) -> AsyncGenerator[str, None]:
        try:
            sid = uuid.UUID(session_id)
        except ValueError:
            yield _sse_event({"type": "error", "message": "\u65e0\u6548\u7684session_id"})
            yield _sse_event({"type": "done"})
            return

        filters = await self._strategy_context.parse_filter(filter_text)

        yield _sse_event({"type": "parsing", "filters": filters})

        query = select(Product).where(Product.session_id == sid)

        if filters.get("price_min"):
            query = query.where(Product.price >= float(filters["price_min"]))
        if filters.get("price_max"):
            query = query.where(Product.price <= float(filters["price_max"]))
        if filters.get("color"):
            query = query.where(Product.attributes["color"].as_string() == filters["color"])
        if filters.get("brand"):
            query = query.where(Product.attributes["brand"].as_string() == filters["brand"])
        if filters.get("shop_type"):
            query = query.where(Product.shop_type == filters["shop_type"])
        if filters.get("min_rating"):
            query = query.where(Product.rating >= float(filters["min_rating"]))

        sort_by = filters.get("sort_by", "")
        if sort_by == "price_asc":
            query = query.order_by(Product.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Product.price.desc())
        elif sort_by == "rating_desc":
            query = query.order_by(Product.rating.desc().nullslast())
        elif sort_by == "sales":
            query = query.order_by(Product.sales_count.desc().nullslast())

        result = await db.execute(query)
        products = result.scalars().all()

        platforms: dict[str, int] = {}
        for p in products:
            platforms[p.platform] = platforms.get(p.platform, 0) + 1
            product_dict = {
                "id": str(p.id),
                "name": p.name,
                "price": float(p.price),
                "original_price": float(p.original_price) if p.original_price else None,
                "platform": p.platform,
                "shop_name": p.shop_name,
                "shop_type": p.shop_type,
                "rating": float(p.rating) if p.rating else None,
                "sales_count": p.sales_count,
                "image_url": p.image_url,
                "attributes": p.attributes or {},
                "tags": [],
            }
            yield _sse_event({"type": "product", "product": product_dict})

        yield _sse_event({"type": "summary", "total": len(products), "platforms": platforms})
        yield _sse_event({"type": "done"})

        action = FilterAction(
            session_id=sid,
            action_type="text_filter",
            filter_text=filter_text,
            params=filters,
            result_count=len(products),
        )
        db.add(action)
        await db.commit()


def _sse_event(data: dict[str, Any]) -> str:
    return f"data: {json.dumps(data, ensure_ascii=False)}\n\n"
