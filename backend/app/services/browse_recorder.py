
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

    entries: list[BrowseHistory] = []
    for p in products:
        product_id = p.get("id", "")
        if not product_id:
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
