import asyncio
import json
import logging
import re
import time

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class BaseArkClient:
    ClientError = Exception
    AuthError = Exception
    RateLimitError = Exception
    APIError = Exception

    def __init__(
        self,
        api_key: str = "",
        endpoint_id: str = "",
        base_url: str = "",
    ):
        self.api_key = api_key or settings.ark_api_key
        self.endpoint_id = endpoint_id
        self.base_url = base_url or settings.ark_base_url
        self._client: httpx.AsyncClient | None = None
        self._max_retries = 1
        self._retry_delays = [1.0]

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(60.0, connect=10.0),  # VLM识别大图需要更长时间
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.api_key}",
                },
            )
        return self._client

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def _call_api(self, payload: dict) -> dict:
        last_exception = None
        for attempt in range(self._max_retries + 1):
            try:
                client = await self._get_client()
                url = f"{self.base_url}/chat/completions"
                t0 = time.time()
                response = await client.post(url, json=payload)
                elapsed = time.time() - t0
                status_code = response.status_code

                if status_code == 200:
                    data = response.json()
                    content = data["choices"][0]["message"]["content"]
                    model = data.get("model", "unknown")
                    usage = data.get("usage", {})
                    logger.info(f"[Ark] {model} 响应成功, 耗时={elapsed:.1f}s, tokens={usage}")
                    return self._parse_json_response(content)

                if status_code in (429, 500, 502, 503, 504):
                    if attempt < self._max_retries:
                        delay = self._retry_delays[min(attempt, len(self._retry_delays) - 1)]
                        await asyncio.sleep(delay)
                        continue
                    raise self.RateLimitError(
                        f"Rate limited or server error after {self._max_retries} retries"
                    )

                if status_code == 401 or status_code == 403:
                    raise self.AuthError(f"Authentication failed: {status_code}")

                raise self.APIError(
                    status_code,
                    response.text[:500] if response.text else "No response body",
                )

            except (self.AuthError, self.RateLimitError, self.APIError) as e:
                logger.error(f"[Ark] API错误 status={getattr(e, 'status_code', '?')}: {e}")
                raise
            except (httpx.TimeoutException, httpx.ConnectError, httpx.RemoteProtocolError) as e:
                last_exception = e
                logger.warning(f"[Ark] 网络错误 attempt={attempt}: {type(e).__name__}: {e}")
                if attempt < self._max_retries:
                    delay = self._retry_delays[min(attempt, len(self._retry_delays) - 1)]
                    await asyncio.sleep(delay)
                    continue
                raise self.ClientError(f"Network error after {self._max_retries} retries: {e}") from e
            except (json.JSONDecodeError, KeyError, IndexError, TypeError, ValueError, asyncio.TimeoutError) as e:
                last_exception = e
                logger.warning(f"[Ark] 可重试错误 attempt={attempt}: {type(e).__name__}: {e}")
                if attempt < self._max_retries:
                    delay = self._retry_delays[min(attempt, len(self._retry_delays) - 1)]
                    await asyncio.sleep(delay)
                    continue
                raise self.ClientError(f"Client error: {e}") from e

        raise self.ClientError(
            f"API call failed after {self._max_retries} retries: {last_exception}"
        )

    @staticmethod
    def _parse_json_response(response_text: str) -> dict:
        text = response_text.strip()

        json_match = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
        if json_match:
            text = json_match.group(1).strip()

        try:
            return json.loads(text)
        except json.JSONDecodeError:
            pass

        brace_start = text.find("{")
        brace_end = text.rfind("}")
        bracket_start = text.find("[")
        bracket_end = text.rfind("]")

        if bracket_start != -1 and bracket_end != -1 and bracket_end > bracket_start:
            try:
                return json.loads(text[bracket_start:bracket_end + 1])
            except json.JSONDecodeError:
                pass

        if brace_start != -1 and brace_end != -1 and brace_end > brace_start:
            try:
                return json.loads(text[brace_start:brace_end + 1])
            except json.JSONDecodeError:
                pass

        return {"raw_text": response_text, "error": "Failed to parse JSON"}