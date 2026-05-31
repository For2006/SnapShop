import re
from abc import ABC, abstractmethod
from typing import Any


class BaseLLMFallbackStrategy(ABC):
    @abstractmethod
    async def parse_filter(self, user_input: str, context: dict[str, Any] | None = None) -> dict[str, Any]:
        ...


class ArkLLMStrategy(BaseLLMFallbackStrategy):
    def __init__(self, llm_client):
        self.llm_client = llm_client

    async def parse_filter(self, user_input: str, context: dict[str, Any] | None = None) -> dict[str, Any]:
        return await self.llm_client.parse_filter_intent(user_input, context or {})


class RegexOfflineStrategy(BaseLLMFallbackStrategy):
    async def parse_filter(self, user_input: str, context: dict[str, Any] | None = None) -> dict[str, Any]:
        filters: dict[str, Any] = {}

        price_patterns = [
            (r'(\d+)\s*元?\s*以内', 'price_max'),
            (r'不超过\s*(\d+)\s*元?', 'price_max'),
            (r'(\d+)\s*元?\s*以下', 'price_max'),
            (r'(\d+)\s*元?\s*以上', 'price_min'),
            (r'不低于\s*(\d+)\s*元?', 'price_min'),
            (r'(\d+)\s*[-~到至]\s*(\d+)\s*元?', 'price_range'),
        ]

        for pattern, key in price_patterns:
            match = re.search(pattern, user_input)
            if match:
                if key == 'price_range':
                    filters['price_min'] = float(match.group(1))
                    filters['price_max'] = float(match.group(2))
                else:
                    filters[key] = float(match.group(1))

        colors = ['黑色', '白色', '红色', '蓝色', '绿色', '黄色', '紫色', '粉色', '灰色', '棕色', '橙色']
        for color in colors:
            if color in user_input:
                filters['color'] = color
                break

        brands = ['Nike', 'Adidas', '苹果', 'Apple', '华为', 'Huawei', '小米', 'Xiaomi', '索尼', 'Sony']
        for brand in brands:
            if brand in user_input:
                filters['brand'] = brand
                break

        if '自营' in user_input:
            filters['shop_type'] = 'self_operated'
        elif '旗舰店' in user_input or '官方' in user_input:
            filters['shop_type'] = 'official'

        rating_match = re.search(r'(\d+(?:\.\d+)?)\s*分\s*以上', user_input)
        if rating_match:
            filters['min_rating'] = float(rating_match.group(1))

        sort_map = {
            '价格从低到高': 'price_asc',
            '价格从高到低': 'price_desc',
            '评价': 'rating_desc',
            '好评': 'rating_desc',
            '销量': 'sales',
        }
        for keyword, sort_value in sort_map.items():
            if keyword in user_input:
                filters['sort_by'] = sort_value
                break

        filters['user_intent'] = user_input
        return filters


class FilterStrategyContext:
    def __init__(self, llm_strategy: ArkLLMStrategy | None = None):
        self.llm_strategy = llm_strategy
        self.regex_strategy = RegexOfflineStrategy()

    async def parse_filter(self, user_input: str, context: dict[str, Any] | None = None) -> dict[str, Any]:
        if self.llm_strategy:
            try:
                return await self.llm_strategy.parse_filter(user_input, context)
            except Exception:
                pass
        return await self.regex_strategy.parse_filter(user_input, context)
