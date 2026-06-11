
from pydantic import BaseModel

from app.schemas.product import PriceSummarySchema, ProductSchema
from app.schemas.suggestion import SuggestionSchema


class AttributeConfidence(BaseModel):
    category: float = 0.0
    brand: float = 0.0
    color: float = 0.0
    style: float = 0.0
    material: float = 0.0
    shape: float = 0.0


class AttributeItem(BaseModel):
    key: str
    label: str
    value: str
    confidence: float


class RecognitionData(BaseModel):
    category: str
    attributes: list[AttributeItem]
    suggestions: list[SuggestionSchema]


class RecognizeResponse(BaseModel):
    session_id: str
    recognition: RecognitionData
    suggestions: list[SuggestionSchema]
    products: list[ProductSchema]
    price_summary: list[PriceSummarySchema]


class AttributeUpdateRequest(BaseModel):
    attribute: str
    new_value: str


class AttributeUpdateResponse(BaseModel):
    updated_attributes: list[AttributeItem]
    products: list[ProductSchema]
