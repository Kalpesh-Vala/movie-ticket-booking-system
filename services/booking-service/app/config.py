"""
Configuration module for Booking Service
"""

import os
from typing import Optional


class Config:
    """Configuration settings for the booking service"""
    
    # Database settings
    MONGODB_URI: str = os.getenv(
        "MONGODB_URI", 
        "mongodb://admin:admin123@localhost:27017/movie_booking?authSource=admin"
    )
    
    # Service URLs - Updated to match the actual service URLs from docker-compose
    USER_SERVICE_REST_URL: str = os.getenv("USER_SERVICE_REST_URL", "http://localhost:8001")
    PAYMENT_SERVICE_REST_URL: str = os.getenv("PAYMENT_SERVICE_REST_URL", "http://localhost:8003")
    CINEMA_SERVICE_GRPC_URL: str = os.getenv("CINEMA_SERVICE_GRPC_URL", "localhost:9090")
    
    # RabbitMQ settings - Updated to match the docker-compose configuration
    RABBITMQ_URL: str = os.getenv("RABBITMQ_URL", "amqp://admin:admin123@localhost:5672/")
    RABBITMQ_EXCHANGE: str = os.getenv("RABBITMQ_EXCHANGE", "movie_app_events")
    
    # Booking settings
    SEAT_LOCK_DURATION: int = int(os.getenv("SEAT_LOCK_DURATION", "300"))  # 5 minutes
    PAYMENT_TIMEOUT: int = int(os.getenv("PAYMENT_TIMEOUT", "300"))  # 5 minutes
    
    # API settings
    API_TIMEOUT: int = int(os.getenv("API_TIMEOUT", "30"))
    
    # Application settings
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"
    
    # CORS settings
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    @classmethod
    def get_database_url(cls) -> str:
        """Get database URL"""
        return cls.MONGODB_URI
    
    @classmethod
    def is_development(cls) -> bool:
        """Check if running in development mode"""
        return cls.ENVIRONMENT.lower() in ["development", "dev", "local"]
    
    @classmethod
    def is_production(cls) -> bool:
        """Check if running in production mode"""
        return cls.ENVIRONMENT.lower() in ["production", "prod"]


# Global config instance
config = Config()