import logging

from typing import Any

from app.clients.base_platform_client import BasePlatformClient

logger = logging.getLogger(__name__)


class TaobaoPlatformClient(BasePlatformClient):
    def __init__(self, config):
        from app.clients.real_taobao_client import RealTaobaoClient
        self._client = RealTaobaoClient(config)

    @property
    def platform_name(self) -> str:
        return "taobao"

    async def search(self, keywords: list[str], **filters: Any) -> list[dict[str, Any]]:
        if not keywords:
            return []
        target_count = min(filters.get("page_size", 20), 50)
        results: list[dict] = []

        import asyncio
        loop = asyncio.get_running_loop()

        for kw in keywords[:5]:
            try:
                raw = await loop.run_in_executor(
                    None, lambda k=kw: self._client.search_items(keyword=k, page_size=target_count)
                )
                items = raw.get("tbk_item_get_response", {}).get("results", {}).get("n_tbk_item", [])
                for item in items:
                    results.append(self._transform(item))
            except Exception as e:
                logger.warning("Taobao search error for kw=%s: %s", kw, e)
                continue

        seen: set[str] = set()
        deduped: list[dict] = []
        for r in results:
            if r["id"] not in seen:
                seen.add(r["id"])
                deduped.append(r)
        return deduped[:target_count]

    def _transform(self, item: dict) -> dict[str, Any]:
        price = float(item.get("zk_final_price", 0))
        original_price = float(item.get("reserve_price", price))
        return {
            "id": f"tb_{item.get('num_iid', '')}",
            "name": item.get("title", ""),
            "price": price,
            "original_price": original_price,
            "platform": "taobao",
            "shop_name": item.get("shop_title", "") or item.get("nick", "") or "淘宝",
            "shop_type": "official" if item.get("user_type") == 1 else "third_party",
            "rating": None,
            "sales_count": int(item.get("volume", 0)),
            "image_url": item.get("pict_url", ""),
            "product_url": f"https://item.taobao.com/item.htm?id={item.get('num_iid', '')}",
            "is_mock": item.get("is_mock", False),
            "attributes": {
                "brand": item.get("brand_name", ""),
                "category": item.get("category_name", ""),
            },
            "tags": item.get("tags", []) if isinstance(item.get("tags"), list) else [],
        }

    async def close(self) -> None:
        pass


def create_platform_clients() -> list[BasePlatformClient]:
    from app.config import settings

    clients: list[BasePlatformClient] = []

    if settings.pdd_client_id:
        from app.clients.real_pdd_client import RealPDDClient
        clients.append(RealPDDClient())

    if settings.jd_app_key:
        from app.clients.real_jd_client import RealJDClient
        clients.append(RealJDClient())

    if settings.taobao_app_key:
        from app.clients.real_taobao_client import TaobaoApiConfig
        clients.append(TaobaoPlatformClient(TaobaoApiConfig(
            app_key=settings.taobao_app_key,
            app_secret=settings.taobao_app_secret,
            adzone_id=settings.taobao_adzone_id,
            use_mock=settings.use_mock_fallback,
        )))

    return clients


__all__ = [
    "BasePlatformClient",
    "create_platform_clients",
]
