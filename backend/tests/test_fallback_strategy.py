import pytest
from app.clients.strategy.llm_fallback_strategy import RegexOfflineStrategy, FilterStrategyContext


class TestRegexOfflineStrategy:
    def setup_method(self):
        self.strategy = RegexOfflineStrategy()

    @pytest.mark.asyncio
    async def test_price_max(self):
        result = await self.strategy.parse_filter("500元以内")
        assert result["price_max"] == 500.0

    @pytest.mark.asyncio
    async def test_price_range(self):
        result = await self.strategy.parse_filter("100-500元")
        assert result["price_min"] == 100.0
        assert result["price_max"] == 500.0

    @pytest.mark.asyncio
    async def test_color(self):
        result = await self.strategy.parse_filter("黑色款 白色")
        assert result["color"] == "黑色"

    @pytest.mark.asyncio
    async def test_shop_type_official(self):
        result = await self.strategy.parse_filter("只看旗舰店")
        assert result["shop_type"] == "official"

    @pytest.mark.asyncio
    async def test_shop_type_self_operated(self):
        result = await self.strategy.parse_filter("自营的")
        assert result["shop_type"] == "self_operated"

    @pytest.mark.asyncio
    async def test_min_rating(self):
        result = await self.strategy.parse_filter("4.8分以上")
        assert result["min_rating"] == 4.8

    @pytest.mark.asyncio
    async def test_sort_by_rating(self):
        result = await self.strategy.parse_filter("评价最好的")
        assert result["sort_by"] == "rating_desc"

    @pytest.mark.asyncio
    async def test_sort_by_price_asc(self):
        result = await self.strategy.parse_filter("价格从低到高")
        assert result["sort_by"] == "price_asc"

    @pytest.mark.asyncio
    async def test_sort_by_sales(self):
        result = await self.strategy.parse_filter("销量最高的")
        assert result["sort_by"] == "sales"

    @pytest.mark.asyncio
    async def test_combined(self):
        result = await self.strategy.parse_filter("500元以内 黑色 自营 4.8分以上")
        assert result["price_max"] == 500.0
        assert result["color"] == "黑色"
        assert result["shop_type"] == "self_operated"
        assert result["min_rating"] == 4.8

    @pytest.mark.asyncio
    async def test_brand(self):
        result = await self.strategy.parse_filter("Nike品牌的")
        assert result["brand"] == "Nike"

    @pytest.mark.asyncio
    async def test_empty_input(self):
        result = await self.strategy.parse_filter("随便看看")
        assert "user_intent" in result
