from abc import ABC, abstractmethod
from typing import Any


class BasePlatformClient(ABC):
    @abstractmethod
    async def search(self, keywords: list[str], **filters: Any) -> list[dict[str, Any]]:
        ...

    @property
    @abstractmethod
    def platform_name(self) -> str:
        ...
