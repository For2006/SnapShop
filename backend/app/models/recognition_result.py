import uuid

from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.core.database import Base


class RecognitionResult(Base):
    __tablename__ = "recognition_results"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("search_sessions.id", ondelete="CASCADE"),
        unique=True,
        index=True,
    )
    category: Mapped[str] = mapped_column(String(100))
    attributes: Mapped[dict] = mapped_column(JSON, default=dict)
    raw_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    confidence: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))

    session = relationship("SearchSession", back_populates="recognition_result")
