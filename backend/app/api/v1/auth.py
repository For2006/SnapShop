from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.exceptions import AppException
from app.core.security import create_access_token, hash_password, verify_password
from app.core.rate_limit import check_auth_rate_limit
from app.models import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter()


def _mask_phone(phone: str) -> str:
    return phone[:3] + "****" + phone[7:]


@router.post("/auth/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    db: AsyncSession = Depends(get_db),
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    result = await db.execute(select(User).where(User.phone == body.phone))
    existing = result.scalar_one_or_none()
    if existing:
        raise AppException(
            status_code=409,
            error_code="PHONE_ALREADY_EXISTS",
            message="注册失败，请稍后重试",
        )

    user = User(
        phone=body.phone,
        hashed_password=hash_password(body.password),
        nickname="用户" + body.phone[-4:],
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(str(user.id))
    return TokenResponse(
        access_token=token,
        user=UserResponse(
            id=str(user.id),
            phone=_mask_phone(user.phone),
            nickname=user.nickname,
            avatar_url=user.avatar_url,
            bio=user.bio,
        ),
    )


@router.post("/auth/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    db: AsyncSession = Depends(get_db),
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.hashed_password):
        raise AppException(
            status_code=401,
            error_code="INVALID_CREDENTIALS",
            message="手机号或密码错误",
        )

    token = create_access_token(str(user.id))
    return TokenResponse(
        access_token=token,
        user=UserResponse(
            id=str(user.id),
            phone=_mask_phone(user.phone),
            nickname=user.nickname,
            avatar_url=user.avatar_url,
            bio=user.bio,
        ),
    )
