#!/bin/bash

# Cinema Service Startup Script
# This script ensures proper directory context and environment setup

set -e

# Navigate to the cinema service directory
cd "$(dirname "$0")"

echo "Starting Cinema Service from: $(pwd)"

# Check if PostgreSQL is running
if ! nc -z localhost 5432 2>/dev/null; then
    echo "❌ PostgreSQL is not running on localhost:5432"
    echo "Please start PostgreSQL first or use Docker:"
    echo "  docker run -d --name movie-postgres -p 5432:5432 -e POSTGRES_DB=cinema_db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password postgres:15"
    exit 1
fi

echo "✅ PostgreSQL is running"

# Set database URL if not provided
export SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL:-jdbc:postgresql://localhost:5432/cinema_db}
export SPRING_DATASOURCE_USERNAME=${SPRING_DATASOURCE_USERNAME:-postgres}
export SPRING_DATASOURCE_PASSWORD=${SPRING_DATASOURCE_PASSWORD:-password}

echo "Database URL: $SPRING_DATASOURCE_URL"

# Start the cinema service
echo "🚀 Starting Cinema Service..."
mvn spring-boot:run