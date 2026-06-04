import json
import pickle
import logging
from functools import wraps
from typing import Any, Callable, Optional, TypeVar

import redis.asyncio as redis

from app.config import settings

logger = logging.getLogger("snapshop")

_redis_client: Optional[redis.Redis] = None
_T = TypeVar("_T")


async def get_redis_client() -> redis.Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.from_url(settings.redis_url, decode_responses=False)
    return _redis_client


async def close_redis_client() -> None:
    global _redis_client
    if _redis_client is not None:
        await _redis_client.close()
        _redis_client = None


class CacheManager:
    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self._redis = redis_client

    async def _get_client(self) -> redis.Redis:
        if self._redis is None:
            self._redis = await get_redis_client()
        return self._redis

    async def get(self, key: str) -> Optional[Any]:
        try:
            client = await self._get_client()
            data = await client.get(key)
            if data is None:
                return None
            try:
                return json.loads(data)
            except (json.JSONDecodeError, TypeError):
                return pickle.loads(data)
        except Exception:
            return None

    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        try:
            client = await self._get_client()
            if isinstance(value, (str, int, float, list, dict, bool, type(None))):
                data = json.dumps(value, ensure_ascii=False).encode("utf-8")
            else:
                data = pickle.dumps(value)
            if ttl:
                await client.setex(key, ttl, data)
            else:
                await client.set(key, data)
            return True
        except Exception:
            return False

    async def delete(self, key: str) -> int:
        try:
            client = await self._get_client()
            return await client.delete(key)
        except Exception:
            return 0

    async def delete_pattern(self, pattern: str) -> int:
        try:
            client = await self._get_client()
            keys = await client.keys(pattern)
            if keys:
                return await client.delete(*keys)
            return 0
        except Exception:
            return 0

    async def exists(self, key: str) -> bool:
        try:
            client = await self._get_client()
            return bool(await client.exists(key))
        except Exception:
            return False

    async def expire(self, key: str, ttl: int) -> bool:
        try:
            client = await self._get_client()
            return bool(await client.expire(key, ttl))
        except Exception:
            return False


_cache_manager: Optional[CacheManager] = None


def get_cache_manager() -> CacheManager:
    global _cache_manager
    if _cache_manager is None:
        _cache_manager = CacheManager()
    return _cache_manager


def cached(key_prefix: str, ttl: int = 300):
    def decorator(func: Callable[..., _T]) -> Callable[..., _T]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            cache_key = f"{key_prefix}:{hash(str(args) + str(sorted(kwargs.items())))}"
            cache = get_cache_manager()
            cached_result = await cache.get(cache_key)
            if cached_result is not None:
                return cached_result
            result = await func(*args, **kwargs)
            await cache.set(cache_key, result, ttl)
            return result
        return wrapper
    return decorator
