from base64 import b64encode

from app.clients._base_ark import BaseArkClient
from app.config import settings


class VLMClientError(Exception):
    pass


class VLMAuthError(VLMClientError):
    pass


class VLMRateLimitError(VLMClientError):
    pass


class VLMAPIError(VLMClientError):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(f"VLM API error {status_code}: {message}")


class ArkVLMClient(BaseArkClient):
    ClientError = VLMClientError
    AuthError = VLMAuthError
    RateLimitError = VLMRateLimitError
    APIError = VLMAPIError

    def __init__(
        self,
        api_key: str = "",
        endpoint_id: str = "",
        base_url: str = "",
    ):
        super().__init__(
            api_key=api_key,
            endpoint_id=endpoint_id or settings.ark_vlm_endpoint_id,
            base_url=base_url,
        )

    async def recognize(self, image_bytes: bytes) -> dict:
        image_base64 = b64encode(image_bytes).decode("utf-8")
        data_url = f"data:image/jpeg;base64,{image_base64}"

        system_prompt = (
            "你是商品图像识别助手。\n"
            "=== 核心规则 ===\n"
            "只识别图中最主要、最突出的一个商品，忽略次要物品和背景杂物。\n"
            "=== 绝对禁止 ===\n"
            "1. 绝对禁止输出任何 markdown 标记、``` 代码块标记、解释性文字\n"
            "2. 绝对禁止输出除纯 JSON 之外的任何内容\n"
            "3. 直接返回 JSON，不要任何前缀后缀\n"
            "=== 必须输出的纯JSON结构 ===\n"
            '{"category": "品类", "keywords": ["关键词1","关键词2"], "brand": "", "color": "", "style": ""}\n'
            "keywords只包含这一个商品的相关关键词。不确定的字段设为空字符串，只返回纯JSON。"
        )

        payload = {
            "model": self.endpoint_id,
            "max_tokens": 80,
            "temperature": 0.1,
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "识别这张图片中最主要的一个商品。"},
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ],
                },
            ],
        }

        result = await self._call_api(payload)
        return self._validate_recognition_result(result)

    def _validate_recognition_result(self, result: dict) -> dict:
        required_fields = ["category", "keywords", "color", "brand", "style"]
        for field in required_fields:
            if field not in result:
                result[field] = "" if field != "keywords" else []

        if not isinstance(result.get("keywords"), list):
            result["keywords"] = []

        result["source"] = "vlm"
        return result
