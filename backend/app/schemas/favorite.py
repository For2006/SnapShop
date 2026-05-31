from datetime import datetime
from pydantic import BaseModel, Field


class ProductSnapshotSchema(BaseModel):
    id: str = ""
    name: str = ""
    price: float = 0.0
    original_price: float | None = None
    platform: str = ""
    image_url: str = ""
    shop_name: str = ""
    shop_type: str = "third_party"
    rating: float | None = None
    sales_count: int | None = None
    tags: list[str] = []


class FavoriteAddRequest(BaseModel):
    product_id: str
    product_snapshot: ProductSnapshotSchema


class BrowseRecordRequest(BaseModel):
    product_id: str
    product_snapshot: ProductSnapshotSchema


class FavoriteItemResponse(BaseModel):
    id: str
    product_id: str
    product_snapshot: ProductSnapshotSchema
    created_at: datetime


class FavoriteListResponse(BaseModel):
    items: list[FavoriteItemResponse]
    total: int
    page: int
    size: int


class BrowseItemResponse(BaseModel):
    id: str
    product_id: str
    product_snapshot: ProductSnapshotSchema
    viewed_at: datetime


class BrowseListResponse(BaseModel):
    items: list[BrowseItemResponse]
    total: int
    page: int
    size: int


class UserStatsResponse(BaseModel):
    favorite_count: int
    browse_count: int
