from pydantic import BaseModel


class SuggestionSchema(BaseModel):
    id: str
    title: str
    icon: str
    action: str
    type: str = "normal"
    params: dict = {}


class SuggestionActionRequest(BaseModel):
    session_id: str
    card_id: str
    params: dict = {}


class SuggestionActionResponse(BaseModel):
    products: list[dict]
