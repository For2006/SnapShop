from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_device, get_suggestion_service
from app.schemas.suggestion import SuggestionActionRequest
from app.services.suggestion_service import SuggestionService

router = APIRouter()


@router.post("/suggestions/action")
async def execute_suggestion_action(
    body: SuggestionActionRequest,
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
    service: SuggestionService = Depends(get_suggestion_service),
):
    products = await service.execute_action(
        session_id=body.session_id,
        card_id=body.card_id,
        params=body.params,
        db=db,
    )
    return {"products": products}
