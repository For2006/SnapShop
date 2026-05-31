from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import BrowseHistory


async def record_browse_entries(
    products: list[dict],
    device_id: str,
    db: AsyncSession,
):
    if not products:
        return

    today = datetime.utcnow().date()
    for p in products:
        product_id = p.get("id", "")
        if not product_id:
            continue

        result = await db.execute(
            select(BrowseHistory).where(
                BrowseHistory.device_id == device_id,
                BrowseHistory.product_id == product_id,
                BrowseHistory.view_date == today,
            )
        )
        if result.scalar_one_or_none():
            continue

        snapshot = {
            "id": product_id,
            "name": p.get("name", ""),
            "price": float(p.get("price", 0)),
            "original_price": float(p["original_price"]) if p.get("original_price") else None,
            "platform": p.get("platform", ""),
            "image_url": p.get("image_url", ""),
            "shop_name": p.get("shop_name", ""),
            "shop_type": p.get("shop_type", "third_party"),
            "rating": float(p["rating"]) if p.get("rating") else None,
            "sales_count": int(p["sales_count"]) if p.get("sales_count") else None,
            "tags": p.get("tags", []),
        }

        entry = BrowseHistory(
            device_id=device_id,
            product_id=product_id,
            product_snapshot=snapshot,
        )
        db.add(entry)

    await db.commit()
