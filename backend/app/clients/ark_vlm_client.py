from base64 import b64encode

from app.config import settings
from app.clients._base_ark import BaseArkClient


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
            "你是一个专业的商品图像识别助手。请仔细观察用户提供的商品图片，"
            "识别并输出商品的属性信息。\n"
            "请严格按照以下JSON格式返回结果，不要包含任何其他内容：\n"
            '{"category": "商品类别", "brand": "品牌名称", "color": "颜色", '
            '"style": "风格", "material": "材质", "shape": "外形", '
            '"keywords": ["关键词1", "关键词2", "关键词3"], '
            '"confidence": {"category": 0.0-1.0, "brand": 0.0-1.0, "color": 0.0-1.0, '
            '"style": 0.0-1.0, "material": 0.0-1.0, "shape": 0.0-1.0}}\n'
            "如果无法确定某个属性，请将对应字段设为空字符串，confidence设为0.0。"
        )

        payload = {
            "model": self.endpoint_id,
            "max_tokens": 300,
            "temperature": 0.1,
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "请识别这张商品图片的属性。"},
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ],
                },
            ],
        }

        result = await self._call_api(payload)
        return self._validate_recognition_result(result)

    def _validate_recognition_result(self, result: dict) -> dict:
        required_fields = ["category", "brand", "color", "style", "material", "shape", "keywords"]
        for field in required_fields:
            if field not in result:
                result[field] = "" if field != "keywords" else []

        if "confidence" not in result:
            result["confidence"] = {}
        confidence_fields = ["category", "brand", "color", "style", "material", "shape"]
        for field in confidence_fields:
            if field not in result["confidence"]:
                result["confidence"][field] = 0.0
            elif not isinstance(result["confidence"][field], (int, float)):
                try:
                    result["confidence"][field] = float(result["confidence"][field])
                except (ValueError, TypeError):
                    result["confidence"][field] = 0.0

        if not isinstance(result.get("keywords"), list):
            result["keywords"] = []

        result["source"] = "vlm"
        return result