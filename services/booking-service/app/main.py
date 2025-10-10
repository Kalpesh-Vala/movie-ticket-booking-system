"""
Booking Service - FastAPI Application with GraphQL
This service orchestrates the booking workflow using multiple communication patterns:
- GraphQL for client API
- gRPC for cinema service communication  
- REST for user/payment service communication
- RabbitMQ for event publishing
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter

from .graphql_resolvers import schema
from .database import connect_to_mongo, close_mongo_connection
from .event_publisher import EventPublisher


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    event_publisher = None
    try:
        # Startup
        await connect_to_mongo()
        print("✅ Connected to MongoDB")
        
        # Initialize event publisher
        event_publisher = EventPublisher()
        await event_publisher.connect()
        print("✅ Connected to RabbitMQ")
        
        # Store event publisher in app state
        app.state.event_publisher = event_publisher
        
        yield
        
    finally:
        # Shutdown
        await close_mongo_connection()
        if event_publisher:
            await event_publisher.close()
        print("✅ Disconnected from databases")


# Create FastAPI app
app = FastAPI(
    title="Movie Ticket Booking Service",
    description="GraphQL API for booking movie tickets with microservice orchestration",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GraphQL router
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")

@app.get("/")
async def root():
    return {"message": "Movie Ticket Booking Service", "graphql_endpoint": "/graphql"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "booking-service"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8004))
    uvicorn.run(app, host="0.0.0.0", port=port)