from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return _pwd_context.verify(plain_password, hashed_password)


def _get_secret() -> str:
    secret = settings.jwt_secret
    if not secret:
        raise ValueError("JWT_SECRET 环境变量未设置，请配置固定密钥")
    return secret


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=settings.access_token_expire_hours)
    to_encode = {"sub": user_id, "exp": expire, "aud": "snapshop-api", "iss": "snapshop"}
    secret = _get_secret()
    return jwt.encode(to_encode, secret, algorithm="HS256")


def decode_access_token(token: str) -> str | None:
    secret = _get_secret()
    try:
        payload = jwt.decode(token, secret, algorithms=["HS256"], options={"verify_aud": True})
        return payload.get("sub")
    except JWTError:
        return None
