from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# 根据数据库类型配置连接池
engine_kwargs = {
    "echo": settings.debug,
    "pool_pre_ping": True,
}

# 仅非 SQLite 数据库支持连接池参数
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
    from app.config import settings
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        # 为旧数据库添加 is_mock 列
        if "sqlite" in settings.database_url:
            try:
                await conn.execute(
                    __import__("sqlalchemy").text("ALTER TABLE products ADD COLUMN is_mock BOOLEAN DEFAULT 0")
                )
            except Exception:
                pass
