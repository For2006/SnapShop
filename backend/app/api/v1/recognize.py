import time
import logging
from typing import Optional

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_device, get_db, get_recognition_service
from app.core.exceptions import InvalidImageError, ImageTooLargeError
from app.core.rate_limit import check_recognize_rate_limit
from app.services.recognition_service import RecognitionService
from app.schemas.recognize import AttributeUpdateRequest

router = APIRouter()
logger = logging.getLogger(__name__)

MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post("/recognize")
async def recognize_product(
    image: Optional[UploadFile] = File(None),
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
