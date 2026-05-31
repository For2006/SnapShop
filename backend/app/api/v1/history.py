import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_device
from app.models import SearchSession, RecognitionResult, Product, FilterAction

router = APIRouter()


@router.get("/history")
async def get_search_history(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=50),
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
):
    count_query = select(func.count(SearchSession.id)).where(
        SearchSession.device_id == device_id,
        SearchSession.status == "completed",
    )
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = (
        select(SearchSession)
        .where(
            SearchSession.device_id == device_id,
            SearchSession.status == "completed",
        )
        .order_by(SearchSession.created_at.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    result = await db.execute(query)
    sessions = result.scalars().all()

    items = [
        {
            "session_id": str(s.id),
            "image_url": s.image_url,
            "category": s.recognition_result.category if s.recognition_result else "",
            "search_type": s.search_type,
            "search_query": s.search_query,
            "created_at": s.created_at.isoformat() if s.created_at else None,
        }
        for s in sessions
    ]

    return {"items": items, "total": total, "page": page, "size": size}


@router.delete("/history")
async def clear_all_search_history(
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[History] 清空搜索记录, device_id={device_id}")

    sessions_result = await db.execute(
        select(SearchSession.id).where(SearchSession.device_id == device_id)
    )
    session_ids = [row[0] for row in sessions_result.all()]
    logger.info(f"[History] 找到 {len(session_ids)} 条记录待删除, ids={[str(s) for s in session_ids]}")

    cleared = 0
    if session_ids:
        try:
            await db.execute(delete(FilterAction).where(FilterAction.session_id.in_(session_ids)))
            await db.execute(delete(Product).where(Product.session_id.in_(session_ids)))
            await db.execute(delete(RecognitionResult).where(RecognitionResult.session_id.in_(session_ids)))
            await db.execute(delete(SearchSession).where(SearchSession.device_id == device_id))
            await db.flush()

            verify_result = await db.execute(
                select(func.count(SearchSession.id)).where(SearchSession.device_id == device_id)
            )
            remaining = verify_result.scalar() or 0
            logger.info(f"[History] 删除后剩余记录数: {remaining}")

            await db.commit()
            cleared = len(session_ids)
            logger.info(f"[History] 已删除 {cleared} 条搜索记录")
        except Exception as e:
            await db.rollback()
            logger.error(f"[History] 删除失败: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail={"error_code": "DELETE_FAILED", "message": f"清空失败: {str(e)}"})

    return {"ok": True, "cleared": cleared}


@router.delete("/history/{session_id}")
async def delete_search_history(
    session_id: str,
    device_id: str = Depends(get_current_device),
    db: AsyncSession = Depends(get_db),
):
    try:
        sid = uuid.UUID(session_id)
    except ValueError:
        raise HTTPException(status_code=400, detail={"error_code": "INVALID_ID", "message": "无效的会话ID"})

    result = await db.execute(
        select(SearchSession).where(
            SearchSession.id == sid,
            SearchSession.device_id == device_id,
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail={"error_code": "NOT_FOUND", "message": "记录不存在"})

    await db.execute(delete(FilterAction).where(FilterAction.session_id == sid))
    await db.execute(delete(Product).where(Product.session_id == sid))
    await db.execute(delete(RecognitionResult).where(RecognitionResult.session_id == sid))
    await db.execute(delete(SearchSession).where(SearchSession.id == sid))
    await db.commit()

    return {"ok": True}
