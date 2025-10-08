#!/bin/bash

# Database setup script for Cinema Service
# This script creates the database, tables, and populates sample data

echo "Setting up Cinema Service Database..."

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="cinema_db"
DB_USER="postgres"
DB_PASSWORD="password"

# Create database if it doesn't exist
echo "Creating database '$DB_NAME'..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE $DB_NAME;" postgres 2>/dev/null || echo "Database '$DB_NAME' already exists"

# Wait a moment for database to be ready
sleep 2

# Execute schema creation
echo "Creating database schema..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f src/main/resources/db/migration/schema.sql

# Insert sample data
echo "Inserting sample data..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f src/main/resources/db/migration/sample_data.sql

# Generate seats for all showtimes
echo "Generating seats for showtimes..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f src/main/resources/db/migration/generate_seats.sql

echo "Database setup completed successfully!"
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"

# Display summary
echo ""
echo "Summary of data created:"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
SELECT 
    (SELECT COUNT(*) FROM cinemas) AS cinemas,
    (SELECT COUNT(*) FROM movies) AS movies,
    (SELECT COUNT(*) FROM screens) AS screens,
    (SELECT COUNT(*) FROM showtimes) AS showtimes,
    (SELECT COUNT(*) FROM seats) AS seats;
"