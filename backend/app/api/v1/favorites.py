from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import delete as sa_delete
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.exceptions import AppException
from app.models import Favorite, User
from app.schemas.favorite import (
    FavoriteAddRequest,
    FavoriteItemResponse,
    FavoriteListResponse,
)

router = APIRouter()


@router.post("/favorites", response_model=FavoriteItemResponse, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    body: FavoriteAddRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user is None:
        raise AppException(status_code=401, error_code="UNAUTHORIZED", message="请先登录")

    result = await db.execute(
        select(Favorite).where(
            Favorite.user_id == user.id,
            Favorite.product_id == body.product_id,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return FavoriteItemResponse(
            id=str(existing.id),
            product_id=existing.product_id,
            product_snapshot=existing.product_snapshot,
            created_at=existing.created_at,
        )

    fav = Favorite(
        user_id=user.id,
        product_id=body.product_id,
        product_snapshot=body.product_snapshot.model_dump(),
    )
    db.add(fav)
    await db.commit()
    await db.refresh(fav)

    return FavoriteItemResponse(
        id=str(fav.id),
        product_id=fav.product_id,
        product_snapshot=fav.product_snapshot,
        created_at=fav.created_at,
    )


@router.delete("/favorites/{product_id}", status_code=status.HTTP_200_OK)
async def remove_favorite(
    product_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user is None:
        raise AppException(status_code=401, error_code="UNAUTHORIZED", message="请先登录")

    await db.execute(
        sa_delete(Favorite).where(
            Favorite.user_id == user.id,
            Favorite.product_id == product_id,
        )
    )
    await db.commit()
    return {"message": "ok"}


@router.get("/favorites", response_model=FavoriteListResponse)
async def list_favorites(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=50),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user is None:
        raise AppException(status_code=401, error_code="UNAUTHORIZED", message="请先登录")

    count_result = await db.execute(
        select(func.count()).select_from(Favorite).where(Favorite.user_id == user.id)
    )
    total = count_result.scalar() or 0

    offset = (page - 1) * size
    result = await db.execute(
        select(Favorite)
        .where(Favorite.user_id == user.id)
        .order_by(Favorite.created_at.desc())
        .offset(offset)
        .limit(size)
    )
    favs = result.scalars().all()

    return FavoriteListResponse(
        items=[
            FavoriteItemResponse(
                id=str(f.id),
                product_id=f.product_id,
                product_snapshot=f.product_snapshot,
                created_at=f.created_at,
            )
            for f in favs
        ],
        total=total,
        page=page,
        size=size,
    )
