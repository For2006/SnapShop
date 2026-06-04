import logging
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse

logger = logging.getLogger("snapshop")


def setup_structured_logging():
    logger.setLevel(logging.INFO)
    
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    handler = logging.StreamHandler()
    
    try:
        from pythonjsonlogger import jsonlogger
        formatter = jsonlogger.JsonFormatter(
            "%(asctime)s %(levelname)s %(name)s %(message)s %(request_id)s %(method)s %(path)s %(process_time)s %(status_code)s %(exception)s"
        )
    except ImportError:
        class SimpleFormatter(logging.Formatter):
            def format(self, record):
                record.__dict__.setdefault('request_id', '-')
                record.__dict__.setdefault('method', '-')
                record.__dict__.setdefault('path', '-')
                record.__dict__.setdefault('process_time', '-')
                record.__dict__.setdefault('status_code', '-')
                record.__dict__.setdefault('exception', '-')
                return super().format(record)
        formatter = SimpleFormatter(
            "%(asctime)s - %(levelname)s - %(name)s - %(message)s - req_id=%(request_id)s - %(method)s %(path)s - time=%(process_time)s - status=%(status_code)s - err=%(exception)s"
        )
    
    handler.setFormatter(formatter)
    logger.addHandler(handler)


setup_structured_logging()

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
from app.core.cache import get_redis_client, close_redis_client
from app.core.exceptions import AppException
from app.schemas.common import ErrorResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await get_redis_client()  # Initialize Redis client
    # 可选地初始化 Prometheus
    try:
        from app.core.metrics import instrumentator
        instrumentator.instrument(app)
    except ImportError:
        pass
    yield
    await _cleanup_clients()
    await close_redis_client()  # Close Redis client


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

# 可选地集成 Prometheus 指标
try:
    from app.core.metrics import instrumentator
    instrumentator.expose(app)
except ImportError:
    pass

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加 Gzip 压缩中间件，压缩级别 6，最小压缩大小 1KB
app.add_middleware(GZipMiddleware, minimum_size=1024, compresslevel=6)


@app.middleware("http")
async def structured_logging_middleware(request: Request, call_next):
    request_id = str(uuid.uuid4())
    start_time = time.time()
    
    request.state.request_id = request_id
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time"] = str(process_time)
        
        log_extra = {
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "process_time": process_time,
            "status_code": response.status_code,
            "exception": None,
        }
        
        logger.info(
            "Request processed",
            extra=log_extra
        )
        
        return response
    except Exception as e:
        process_time = time.time() - start_time
        log_extra = {
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "process_time": process_time,
            "status_code": 500,
            "exception": str(e),
        }
        logger.exception(
            "Request failed",
            extra=log_extra
        )
        raise


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
    request_id = getattr(request.state, "request_id", "unknown")
    log_extra = {
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
        "process_time": 0,
        "status_code": 500,
        "exception": str(exc),
    }
    if settings.debug:
        logger.exception("Internal error", extra=log_extra)
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
    request_id = getattr(request.state, "request_id", "unknown")
    log_extra = {
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
        "process_time": 0,
        "status_code": exc.status_code,
        "exception": str(exc),
    }
    logger.warning(
        "Application exception",
        extra=log_extra
    )
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
    request_id = getattr(request.state, "request_id", "unknown")
    detail = str(exc.errors()) if settings.debug else None
    log_extra = {
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
        "process_time": 0,
        "status_code": 400,
        "exception": detail,
    }
    logger.warning(
        "Validation error",
        extra=log_extra
    )
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(
            error_code="VALIDATION_ERROR",
            message="请求参数校验失败",
            detail=detail,
        ).model_dump(),
    )
