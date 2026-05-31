from pydantic import BaseModel


class TextSearchRequest(BaseModel):
    keywords: list[str]


class TextSearchResponse(BaseModel):
    session_id: str
    suggestions: list[dict]
    products: list[dict]
    price_summary: list[dict]
