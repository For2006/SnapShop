import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy import select, func, delete as sa_delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.exceptions import AppException
from app.models import BrowseHistory, User
from app.schemas.favorite import (
    BrowseRecordRequest,
    BrowseItemResponse,
    BrowseListResponse,
)

router = APIRouter()


async def _get_optional_user(
    authorization: str | None = Header(None, alias="Authorization"),
    db: AsyncSession = Depends(get_db),
):
    from app.api.deps import get_optional_user
    return await get_optional_user(authorization=authorization, db=db)


@router.post("/browse", status_code=200)
async def record_browse(
    body: BrowseRecordRequest,
    user: User | None = Depends(_get_optional_user),
    x_device_id: str = Header(None, alias="X-Device-Id"),
    db: AsyncSession = Depends(get_db),
):
    today = datetime.utcnow().date()

    if user:
        result = await db.execute(
            select(BrowseHistory).where(
                BrowseHistory.user_id == user.id,
                BrowseHistory.product_id == body.product_id,
                BrowseHistory.view_date == today,
            )
        )
    else:
        device_id = x_device_id or "anonymous"
        result = await db.execute(
            select(BrowseHistory).where(
                BrowseHistory.device_id == device_id,
                BrowseHistory.product_id == body.product_id,
                BrowseHistory.view_date == today,
            )
        )

    existing = result.scalar_one_or_none()
    if existing:
        return {"message": "already recorded"}

    record = BrowseHistory(
        user_id=user.id if user else None,
        device_id=x_device_id or "anonymous",
        product_id=body.product_id,
        product_snapshot=body.product_snapshot.model_dump(),
    )
    db.add(record)
    await db.commit()
    return {"message": "ok"}


@router.get("/browse", response_model=BrowseListResponse)
async def list_browse_history(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=50),
    user: User | None = Depends(_get_optional_user),
    x_device_id: str = Header(None, alias="X-Device-Id"),
    db: AsyncSession = Depends(get_db),
):
    if user:
        count_stmt = select(func.count()).select_from(BrowseHistory).where(BrowseHistory.user_id == user.id)
        items_stmt = (
            select(BrowseHistory)
            .where(BrowseHistory.user_id == user.id)
            .order_by(BrowseHistory.viewed_at.desc())
        )
    else:
        device_id = x_device_id or "anonymous"
        count_stmt = select(func.count()).select_from(BrowseHistory).where(BrowseHistory.device_id == device_id)
        items_stmt = (
            select(BrowseHistory)
            .where(BrowseHistory.device_id == device_id)
            .order_by(BrowseHistory.viewed_at.desc())
        )

    count_result = await db.execute(count_stmt)
    total = count_result.scalar() or 0

    offset = (page - 1) * size
    result = await db.execute(items_stmt.offset(offset).limit(size))
    records = result.scalars().all()

    return BrowseListResponse(
        items=[
            BrowseItemResponse(
                id=str(r.id),
                product_id=r.product_id,
                product_snapshot=r.product_snapshot,
                viewed_at=r.viewed_at,
            )
            for r in records
        ],
        total=total,
        page=page,
        size=size,
    )


@router.delete("/browse/{browse_id}")
async def delete_single_browse(
    browse_id: str,
    user: User | None = Depends(_get_optional_user),
    x_device_id: str = Header(None, alias="X-Device-Id"),
    db: AsyncSession = Depends(get_db),
):
    try:
        bid = uuid.UUID(browse_id)
    except ValueError:
        raise HTTPException(status_code=400, detail={"error_code": "INVALID_ID", "message": "无效的记录ID"})

    if user:
        stmt = select(BrowseHistory).where(BrowseHistory.id == bid, BrowseHistory.user_id == user.id)
    else:
        device_id = x_device_id or "anonymous"
        stmt = select(BrowseHistory).where(BrowseHistory.id == bid, BrowseHistory.device_id == device_id)

    result = await db.execute(stmt)
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail={"error_code": "NOT_FOUND", "message": "记录不存在"})

    await db.execute(sa_delete(BrowseHistory).where(BrowseHistory.id == bid))
    await db.commit()
    return {"ok": True}


@router.delete("/browse")
async def clear_all_browse(
    user: User | None = Depends(_get_optional_user),
    x_device_id: str = Header(None, alias="X-Device-Id"),
    db: AsyncSession = Depends(get_db),
):
    if user:
        await db.execute(sa_delete(BrowseHistory).where(BrowseHistory.user_id == user.id))
    else:
        device_id = x_device_id or "anonymous"
        await db.execute(sa_delete(BrowseHistory).where(BrowseHistory.device_id == device_id))
    await db.commit()
    return {"ok": True, "cleared": True}
