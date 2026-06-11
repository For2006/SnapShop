import json

from typing import Any

from app.clients._base_ark import BaseArkClient
from app.config import settings


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
    ) -> Any:
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

        result = await self._call_api(payload)
        
        if isinstance(result, dict) and "_list" in result:
            return result["_list"]
        
        return result

    async def generate_suggestions(
        self, recognition_result: dict, recall_stats: dict
    ) -> list[dict]:
        system_prompt = (
            "你是一个专业的智能购物助手，擅长根据商品识别结果和召回统计数据，"
            "为用户生成精准、实用、有针对性的筛选建议卡片。你的目标是帮助用户快速找到最适合的商品，"
            "提升购物决策效率。请根据不同商品类别和平台数据，生成差异化的建议卡片。"
        )

        user_prompt = json.dumps(
            {
                "recognition": recognition_result,
                "recall_stats": recall_stats,
            },
            ensure_ascii=False,
        )

        instruction = (
            "请返回一个JSON数组，包含3-6个建议卡片，每个卡片必须严格遵循以下格式：\n"
            '{"id": "card_唯一标识", "title": "中文标题（简洁有力，不超过12字）", '
            '"icon": "图标名", "action": "动作名", "type": "normal或primary", "params": {}}\n\n'
            "=== 卡片生成规则 ===\n"
            "1. 基础必选卡片（优先包含）：\n"
            "   - 查看同款低价：按价格升序排序，icon=trending-down\n"
            "   - 按销量排序：优先展示热门爆款，icon=trending-up\n"
            "   - 按评分排序：优先展示高好评商品，icon=star\n"
            "   - 只看官方旗舰店：保障正品，icon=shield-check\n\n"
            "2. 平台专属卡片（根据平台数据动态生成）：\n"
            "   - 全网最低价在拼多多：当拼多多价格明显低于其他平台时，type=primary，icon=zap\n"
            "   - 只看京东自营：数码/家电类商品推荐，含售后延保，type=primary，icon=verified\n"
            "   - 天猫国际正品保障：美妆/护肤/奢侈品推荐，icon=shield\n"
            "   - 只看京东商品：icon=shopping-cart\n"
            "   - 只看淘宝天猫：icon=shopping-bag\n\n"
            "3. 场景化筛选卡片：\n"
            "   - 按预算筛选：当不同平台价格差超过30%时显示，icon=filter\n"
            "   - 筛选4.8分以上：高评分商品推荐，icon=star-filled\n"
            "   - 只看有货商品：避免无货商品，icon=check-circle\n"
            "   - 查看高端精选：按价格降序排序，icon=diamond\n"
            "   - 更多筛选条件：商品总数超过50时显示，icon=sliders\n\n"
            "4. 图标完整可选列表：\n"
            "trending-down, trending-up, shield-check, shield, zap, star, star-filled, "
            "check-circle, filter, sliders, palette, verified, shopping-cart, shopping-bag, diamond, tag\n\n"
            "5. Action完整可选列表：\n"
            "sort_price, sort_sales, sort_rating, sort_price_desc, filter_official, "
            "filter_platform, filter_budget, filter_high_rating, filter_available, show_filters\n\n"
            "6. 重要原则：\n"
            "   - 卡片标题必须简洁易懂，直击用户痛点\n"
            "   - primary类型卡片最多2个，用于最核心的推荐\n"
            "   - 卡片总数控制在3-6个，不要过多\n"
            "   - 必须严格返回纯JSON数组，不要任何其他文字说明"
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

    async def parse_filter_to_cards(self, filter_text: str) -> list[dict]:
        system_prompt = (
            "你是一个智能购物筛选助手。将用户的自然语言筛选需求解析为一组可操作的筛选卡片，"
            "每个卡片代表一个独立的筛选条件。用户可以选择多个卡片进行组合筛选。"
        )

        instruction = (
            "请返回一个JSON数组，包含3-6张筛选卡片，每张卡片严格遵循以下格式：\n"
            '{"id": "card_唯一标识", "title": "简洁标题(≤8字)", "icon": "图标名", '
            '"action": "动作名", "type": "normal或primary", "params": {}}\n\n'
            "=== 解析规则 ===\n"
            "1. 价格相关：\n"
            "   - '200元以内' → card: price_under_200, action: filter_price, params: {price_max: 200}\n"
            "   - '500-1000元' → card: price_500_1000, action: filter_price, params: {price_min: 500, price_max: 1000}\n"
            "   - '便宜的' → card: sort_price_low, action: sort_price, params: {sort_by: price_asc}\n\n"
            "2. 颜色相关：\n"
            "   - '红色' → card: color_red, action: filter_color, params: {color: '红色'}\n"
            "   - '黑色或白色' → card: color_black, card: color_white (拆为2张卡)\n\n"
            "3. 品牌相关：\n"
            "   - '华为' → card: brand_huawei, action: filter_brand, params: {brand: '华为'}\n\n"
            "4. 平台相关：\n"
            "   - '京东' → card: platform_jd, action: filter_platform, params: {platform: 'jd'}\n"
            "   - '拼多多' → card: platform_pdd, action: filter_platform, params: {platform: 'pdd'}\n"
            "   - '淘宝' → card: platform_taobao, action: filter_platform, params: {platform: 'taobao'}\n\n"
            "5. 店铺类型：\n"
            "   - '自营' → card: shop_self, action: filter_shop_type, params: {shop_type: 'self_operated'}\n"
            "   - '官方旗舰店' → card: shop_official, action: filter_shop_type, params: {shop_type: 'official'}\n"
            "   - '旗舰店' → card: shop_official, action: filter_shop_type, params: {shop_type: 'exclusive'}\n\n"
            "6. 评分相关：\n"
            "   - '4.5分以上' → card: rating_high, action: filter_rating, params: {min_rating: 4.5}\n"
            "   - '好评' → card: rating_good, action: sort_rating, params: {sort_by: 'rating_desc'}\n\n"
            "7. 排序：\n"
            "   - '按价格排序' → card: sort_price, action: sort_price, params: {sort_by: 'price_asc'}\n"
            "   - '按销量排序' → card: sort_sales, action: sort_sales, params: {sort_by: 'sales'}\n"
            "   - '按评分排序' → card: sort_rating, action: sort_rating, params: {sort_by: 'rating_desc'}\n\n"
            "8. 其他：\n"
            "   - '有货' → card: filter_available, action: filter_available, params: {}\n"
            "   - '打折/有优惠' → card: filter_discount, action: filter_discount, params: {has_discount: true}\n\n"
            "图标可选: trending-down, trending-up, shield-check, palette, zap, star, check-circle, filter, shopping-cart, verified\n"
            "重要：标题必须精确反映筛选条件，如'500元以内'、'红色'、'京东'等。必须严格返回纯JSON数组。"
        )

        full_user_prompt = f"用户输入的筛选需求：{filter_text}\n\n{instruction}"

        result = await self.generate(system_prompt, full_user_prompt)
        if isinstance(result, list):
            return result
        if isinstance(result, dict) and "cards" in result:
            return result["cards"]
        return []

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
