import uuid

from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.core.database import Base


class FilterAction(Base):
    __tablename__ = "filter_actions"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("search_sessions.id", ondelete="CASCADE"), index=True
    )
    action_type: Mapped[str] = mapped_column(String(20))
    filter_text: Mapped[str | None] = mapped_column(String(500), nullable=True)
    params: Mapped[dict] = mapped_column(JSON, default=dict)
    result_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))

    session = relationship("SearchSession", back_populates="filter_actions")
