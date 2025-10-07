"""
Configuration module for Booking Service
"""

import os
from typing import Optional


class Config:
    """Configuration settings for the booking service"""
    
    # Database settings
    MONGODB_URL: str = os.getenv(
        "MONGODB_URL", 
        "mongodb://admin:password@localhost:27017/movietickets?authSource=admin"
    )
    
    # Service URLs
    USER_SERVICE_URL: str = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
    PAYMENT_SERVICE_URL: str = os.getenv("PAYMENT_SERVICE_URL", "http://localhost:8002")
    CINEMA_SERVICE_URL: str = os.getenv("CINEMA_SERVICE_URL", "localhost:50051")
    
    # RabbitMQ settings
    RABBITMQ_URL: str = os.getenv("RABBITMQ_URL", "amqp://admin:password@localhost:5672/")
    
    # Booking settings
    SEAT_LOCK_DURATION: int = int(os.getenv("SEAT_LOCK_DURATION", "300"))  # 5 minutes
    PAYMENT_TIMEOUT: int = int(os.getenv("PAYMENT_TIMEOUT", "300"))  # 5 minutes
    
    # API settings
    API_TIMEOUT: int = int(os.getenv("API_TIMEOUT", "30"))
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"
    
    # CORS settings
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    @classmethod
    def get_database_url(cls) -> str:
        """Get database URL"""
        return cls.MONGODB_URL
    
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