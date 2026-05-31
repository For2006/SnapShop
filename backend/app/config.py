from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "SnapShop API"
    debug: bool = False

    database_url: str = "sqlite+aiosqlite:///./snapshop.db"

    redis_url: str = "redis://localhost:6379/0"

    minio_endpoint: str = "localhost:9000"
    minio_access_key: str = ""
    minio_secret_key: str = ""
    minio_bucket: str = "snapshop-images"

    ark_api_key: str = ""
    ark_vlm_endpoint_id: str = ""
    ark_llm_endpoint_id: str = ""
    ark_base_url: str = "https://ark.cn-beijing.volces.com/api/v3"

    # 拼多多开放平台
    pdd_client_id: str = ""
    pdd_client_secret: str = ""
    pdd_access_token: str = ""
    pdd_pid: str = ""
    pdd_media_id: str = ""
    pdd_custom_parameters: str = ""
    pdd_api_url: str = "https://gw-api.pinduoduo.com/api/router"

    # 京东联盟开放平台
    jd_app_key: str = ""
    jd_app_secret: str = ""
    jd_access_token: str = ""
    jd_site_id: str = ""
    jd_api_url: str = "https://router.jd.com/api"

    recognize_rate_limit: int = 10
    filter_rate_limit: int = 30

    # 电商平台每次请求返回商品数（1-50，默认 20）
    platform_page_size: int = 20  # 降低 page_size 提高响应速度

    # 是否启用 Mock 兜底（真实 API 失败或无结果时自动切换 Mock 数据）
    use_mock_fallback: bool = True

    # 开发环境未设置时自动生成随机密钥
    jwt_secret: str = ""
    access_token_expire_hours: int = 24


settings = Settings()
