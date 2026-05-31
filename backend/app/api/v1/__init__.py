from fastapi import APIRouter

from app.api.v1.recognize import router as recognize_router
from app.api.v1.search import router as search_router
from app.api.v1.products import router as products_router
from app.api.v1.filter import router as filter_router
from app.api.v1.suggestions import router as suggestions_router
from app.api.v1.history import router as history_router

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(recognize_router, tags=["识别"])
api_router.include_router(search_router, tags=["搜索"])
api_router.include_router(products_router, tags=["商品"])
api_router.include_router(filter_router, tags=["筛选"])
api_router.include_router(suggestions_router, tags=["建议"])
api_router.include_router(history_router, tags=["历史"])
