import hashlib
import time
import urllib.parse
from typing import Dict, Any, Optional, List
from dataclasses import dataclass

from .taobao_mock_database import TaobaoMockDatabase


@dataclass
class TaobaoApiConfig:
    app_key: str
    app_secret: str
    adzone_id: str
    site_id: Optional[str] = None
    use_mock: bool = True


class TaobaoApiError(Exception):
    def __init__(self, code: int, msg: str, sub_code: str = "", sub_msg: str = ""):
        self.code = code
        self.msg = msg
        self.sub_code = sub_code
        self.sub_msg = sub_msg
        super().__init__(f"[{code}] {msg} - {sub_msg}")


class RealTaobaoClient:
    def __init__(self, config: TaobaoApiConfig):
        self.config = config
        self.mock_db = TaobaoMockDatabase() if config.use_mock else None
        self.api_gateway = "https://eco.taobao.com/router/rest"
        self._session = None

    def _generate_sign(self, params: Dict[str, str]) -> str:
        sorted_params = sorted(params.items())
        sign_str = self.config.app_secret + "".join([f"{k}{v}" for k, v in sorted_params]) + self.config.app_secret
        return hashlib.md5(sign_str.encode("utf-8")).hexdigest().upper()

    def _build_common_params(self, method: str) -> Dict[str, str]:
        timestamp = str(int(time.time() * 1000))
        return {
            "method": method,
            "app_key": self.config.app_key,
            "timestamp": timestamp,
            "format": "json",
            "v": "2.0",
            "sign_method": "md5",
        }

    def _request(self, method: str, api_params: Dict[str, Any]) -> Dict[str, Any]:
        if self.config.use_mock and self.mock_db:
            return self._mock_request(method, api_params)
        
        common_params = self._build_common_params(method)
        all_params = {**common_params, **api_params}
        all_params["sign"] = self._generate_sign(all_params)
        
        return self._real_http_request(all_params)

    def _mock_request(self, method: str, api_params: Dict[str, Any]) -> Dict[str, Any]:
        if method == "taobao.tbk.item.get":
            return self._mock_tbk_item_get(api_params)
        elif method == "taobao.tbk.item.info.get":
            return self._mock_tbk_item_info_get(api_params)
        elif method == "taobao.tbk.item.recommend.get":
            return self._mock_tbk_item_recommend_get(api_params)
        elif method == "taobao.tbk.coupon.get":
            return self._mock_tbk_coupon_get(api_params)
        elif method == "taobao.tbk.shop.get":
            return self._mock_tbk_shop_get(api_params)
        else:
            return {
                "tbk_response": {
                    "code": 0,
                    "msg": "success",
                    "data": []
                }
            }

    def _mock_tbk_item_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        keyword = params.get("q", "")
        cat = params.get("cat", "")
        page_no = int(params.get("page_no", 1))
        page_size = int(params.get("page_size", 20))
        
        result = self.mock_db.search_products(
            keyword=keyword,
            category=cat,
            page=page_no,
            page_size=page_size
        )
        
        return {
            "tbk_item_get_response": {
                "total_results": result["total"],
                "results": {
                    "n_tbk_item": result["data"]
                },
                "request_id": f"mock_{int(time.time())}"
            }
        }

    def _mock_tbk_item_info_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        num_iids = params.get("num_iids", "")
        item_ids = str(num_iids).split(",")
        
        items = []
        for item_id in item_ids:
            product = self.mock_db.get_product_by_id(item_id.strip())
            if product:
                items.append(product)
        
        return {
            "tbk_item_info_get_response": {
                "results": {
                    "n_tbk_item": items
                },
                "request_id": f"mock_{int(time.time())}"
            }
        }

    def _mock_tbk_item_recommend_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        count = int(params.get("count", 20))
        items = self.mock_db.get_hot_products(limit=count)
        
        return {
            "tbk_item_recommend_get_response": {
                "results": {
                    "n_tbk_item": items
                },
                "request_id": f"mock_{int(time.time())}"
            }
        }

    def _mock_tbk_coupon_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        items = self.mock_db.search_products(page_size=50)["data"]
        coupon_items = [item for item in items if item.get("coupon_amount", 0) > 0]
        
        return {
            "tbk_coupon_get_response": {
                "total_results": len(coupon_items),
                "results": {
                    "n_tbk_item": coupon_items
                },
                "request_id": f"mock_{int(time.time())}"
            }
        }

    def _mock_tbk_shop_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        page_no = int(params.get("page_no", 1))
        page_size = int(params.get("page_size", 20))
        
        all_products = self.mock_db.get_all_products()
        unique_shops = {}
        for p in all_products:
            shop_name = p["shop_name"]
            if shop_name not in unique_shops:
                unique_shops[shop_name] = {
                    "shop_id": f"shop_{hash(shop_name) % 1000000}",
                    "shop_name": shop_name,
                    "shop_level": p["shop_level"],
                    "is_tmall": p["is_tianmao"],
                    "item_count": 0
                }
            unique_shops[shop_name]["item_count"] += 1
        
        shops_list = list(unique_shops.values())
        total = len(shops_list)
        start = (page_no - 1) * page_size
        paginated_shops = shops_list[start:start + page_size]
        
        return {
            "tbk_shop_get_response": {
                "total_results": total,
                "results": {
                    "n_tbk_shop": paginated_shops
                },
                "request_id": f"mock_{int(time.time())}"
            }
        }

    def _real_http_request(self, params: Dict[str, Any]) -> Dict[str, Any]:
        try:
            import requests
            response = requests.get(self.api_gateway, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if "error_response" in data:
                error = data["error_response"]
                raise TaobaoApiError(
                    code=error.get("code", -1),
                    msg=error.get("msg", "unknown error"),
                    sub_code=error.get("sub_code", ""),
                    sub_msg=error.get("sub_msg", "")
                )
            
            return data
        except ImportError:
            raise TaobaoApiError(-1, "requests library not installed")
        except requests.RequestException as e:
            raise TaobaoApiError(-2, f"network error: {str(e)}")

    def search_items(self, keyword: str = "", category: str = "", 
                    page_no: int = 1, page_size: int = 20,
                    sort: str = "tk_total_sales_desc") -> Dict[str, Any]:
        params = {
            "q": keyword,
            "cat": category,
            "page_no": str(page_no),
            "page_size": str(page_size),
            "sort": sort,
            "adzone_id": self.config.adzone_id
        }
        return self._request("taobao.tbk.item.get", params)

    def get_item_info(self, item_ids: List[str]) -> Dict[str, Any]:
        params = {
            "num_iids": ",".join(item_ids),
        }
        return self._request("taobao.tbk.item.info.get", params)

    def get_recommend_items(self, count: int = 20) -> Dict[str, Any]:
        params = {
            "count": str(count),
        }
        return self._request("taobao.tbk.item.recommend.get", params)

    def get_coupon_items(self, page_no: int = 1, page_size: int = 50) -> Dict[str, Any]:
        params = {
            "page_no": str(page_no),
            "page_size": str(page_size),
        }
        return self._request("taobao.tbk.coupon.get", params)

    def get_shops(self, page_no: int = 1, page_size: int = 20) -> Dict[str, Any]:
        params = {
            "page_no": str(page_no),
            "page_size": str(page_size),
        }
        return self._request("taobao.tbk.shop.get", params)

    def get_mock_statistics(self) -> Dict[str, Any]:
        if self.mock_db:
            return self.mock_db.get_statistics()
        return {"error": "Mock database not enabled"}

    def generate_tbk_promotion_url(self, item_id: str, coupon_id: str = "") -> str:
        base_url = "https://s.click.taobao.com/t"
        params = {
            "e": f"item_{item_id}_{self.config.adzone_id}",
        }
        if coupon_id:
            params["e"] += f"_{coupon_id}"
        return f"{base_url}?{urllib.parse.urlencode(params)}"
