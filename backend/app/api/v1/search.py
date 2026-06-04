from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_device, get_db, get_text_search_service
from app.schemas.search import TextSearchRequest
from app.services.text_search_service import TextSearchService

router = APIRouter()


@router.post("/search")
async def text_search(
    body: TextSearchRequest,
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
    service: TextSearchService = Depends(get_text_search_service),
):
    if not body.keywords:
        raise HTTPException(status_code=400, detail={"error_code": "VALIDATION_ERROR", "message": "keywords不可为空"})
    return await service.search(body.keywords, device_id=device_id, db=db)
