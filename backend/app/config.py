import secrets
from typing import List

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = Field(default="SnapShop API")
    debug: bool = Field(default=True)

    database_url: str = Field(default="sqlite+aiosqlite:///./snapshop.db")

    redis_url: str = Field(default="redis://localhost:6379/0")
    redis_max_connections: int = 10
    redis_socket_timeout: int = 5
    redis_socket_connect_timeout: int = 5

    bcrypt_rounds: int = 12

    ark_api_key: SecretStr = SecretStr("")
    ark_vlm_endpoint_id: str = ""
    ark_llm_endpoint_id: str = ""
    ark_base_url: str = Field(default="https://ark.cn-beijing.volces.com/api/v3")

    minio_endpoint: str = "localhost:9000"
    minio_access_key: SecretStr = SecretStr("")
    minio_secret_key: SecretStr = SecretStr("")
    minio_bucket: str = "snapshop-images"
    minio_secure: bool = False

    use_mock_fallback: bool = True

    product_search_timeout: int = 8
    product_search_max_concurrent: int = 10
    platform_page_size: int = 20

    jwt_secret: SecretStr = SecretStr("")
    access_token_expire_hours: int = 24

    allowed_origins: str = ""

    redis_ttl_seconds: int = 3600

    recognize_rate_limit: int = 10
    filter_rate_limit: int = 30

    sms_code_expire_seconds: int = 300
    sms_code_cooldown_seconds: int = 60

    aliyun_sms_access_key_id: SecretStr = SecretStr("")
    aliyun_sms_access_key_secret: SecretStr = SecretStr("")
    aliyun_sms_sign_name: str = ""
    aliyun_sms_login_template_code: str = ""
    aliyun_sms_change_phone_template_code: str = ""

    pdd_client_id: str = ""
    pdd_client_secret: str = ""
    pdd_access_token: str = ""
    pdd_pid: str = ""
    pdd_media_id: str = ""
    pdd_custom_parameters: str = ""
    pdd_api_url: str = ""

    jd_app_key: str = ""
    jd_app_secret: str = ""
    jd_access_token: str = ""
    jd_site_id: str = ""
    jd_api_url: str = ""

    taobao_app_key: str = ""
    taobao_app_secret: str = ""
    taobao_adzone_id: str = ""

    @field_validator("jwt_secret", mode="after")
    @classmethod
    def set_default_jwt_secret_in_debug(cls, v: SecretStr, info):
        data = info.data or {}
        debug = data.get("debug", True)
        if debug and not v.get_secret_value():
            return SecretStr("snapshop-dev-secret-key-not-for-production")
        return v

    @field_validator("jwt_secret", mode="after")
    @classmethod
    def require_strong_jwt_secret_in_production(cls, v: SecretStr, info):
        data = info.data or {}
        debug = data.get("debug", True)
        if not debug and len(v.get_secret_value()) < 32:
            raise ValueError(
                "生产环境必须配置至少32位强随机JWT_SECRET，请运行 "
                'python -c "import secrets; print(secrets.token_urlsafe(32))" '
                "生成并填入 .env"
            )
        return v

    @field_validator("allowed_origins", mode="after")
    @classmethod
    def validate_cors_origins_in_production(cls, v: str, info):
        data = info.data or {}
        debug = data.get("debug", True)
        if not debug and not v:
            raise ValueError(
                "生产环境必须显式配置 ALLOWED_ORIGINS（逗号分隔的域名列表），"
                "禁止使用通配符 * 降低跨域攻击风险"
            )
        return v

    @property
    def allowed_origins_list(self) -> List[str]:
        if not self.allowed_origins:
            return []
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]

    def model_post_init(self, __context: object = None) -> None:
        if self.debug:
            print("=" * 60)
            print("[!] 警告: 当前运行在 DEBUG 开发模式，请勿用于生产环境")
            print("=" * 60)


settings = Settings()
