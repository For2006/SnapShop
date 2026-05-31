import asyncio
import time

from fastapi import Request

from app.config import settings
from app.core.exceptions import RateLimitedError

_in_memory_counters: dict[str, list[float]] = {}
_lock = asyncio.Lock()


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
                return False
            timestamps.append(now)
            _in_memory_counters[key] = timestamps
            return True


recognize_limiter = RateLimiter(max_requests=settings.recognize_rate_limit, window_seconds=60)
filter_limiter = RateLimiter(max_requests=settings.filter_rate_limit, window_seconds=60)
auth_limiter = RateLimiter(max_requests=5, window_seconds=60)


async def check_recognize_rate_limit(request: Request):
    device_id = request.headers.get("X-Device-Id", "anonymous")
    if not await recognize_limiter.is_allowed(device_id):
        raise RateLimitedError()


async def check_filter_rate_limit(request: Request):
    device_id = request.headers.get("X-Device-Id", "anonymous")
    if not await filter_limiter.is_allowed(device_id):
        raise RateLimitedError()


async def check_auth_rate_limit(request: Request):
    device_id = request.headers.get("X-Device-Id", "anonymous")
    if not await auth_limiter.is_allowed(device_id):
        raise RateLimitedError()
