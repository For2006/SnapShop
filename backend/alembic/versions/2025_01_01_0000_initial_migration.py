"""initial migration - create all tables

Revision ID: 000000000001
Revises: 
Create Date: 2025-01-01 00:00:00.000000

"""
import sqlalchemy as sa

from alembic import op

revision = "000000000001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("hashed_password", sa.String(length=128), nullable=False),
        sa.Column("nickname", sa.String(length=50), nullable=False),
        sa.Column("avatar_url", sa.String(length=500), nullable=True),
        sa.Column("bio", sa.String(length=200), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_users_created_at"), ["created_at"], unique=False)
        batch_op.create_index(batch_op.f("ix_users_phone"), ["phone"], unique=True)

    op.create_table(
        "search_sessions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("device_id", sa.String(length=100), nullable=False),
        sa.Column("image_url", sa.String(length=2000), nullable=True),
        sa.Column("search_type", sa.String(length=20), nullable=False),
        sa.Column("search_query", sa.String(length=500), nullable=True),
        sa.Column("status", sa.Enum("RECOGNIZING", "COMPLETED", "FAILED", name="sessionstatus"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("search_sessions", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_search_sessions_created_at"), ["created_at"], unique=False)
        batch_op.create_index(batch_op.f("ix_search_sessions_device_id"), ["device_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_search_sessions_search_type"), ["search_type"], unique=False)
        batch_op.create_index(batch_op.f("ix_search_sessions_status"), ["status"], unique=False)

    op.create_table(
        "browse_history",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=True),
        sa.Column("device_id", sa.String(length=100), nullable=True),
        sa.Column("product_id", sa.String(length=200), nullable=False),
        sa.Column("product_snapshot", sa.JSON(), nullable=False),
        sa.Column("viewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("view_date", sa.Date(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("browse_history", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_browse_history_device_id"), ["device_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_browse_history_product_id"), ["product_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_browse_history_user_id"), ["user_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_browse_history_view_date"), ["view_date"], unique=False)
        batch_op.create_index(batch_op.f("ix_browse_history_viewed_at"), ["viewed_at"], unique=False)

    op.create_table(
        "favorites",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("product_id", sa.String(length=200), nullable=False),
        sa.Column("product_snapshot", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("favorites", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_favorites_created_at"), ["created_at"], unique=False)
        batch_op.create_index(batch_op.f("ix_favorites_product_id"), ["product_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_favorites_user_id"), ["user_id"], unique=False)

    op.create_table(
        "filter_actions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("session_id", sa.Uuid(), nullable=False),
        sa.Column("action_type", sa.String(length=20), nullable=False),
        sa.Column("filter_text", sa.String(length=500), nullable=True),
        sa.Column("params", sa.JSON(), nullable=False),
        sa.Column("result_count", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["search_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("filter_actions", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_filter_actions_session_id"), ["session_id"], unique=False)

    op.create_table(
        "products",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("session_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=500), nullable=False),
        sa.Column("image_url", sa.String(length=2000), nullable=False),
        sa.Column("price", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("original_price", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("platform", sa.String(length=20), nullable=False),
        sa.Column("shop_name", sa.String(length=200), nullable=False),
        sa.Column("shop_type", sa.String(length=30), nullable=False),
        sa.Column("rating", sa.Numeric(precision=2, scale=1), nullable=True),
        sa.Column("sales_count", sa.Integer(), nullable=True),
        sa.Column("product_url", sa.String(length=2000), nullable=True),
        sa.Column("is_mock", sa.Boolean(), nullable=False),
        sa.Column("attributes", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["search_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("products", schema=None) as batch_op:
        batch_op.create_index("ix_products_session_price", ["session_id", "price"], unique=False)
        batch_op.create_index("ix_products_session_rating", ["session_id", "rating"], unique=False)
        batch_op.create_index("ix_products_session_sales", ["session_id", "sales_count"], unique=False)
        batch_op.create_index(batch_op.f("ix_products_session_id"), ["session_id"], unique=False)

    op.create_table(
        "recognition_results",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("session_id", sa.Uuid(), nullable=False),
        sa.Column("category", sa.String(length=100), nullable=False),
        sa.Column("attributes", sa.JSON(), nullable=False),
        sa.Column("raw_response", sa.JSON(), nullable=True),
        sa.Column("confidence", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["search_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id")
    )
    with op.batch_alter_table("recognition_results", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_recognition_results_session_id"), ["session_id"], unique=True)


def downgrade() -> None:
    with op.batch_alter_table("recognition_results", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_recognition_results_session_id"))
    op.drop_table("recognition_results")
    with op.batch_alter_table("products", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_products_session_id"))
        batch_op.drop_index("ix_products_session_sales")
        batch_op.drop_index("ix_products_session_rating")
        batch_op.drop_index("ix_products_session_price")
    op.drop_table("products")
    with op.batch_alter_table("filter_actions", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_filter_actions_session_id"))
    op.drop_table("filter_actions")
    with op.batch_alter_table("favorites", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_favorites_user_id"))
        batch_op.drop_index(batch_op.f("ix_favorites_product_id"))
        batch_op.drop_index(batch_op.f("ix_favorites_created_at"))
    op.drop_table("favorites")
    with op.batch_alter_table("browse_history", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_browse_history_viewed_at"))
        batch_op.drop_index(batch_op.f("ix_browse_history_view_date"))
        batch_op.drop_index(batch_op.f("ix_browse_history_user_id"))
        batch_op.drop_index(batch_op.f("ix_browse_history_product_id"))
        batch_op.drop_index(batch_op.f("ix_browse_history_device_id"))
    op.drop_table("browse_history")
    with op.batch_alter_table("search_sessions", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_search_sessions_status"))
        batch_op.drop_index(batch_op.f("ix_search_sessions_search_type"))
        batch_op.drop_index(batch_op.f("ix_search_sessions_device_id"))
        batch_op.drop_index(batch_op.f("ix_search_sessions_created_at"))
    op.drop_table("search_sessions")
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_users_phone"))
        batch_op.drop_index(batch_op.f("ix_users_created_at"))
    op.drop_table("users")
