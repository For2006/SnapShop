import asyncio
import time

from fastapi import Request

from app.config import settings
from app.core.exceptions import RateLimitedError

_in_memory_counters: dict[str, list[float]] = {}
_last_accessed: dict[str, float] = {}
_lock = asyncio.Lock()
_last_cleanup_time: float = time.time()
_CLEANUP_INTERVAL = 300
_INACTIVE_THRESHOLD = 600


class RateLimiter:
    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds

    async def is_allowed(self, key: str) -> bool:
        now = time.time()
        async with _lock:
            if key not in _in_memory_counters:
                _in_memory_counters[key] = []
            timestamps = [t for t in _in_memory_counters[key] if now - t < self.window_seconds]
            if len(timestamps) >= self.max_requests:
                _last_accessed[key] = now
                return False
            timestamps.append(now)
            _in_memory_counters[key] = timestamps
            _last_accessed[key] = now
            await self._cleanup_if_needed(now)
            return True

    async def _cleanup_if_needed(self, now: float) -> None:
        global _last_cleanup_time
        if now - _last_cleanup_time < _CLEANUP_INTERVAL:
            return
        _last_cleanup_time = now
        stale_keys = [
            k for k, last in _last_accessed.items()
            if now - last > _INACTIVE_THRESHOLD
        ]
        for k in stale_keys:
            _in_memory_counters.pop(k, None)
            _last_accessed.pop(k, None)


recognize_limiter = RateLimiter(max_requests=settings.recognize_rate_limit, window_seconds=60)
filter_limiter = RateLimiter(max_requests=settings.filter_rate_limit, window_seconds=60)
auth_limiter = RateLimiter(max_requests=5, window_seconds=60)


def _get_rate_limit_key(request: Request) -> str:
    device_id = request.headers.get("X-Device-Id")
    ip = _get_client_ip(request)
    if device_id and ip:
        return f"{device_id}:{ip}"
    if device_id:
        return device_id
    return ip or "anonymous"


def _get_client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    client = request.client
    if client:
        return client.host
    return None


async def check_recognize_rate_limit(request: Request):
    key = _get_rate_limit_key(request)
    if not await recognize_limiter.is_allowed(key):
        raise RateLimitedError()


async def check_filter_rate_limit(request: Request):
    key = _get_rate_limit_key(request)
    if not await filter_limiter.is_allowed(key):
        raise RateLimitedError()


async def check_auth_rate_limit(request: Request):
    key = _get_rate_limit_key(request)
    if not await auth_limiter.is_allowed(key):
        raise RateLimitedError()
