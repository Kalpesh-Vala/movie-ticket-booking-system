"""
Integration tests for the FastAPI application
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock

from app.main import app


class TestFastAPIApp:
    """Test FastAPI application endpoints"""
    
    def test_root_endpoint(self):
        """Test root endpoint"""
        client = TestClient(app)
        response = client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Movie Ticket Booking Service" in data["message"]
        assert "graphql_endpoint" in data
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        client = TestClient(app)
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "booking-service"
    
    def test_graphql_endpoint_options(self):
        """Test GraphQL endpoint OPTIONS request (CORS)"""
        client = TestClient(app)
        response = client.options("/graphql")
        
        # Should handle CORS preflight
        assert response.status_code in [200, 204]
    
    @pytest.mark.asyncio
    async def test_graphql_query(self):
        """Test GraphQL query execution"""
        # Mock database and dependencies
        with patch('app.main.connect_to_mongo'), \
             patch('app.main.EventPublisher') as mock_event_publisher_class:
            
            mock_event_publisher = AsyncMock()
            mock_event_publisher_class.return_value = mock_event_publisher
            
            client = TestClient(app)
            
            # Test GraphQL introspection query
            query = """
            query {
                __schema {
                    types {
                        name
                    }
                }
            }
            """
            
            response = client.post(
                "/graphql",
                json={"query": query}
            )
            
            assert response.status_code == 200
            data = response.json()
            assert "data" in data
            assert "__schema" in data["data"]


class TestCORSMiddleware:
    """Test CORS middleware configuration"""
    
    def test_cors_headers(self):
        """Test CORS headers are set correctly"""
        client = TestClient(app)
        
        response = client.options(
            "/graphql",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "Content-Type"
            }
        )
        
        # Check CORS headers
        assert response.headers.get("access-control-allow-origin") == "*"
        assert "POST" in response.headers.get("access-control-allow-methods", "")
    
    def test_preflight_request(self):
        """Test CORS preflight request handling"""
        client = TestClient(app)
        
        response = client.options(
            "/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET"
            }
        )
        
        assert response.status_code in [200, 204]


class TestApplicationLifespan:
    """Test application startup and shutdown"""
    
    @pytest.mark.asyncio
    async def test_lifespan_startup_success(self):
        """Test successful application startup"""
        with patch('app.main.connect_to_mongo') as mock_connect, \
             patch('app.main.EventPublisher') as mock_event_publisher_class:
            
            mock_event_publisher = AsyncMock()
            mock_event_publisher_class.return_value = mock_event_publisher
            
            # Test that startup doesn't raise exceptions
            try:
                client = TestClient(app)
                response = client.get("/health")
                assert response.status_code == 200
            except Exception as e:
                pytest.fail(f"Application startup failed: {e}")
    
    @pytest.mark.asyncio
    async def test_lifespan_shutdown_success(self):
        """Test successful application shutdown"""
        with patch('app.main.close_mongo_connection') as mock_close, \
             patch('app.main.EventPublisher') as mock_event_publisher_class:
            
            mock_event_publisher = AsyncMock()
            mock_event_publisher_class.return_value = mock_event_publisher
            
            # Test that shutdown doesn't raise exceptions
            try:
                client = TestClient(app)
                # Client context manager handles lifespan
                with client:
                    pass
            except Exception as e:
                pytest.fail(f"Application shutdown failed: {e}")


class TestErrorHandling:
    """Test application error handling"""
    
    def test_404_error(self):
        """Test 404 error handling"""
        client = TestClient(app)
        response = client.get("/nonexistent-endpoint")
        
        assert response.status_code == 404
    
    def test_invalid_graphql_query(self):
        """Test invalid GraphQL query handling"""
        client = TestClient(app)
        
        # Invalid GraphQL syntax
        response = client.post(
            "/graphql",
            json={"query": "invalid query syntax"}
        )
        
        assert response.status_code == 400
        data = response.json()
        assert "errors" in data
    
    def test_missing_graphql_query(self):
        """Test missing GraphQL query handling"""
        client = TestClient(app)
        
        response = client.post("/graphql", json={})
        
        assert response.status_code == 400