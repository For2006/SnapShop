import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.core.database import Base


class RecognitionResult(Base):
    __tablename__ = "recognition_results"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("search_sessions.id"),
        unique=True,
        index=True,
    )
    category: Mapped[str] = mapped_column(String(100))
    attributes: Mapped[dict] = mapped_column(JSON, default=dict)
    raw_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    confidence: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    session = relationship("SearchSession", back_populates="recognition_result")
