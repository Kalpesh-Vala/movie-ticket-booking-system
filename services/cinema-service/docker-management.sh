#!/bin/bash

# Docker Management Script for Cinema Service
# This script provides easy commands to manage the cinema service with Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
    echo -e "${BLUE}Cinema Service Docker Management${NC}"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build         Build the cinema service Docker image"
    echo "  up            Start all services (postgres + cinema service)"
    echo "  down          Stop all services"
    echo "  restart       Restart all services"
    echo "  logs          Show logs for all services"
    echo "  logs-cinema   Show logs for cinema service only"
    echo "  logs-db       Show logs for database only"
    echo "  status        Show status of all containers"
    echo "  clean         Stop and remove all containers, networks, and volumes"
    echo "  test          Run API tests against dockerized service"
    echo "  shell-cinema  Open shell in cinema service container"
    echo "  shell-db      Open psql shell in database container"
    echo "  backup-db     Backup database to file"
    echo "  restore-db    Restore database from backup file"
    echo "  health        Check health of all services"
    echo ""
}

build_service() {
    echo -e "${BLUE}Building Cinema Service Docker image...${NC}"
    docker-compose build cinema-service
    echo -e "${GREEN}✅ Build completed successfully${NC}"
}

start_services() {
    echo -e "${BLUE}Starting Cinema Service with PostgreSQL...${NC}"
    docker-compose up -d
    
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 10
    
    # Wait for database to be ready
    echo -e "${YELLOW}Waiting for PostgreSQL...${NC}"
    until docker-compose exec -T cinema-postgres pg_isready -U postgres -d cinema_db > /dev/null 2>&1; do
        echo -e "${YELLOW}Waiting for database...${NC}"
        sleep 2
    done
    
    # Wait for cinema service to be ready
    echo -e "${YELLOW}Waiting for Cinema Service...${NC}"
    until curl -f http://localhost:8002/actuator/health > /dev/null 2>&1; do
        echo -e "${YELLOW}Waiting for cinema service...${NC}"
        sleep 3
    done
    
    echo -e "${GREEN}✅ All services are running!${NC}"
    show_status
}

stop_services() {
    echo -e "${BLUE}Stopping all services...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ All services stopped${NC}"
}

restart_services() {
    echo -e "${BLUE}Restarting all services...${NC}"
    docker-compose restart
    echo -e "${GREEN}✅ All services restarted${NC}"
}

show_logs() {
    docker-compose logs -f
}

show_cinema_logs() {
    docker-compose logs -f cinema-service
}

show_db_logs() {
    docker-compose logs -f cinema-postgres
}

show_status() {
    echo -e "${BLUE}Service Status:${NC}"
    docker-compose ps
    echo ""
    
    # Check individual service health
    echo -e "${BLUE}Health Checks:${NC}"
    
    # Database health
    if docker-compose exec -T cinema-postgres pg_isready -U postgres -d cinema_db > /dev/null 2>&1; then
        echo -e "Database:      ${GREEN}✅ Healthy${NC}"
    else
        echo -e "Database:      ${RED}❌ Unhealthy${NC}"
    fi
    
    # Cinema service health
    if curl -f http://localhost:8002/actuator/health > /dev/null 2>&1; then
        echo -e "Cinema Service: ${GREEN}✅ Healthy${NC}"
    else
        echo -e "Cinema Service: ${RED}❌ Unhealthy${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Service URLs:${NC}"
    echo "Cinema Service REST API: http://localhost:8002"
    echo "Cinema Service gRPC:     localhost:9090"
    echo "pgAdmin:                 http://localhost:8080 (admin@cinema.com / admin)"
    echo "PostgreSQL:              localhost:5433"
}

clean_all() {
    echo -e "${YELLOW}⚠️  This will remove all containers, networks, and volumes!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning up all Docker resources...${NC}"
        docker-compose down -v --remove-orphans
        docker system prune -f
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled${NC}"
    fi
}

run_tests() {
    echo -e "${BLUE}Running API tests against dockerized service...${NC}"
    if [ -f "./validate_service.sh" ]; then
        ./validate_service.sh
    else
        echo -e "${RED}❌ validate_service.sh not found${NC}"
        exit 1
    fi
}

shell_cinema() {
    echo -e "${BLUE}Opening shell in cinema service container...${NC}"
    docker-compose exec cinema-service /bin/bash
}

shell_db() {
    echo -e "${BLUE}Opening PostgreSQL shell...${NC}"
    docker-compose exec cinema-postgres psql -U postgres -d cinema_db
}

backup_db() {
    BACKUP_FILE="cinema_db_backup_$(date +%Y%m%d_%H%M%S).sql"
    echo -e "${BLUE}Creating database backup: ${BACKUP_FILE}${NC}"
    docker-compose exec -T cinema-postgres pg_dump -U postgres -d cinema_db > "${BACKUP_FILE}"
    echo -e "${GREEN}✅ Database backup created: ${BACKUP_FILE}${NC}"
}

restore_db() {
    if [ -z "$2" ]; then
        echo -e "${RED}❌ Please provide backup file path${NC}"
        echo "Usage: $0 restore-db <backup_file.sql>"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ Backup file not found: ${BACKUP_FILE}${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Restoring database from: ${BACKUP_FILE}${NC}"
    docker-compose exec -T cinema-postgres psql -U postgres -d cinema_db < "$BACKUP_FILE"
    echo -e "${GREEN}✅ Database restored successfully${NC}"
}

check_health() {
    echo -e "${BLUE}Checking health of all services...${NC}"
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        echo -e "${RED}❌ Services are not running. Start them with: $0 up${NC}"
        exit 1
    fi
    
    # Detailed health check
    echo -e "${BLUE}Detailed Health Check:${NC}"
    
    # Database
    echo -n "PostgreSQL connection: "
    if docker-compose exec -T cinema-postgres pg_isready -U postgres -d cinema_db > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    # Cinema service health endpoint
    echo -n "Cinema Service health: "
    HEALTH_RESPONSE=$(curl -s http://localhost:8002/actuator/health 2>/dev/null || echo "failed")
    if [[ "$HEALTH_RESPONSE" == *"UP"* ]]; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
    
    # gRPC service
    echo -n "gRPC service:          "
    if nc -z localhost 9090 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
}

# Main script logic
case "$1" in
    build)
        build_service
        ;;
    up)
        start_services
        ;;
    down)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    logs-cinema)
        show_cinema_logs
        ;;
    logs-db)
        show_db_logs
        ;;
    status)
        show_status
        ;;
    clean)
        clean_all
        ;;
    test)
        run_tests
        ;;
    shell-cinema)
        shell_cinema
        ;;
    shell-db)
        shell_db
        ;;
    backup-db)
        backup_db
        ;;
    restore-db)
        restore_db "$@"
        ;;
    health)
        check_health
        ;;
    *)
        print_usage
        exit 1
        ;;
esac