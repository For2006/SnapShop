import hashlib
import logging
import time

from typing import Any

import httpx

from app.clients.base_platform_client import BasePlatformClient
from app.config import settings

logger = logging.getLogger(__name__)


class PDDAPIError(Exception):
    def __init__(self, code: int, message: str):
        self.code = code
        self.message = message
        super().__init__(f"PDD API error {code}: {message}")


class RealPDDClient(BasePlatformClient):
    def __init__(self):
        self._client_id = settings.pdd_client_id
        self._client_secret = settings.pdd_client_secret
        self._access_token = settings.pdd_access_token
        self._pid = settings.pdd_pid
        self._api_url = settings.pdd_api_url
        self._client: httpx.AsyncClient | None = None

    @property
    def platform_name(self) -> str:
        return "pdd"

    async def search(self, keywords: list[str], **filters: Any) -> list[dict[str, Any]]:
        if not keywords:
            return []

        target_count = min(filters.get("page_size", 20), 50)
        results: list[dict] = []

        if not self._client_id or not self._client_secret:
            logger.warning("PDD client_id or client_secret not configured")
            return []

        for kw in keywords[:5]:
            try:
                goods = await self._search_keyword(kw, page_size=target_count)
                for g in goods:
                    results.append(self._transform(g))
            except PDDAPIError as e:
                logger.warning("PDD API error for kw=%s: code=%s msg=%s", kw, e.code, e.message)
                continue
            except Exception as e:
                logger.warning("PDD search error for kw=%s: %s", kw, e)
                continue

        seen: set[str] = set()
        deduped: list[dict] = []
        for r in results:
            if r["id"] not in seen:
                seen.add(r["id"])
                deduped.append(r)

        return deduped[:target_count]

    async def _search_keyword(self, keyword: str, page_size: int = 50) -> list[dict]:
        params = {
            "type": "pdd.ddk.goods.search",
            "client_id": self._client_id,
            "timestamp": str(int(time.time())),
            "data_type": "JSON",
            "keyword": keyword,
            "pid": self._pid,
            "page_size": min(page_size, 50),
        }
        if self._access_token:
            params["access_token"] = self._access_token
        data = await self._request(params)
        return data.get("goods_search_response", {}).get("goods_list", [])

    async def _recommend(self, limit: int = 20) -> list[dict]:
        params = {
            "type": "pdd.ddk.goods.recommend.get",
            "client_id": self._client_id,
            "timestamp": str(int(time.time())),
            "data_type": "JSON",
            "pid": self._pid,
            "channel_type": 0,
            "limit": min(limit, 50),
        }
        if self._access_token:
            params["access_token"] = self._access_token
        data = await self._request(params)
        return data.get("goods_basic_detail_response", {}).get("list", [])

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=8.0)
        return self._client

    async def _request(self, params: dict) -> dict:
        sign = self._sign(params)
        body = {"sign": sign, **params}
        client = await self._get_client()
        resp = await client.post(self._api_url, json=body)
        resp.raise_for_status()
        data = resp.json()
        error = data.get("error_response")
        if error:
            error_code = error.get("error_code")
            error_msg = error.get("error_msg")
            logger.warning("PDD API error: code=%s msg=%s", error_code, error_msg)
            raise PDDAPIError(error_code, error_msg)
        return data

    async def close(self) -> None:
        if self._client is not None:
            if not self._client.is_closed:
                await self._client.aclose()
            self._client = None

    def _sign(self, params: dict) -> str:
        ordered = sorted(params.items(), key=lambda x: x[0])
        raw = "".join(f"{k}{v}" for k, v in ordered)
        raw = self._client_secret + raw + self._client_secret
        return hashlib.md5(raw.encode("utf-8")).hexdigest().upper()

    def _transform(self, raw: dict) -> dict[str, Any]:
        min_price = int(raw.get("min_group_price", 0)) / 100
        coupon = int(raw.get("coupon_discount", 0)) / 100
        price = round(max(min_price - coupon, 0), 2) if coupon else min_price

        sales_tip = raw.get("sales_tip", "0") or "0"
        sales_count_str = str(sales_tip).replace("万", "0000").replace("+", "")
        try:
            sales_count = int(float(sales_count_str))
        except (ValueError, TypeError):
            sales_count = 0

        goods_sign = str(raw.get("goods_sign", ""))
        numeric_goods_id = str(raw.get("goods_id", ""))
        goods_id = numeric_goods_id or goods_sign

        brand = raw.get("brand_name") or ""
        cat_ids = raw.get("cat_ids") or []
        category = raw.get("category_name") or (str(cat_ids[0]) if cat_ids else "")

        tags = []
        unified_tags = raw.get("unified_tags") or []
        if isinstance(unified_tags, list):
            for t in unified_tags:
                if isinstance(t, str):
                    tags.append(t)
        activity_tags = raw.get("activity_tags") or []
        if isinstance(activity_tags, list):
            for t in activity_tags:
                if isinstance(t, dict):
                    name = t.get("name", "")
                    if name:
                        tags.append(name)
        if raw.get("has_coupon"):
            tags.append("有优惠券")

        product_url = f"https://mobile.yangkeduo.com/goods.html?goods_id={numeric_goods_id}" if numeric_goods_id else ""

        return {
            "id": f"pdd_{goods_id}",
            "name": raw.get("goods_name", ""),
            "price": price,
            "original_price": min_price,
            "platform": "pdd",
            "shop_name": raw.get("mall_name") or "拼多多",
            "shop_type": "official" if raw.get("mall_cps") == 1 else "third_party",
            "rating": None,
            "sales_count": sales_count,
            "image_url": raw.get("goods_thumbnail_url", "") or raw.get("goods_image_url", ""),
            "product_url": product_url,
            "is_mock": False,
            "attributes": {
                "brand": brand,
                "category": category,
            },
            "tags": tags,
        }
