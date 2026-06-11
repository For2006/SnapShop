from pydantic import BaseModel

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_device, get_db, get_filter_service
from app.core.rate_limit import check_filter_rate_limit
from app.services.filter_service import FilterService


class FilterRequest(BaseModel):
    session_id: str
    filter_text: str


router = APIRouter()


@router.get("/filter/stream")
async def filter_stream(
    session_id: str = Query(..., description="搜索会话ID"),
    filter_text: str = Query(..., description="自然语言筛选文本"),
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
    service: FilterService = Depends(get_filter_service),
    _rate_limit: None = Depends(check_filter_rate_limit),
):
    return StreamingResponse(
        service.filter_stream(
            session_id=session_id,
            filter_text=filter_text,
            db=db,
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/filter")
async def filter_products(
    body: FilterRequest,
    service: FilterService = Depends(get_filter_service),
):
    result = await service.parse_to_cards(body.filter_text)
    return result
