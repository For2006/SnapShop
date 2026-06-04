from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import BrowseHistory


async def record_browse_entries(
    products: list[dict],
    device_id: str,
    db: AsyncSession,
    user_id: str | None = None,
):
    if not products:
        return

    today = datetime.now(timezone.utc).date()
    product_ids = [p.get("id", "") for p in products if p.get("id")]
    if not product_ids:
        return

    query = select(BrowseHistory.product_id).where(
        BrowseHistory.product_id.in_(product_ids),
        BrowseHistory.view_date == today,
    )
    if user_id:
        query = query.where(BrowseHistory.user_id == user_id)
    else:
        query = query.where(BrowseHistory.device_id == device_id)
    result = await db.execute(query)
    existing_ids = {row[0] for row in result.all()}

    entries: list[BrowseHistory] = []
    for p in products:
        product_id = p.get("id", "")
        if not product_id or product_id in existing_ids:
            continue

        snapshot = {
            "id": product_id,
            "name": p.get("name", ""),
            "price": float(p.get("price", 0)),
            "original_price": float(p["original_price"]) if p.get("original_price") is not None else None,
            "platform": p.get("platform", ""),
            "image_url": p.get("image_url", ""),
            "shop_name": p.get("shop_name", ""),
            "shop_type": p.get("shop_type", "third_party"),
            "rating": float(p["rating"]) if p.get("rating") is not None else None,
            "sales_count": int(p["sales_count"]) if p.get("sales_count") is not None else None,
            "tags": p.get("tags", []),
        }

        entries.append(BrowseHistory(
            user_id=user_id,
            device_id=device_id,
            product_id=product_id,
            product_snapshot=snapshot,
        ))

    if entries:
        db.add_all(entries)
        await db.commit()
