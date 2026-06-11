from typing import Generic, TypeVar

from pydantic import BaseModel


class ErrorResponse(BaseModel):
    error_code: str
    message: str
    detail: str | None = None


T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    size: int
