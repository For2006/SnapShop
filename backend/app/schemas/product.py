from typing import Any

from pydantic import BaseModel


class ProductSchema(BaseModel):
    id: str
    name: str
    price: float
    original_price: float | None = None
    platform: str
    shop_name: str
    shop_type: str
    rating: float | None = None
    sales_count: int | None = None
    image_url: str
    attributes: dict[str, Any] = {}
    tags: list[str] = []


class PriceSummarySchema(BaseModel):
    platform: str
    platform_name: str
    min_price: float
    avg_price: float
    count: int
