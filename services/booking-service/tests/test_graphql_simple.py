"""
Simple integration tests for GraphQL functionality
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock

# Import app with mocked dependencies
with patch('app.database.connect_to_mongo'), \
     patch('app.main.EventPublisher'):
    from app.main import app


class TestGraphQLIntegration:
    """Test GraphQL integration with FastAPI"""
    
    def test_graphql_introspection(self):
        """Test GraphQL introspection query works"""
        client = TestClient(app)
        
        query = """
        query {
            __schema {
                types {
                    name
                }
            }
        }
        """
        
        response = client.post("/graphql", json={"query": query})
        assert response.status_code == 200
        
        data = response.json()
        assert "data" in data
        assert "__schema" in data["data"]
        assert "types" in data["data"]["__schema"]
    
    def test_graphql_invalid_query(self):
        """Test GraphQL handles invalid queries"""
        client = TestClient(app)
        
        query = "invalid query"
        
        response = client.post("/graphql", json={"query": query})
        assert response.status_code == 200  # GraphQL returns 200 but with errors
        
        data = response.json()
        assert "errors" in data
    
    def test_graphql_missing_query(self):
        """Test GraphQL handles missing query"""
        client = TestClient(app)
        
        response = client.post("/graphql", json={})
        assert response.status_code == 400