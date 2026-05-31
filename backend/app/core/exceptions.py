from fastapi import HTTPException


class AppException(HTTPException):
    def __init__(self, status_code: int, error_code: str, message: str, detail: str | None = None):
        super().__init__(status_code=status_code, detail={"error_code": error_code, "message": message, "detail": detail})


class RecognitionFailedError(AppException):
    def __init__(self, message: str = "未识别到商品，请上传清晰的商品图片"):
        super().__init__(status_code=400, error_code="RECOGNITION_FAILED", message=message)


class InvalidImageError(AppException):
    def __init__(self, message: str = "图片格式不支持或文件过大"):
        super().__init__(status_code=400, error_code="INVALID_IMAGE", message=message)


class ImageTooLargeError(AppException):
    def __init__(self, message: str = "图片超过最大限制"):
        super().__init__(status_code=413, error_code="IMAGE_TOO_LARGE", message=message)


class SessionNotFoundError(AppException):
    def __init__(self, session_id: str = ""):
        super().__init__(status_code=404, error_code="SESSION_NOT_FOUND", message=f"会话不存在: {session_id}")


class RateLimitedError(AppException):
    def __init__(self, message: str = "请求过于频繁，请稍后再试"):
        super().__init__(status_code=429, error_code="RATE_LIMITED", message=message)


class AIServiceUnavailableError(AppException):
    def __init__(self, message: str = "AI服务暂时不可用"):
        super().__init__(status_code=503, error_code="SERVICE_UNAVAILABLE", message=message)
