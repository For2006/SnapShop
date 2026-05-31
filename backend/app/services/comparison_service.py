import re
import json
from typing import Any


class ComparisonService:
    def compare_and_rerank(
        self, products: list[dict], keywords: list[str]
    ) -> tuple[list[dict], list[dict]]:
        if not products:
            return [], []

        products = self._filter_seo_noise(products)
        products = self._levenshtein_filter(products, keywords)
        products = self._deduplicate(products)

        price_summary = self._aggregate_prices(products)
        return products, price_summary

    def _levenshtein_filter(self, products: list[dict], keywords: list[str]) -> list[dict]:
        if not keywords:
            return products
        results = []
        for p in products:
            name = p.get("name", "")
            category = p.get("_category", p.get("attributes", {}).get("category", ""))
            searchable = f"{name} {category}".lower()
            match_count = 0
            for kw in keywords:
                if kw.lower() in searchable:
                    match_count += 1
            if match_count > 0:
                results.append(p)
        if not results:
            return products
        return results

    def _filter_seo_noise(self, products: list[dict]) -> list[dict]:
        seo_patterns = [
            r'【[^】]*】', r'\[[^\]]*\]', r'「[^」]*」',
            r'正品保障', r'假一赔十', r'顺丰包邮', r'限时特惠',
        ]
        for p in products:
            name = p.get("name", "")
            for pattern in seo_patterns:
                name = re.sub(pattern, '', name)
            name = re.sub(r'\s+', ' ', name).strip()
            p["name"] = name
        return products

    def _deduplicate(self, products: list[dict]) -> list[dict]:
        seen = set()
        unique = []
        for p in products:
            key = p.get("id", "")
            if key and key not in seen:
                seen.add(key)
                unique.append(p)
        return unique

    def _aggregate_prices(self, products: list[dict]) -> list[dict]:
        platforms: dict[str, list[float]] = {}
        platform_names = {"taobao": "淘宝", "jd": "京东", "pdd": "拼多多"}
        
        for p in products:
            plat = p.get("platform", "unknown")
            price = float(p.get("price", 0))
            if plat not in platforms:
                platforms[plat] = []
            platforms[plat].append(price)

        summary = []
        for plat, prices in platforms.items():
            if prices:
                summary.append({
                    "platform": plat,
                    "platform_name": platform_names.get(plat, plat),
                    "min_price": min(prices),
                    "avg_price": round(sum(prices) / len(prices), 2),
                    "count": len(prices),
                })
        
        summary.sort(key=lambda x: x["min_price"])
        return summary
