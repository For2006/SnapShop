import enum

from app.models.browse_history import BrowseHistory
from app.models.favorite import Favorite
from app.models.filter_action import FilterAction
from app.models.product import Product
from app.models.recognition_result import RecognitionResult
from app.models.search_session import SearchSession, SessionStatus
from app.models.user import User


class ShopType(str, enum.Enum):
    OFFICIAL = "official"
    SELF_OPERATED = "self_operated"
    EXCLUSIVE = "exclusive"
    THIRD_PARTY = "third_party"
    INDIVIDUAL = "individual"

    @property
    def label_zh(self) -> str:
        _labels = {
            "official": "官方旗舰店",
            "self_operated": "自营",
            "exclusive": "专卖店",
            "third_party": "第三方店铺",
            "individual": "个人店铺",
        }
        return _labels.get(self.value, self.value)


__all__ = [
    "BrowseHistory",
    "Favorite",
    "FilterAction",
    "Product",
    "RecognitionResult",
    "SearchSession",
    "SessionStatus",
    "ShopType",
    "User",
]
