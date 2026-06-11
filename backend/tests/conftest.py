from unittest.mock import AsyncMock

import pytest

from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def mock_db():
    return AsyncMock()


@pytest.fixture
def mock_vlm_client():
    client = AsyncMock()
    client.recognize.return_value = {
        "category": "运动鞋",
        "brand": "Nike",
        "color": "黑色",
        "style": "运动",
        "material": "网面",
        "shape": "高帮",
        "keywords": ["运动鞋", "跑鞋", "sneaker", "Nike"],
        "confidence": {
            "category": 0.95,
            "brand": 0.88,
            "color": 0.92,
            "style": 0.85,
            "material": 0.80,
            "shape": 0.75,
        },
    }
    return client


@pytest.fixture
def mock_vlm_low_confidence():
    client = AsyncMock()
    client.recognize.return_value = {
        "category": "运动鞋",
        "brand": "",
        "color": "蓝色",
        "style": "",
        "material": "",
        "shape": "",
        "keywords": ["运动鞋", "鞋"],
        "confidence": {
            "category": 0.55,
            "brand": 0.30,
            "color": 0.40,
            "style": 0.25,
            "material": 0.20,
            "shape": 0.15,
        },
    }
    return client


@pytest.fixture
def mock_vlm_failing():
    client = AsyncMock()
    client.recognize.side_effect = Exception("VLM API error")
    return client


@pytest.fixture
def mock_llm_client():
    client = AsyncMock()
    client.generate.return_value = {"result": "ok"}
    client.generate_suggestions.return_value = [
        {"id": "card_1", "title": "查看同款低价", "icon": "trending-down", "action": "sort_price", "type": "normal", "params": {"sort_by": "price_asc"}},
        {"id": "card_2", "title": "只看官方旗舰店", "icon": "shield-check", "action": "filter_official", "type": "normal", "params": {"shop_type": "official"}},
    ]
    client.parse_filter_intent.return_value = {
        "price_max": 1000, "color": "黑色", "min_rating": 4.8, "user_intent": "搜索中等价位黑色高评价商品"
    }
    client.expand_keywords.return_value = {
        "category": "蓝牙耳机",
        "color": "黑色",
        "keywords": ["蓝牙耳机", "无线耳机", "黑色", "入耳式"]
    }
    client.self_correct.return_value = {
        "category": "运动鞋",
        "brand": "Nike",
        "color": "红色",
        "style": "运动",
        "material": "网面",
        "shape": "",
        "keywords": ["运动鞋", "跑鞋", "sneaker"],
        "confidence": {"category": 0.90, "brand": 0.80, "color": 0.85, "style": 0.75, "material": 0.70, "shape": 0.60},
    }
    return client


@pytest.fixture
def sample_product():
    return {
        "id": "test_001",
        "name": "Nike Air Max 270 男子跑步鞋",
        "price": 899.00,
        "original_price": 1199.00,
        "platform": "taobao",
        "shop_name": "Nike官方旗舰店",
        "shop_type": "official",
        "rating": 4.9,
        "sales_count": 12580,
        "image_url": "https://example.com/test.jpg",
        "product_url": "https://example.com/product/test_001",
        "attributes": {"brand": "Nike", "color": "黑色", "style": "运动", "material": "网面"},
        "tags": ["官方正品", "7天无理由"],
    }


@pytest.fixture
def sample_products_list():
    return [
        {
            "id": "test_001",
            "name": "Nike Air Max 270 男子跑步鞋",
            "price": 899.00,
            "original_price": 1199.00,
            "platform": "taobao",
            "shop_name": "Nike官方旗舰店",
            "shop_type": "official",
            "rating": 4.9,
            "sales_count": 12580,
            "image_url": "https://example.com/test1.jpg",
            "attributes": {"brand": "Nike", "color": "黑色"},
            "tags": [],
        },
        {
            "id": "test_002",
            "name": "Nike Air Max 男子运动鞋",
            "price": 859.00,
            "original_price": 1099.00,
            "platform": "jd",
            "shop_name": "京东自营",
            "shop_type": "self_operated",
            "rating": 4.8,
            "sales_count": 8900,
            "image_url": "https://example.com/test2.jpg",
            "attributes": {"brand": "Nike", "color": "蓝色"},
            "tags": [],
        },
        {
            "id": "test_003",
            "name": "耐克男鞋跑步鞋",
            "price": 699.00,
            "original_price": 999.00,
            "platform": "pdd",
            "shop_name": "耐克品牌店",
            "shop_type": "third_party",
            "rating": 4.6,
            "sales_count": 34000,
            "image_url": "https://example.com/test3.jpg",
            "attributes": {"brand": "Nike", "color": "红色"},
            "tags": ["百亿补贴"],
        },
    ]
