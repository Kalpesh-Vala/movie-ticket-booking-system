# Docker Deployment Guide

This guide explains how to run the Cinema Service using Docker and Docker Compose with PostgreSQL database.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB free disk space
- Ports 8002, 9090, 5433, and 8080 available

## Quick Start

### 1. Start All Services
```bash
# Start PostgreSQL and Cinema Service
./docker-management.sh up
```

### 2. Check Status
```bash
# View service status and health
./docker-management.sh status
```

### 3. Test the Service
```bash
# Run comprehensive API tests
./docker-management.sh test
```

## Docker Management Commands

### Build and Deployment
```bash
# Build the Docker image
./docker-management.sh build

# Start all services (database + cinema service)
./docker-management.sh up

# Stop all services
./docker-management.sh down

# Restart all services
./docker-management.sh restart
```

### Monitoring and Debugging
```bash
# View logs from all services
./docker-management.sh logs

# View cinema service logs only
./docker-management.sh logs-cinema

# View database logs only
./docker-management.sh logs-db

# Check health status
./docker-management.sh health

# View container status
./docker-management.sh status
```

### Database Management
```bash
# Open PostgreSQL shell
./docker-management.sh shell-db

# Backup database
./docker-management.sh backup-db

# Restore database from backup
./docker-management.sh restore-db backup_file.sql
```

### Container Access
```bash
# Open shell in cinema service container
./docker-management.sh shell-cinema

# Open database shell
./docker-management.sh shell-db
```

### Cleanup
```bash
# Remove all containers, networks, and volumes
./docker-management.sh clean
```

## Service Configuration

### Architecture Overview
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client Apps   │    │  Cinema Service  │    │   PostgreSQL    │
│                 │    │   (Port 8002)    │    │   (Port 5433)   │
│  REST/gRPC      │◄──►│   REST + gRPC    │◄──►│   Database      │
│  Clients        │    │   (Port 9090)    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │     pgAdmin      │
                       │   (Port 8080)    │
                       │   Web UI for DB  │
                       └──────────────────┘
```

### Network Configuration
- **Network Name**: `cinema-network`
- **Network Type**: Bridge
- **Subnet**: `172.20.0.0/16`
- **DNS Resolution**: Automatic between containers

### Port Mapping
| Service | Internal Port | External Port | Protocol |
|---------|---------------|---------------|----------|
| Cinema Service (REST) | 8002 | 8002 | HTTP |
| Cinema Service (gRPC) | 9090 | 9090 | gRPC |
| PostgreSQL | 5432 | 5433 | TCP |
| pgAdmin | 80 | 8080 | HTTP |

### Volume Configuration
| Volume Name | Mount Point | Purpose |
|-------------|-------------|---------|
| `cinema_postgres_data` | `/var/lib/postgresql/data` | Database persistence |
| `cinema_pgadmin_data` | `/var/lib/pgadmin` | pgAdmin settings |

## Environment Variables

### Database Configuration
```bash
POSTGRES_DB=cinema_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
```

### Cinema Service Configuration
```bash
# Database Connection
SPRING_DATASOURCE_URL=jdbc:postgresql://cinema-postgres:5432/cinema_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=password

# Server Ports
SERVER_PORT=8002
GRPC_SERVER_PORT=9090

# Logging
LOGGING_LEVEL_COM_MOVIETICKET=INFO
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK=WARN

