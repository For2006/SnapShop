from app.api.v1.filter import router as filter_router
from app.api.v1.history import router as history_router
from app.api.v1.products import router as products_router
from app.api.v1.recognize import router as recognize_router
from app.api.v1.search import router as search_router
from app.api.v1.suggestions import router as suggestions_router

__all__ = [
    "filter_router",
    "history_router",
    "products_router",
    "recognize_router",
    "search_router",
    "suggestions_router",
]
