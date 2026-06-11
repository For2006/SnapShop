import asyncio
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
        rule_suggestions = self._generate_default_suggestions(recall_stats, recognition_result)

        if self._llm_client is None:
            return rule_suggestions

        try:
            llm_suggestions = await asyncio.wait_for(
                self._llm_client.generate_suggestions(recognition_result, recall_stats),
                timeout=5.0,
            )
        except Exception:
            return rule_suggestions

        if not isinstance(llm_suggestions, list) or not llm_suggestions:
            return rule_suggestions

        merged = self._merge_suggestions(rule_suggestions, llm_suggestions)

        if len(merged) < 4:
            return rule_suggestions[:6]
        if len(merged) > 6:
            return merged[:6]
        return merged

    def _merge_suggestions(self, rule_suggestions: list[dict], llm_suggestions: list[dict]) -> list[dict]:
        seen_ids = set()
        merged = []
        for card in rule_suggestions:
            merged.append(card)
            seen_ids.add(card["id"])
        for card in llm_suggestions:
            card_id = card.get("id", "")
            if card_id and card_id in seen_ids:
                continue
            merged.append(card)
            seen_ids.add(card_id)
        return merged

    def _generate_default_suggestions(self, recall_stats: dict, recognition_result: dict = None) -> list[dict]:
        suggestions = []
        platforms = recall_stats.get("platforms", {})
        total_count = recall_stats.get("total_count", 0)
        category = recall_stats.get("category", "") or (recognition_result.get("category", "") if recognition_result else "")
        prices = []
        ratings = []
        for plat_data in platforms.values():
            if isinstance(plat_data, dict):
                prices.append(plat_data.get("min_price", 0))
                if plat_data.get("avg_rating"):
                    ratings.append(plat_data.get("avg_rating", 0))

        suggestions.extend([
            {
                "id": "card_sort_price_asc",
                "title": "查看同款低价",
                "icon": "trending-down",
                "action": "sort_price",
                "type": "normal",
                "params": {"sort_by": "price_asc"},
            },
            {
                "id": "card_sort_sales",
                "title": "按销量排序",
                "icon": "trending-up",
                "action": "sort_sales",
                "type": "normal",
                "params": {"sort_by": "sales_desc"},
            },
            {
                "id": "card_sort_rating",
                "title": "按评分排序",
                "icon": "star",
                "action": "sort_rating",
                "type": "normal",
                "params": {"sort_by": "rating_desc"},
            },
            {
                "id": "card_filter_official",
                "title": "只看官方旗舰店",
                "icon": "shield-check",
                "action": "filter_official",
                "type": "normal",
                "params": {"shop_type": "official"},
            },
        ])

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

        if "数码" in category or "手机" in category or "电脑" in category or "笔记本" in category or "平板" in category:
            suggestions.append({
                "id": "card_jd_self",
                "title": "只看京东自营（含延保）",
                "icon": "verified",
                "action": "filter_jd_self",
                "type": "primary",
                "params": {"platform": "jd", "shop_type": "self_operated"},
            })

        if "美妆" in category or "护肤" in category or "化妆品" in category or "香水" in category:
            suggestions.append({
                "id": "card_tmall_official",
                "title": "天猫国际正品保障",
                "icon": "shield",
                "action": "filter_tmall",
                "type": "primary",
                "params": {"platform": "tmall"},
            })

        if "服饰" in category or "衣服" in category or "鞋" in category or "包" in category:
            suggestions.append({
                "id": "card_tmall_fashion",
                "title": "天猫品牌旗舰店",
                "icon": "palette",
                "action": "filter_tmall",
                "type": "normal",
                "params": {"platform": "tmall"},
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

        if "jd" in platforms:
            suggestions.append({
                "id": "card_filter_jd",
                "title": "只看京东商品",
                "icon": "shopping-cart",
                "action": "filter_platform",
                "type": "normal",
                "params": {"platform": "jd"},
            })

        if "taobao" in platforms or "tmall" in platforms:
            suggestions.append({
                "id": "card_filter_taobao",
                "title": "只看淘宝天猫",
                "icon": "shopping-bag",
                "action": "filter_platform",
                "type": "normal",
                "params": {"platform": "taobao"},
            })

        if ratings and len(ratings) >= 2:
            avg_rating = sum(ratings) / len(ratings)
            if avg_rating >= 4.5:
                suggestions.append({
                    "id": "card_high_rating",
                    "title": "筛选4.8分以上",
                    "icon": "star-filled",
                    "action": "filter_high_rating",
                    "type": "normal",
                    "params": {"min_rating": 4.8},
                })

        suggestions.append({
            "id": "card_filter_available",
            "title": "只看有货商品",
            "icon": "check-circle",
            "action": "filter_available",
            "type": "normal",
            "params": {"in_stock": True},
        })

        suggestions.append({
            "id": "card_sort_price_desc",
            "title": "查看高端精选",
            "icon": "diamond",
            "action": "sort_price_desc",
            "type": "normal",
            "params": {"sort_by": "price_desc"},
        })

        if total_count > 50:
            suggestions.append({
                "id": "card_more_filters",
                "title": "更多筛选条件",
                "icon": "sliders",
                "action": "show_filters",
                "type": "normal",
                "params": {},
            })

        return suggestions[:8]

    @staticmethod
    def get_preset_suggestions() -> list[dict]:
        return [
            {
                "id": "card_sort_price_asc",
                "title": "查看同款低价",
                "icon": "trending-down",
                "action": "sort_price",
                "type": "normal",
                "params": {"sort_by": "price_asc"},
            },
            {
                "id": "card_sort_sales",
                "title": "按销量排序",
                "icon": "trending-up",
                "action": "sort_sales",
                "type": "normal",
                "params": {"sort_by": "sales_desc"},
            },
            {
                "id": "card_sort_rating",
                "title": "按评分排序",
                "icon": "star",
                "action": "sort_rating",
                "type": "normal",
                "params": {"sort_by": "rating_desc"},
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

        min_rating = params.get("min_rating", 0)
        if min_rating > 0:
            query = query.where(Product.rating >= min_rating)

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
