import hashlib
import json
import logging
import re
import time

from collections import OrderedDict
from collections.abc import Callable
from functools import wraps
from threading import RLock
from typing import Any, TypeVar

import redis.asyncio as redis

from redis.asyncio import ConnectionPool

from app.config import settings

logger = logging.getLogger("snapshop")
_redis_client: redis.Redis | None = None
_T = TypeVar("_T")


class LRUMemoryCache:
    def __init__(self, max_size: int = 1000):
        self._cache: OrderedDict[str, tuple[Any, float | None]] = OrderedDict()
        self._max_size = max_size
        self._lock = RLock()

    def get(self, key: str) -> Any | None:
        with self._lock:
            if key not in self._cache:
                return None
            value, expiry = self._cache[key]
            if expiry is not None and time.time() > expiry:
                del self._cache[key]
                return None
            self._cache.move_to_end(key)
            return value

    def set(self, key: str, value: Any, ttl: int | None = None) -> None:
        with self._lock:
            if key in self._cache:
                del self._cache[key]
            expiry = time.time() + ttl if ttl is not None else None
            self._cache[key] = (value, expiry)
            if len(self._cache) > self._max_size:
                self._cache.popitem(last=False)

    def delete(self, key: str) -> int:
        with self._lock:
            if key in self._cache:
                del self._cache[key]
                return 1
            return 0

    def delete_pattern(self, pattern: str) -> int:
        regex = re.compile(pattern.replace("*", ".*"))
        count = 0
        with self._lock:
            keys_to_delete = [k for k in self._cache.keys() if regex.fullmatch(k)]
            for k in keys_to_delete:
                del self._cache[k]
                count += 1
        return count

    def exists(self, key: str) -> bool:
        with self._lock:
            return key in self._cache

    def expire(self, key: str, ttl: int) -> bool:
        with self._lock:
            if key not in self._cache:
                return False
            value, _ = self._cache[key]
            self._cache[key] = (value, time.time() + ttl)
            return True


_memory_cache = LRUMemoryCache()


async def get_redis_client() -> redis.Redis:
    global _redis_client
    if _redis_client is None:
        pool = ConnectionPool.from_url(
            settings.redis_url,
            decode_responses=False,
            max_connections=settings.redis_max_connections,
            socket_timeout=settings.redis_socket_timeout,
            socket_connect_timeout=settings.redis_socket_connect_timeout,
        )
        _redis_client = redis.Redis(connection_pool=pool)
    return _redis_client


async def close_redis_client() -> None:
    global _redis_client
    if _redis_client is not None:
        await _redis_client.close()
        _redis_client = None


class CacheManager:
    def __init__(self, redis_client: redis.Redis | None = None):
        self._redis = redis_client

    async def _get_client(self) -> redis.Redis:
        if self._redis is None:
            self._redis = await get_redis_client()
        return self._redis

    async def get(self, key: str) -> Any | None:
        try:
            client = await self._get_client()
            data = await client.get(key)
            if data is None:
                return _memory_cache.get(key)
            return json.loads(data)
        except Exception:
            return _memory_cache.get(key)

    async def set(self, key: str, value: Any, ttl: int | None = None) -> bool:
        try:
            client = await self._get_client()
            data = json.dumps(value, ensure_ascii=False).encode("utf-8")
            if ttl:
                await client.set(key, data, ex=ttl)
            else:
                await client.set(key, data)
            _memory_cache.set(key, value, ttl)
            return True
        except Exception:
            _memory_cache.set(key, value, ttl)
            return True

    async def delete(self, key: str) -> int:
        try:
            client = await self._get_client()
            count = await client.delete(key)
            _memory_cache.delete(key)
            return count
        except Exception:
            return _memory_cache.delete(key)

    async def delete_pattern(self, pattern: str) -> int:
        total = 0
        try:
            client = await self._get_client()
            async for key in client.scan_iter(pattern):
                total += await client.delete(key)
        except Exception:
            pass
        total += _memory_cache.delete_pattern(pattern)
        return total

    async def exists(self, key: str) -> bool:
        try:
            client = await self._get_client()
            return bool(await client.exists(key))
        except Exception:
            return _memory_cache.exists(key)

    async def expire(self, key: str, ttl: int) -> bool:
        try:
            client = await self._get_client()
            result = await client.expire(key, ttl)
            _memory_cache.expire(key, ttl)
            return bool(result)
        except Exception:
            return _memory_cache.expire(key, ttl)

    async def get_image_cache(self, image_bytes: bytes) -> Any | None:
        try:
            sha = hashlib.sha256(image_bytes).hexdigest()
            key = f"vlm:cache:{sha}"
            client = await self._get_client()
            data = await client.get(key)
            if data is None:
                return _memory_cache.get(key)
            return json.loads(data)
        except Exception:
            sha = hashlib.sha256(image_bytes).hexdigest()
            key = f"vlm:cache:{sha}"
            return _memory_cache.get(key)

    async def set_image_cache(self, image_bytes: bytes, result: Any, ttl: int = 3600) -> bool:
        try:
            sha = hashlib.sha256(image_bytes).hexdigest()
            key = f"vlm:cache:{sha}"
            client = await self._get_client()
            data = json.dumps(result, ensure_ascii=False).encode("utf-8")
            await client.set(key, data, ex=ttl)
            _memory_cache.set(key, result, ttl)
            return True
        except Exception:
            sha = hashlib.sha256(image_bytes).hexdigest()
            key = f"vlm:cache:{sha}"
            _memory_cache.set(key, result, ttl)
            return True


_cache_manager: CacheManager | None = None


def get_cache_manager() -> CacheManager:
    global _cache_manager
    if _cache_manager is None:
        _cache_manager = CacheManager()
    return _cache_manager


def cached(key_prefix: str, ttl: int = 300):
    def decorator(func: Callable[..., _T]) -> Callable[..., _T]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            key_data = {
                "args": args,
                "kwargs": sorted(kwargs.items())
            }
            key_json = json.dumps(key_data, ensure_ascii=False, sort_keys=True)
            key_hash = hashlib.sha256(key_json.encode("utf-8")).hexdigest()
            cache_key = f"{key_prefix}:{key_hash}"
            cache = get_cache_manager()
            cached_result = await cache.get(cache_key)
            if cached_result is not None:
                return cached_result
            result = await func(*args, **kwargs)
            await cache.set(cache_key, result, ttl)
            return result
        return wrapper
    return decorator
