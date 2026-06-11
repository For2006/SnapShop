import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.exceptions import SessionNotFoundError
from app.models import Product, SearchSession

router = APIRouter()


@router.get("/products/{session_id}")
async def get_products(
    session_id: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    sort_by: str = Query("comprehensive"),
    platform: str = Query(""),
    db: AsyncSession = Depends(get_db),
):
    try:
        sid = uuid.UUID(session_id)
    except ValueError:
        raise SessionNotFoundError(session_id)

    session_result = await db.execute(
        select(SearchSession.id).where(SearchSession.id == sid)
    )
    if not session_result.scalar_one_or_none():
        raise SessionNotFoundError(session_id)

    query = select(Product).where(Product.session_id == sid)

    if platform and platform in ("taobao", "jd", "pdd"):
        query = query.where(Product.platform == platform)

    count_query = select(func.count(Product.id)).where(Product.session_id == sid)
    if platform and platform in ("taobao", "jd", "pdd"):
        count_query = count_query.where(Product.platform == platform)
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    if sort_by == "price_asc":
        query = query.order_by(Product.price.asc())
    elif sort_by == "price_desc":
        query = query.order_by(Product.price.desc())
    elif sort_by == "sales":
        query = query.order_by(Product.sales_count.desc().nullslast())
    elif sort_by == "rating":
        query = query.order_by(Product.rating.desc().nullslast())

    offset = (page - 1) * size
    query = query.offset(offset).limit(size)

    result = await db.execute(query)
    products = result.scalars().all()

    items = [
        {
            "id": str(p.id),
            "name": p.name,
            "price": float(p.price),
            "original_price": float(p.original_price) if p.original_price is not None else None,
            "platform": p.platform,
            "shop_name": p.shop_name,
            "shop_type": p.shop_type,
            "rating": float(p.rating) if p.rating is not None else None,
            "sales_count": p.sales_count,
            "image_url": p.image_url,
            "product_url": p.product_url or "",
            "is_mock": p.is_mock,
            "attributes": p.attributes or {},
            "tags": [],
        }
        for p in products
    ]

    return {
        "items": items,
        "total": total,
        "page": page,
        "size": size,
    }
