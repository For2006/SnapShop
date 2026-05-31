import logging

from app.clients.base_platform_client import BasePlatformClient

logger = logging.getLogger(__name__)


def create_platform_clients() -> list[BasePlatformClient]:
    from app.config import settings

    clients: list[BasePlatformClient] = []

    if settings.pdd_client_id:
        from app.clients.real_pdd_client import RealPDDClient
        clients.append(RealPDDClient())

    if settings.jd_app_key:
        from app.clients.real_jd_client import RealJDClient
        clients.append(RealJDClient())

    return clients


__all__ = [
    "BasePlatformClient",
    "create_platform_clients",
]