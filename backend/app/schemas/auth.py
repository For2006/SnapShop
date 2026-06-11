import re

from pydantic import BaseModel, Field, field_validator


class RegisterRequest(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")
    password: str = Field(..., min_length=8, max_length=128)
    password_confirm: str = Field(..., min_length=8, max_length=128)

    @field_validator("password")
    @classmethod
    def password_must_have_letter_and_digit(cls, v: str) -> str:
        if not re.search(r"[a-zA-Z]", v) or not re.search(r"\d", v):
            raise ValueError("密码必须包含至少一个字母和一个数字")
        return v

    @field_validator("password_confirm")
    @classmethod
    def passwords_match(cls, v: str, info) -> str:
        password = info.data.get("password")
        if password is not None and v != password:
            raise ValueError("两次输入的密码不一致")
        return v


class LoginRequest(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11)
    password: str = Field(..., min_length=1, max_length=128)


class SendSmsCodeRequest(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")
    scene: str = Field(..., pattern=r"^[a-z_]+$", max_length=32)


class SmsLoginRequest(BaseModel):
    phone: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")
    code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(..., min_length=8, max_length=128)
    new_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("new_password")
    @classmethod
    def new_password_must_have_letter_and_digit(cls, v: str) -> str:
        if not re.search(r"[a-zA-Z]", v) or not re.search(r"\d", v):
            raise ValueError("密码必须包含至少一个字母和一个数字")
        return v


class ChangePhoneRequest(BaseModel):
    password: str = Field(..., min_length=8, max_length=128)
    new_phone: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")
    new_phone_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class UserResponse(BaseModel):
    id: str
    phone: str
    nickname: str
    avatar_url: str | None = None
    bio: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class SendSmsCodeResponse(BaseModel):
    success: bool
    debug_code: str | None = None


class UpdateProfileRequest(BaseModel):
    nickname: str | None = Field(None, max_length=50)
    avatar_url: str | None = Field(None, max_length=500)
    bio: str | None = Field(None, max_length=200)
