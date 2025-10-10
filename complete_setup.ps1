# Movie Ticket Booking System - Complete Setup (PowerShell)
# Windows PowerShell Script for setting up the complete system

Write-Host "🚀 Movie Ticket Booking System - Complete Setup (PowerShell)" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Wait-ForService {
    param(
        [string]$Url,
        [string]$ServiceName,
        [int]$MaxAttempts = 30
    )
    
    Write-Status "Waiting for $ServiceName to be ready..."
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "$ServiceName is ready!"
                return $true
            }
        }
        catch {
            # Service not ready yet
        }
        
        Write-Host "  Attempt $attempt/$MaxAttempts - $ServiceName not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
    
    Write-Error "$ServiceName failed to start after $MaxAttempts attempts"
    return $false
}

# Step 1: Clean up any existing containers
Write-Host ""
Write-Host "Step 1: Cleanup Previous Containers" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

Write-Status "Stopping and removing existing containers..."
try {
    docker-compose down -v 2>$null
    docker container prune -f 2>$null
}
catch {
    Write-Host "No existing containers to clean up" -ForegroundColor Yellow
}

# Step 2: Start infrastructure services first
Write-Host ""
Write-Host "Step 2: Starting Infrastructure Services" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Status "Starting databases and message broker..."
docker-compose up -d postgres mongodb redis rabbitmq

Write-Status "Waiting for infrastructure services to be ready..."
$infraReady = $true
$infraReady = $infraReady -and (Wait-ForService "http://localhost:15672" "RabbitMQ Management")

if (-not $infraReady) {
    Write-Error "Infrastructure services failed to start"
    exit 1
}

Write-Success "Infrastructure services are ready!"

# Step 3: Start Kong Gateway
Write-Host ""
Write-Host "Step 3: Starting Kong Gateway" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow

Write-Status "Starting Kong database and gateway..."
docker-compose up -d kong-database
Start-Sleep -Seconds 10
docker-compose up -d kong-migrations
Start-Sleep -Seconds 10
docker-compose up -d kong

$kongReady = Wait-ForService "http://localhost:8000" "Kong Gateway"
if (-not $kongReady) {
    Write-Error "Kong Gateway failed to start"
    exit 1
}

# Step 4: Start microservices
Write-Host ""
Write-Host "Step 4: Starting Microservices" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

Write-Status "Starting User Service..."
docker-compose up -d user-service
Wait-ForService "http://localhost:8001/health" "User Service" | Out-Null

Write-Status "Starting Cinema Service..."
docker-compose up -d cinema-service
Wait-ForService "http://localhost:8002/actuator/health" "Cinema Service" | Out-Null

Write-Status "Starting Payment Service..."
docker-compose up -d payment-service
Wait-ForService "http://localhost:8003/health" "Payment Service" | Out-Null

Write-Status "Starting Booking Service..."
docker-compose up -d booking-service
Wait-ForService "http://localhost:8010/health" "Booking Service" | Out-Null

Write-Status "Starting Notification Service..."
docker-compose up -d notification-service

# Step 5: Start monitoring tools
Write-Host ""
Write-Host "Step 5: Starting Monitoring Tools" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

Write-Status "Starting management interfaces..."
docker-compose up -d mongo-express pgadmin redis-commander

Write-Success "All services started successfully!"

# Step 6: Verify all services are running
Write-Host ""
Write-Host "Step 6: Service Verification" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow

Write-Status "Checking service status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "(kong|user-service|cinema-service|booking-service|payment-service|notification-service|postgres|mongodb|redis|rabbitmq)"

# Step 7: Display access information
Write-Host ""
Write-Host "Step 7: System Access Information" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

Write-Success "🎉 Setup completed successfully!"
Write-Host ""
Write-Host "📡 Service Endpoints (through Kong Gateway):" -ForegroundColor Cyan
Write-Host "  - Kong Gateway:           http://localhost:8000"
Write-Host "  - User Service API:       http://localhost:8000/api/v1/"
Write-Host "  - Cinema Service API:     http://localhost:8000/api/v1/"
Write-Host "  - Booking GraphQL:        http://localhost:8000/graphql"
Write-Host "  - Payment Service API:    http://localhost:8000/payment/"
Write-Host ""
Write-Host "🔧 Direct Service Access (for development):" -ForegroundColor Cyan
Write-Host "  - User Service:           http://localhost:8001"
Write-Host "  - Cinema Service:         http://localhost:8002"
Write-Host "  - Booking Service:        http://localhost:8010"
Write-Host "  - Payment Service:        http://localhost:8003"
Write-Host ""
Write-Host "📊 Management Interfaces:" -ForegroundColor Cyan
Write-Host "  - Kong Admin:             http://localhost:8001 (Kong admin API)"
Write-Host "  - RabbitMQ Management:    http://localhost:15672 (admin/admin123)"
Write-Host "  - MongoDB Express:        http://localhost:8081 (admin/admin123)"
Write-Host "  - PostgreSQL pgAdmin:     http://localhost:8080 (admin@movietickets.com/admin123)"
Write-Host "  - Redis Commander:        http://localhost:8082"
Write-Host ""
Write-Host "🐳 Docker Commands:" -ForegroundColor Cyan
Write-Host "  - View logs:              docker-compose logs -f [service-name]"
Write-Host "  - Stop all:               docker-compose down"
Write-Host "  - Restart service:        docker-compose restart [service-name]"
Write-Host ""
Write-Host "🧪 Testing:" -ForegroundColor Cyan
Write-Host "  - Run integration test:   .\windows_integration_test.ps1"
Write-Host "  - GraphQL Playground:     http://localhost:8000/graphql"
Write-Host ""
Write-Host "🚨 Important Notes:" -ForegroundColor Yellow
Write-Host "  - All external access goes through Kong Gateway (port 8000)"
Write-Host "  - JWT authentication is disabled for GraphQL (easier testing)"
Write-Host "  - Check RabbitMQ queues for message flow"
Write-Host "  - Monitor notification service logs for email processing"
Write-Host ""
Write-Success "System is ready for testing!"

# Test basic connectivity
Write-Host ""
Write-Host "Quick Connectivity Test:" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow

$services = @(
    @{Name="Kong Gateway"; Url="http://localhost:8000"},
    @{Name="User Service"; Url="http://localhost:8001/health"},
    @{Name="Cinema Service"; Url="http://localhost:8002/actuator/health"},
    @{Name="Booking Service"; Url="http://localhost:8010/health"},
    @{Name="Payment Service"; Url="http://localhost:8003/health"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ $($service.Name) is responding"
        }
        else {
            Write-Error "❌ $($service.Name) returned status $($response.StatusCode)"
        }
    }
    catch {
        Write-Error "❌ $($service.Name) is not responding"
    }
}

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Green
Write-Host "1. Run the integration test script to validate the complete workflow"
Write-Host "2. Access the GraphQL playground at http://localhost:8000/graphql"
Write-Host "3. Check RabbitMQ management interface for message flow"
Write-Host "4. Monitor service logs for any issues"
Write-Host ""
Write-Host "Ready to test the complete system! 🚀" -ForegroundColor Green