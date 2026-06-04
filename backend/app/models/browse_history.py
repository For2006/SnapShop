import uuid
from datetime import date, datetime, timezone


def _utc_today() -> date:
    return datetime.now(timezone.utc).date()

from sqlalchemy import Date, DateTime, ForeignKey, JSON, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class BrowseHistory(Base):
    __tablename__ = "browse_history"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    device_id: Mapped[str | None] = mapped_column(String(100), index=True, nullable=True)
    product_id: Mapped[str] = mapped_column(String(200), index=True, nullable=False)
    product_snapshot: Mapped[dict] = mapped_column(JSON, nullable=False)
    viewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    view_date: Mapped[date] = mapped_column(Date, default=_utc_today, index=True)
