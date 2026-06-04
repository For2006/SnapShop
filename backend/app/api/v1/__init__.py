from app.api.v1.recognize import router as recognize_router
from app.api.v1.search import router as search_router
from app.api.v1.products import router as products_router
from app.api.v1.filter import router as filter_router
from app.api.v1.suggestions import router as suggestions_router
from app.api.v1.history import router as history_router

__all__ = [
    "recognize_router",
    "search_router",
    "products_router",
    "filter_router",
    "suggestions_router",
    "history_router",
]
