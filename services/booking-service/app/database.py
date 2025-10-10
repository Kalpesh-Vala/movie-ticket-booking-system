"""
Database connection and operations for Booking Service
"""

import os
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo.errors import ConnectionFailure
import logging

# Setup logging
logger = logging.getLogger(__name__)

# Global variables
client = None
database = None


async def connect_to_mongo():
    """Create database connection"""
    global client, database
    
    # Get MongoDB connection string from environment
    mongo_url = os.getenv(
        "MONGODB_URI", 
        "mongodb://admin:admin123@localhost:27017/movie_booking?authSource=admin"
    )
    
    try:
        client = AsyncIOMotorClient(mongo_url)
        
        # Test the connection
        await client.admin.command('ping')
        
        database = client.movie_booking
        
        # Create indexes for better performance
        await create_indexes()
        
        print(f"✅ Connected to MongoDB at {mongo_url}")
        logger.info(f"Connected to MongoDB at {mongo_url}")
        
    except ConnectionFailure as e:
        print(f"❌ Failed to connect to MongoDB: {e}")
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise e


async def close_mongo_connection():
    """Close database connection"""
    global client
    if client:
        client.close()
        print("✅ Disconnected from MongoDB")


async def get_database():
    """Get database instance"""
    global database
    if database is None:
        await connect_to_mongo()
    return database


async def create_indexes():
    """Create database indexes for optimal performance"""
    global database
    
    if database is None:
        return
    
    # Bookings collection indexes
    bookings_collection = database.bookings
    
    # Index on user_id for user booking queries
    await bookings_collection.create_index("user_id")
    
    # Index on showtime_id for showtime booking queries
    await bookings_collection.create_index("showtime_id")
    
    # Index on status for status-based queries
    await bookings_collection.create_index("status")
    
    # Index on lock_expires_at for cleanup operations
    await bookings_collection.create_index("lock_expires_at")
    
    # Compound index for user + status queries
    await bookings_collection.create_index([("user_id", 1), ("status", 1)])
    
    print("✅ Database indexes created")