import enum
import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class SessionStatus(str, enum.Enum):
    RECOGNIZING = "recognizing"
    COMPLETED = "completed"
    FAILED = "failed"


class SearchSession(Base):
    __tablename__ = "search_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid, primary_key=True, default=uuid.uuid4
    )
    device_id: Mapped[str] = mapped_column(String(100), index=True)
    image_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    search_type: Mapped[str] = mapped_column(String(20), default="image", index=True)
    search_query: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[SessionStatus] = mapped_column(
        Enum(SessionStatus), default=SessionStatus.RECOGNIZING, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)

    recognition_result = relationship(
        "RecognitionResult", back_populates="session", uselist=False, lazy="selectin"
    )
    products = relationship("Product", back_populates="session", lazy="selectin")
    filter_actions = relationship(
        "FilterAction", back_populates="session", lazy="selectin"
    )
