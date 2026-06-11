from app.services.comparison_service import ComparisonService


class TestComparisonService:
    def setup_method(self):
        self.service = ComparisonService()

    def test_filter_seo_noise(self, sample_products_list):
        products = [
            {"id": "1", "name": "【官方正品】Nike 运动鞋 假一赔十", "price": 100, "platform": "taobao"},
            {"id": "2", "name": "限时特惠 Nike Air Max", "price": 200, "platform": "jd"},
        ]
        result, _ = self.service.compare_and_rerank(products, ["Nike"])
        assert len(result) >= 1
        for p in result:
            assert "【" not in p["name"]
            assert "假一赔十" not in p["name"]

    def test_deduplicate(self, sample_products_list):
        products = [
            {"id": "test_001", "name": "A", "price": 100, "platform": "taobao"},
            {"id": "test_001", "name": "A", "price": 100, "platform": "jd"},
            {"id": "test_002", "name": "B", "price": 200, "platform": "taobao"},
        ]
        result, _ = self.service.compare_and_rerank(products, [])
        assert len(result) == 2

    def test_price_aggregation(self):
        products = [
            {"id": "1", "name": "Nike A", "price": 100, "platform": "taobao"},
            {"id": "2", "name": "Nike B", "price": 300, "platform": "taobao"},
            {"id": "3", "name": "Nike C", "price": 200, "platform": "jd"},
        ]
        _, summary = self.service.compare_and_rerank(products, ["Nike"])
        assert len(summary) >= 2
        taobao_summary = next((s for s in summary if s["platform"] == "taobao"), None)
        assert taobao_summary is not None
        assert taobao_summary["min_price"] == 100
        assert taobao_summary["avg_price"] == 200.0
        assert taobao_summary["count"] == 2
        assert taobao_summary["platform_name"] == "淘宝"

    def test_empty_products(self):
        result, summary = self.service.compare_and_rerank([], [])
        assert result == []
        assert summary == []

    def test_keyword_filter(self):
        products = [
            {"id": "1", "name": "蓝牙耳机 黑色", "price": 100, "platform": "taobao"},
            {"id": "2", "name": "运动鞋 Nike", "price": 200, "platform": "jd"},
            {"id": "3", "name": "无线蓝牙耳机 Pro", "price": 150, "platform": "pdd"},
        ]
        result, _ = self.service.compare_and_rerank(products, ["蓝牙耳机"])
        assert len(result) == 2
        ids = {p["id"] for p in result}
        assert "1" in ids
        assert "3" in ids
