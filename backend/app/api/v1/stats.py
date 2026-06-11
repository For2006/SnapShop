from fastapi import APIRouter, Depends, Header
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_optional_user
from app.models import BrowseHistory, Favorite, User
from app.schemas.favorite import UserStatsResponse

router = APIRouter()


@router.get("/user/stats", response_model=UserStatsResponse)
async def get_user_stats(
    user: User | None = Depends(get_optional_user),
    x_device_id: str = Header(None, alias="X-Device-Id"),
    db: AsyncSession = Depends(get_db),
):
    device_id = x_device_id or "anonymous"

    if user:
        fav_result = await db.execute(
            select(func.count()).select_from(Favorite).where(Favorite.user_id == user.id)
        )
        favorite_count = fav_result.scalar() or 0

        browse_result = await db.execute(
            select(func.count()).select_from(BrowseHistory).where(
                or_(BrowseHistory.user_id == user.id, BrowseHistory.device_id == device_id)
            )
        )
        browse_count = browse_result.scalar() or 0
    else:
        favorite_count = 0
        browse_result = await db.execute(
            select(func.count()).select_from(BrowseHistory).where(BrowseHistory.device_id == device_id)
        )
        browse_count = browse_result.scalar() or 0

    return UserStatsResponse(favorite_count=favorite_count, browse_count=browse_count)
