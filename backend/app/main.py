import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

logger = logging.getLogger("snapshop")

from app.api.v1 import (
    auth,
    recognize,
    search,
    products,
    filter,
    suggestions,
    history,
    favorites,
    browse,
    stats,
)
from app.config import settings
from app.core.database import init_db
from app.core.exceptions import AppException
from app.schemas.common import ErrorResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await _cleanup_clients()


async def _cleanup_clients():
    from app.api.deps import _service_registry
    from app.services.search_service import SearchService

    for key, svc in list(_service_registry.items()):
        if isinstance(svc, SearchService):
            for client in svc.get_clients():
                try:
                    await client.close()
                except Exception:
                    pass


app = FastAPI(
    title=settings.app_name,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加性能监控中间件
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    try:
        logger.info("%s %s - %.2fs", request.method, request.url.path, process_time)
    except UnicodeEncodeError:
        logger.info("[%s] %s - %.2fs", request.method, request.url.path, process_time)
    return response


@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "frame-ancestors 'none'"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    if settings.debug:
        logger.exception("Internal error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "error_code": "INTERNAL_ERROR",
            "message": "服务器内部错误",
            "detail": None,
        },
    )


app.include_router(auth.router, prefix="/api/v1", tags=["auth"])
app.include_router(recognize.router, prefix="/api/v1", tags=["recognize"])
app.include_router(search.router, prefix="/api/v1", tags=["search"])
app.include_router(products.router, prefix="/api/v1", tags=["products"])
app.include_router(filter.router, prefix="/api/v1", tags=["filter"])
app.include_router(suggestions.router, prefix="/api/v1", tags=["suggestions"])
app.include_router(history.router, prefix="/api/v1", tags=["history"])
app.include_router(favorites.router, prefix="/api/v1", tags=["favorites"])
app.include_router(browse.router, prefix="/api/v1", tags=["browse"])
app.include_router(stats.router, prefix="/api/v1", tags=["stats"])


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error_code=exc.detail["error_code"],
            message=exc.detail["message"],
            detail=exc.detail.get("detail"),
        ).model_dump(),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    if settings.debug:
        detail = str(exc.errors())
    else:
        detail = None
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(
            error_code="VALIDATION_ERROR",
            message="请求参数校验失败",
            detail=detail,
        ).model_dump(),
    )
