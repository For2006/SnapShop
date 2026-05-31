import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.core.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("search_sessions.id"), index=True
    )
    name: Mapped[str] = mapped_column(String(500))
    image_url: Mapped[str] = mapped_column(String(2000))
    price: Mapped[float] = mapped_column(Numeric(10, 2))
    original_price: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    platform: Mapped[str] = mapped_column(String(20))
    shop_name: Mapped[str] = mapped_column(String(200))
    shop_type: Mapped[str] = mapped_column(String(30))
    rating: Mapped[float | None] = mapped_column(Numeric(2, 1), nullable=True)
    sales_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    product_url: Mapped[str] = mapped_column(String(2000), nullable=True, default="")
    attributes: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    session = relationship("SearchSession", back_populates="products")

    __table_args__ = (
        Index("ix_products_session_price", "session_id", "price"),
        Index("ix_products_session_rating", "session_id", "rating"),
        Index("ix_products_session_sales", "session_id", "sales_count"),
    )
