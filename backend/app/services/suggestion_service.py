import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Product


class SuggestionService:
    def __init__(self, llm_client=None):
        self._llm_client = llm_client

    async def generate(
        self,
        recognition_result: dict,
        recall_stats: dict,
    ) -> list[dict]:
        # 优先使用快速生成的默认建议，提高响应速度
        # 不再等待缓慢的 LLM 调用
        return self._generate_default_suggestions(recall_stats)

    def _generate_default_suggestions(self, recall_stats: dict) -> list[dict]:
        suggestions = [
            {
                "id": "card_sort_price",
                "title": "查看同款低价",
                "icon": "trending-down",
                "action": "sort_price",
                "type": "normal",
                "params": {"sort_by": "price_asc"},
            },
            {
                "id": "card_filter_official",
                "title": "只看官方旗舰店",
                "icon": "shield-check",
                "action": "filter_official",
                "type": "normal",
                "params": {"shop_type": "official"},
            },
        ]

        platforms = recall_stats.get("platforms", {})
        prices = []
        for plat_data in platforms.values():
            if isinstance(plat_data, dict):
                prices.append(plat_data.get("min_price", 0))
        if prices and len(prices) >= 2:
            if max(prices) / (min(prices) + 0.01) > 1.3:
                suggestions.append({
                    "id": "card_budget",
                    "title": "按预算筛选",
                    "icon": "filter",
                    "action": "filter_budget",
                    "type": "normal",
                    "params": {},
                })

        category = recall_stats.get("category", "")
        if "数码" in category or "手机" in category or "电脑" in category:
            suggestions.append({
                "id": "card_jd_self",
                "title": "只看京东自营（含延保服务）",
                "icon": "verified",
                "action": "filter_jd_self",
                "type": "primary",
                "params": {"platform": "jd", "shop_type": "self_operated"},
            })

        pdd_min = None
        other_min = None
        for plat, data in platforms.items():
            if isinstance(data, dict):
                mp = data.get("min_price", 0)
                if plat == "pdd":
                    pdd_min = mp
                elif other_min is None or mp < other_min:
                    other_min = mp
        if pdd_min and other_min and other_min > 0 and pdd_min < other_min * 0.9:
            suggestions.append({
                "id": "card_pdd_lowest",
                "title": "全网最低价在拼多多",
                "icon": "zap",
                "action": "filter_pdd",
                "type": "primary",
                "params": {"platform": "pdd"},
            })

        return suggestions[:6]

    @staticmethod
    def get_preset_suggestions() -> list[dict]:
        return [
            {
                "id": "card_sort_price",
                "title": "查看同款低价",
                "icon": "trending-down",
                "action": "sort_price",
                "type": "normal",
                "params": {"sort_by": "price_asc"},
            },
            {
                "id": "card_filter_official",
                "title": "只看官方旗舰店",
                "icon": "shield-check",
                "action": "filter_official",
                "type": "normal",
                "params": {"shop_type": "official"},
            },
        ]

    async def execute_action(
        self,
        session_id: str,
        card_id: str,
        params: dict,
        db: AsyncSession,
    ) -> list[dict]:
        try:
            sid = uuid.UUID(session_id)
        except ValueError:
            return []

        query = select(Product).where(Product.session_id == sid)

        sort_by = params.get("sort_by", "")
        if sort_by == "price_asc":
            query = query.order_by(Product.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Product.price.desc())
        elif sort_by == "rating":
            query = query.order_by(Product.rating.desc().nullslast())
        elif sort_by == "sales":
            query = query.order_by(Product.sales_count.desc().nullslast())

        shop_type = params.get("shop_type", "")
        if shop_type:
            query = query.where(Product.shop_type == shop_type)

        platform = params.get("platform", "")
        if platform:
            query = query.where(Product.platform == platform)

        result = await db.execute(query.limit(100))
        products = result.scalars().all()

        return [
            {
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
                "is_mock": p.is_mock,
                "attributes": p.attributes or {},
                "tags": [],
            }
            for p in products
        ]
