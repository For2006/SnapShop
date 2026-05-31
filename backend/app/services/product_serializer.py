import uuid


def serialize_product(p: dict) -> dict:
    return {
        "id": p.get("id", str(uuid.uuid4())),
        "name": p.get("name", ""),
        "price": float(p.get("price", 0)),
        "original_price": float(p["original_price"]) if p.get("original_price") else None,
        "platform": p.get("platform", ""),
        "shop_name": p.get("shop_name", ""),
        "shop_type": p.get("shop_type", "third_party"),
        "rating": float(p["rating"]) if p.get("rating") else None,
        "sales_count": int(p["sales_count"]) if p.get("sales_count") else None,
        "image_url": p.get("image_url", ""),
        "product_url": p.get("product_url", ""),
        "attributes": p.get("attributes", {}),
        "tags": p.get("tags", []),
    }
