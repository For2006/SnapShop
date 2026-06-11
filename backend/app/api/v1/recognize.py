import logging
import time

from io import BytesIO

from fastapi import APIRouter, Depends, File, UploadFile
from PIL import Image
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_device, get_db, get_recognition_service
from app.core.exceptions import ImageTooLargeError, InvalidImageError
from app.core.rate_limit import check_recognize_rate_limit
from app.schemas.recognize import AttributeUpdateRequest
from app.services.recognition_service import RecognitionService

router = APIRouter()
logger = logging.getLogger(__name__)

MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_PX = 512


def _resize_image(image_bytes: bytes) -> bytes:
    img = Image.open(BytesIO(image_bytes))
    width, height = img.size
    longest = max(width, height)
    if longest <= MAX_IMAGE_PX:
        return image_bytes
    ratio = MAX_IMAGE_PX / longest
    new_size = (int(width * ratio), int(height * ratio))
    img = img.resize(new_size, Image.LANCZOS)
    output = BytesIO()
    img_format = img.format or "JPEG"
    if img_format.upper() not in ("JPEG", "PNG", "WEBP"):
        img_format = "JPEG"
    img = img.convert("RGB")
    img.save(output, format="JPEG", quality=85)
    return output.getvalue()


@router.post("/recognize")
async def recognize_product(
    image: UploadFile | None = File(None),
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
    service: RecognitionService = Depends(get_recognition_service),
    _rate_limit: None = Depends(check_recognize_rate_limit),
):
    t0 = time.time()

    if image is None:
        raise InvalidImageError("请上传商品图片")

    if image.content_type and image.content_type not in ALLOWED_TYPES:
        raise InvalidImageError("仅支持 JPEG / PNG / WebP 格式的图片")

    image_bytes = await image.read()
    t1 = time.time()
    logger.info(f"[识别] 图片读取: {len(image_bytes)} bytes, contentType={image.content_type}, 耗时={t1-t0:.2f}s")

    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise ImageTooLargeError("图片大小超过 5MB 限制，请压缩后重试")

    if len(image_bytes) == 0:
        raise InvalidImageError("图片文件为空")

    original_size = len(image_bytes)
    image_bytes = _resize_image(image_bytes)
    if len(image_bytes) != original_size:
        logger.info(f"[识别] 图片压缩: {original_size} → {len(image_bytes)} bytes")

    result = await service.recognize(image_bytes, device_id=device_id, db=db)
    t2 = time.time()
    logger.info(f"[识别] 总耗时={t2-t0:.2f}s (读取={t1-t0:.2f}s, 识别+搜索={t2-t1:.2f}s)")
    return result


@router.patch("/recognize/{session_id}/attributes")
async def update_attributes(
    session_id: str,
    body: AttributeUpdateRequest,
    db: AsyncSession = Depends(get_db),
    service: RecognitionService = Depends(get_recognition_service),
):
    """属性修正：纯结构化操作，不调用 LLM"""
    return await service.update_attributes(session_id, body.attribute, body.new_value, db)