# Connection Pool
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=20
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=5
```

## Service URLs

After starting the services, you can access:

- **Cinema Service REST API**: http://localhost:8002
- **Cinema Service Health Check**: http://localhost:8002/actuator/health
- **Cinema Service gRPC**: localhost:9090
- **pgAdmin Web Interface**: http://localhost:8080
  - Email: `admin@cinema.com`
  - Password: `admin`
- **PostgreSQL Database**: localhost:5433
  - Database: `cinema_db`
  - Username: `postgres`
  - Password: `password`

## Health Checks

The deployment includes comprehensive health checks:

### Application Health Check
```bash
curl http://localhost:8002/actuator/health
```

### Database Health Check
```bash
docker-compose exec cinema-postgres pg_isready -U postgres -d cinema_db
```

### Automated Health Monitoring
- **Cinema Service**: Health check every 30 seconds
- **PostgreSQL**: Health check every 10 seconds
- **Startup Grace Period**: 60 seconds for cinema service, 30 seconds for database

## Database Initialization

The database is automatically initialized with:

1. **Schema Creation** (`schema.sql`)
   - All tables, indexes, and constraints
   - Foreign key relationships
   - Proper data types and constraints

2. **Sample Data** (`sample_data.sql`)
   - 2 cinemas with multiple screens
   - 5 movies with various genres
   - 10 showtimes across different dates

3. **Seat Generation** (`generate_seats.sql`)
   - 1,250 seats across all screens
   - Proper seat numbering (A01, A02, etc.)
   - Different seat types (REGULAR, PREMIUM, VIP)

## Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check if ports are in use
sudo netstat -tlnp | grep -E ':(8002|9090|5433|8080)'

# Stop conflicting services
sudo systemctl stop postgresql  # If local PostgreSQL conflicts
```

#### Memory Issues
```bash
# Check available memory
free -h

# Check Docker resource usage
docker stats
```

#### Database Connection Issues
```bash
# Check database container logs
./docker-management.sh logs-db

# Verify database is ready
./docker-management.sh shell-db
```

#### Service Startup Issues
```bash
# Check cinema service logs
./docker-management.sh logs-cinema

# Verify environment variables
docker-compose exec cinema-service env | grep SPRING
```

### Log Analysis

#### Application Logs
```bash
# Real-time application logs
./docker-management.sh logs-cinema

# Search for errors
./docker-management.sh logs-cinema | grep ERROR

# Check startup sequence
docker-compose logs cinema-service | head -50
```

#### Database Logs
```bash
# Database connection logs
./docker-management.sh logs-db | grep "connection"

# Query logs (if enabled)
./docker-management.sh logs-db | grep "LOG:"
```

### Performance Monitoring

#### Container Resource Usage
```bash
# Real-time resource monitoring
docker stats

# Specific service monitoring
docker stats cinema-service cinema-postgres
```

#### Database Performance
```bash
# Connect to database and check connections
./docker-management.sh shell-db

# Inside PostgreSQL:
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_database;
```

## Development vs Production

### Development Mode
- Enable SQL logging: `SPRING_JPA_SHOW_SQL=true`
- Verbose logging: `LOGGING_LEVEL_COM_MOVIETICKET=DEBUG`
- Development profile: `SPRING_PROFILES_ACTIVE=docker,dev`

### Production Mode
- Disable SQL logging: `SPRING_JPA_SHOW_SQL=false`
- Minimal logging: `LOGGING_LEVEL_ORG_SPRINGFRAMEWORK=WARN`
- Production profile: `SPRING_PROFILES_ACTIVE=docker,prod`

## Security Considerations

### Container Security
- **Non-root user**: Cinema service runs as `cinema` user
- **Read-only filesystem**: Database migration scripts mounted read-only
- **Network isolation**: Services communicate through dedicated bridge network
- **Resource limits**: Configure memory and CPU limits in production

### Database Security
- **Password protection**: Change default passwords in production
- **Network access**: Database only accessible from cinema service container
- **Data encryption**: Enable PostgreSQL encryption in production
- **Backup encryption**: Encrypt database backups

### Production Recommendations
- Use Docker secrets for sensitive data
- Enable PostgreSQL SSL/TLS
- Configure firewall rules
- Regular security updates
- Monitor container vulnerabilities

## Backup and Recovery

### Automated Backups
```bash
# Create backup
./docker-management.sh backup-db

# Schedule regular backups (add to crontab)
0 2 * * * cd /path/to/cinema-service && ./docker-management.sh backup-db
```

### Disaster Recovery
```bash
# Stop services
./docker-management.sh down

# Restore from backup
./docker-management.sh restore-db backup_file.sql

# Start services
./docker-management.sh up
```

### Data Migration
```bash
# Export data
docker-compose exec cinema-postgres pg_dump -U postgres cinema_db > export.sql

# Import to new environment
docker-compose exec cinema-postgres psql -U postgres cinema_db < export.sql
```