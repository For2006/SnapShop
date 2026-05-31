from typing import Any

from pydantic import BaseModel


class FilterRequest(BaseModel):
    session_id: str
    filter_text: str


class FilterParsingChunk(BaseModel):
    type: str = "parsing"
    filters: dict[str, Any]


class FilterProductChunk(BaseModel):
    type: str = "product"
    product: dict[str, Any]


class FilterSummaryChunk(BaseModel):
    type: str = "summary"
    total: int
    platforms: dict[str, Any] = {}


class FilterDoneChunk(BaseModel):
    type: str = "done"
