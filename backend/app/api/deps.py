import uuid

from fastapi import Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db as _get_db
from app.core.exceptions import AppException, SessionNotFoundError
from app.models import SearchSession


async def get_db() -> AsyncSession:
    async for session in _get_db():
        yield session


def get_current_device(x_device_id: str = Header(None, alias="X-Device-Id")) -> str:
    if not x_device_id:
        x_device_id = "anonymous-device"
    return x_device_id


async def get_current_user(
    authorization: str | None = Header(None, alias="Authorization"),
    db: AsyncSession = Depends(get_db),
):
    from app.core.security import decode_access_token, is_token_blacklisted
    from app.models import User

    if not authorization or not authorization.startswith("Bearer "):
        raise AppException(status_code=401, error_code="UNAUTHORIZED", message="未登录，请先登录")
    token = authorization.removeprefix("Bearer ")
    if await is_token_blacklisted(token):
        raise AppException(status_code=401, error_code="TOKEN_REVOKED", message="Token已被吊销，请重新登录")
    user_id = decode_access_token(token)
    if not user_id:
        raise AppException(status_code=401, error_code="INVALID_TOKEN", message="Token无效或已过期")
    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        raise AppException(status_code=401, error_code="INVALID_TOKEN", message="Token无效或已过期")
    result = await db.execute(select(User).where(User.id == uid))
    user = result.scalar_one_or_none()
    if not user:
        raise AppException(status_code=401, error_code="INVALID_TOKEN", message="用户不存在，请重新登录")
    return user


async def get_optional_user(
    authorization: str | None = Header(None, alias="Authorization"),
    db: AsyncSession = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        return None
    try:
        return await get_current_user(authorization=authorization, db=db)
    except HTTPException:
        return None


async def get_session(
    session_id: str,
    db: AsyncSession = Depends(get_db),
) -> SearchSession:
    try:
        sid = uuid.UUID(session_id)
    except ValueError:
        raise SessionNotFoundError(session_id)
    result = await db.execute(select(SearchSession).where(SearchSession.id == sid))
    session = result.scalar_one_or_none()
    if not session:
        raise SessionNotFoundError(session_id)
    return session


_service_registry: dict[str, object] = {}


def _get_or_create_service(key: str, factory):
    if key not in _service_registry:
        _service_registry[key] = factory()
    return _service_registry[key]


def get_recognition_service():
    from app.clients.ark_llm_client import ArkLLMClient
    from app.clients.ark_vlm_client import ArkVLMClient
    from app.services.recognition_service import RecognitionService
    from app.services.search_service import SearchService

    search_service = _get_or_create_service("search", lambda: SearchService())
    return _get_or_create_service(
        "recognition",
        lambda: RecognitionService(
            vlm_client=ArkVLMClient(),
            llm_client=ArkLLMClient(),
            search_service=search_service,
        ),
    )


def get_search_service():
    from app.services.search_service import SearchService

    return _get_or_create_service("search", lambda: SearchService())


def get_filter_service():
    from app.clients.ark_llm_client import ArkLLMClient
    from app.clients.strategy.llm_fallback_strategy import ArkLLMStrategy
    from app.services.filter_service import FilterService

    return _get_or_create_service(
        "filter",
        lambda: FilterService(
            llm_strategy=ArkLLMStrategy(llm_client=ArkLLMClient()),
            llm_client=ArkLLMClient(),
        ),
    )


def get_suggestion_service():
    from app.clients.ark_llm_client import ArkLLMClient
    from app.services.suggestion_service import SuggestionService

    return _get_or_create_service("suggestion", lambda: SuggestionService(llm_client=ArkLLMClient()))


def get_comparison_service():
    from app.services.comparison_service import ComparisonService

    return _get_or_create_service("comparison", lambda: ComparisonService())


def get_text_search_service():
    from app.clients.ark_llm_client import ArkLLMClient
    from app.services.search_service import SearchService
    from app.services.text_search_service import TextSearchService

    search_service = _get_or_create_service("search", lambda: SearchService())
    return _get_or_create_service("text_search", lambda: TextSearchService(
        llm_client=ArkLLMClient(),
        search_service=search_service,
    ))
