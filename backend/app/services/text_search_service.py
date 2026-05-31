import uuid
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import SearchSession, SessionStatus
from app.services.search_service import SearchService
from app.services.comparison_service import ComparisonService
from app.services.suggestion_service import SuggestionService
from app.services.product_serializer import serialize_product


class TextSearchService:
    def __init__(self, llm_client=None):
        self._llm_client = llm_client
        self._search_service = SearchService()
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

        # 直接使用原始关键词，不等待缓慢的 LLM 扩展，提高响应速度
        expanded_keywords = keywords

        products = await self._search_service.search_all(
            keywords=expanded_keywords, session=session, db=db
        )

        filtered_products, price_summary = self._comparison_service.compare_and_rerank(
            products, expanded_keywords
        )

        from app.services.browse_recorder import record_browse_entries
        await record_browse_entries(filtered_products, device_id, db)

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
