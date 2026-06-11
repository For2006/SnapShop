import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.models import SearchSession, SessionStatus
from app.services.comparison_service import ComparisonService
from app.services.product_serializer import serialize_product
from app.services.search_service import SearchService
from app.services.suggestion_service import SuggestionService

logger = logging.getLogger(__name__)


class TextSearchService:
    def __init__(self, llm_client=None, search_service=None):
        self._search_service = search_service or SearchService()
        self._comparison_service = ComparisonService()
        self._suggestion_service = SuggestionService()

    async def search(
        self,
        keywords: list[str],
        device_id: str,
        db: AsyncSession,
    ) -> dict:
        session = SearchSession(
            device_id=device_id,
            search_type="text",
            search_query=" ".join(keywords),
            status=SessionStatus.RECOGNIZING,
        )
        db.add(session)
        await db.flush()

        try:
            products = await self._search_service.search_all(
                keywords=keywords, session=session, db=db, skip_persist=True,
            )
        except Exception as e:
            logger.error(f"[TextSearch] 搜索异常: {e}")
            session.status = SessionStatus.FAILED
            await db.commit()
            raise AppException(status_code=500, error_code="SEARCH_FAILED", message="搜索服务暂时不可用，请稍后重试")

        filtered_products, price_summary = self._comparison_service.compare_and_rerank(
            products, keywords
        )

        await self._search_service._persist_products(filtered_products, session.id, db)

        suggestions = SuggestionService.get_preset_suggestions()

        session.status = SessionStatus.COMPLETED
        await db.commit()

        return {
            "session_id": str(session.id),
            "recognition": {
                "category": "",
                "attributes": [],
                "suggestions": suggestions,
            },
            "suggestions": suggestions,
            "products": [
                serialize_product(p)
                for p in filtered_products
            ],
            "price_summary": price_summary,
        }
