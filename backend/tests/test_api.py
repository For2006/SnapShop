from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
import uuid


class TestHealthEndpoint:
    def test_health_check(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}

    def test_docs_accessible(self, client):
        response = client.get("/docs")
        assert response.status_code == 200
        assert "SnapShop" in response.text

    def test_openapi_schema(self, client):
        response = client.get("/openapi.json")
        assert response.status_code == 200
        schema = response.json()
        assert schema["info"]["title"] == "SnapShop API"
        paths = schema["paths"]
        assert "/api/v1/recognize" in paths
        assert "/api/v1/search" in paths
        assert "/api/v1/products/{session_id}" in paths
        assert "/api/v1/filter/stream" in paths
        assert "/api/v1/suggestions/action" in paths
        assert "/api/v1/history" in paths
        assert "/api/v1/recognize/{session_id}/attributes" in paths


class TestRouteRegistration:
    def test_all_routes_registered(self, client):
        paths = [
            "/api/v1/recognize",
            "/api/v1/search",
            "/api/v1/history",
        ]
        for path in paths:
            response = client.options(path)
            assert response.status_code in (200, 204, 405)

    def test_recognize_rejects_get(self, client):
        response = client.get("/api/v1/recognize")
        assert response.status_code == 405

    def test_search_rejects_get(self, client):
        response = client.get("/api/v1/search")
        assert response.status_code == 405

    def test_history_endpoint_registered(self, client):
        response = client.get("/openapi.json")
        schema = response.json()
        paths = schema["paths"]
        assert "/api/v1/history" in paths


class TestErrorResponseFormat:
    def test_validation_error_format(self, client):
        response = client.post("/api/v1/search", json={"keywords": "not_a_list"})
        data = response.json()
        assert "error_code" in data
        assert "message" in data

    def test_missing_required_field(self, client):
        response = client.post("/api/v1/search", json={})
        data = response.json()
        assert "error_code" in data

    def test_invalid_session_id_format(self, client):
        response = client.get("/api/v1/products/not-a-valid-uuid")
        data = response.json()
        assert "error_code" in data

    def test_rate_limit_error(self):
        from app.core.exceptions import RateLimitedError
        exc = RateLimitedError()
        assert exc.status_code == 429
        assert exc.detail["error_code"] == "RATE_LIMITED"

    def test_recognition_failed_error(self):
        from app.core.exceptions import RecognitionFailedError
        exc = RecognitionFailedError("测试错误")
        assert exc.status_code == 400
        assert exc.detail["error_code"] == "RECOGNITION_FAILED"

    def test_session_not_found_error(self):
        from app.core.exceptions import SessionNotFoundError
        exc = SessionNotFoundError("test-session")
        assert exc.status_code == 404
        assert exc.detail["error_code"] == "SESSION_NOT_FOUND"

    def test_ai_service_unavailable_error(self):
        from app.core.exceptions import AIServiceUnavailableError
        exc = AIServiceUnavailableError()
        assert exc.status_code == 503
        assert exc.detail["error_code"] == "SERVICE_UNAVAILABLE"

    def test_image_error(self):
        from app.core.exceptions import InvalidImageError, ImageTooLargeError
        exc1 = InvalidImageError()
        assert exc1.status_code == 400
        assert exc1.detail["error_code"] == "INVALID_IMAGE"
        exc2 = ImageTooLargeError()
        assert exc2.status_code == 413
        assert exc2.detail["error_code"] == "IMAGE_TOO_LARGE"
