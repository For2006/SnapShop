from fastapi import APIRouter, Depends, Header, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.exceptions import AppException
from app.core.rate_limit import check_auth_rate_limit
from app.core.security import add_token_to_blacklist, create_access_token, hash_password, verify_password
from app.core.sms_service import get_sms_service
from app.models import User
from app.schemas.auth import (
    ChangePasswordRequest,
    ChangePhoneRequest,
    LoginRequest,
    RegisterRequest,
    SendSmsCodeRequest,
    SendSmsCodeResponse,
    SmsLoginRequest,
    TokenResponse,
    UpdateProfileRequest,
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
            message="该手机号已被注册",
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


@router.post("/auth/send-sms-code", response_model=SendSmsCodeResponse)
async def send_sms_code(
    body: SendSmsCodeRequest,
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    sms_svc = get_sms_service()
    try:
        code = await sms_svc.send(body.phone, body.scene)
    except Exception as e:
        raise AppException(
            status_code=429,
            error_code="SMS_CODE_TOO_FREQUENT",
            message="验证码发送过于频繁，请60秒后重试",
        ) from e

    return SendSmsCodeResponse(
        success=True,
        debug_code=code,
    )


@router.post("/auth/sms-login", response_model=TokenResponse)
async def sms_login(
    body: SmsLoginRequest,
    db: AsyncSession = Depends(get_db),
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    sms_svc = get_sms_service()
    ok = await sms_svc.verify(body.phone, "login", body.code)
    if not ok:
        raise AppException(
            status_code=401,
            error_code="INVALID_SMS_CODE",
            message="验证码错误或已过期",
        )

    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            phone=body.phone,
            hashed_password=hash_password(body.phone + "Auto123"),
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


@router.post("/auth/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    body: ChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    authorization: str | None = Header(None, alias="Authorization"),
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    if not verify_password(body.old_password, current_user.hashed_password):
        raise AppException(
            status_code=400,
            error_code="OLD_PASSWORD_MISMATCH",
            message="原密码不正确",
        )

    current_user.hashed_password = hash_password(body.new_password)
    if authorization and authorization.startswith("Bearer "):
        token = authorization.removeprefix("Bearer ")
        await add_token_to_blacklist(token)
    await db.commit()

    return {"success": True, "message": "密码修改成功"}


@router.post("/auth/change-phone", status_code=status.HTTP_200_OK)
async def change_phone(
    body: ChangePhoneRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _rate_limit: None = Depends(check_auth_rate_limit),
):
    sms_svc = get_sms_service()

    if not verify_password(body.password, current_user.hashed_password):
        raise AppException(
            status_code=400,
            error_code="PASSWORD_MISMATCH",
            message="账号密码验证失败",
        )

    new_ok = await sms_svc.verify(body.new_phone, "change_phone", body.new_phone_code)
    if not new_ok:
        raise AppException(
            status_code=400,
            error_code="NEW_PHONE_CODE_INVALID",
            message="新手机号验证码错误或已过期",
        )

    result = await db.execute(select(User).where(User.phone == body.new_phone))
    existing_new = result.scalar_one_or_none()
    if existing_new:
        raise AppException(
            status_code=409,
            error_code="NEW_PHONE_ALREADY_USED",
            message="新手机号已被其他账号使用",
        )

    current_user.phone = body.new_phone
    await db.commit()

    return {
        "success": True,
        "message": "手机号换绑成功",
        "new_masked_phone": _mask_phone(body.new_phone),
    }


@router.post("/auth/logout", status_code=status.HTTP_200_OK)
async def logout(
    authorization: str | None = Header(None, alias="Authorization"),
    current_user: User = Depends(get_current_user),
):
    if authorization and authorization.startswith("Bearer "):
        token = authorization.removeprefix("Bearer ")
        await add_token_to_blacklist(token)

    return {"success": True, "message": "登出成功，Token 已吊销"}


@router.patch("/auth/profile", response_model=UserResponse)
async def update_profile(
    body: UpdateProfileRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.nickname is not None:
        current_user.nickname = body.nickname
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url
    if body.bio is not None:
        current_user.bio = body.bio

    await db.commit()
    await db.refresh(current_user)

    return UserResponse(
        id=str(current_user.id),
        phone=_mask_phone(current_user.phone),
        nickname=current_user.nickname,
        avatar_url=current_user.avatar_url,
        bio=current_user.bio,
    )
