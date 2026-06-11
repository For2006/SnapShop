from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

engine_kwargs = {
    "echo": settings.debug,
    "pool_pre_ping": True,
}

if "sqlite" not in settings.database_url:
    engine_kwargs.update({
        "pool_size": 10,
        "max_overflow": 20,
        "pool_recycle": 3600,
    })

engine = create_async_engine(
    settings.database_url,
    **engine_kwargs
)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        yield session


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await _ensure_mock_column_exists(conn)


async def _ensure_mock_column_exists(conn):
    if "sqlite" not in settings.database_url:
        return

    try:
        result = await conn.execute(text("PRAGMA table_info(products)"))
        columns = [row[1] for row in result.fetchall()]
        if "is_mock" not in columns:
            await conn.execute(text("ALTER TABLE products ADD COLUMN is_mock BOOLEAN DEFAULT 0"))
    except Exception:
        pass
