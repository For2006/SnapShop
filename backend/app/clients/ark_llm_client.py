import json
from typing import Any

from app.config import settings
from app.clients._base_ark import BaseArkClient


class LLMClientError(Exception):
    pass


class LLMAuthError(LLMClientError):
    pass


class LLMRateLimitError(LLMClientError):
    pass


class LLMAPIError(LLMClientError):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(f"LLM API error {status_code}: {message}")


class ArkLLMClient(BaseArkClient):
    ClientError = LLMClientError
    AuthError = LLMAuthError
    RateLimitError = LLMRateLimitError
    APIError = LLMAPIError

    def __init__(
        self,
        api_key: str = "",
        endpoint_id: str = "",
        base_url: str = "",
    ):
        super().__init__(
            api_key=api_key,
            endpoint_id=endpoint_id or settings.ark_llm_endpoint_id,
            base_url=base_url,
        )

    async def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        response_schema: dict | None = None,
    ) -> dict:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]

        payload: dict[str, Any] = {
            "model": self.endpoint_id,
            "messages": messages,
        }

        if response_schema:
            payload["response_format"] = response_schema

        return await self._call_api(payload)

    async def generate_suggestions(
        self, recognition_result: dict, recall_stats: dict
    ) -> list[dict]:
        system_prompt = (
            "你是一个购物推荐助手。根据商品识别结果和商品召回统计，"
            "生成3-6个建议卡片，帮助用户进行筛选和排序。"
        )

        user_prompt = json.dumps(
            {
                "recognition": recognition_result,
                "recall_stats": recall_stats,
            },
            ensure_ascii=False,
        )

        instruction = (
            "请返回一个JSON数组，每个元素包含：\n"
            '{"id": "card_N", "title": "中文标题", "icon": "图标名", '
            '"action": "动作名", "type": "normal|primary", "params": {}}\n'
            "icon可选值: trending-down, shield-check, palette, zap, star, "
            "check-circle, search, filter, sliders, tag\n"
            "action可选值: sort_price, sort_rating, sort_sales, "
            "filter_official, filter_color, filter_brand, filter_platform, "
            "filter_available, text_search"
        )

        full_user_prompt = f"{user_prompt}\n\n{instruction}"

        result = await self.generate(system_prompt, full_user_prompt)
        if isinstance(result, list):
            return result
        if isinstance(result, dict) and "suggestions" in result:
            return result["suggestions"]
        return []

    async def parse_filter_intent(self, filter_text: str, context: dict) -> dict:
        system_prompt = (
            "你是一个购物筛选解析助手。将用户的自然语言筛选条件解析为结构化参数。"
        )

        user_prompt = json.dumps(
            {"filter_text": filter_text, "context": context},
            ensure_ascii=False,
        )

        instruction = (
            "请返回JSON对象，包含以下可选字段：\n"
            '{"price_min": 最低价(数字), "price_max": 最高价(数字), '
            '"color": "颜色", "brand": "品牌", "shop_type": "official|exclusive|individual", '
            '"min_rating": 最低评分(数字0-5), "sort_by": "price_asc|price_desc|rating_desc|sales_desc|none", '
            '"user_intent": "用户意图简述"}\n'
            "未提到的字段可以省略。"
        )

        full_user_prompt = f"{user_prompt}\n\n{instruction}"

        result = await self.generate(system_prompt, full_user_prompt)
        if not isinstance(result, dict):
            return {"user_intent": filter_text}
        return result

    async def expand_keywords(self, keywords: list[str]) -> dict:
        system_prompt = (
            "你是一个商品搜索关键词扩展助手。分析用户输入的关键词，"
            "提取商品类别、属性，并生成相关的扩展关键词用于搜索。"
        )

        user_prompt = json.dumps({"keywords": keywords}, ensure_ascii=False)

        instruction = (
            "请返回JSON对象：\n"
            '{"category": "商品类别", "color": "颜色(如有)", "brand": "品牌(如有)", '
            '"style": "风格(如有)", "material": "材质(如有)", '
            '"keywords": ["扩展后的搜索关键词列表"]}'
        )

        full_user_prompt = f"{user_prompt}\n\n{instruction}"

        result = await self.generate(system_prompt, full_user_prompt)
        if not isinstance(result, dict):
            return {"keywords": keywords}
        return result

    async def self_correct(self, previous_result: dict) -> dict:
        system_prompt = (
            "你是一个商品识别纠正助手。之前VLM模型对商品图片的识别结果置信度偏低，"
            "请根据已有信息进行推理和纠正，提高属性准确度。"
        )

        user_prompt = json.dumps({"previous_result": previous_result}, ensure_ascii=False)

        instruction = (
            "请返回JSON对象，保持与输入相同的结构，但修正你认为不合理的属性值，"
            "并适当提高confidence分数：\n"
            '{"category": "...", "brand": "...", "color": "...", '
            '"style": "...", "material": "...", "shape": "...", '
            '"keywords": [...], "confidence": {...}}'
        )

        full_user_prompt = f"{user_prompt}\n\n{instruction}"

        result = await self.generate(system_prompt, full_user_prompt)
        if not isinstance(result, dict):
            return previous_result

        result["source"] = "corrected"
        return result
