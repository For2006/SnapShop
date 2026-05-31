import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class SessionStatus(str, enum.Enum):
    RECOGNIZING = "recognizing"
    COMPLETED = "completed"
    FAILED = "failed"


class SearchSession(Base):
    __tablename__ = "search_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    device_id: Mapped[str] = mapped_column(String(100), index=True)
    image_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    search_type: Mapped[str] = mapped_column(String(20), default="image")
    search_query: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[SessionStatus] = mapped_column(
        Enum(SessionStatus), default=SessionStatus.RECOGNIZING
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    recognition_result = relationship(
        "RecognitionResult", back_populates="session", uselist=False, lazy="selectin"
    )
    products = relationship("Product", back_populates="session", lazy="selectin")
    filter_actions = relationship(
        "FilterAction", back_populates="session", lazy="selectin"
    )
