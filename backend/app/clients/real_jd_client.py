import hashlib
import json
import logging
import time
from typing import Any

import httpx

from app.clients.base_platform_client import BasePlatformClient
from app.clients.jd_mock_database import JDMockDatabase
from app.config import settings

logger = logging.getLogger(__name__)


class JDAPIError(Exception):
    def __init__(self, code: int, message: str):
        self.code = code
        self.message = message
        super().__init__(f"JD API error {code}: {message}")


class RealJDClient(BasePlatformClient):
    def __init__(self):
        self._app_key = settings.jd_app_key
        self._app_secret = settings.jd_app_secret
        self._site_id = settings.jd_site_id
        self._api_url = settings.jd_api_url
        self._client: httpx.AsyncClient | None = None
        self._mock_db = JDMockDatabase()

    @property
    def platform_name(self) -> str:
        return "jd"

    async def search(self, keywords: list[str], **filters: Any) -> list[dict[str, Any]]:
        if not keywords:
            return []

        page_size = min(filters.get("page_size", 20), 50)
        results: list[dict] = []

        error_count = 0
        last_error = None
        if self._app_key and self._app_secret:
            for kw in keywords[:3]:
                try:
                    goods_list = await self._fetch_jingfen(page_size * 2)
                    matched = self._filter_by_keyword(goods_list, kw)
                    for g in matched:
                        results.append(self._transform(g))
                except JDAPIError as e:
                    logger.warning("JD API error for kw=%s: code=%s msg=%s", kw, e.code, e.message)
                    error_count += 1
                    last_error = e
                except (httpx.TimeoutException, httpx.ConnectError, httpx.RemoteProtocolError) as e:
                    logger.warning("JD network error for kw=%s: %s", kw, e)
                    error_count += 1
                    last_error = e
                except Exception as e:
                    logger.warning("JD unexpected error for kw=%s: %s", kw, e)
                    error_count += 1
                    last_error = e

        if not results and error_count == min(len(keywords), 3) and last_error:
            raise last_error

        if len(results) < page_size // 2:
            if settings.use_mock_fallback:
                logger.info("JD API 返回结果不足，使用独立 JD Mock 数据库兜底")
                mock_results = self._mock_db.search_by_keywords(keywords, limit=page_size)
                for product in mock_results:
                    results.append(self._transform_mock_product(product))
            else:
                logger.info("JD API 返回结果不足，Mock 已禁用")

        seen: set[str] = set()
        deduped: list[dict] = []
        for r in results:
            if r["id"] not in seen:
                seen.add(r["id"])
                deduped.append(r)

        return deduped[:page_size]

    async def _fetch_jingfen(self, limit: int = 40) -> list[dict]:
        biz_params = {
            "goodsReq": {
                "eliteId": 1,
                "pageIndex": 1,
                "pageSize": limit,
            }
        }

        request_params = {
            "method": "jd.union.open.goods.jingfen.query",
            "app_key": self._app_key,
            "timestamp": self._jd_timestamp(),
            "format": "json",
            "v": "1.0",
            "sign_method": "md5",
            "param_json": json.dumps(biz_params, ensure_ascii=False),
        }

        resp = await self._request(request_params)
        data = resp.get("jd_union_open_goods_jingfen_query_response", {})
        result_str = data.get("queryResult") or data.get("result") or "{}"
        result = json.loads(result_str) if isinstance(result_str, str) else result_str
        if result.get("code") and result["code"] != 200:
            raise JDAPIError(result["code"], result.get("message", ""))
        return result.get("data", [])

    @staticmethod
    def _filter_by_keyword(goods: list[dict], keyword: str) -> list[dict]:
        if not keyword:
            return goods
        kw = keyword.lower()
        matched = []
        for g in goods:
            name = (g.get("skuName") or "").lower()
            brand = (g.get("brandName") or "").lower()
            cat_info = g.get("categoryInfo") or {}
            cat_name = (cat_info.get("cid1Name") or "").lower()
            searchable = f"{name} {brand} {cat_name}"
            if kw in searchable:
                matched.append(g)
        return matched

    async def _request(self, params: dict) -> dict:
        sign = self._sign(params)
        params["sign"] = sign
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=8.0)
        resp = await self._client.get(self._api_url, params=params)
        resp.raise_for_status()
        return resp.json()

    async def close(self) -> None:
        if self._client is not None and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    def _sign(self, params: dict) -> str:
        ordered = sorted(params.items(), key=lambda x: x[0])
        raw = "".join(f"{k}{v}" for k, v in ordered)
        raw = self._app_secret + raw + self._app_secret
        return hashlib.md5(raw.encode("utf-8")).hexdigest().upper()

    @staticmethod
    def _jd_timestamp() -> str:
        return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())

    def _transform(self, raw: dict) -> dict[str, Any]:
        price_info = raw.get("priceInfo", {}) or {}
        coupon_info = raw.get("couponInfo", {}) or {}
        coupon_list = coupon_info.get("couponList", [])
        coupon_discount = 0.0
        if coupon_list:
            coupon_discount = float(coupon_list[0].get("discount", 0))

        price = float(price_info.get("lowestPrice", 0)) or float(price_info.get("price", 0))
        original_price = float(price_info.get("price", 0)) or price
        display_price = round(max(price - coupon_discount, 0), 2) if coupon_discount else price

        shop_info = raw.get("shopInfo", {}) or {}
        shop_name = shop_info.get("shopName") or raw.get("shopName") or "京东"

        category_info = raw.get("categoryInfo", {}) or {}
        category = category_info.get("cid1Name", "")

        image_info = raw.get("imageInfo", {}) or {}
        image_list = image_info.get("imageList", [])
        image_url = image_list[0].get("url", "") if image_list else ""

        brand = raw.get("brandName", "")

        tags = []
        if raw.get("isHot"):
            tags.append("热销")
        owner_name = raw.get("ownerName")
        if owner_name:
            tags.append(owner_name)

        item_id = raw.get("itemId") or raw.get("skuId", "")
        platform_id = f"jd_{item_id}"

        rating_val = raw.get("goodCommentsShare")
        rating = float(rating_val) if rating_val else None

        sales_val = raw.get("inOrderCount30Days")
        sales_count = int(sales_val) if sales_val else 0

        return {
            "id": platform_id,
            "name": raw.get("skuName", ""),
            "price": display_price,
            "original_price": original_price,
            "platform": "jd",
            "shop_name": shop_name,
            "shop_type": "self_operated" if raw.get("owner", "") == "g" else "third_party",
            "rating": rating,
            "sales_count": sales_count,
            "image_url": image_url,
            "product_url": f"https://item.jd.com/{item_id}.html",
            "attributes": {
                "brand": brand,
                "category": category,
            },
            "tags": tags,
        }

    def _transform_mock_product(self, product: dict) -> dict[str, Any]:
        item_id = product.get("item_id", "")
        platform_id = f"jd_{item_id}"

        return {
            "id": platform_id,
            "name": product.get("title", ""),
            "price": product.get("price", 0.0),
            "original_price": product.get("original_price", 0.0),
            "platform": "jd",
            "shop_name": product.get("shop_name", "京东"),
            "shop_type": product.get("shop_type", "third_party"),
            "rating": product.get("rating", 4.5),
            "sales_count": product.get("sales_count", 0),
            "image_url": product.get("image_url", ""),
            "product_url": product.get("product_url", ""),
            "is_mock": True,
            "attributes": {
                "brand": product.get("brand", ""),
                "category": product.get("category", ""),
            },
            "tags": product.get("tags", []),
        }
