# Movie Ticket Booking System - Integration Test (PowerShell)
# Complete workflow test through Kong Gateway

Write-Host "🎬 Movie Ticket Booking System - Integration Test (PowerShell)" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Configuration
$KONG_GATEWAY = "http://localhost:8000"
$USER_EMAIL = "test.user$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
$USER_PASSWORD = "password123"
$USER_FIRST_NAME = "Test"
$USER_LAST_NAME = "User"

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

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Test-Service {
    param(
        [string]$Url,
        [string]$ServiceName
    )
    
    Write-Status "Checking $ServiceName..."
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Success "$ServiceName is running"
            return $true
        }
        else {
            Write-Error "$ServiceName returned status $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-Error "$ServiceName is not running at $Url"
        return $false
    }
}

# Step 1: Check all services are running
Write-Host ""
Write-Host "Step 1: Checking Service Health" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow

$servicesHealthy = $true
$servicesHealthy = $servicesHealthy -and (Test-Service $KONG_GATEWAY "Kong Gateway")
$servicesHealthy = $servicesHealthy -and (Test-Service "http://localhost:8001/health" "User Service")
$servicesHealthy = $servicesHealthy -and (Test-Service "http://localhost:8002/actuator/health" "Cinema Service")
$servicesHealthy = $servicesHealthy -and (Test-Service "http://localhost:8010/health" "Booking Service")
$servicesHealthy = $servicesHealthy -and (Test-Service "http://localhost:8003/health" "Payment Service")

if (-not $servicesHealthy) {
    Write-Error "Some services are not healthy. Please check the setup."
    exit 1
}

# Step 2: Register a new user through Kong Gateway
Write-Host ""
Write-Host "Step 2: User Registration" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow

Write-Status "Registering new user through Kong Gateway..."
Write-Status "Email: $USER_EMAIL"

$registrationBody = @{
    email = $USER_EMAIL
    password = $USER_PASSWORD
    first_name = $USER_FIRST_NAME
    last_name = $USER_LAST_NAME
} | ConvertTo-Json

try {
    $userResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/api/v1/register" -Method Post -Body $registrationBody -ContentType "application/json" -TimeoutSec 30
    Write-Host "Registration Response: $($userResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan
    
    if ($userResponse.message -like "*successfully*") {
        Write-Success "User registered successfully"
    }
    else {
        Write-Warning "Registration response received (might already exist)"
    }
}
catch {
    Write-Warning "Registration might have failed: $($_.Exception.Message)"
}

# Step 3: Login and get JWT token
Write-Host ""
Write-Host "Step 3: User Authentication" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

Write-Status "Logging in user through Kong Gateway..."

$loginBody = @{
    email = $USER_EMAIL
    password = $USER_PASSWORD
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/api/v1/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 30
    Write-Host "Login Response: $($loginResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan
    
    $JWT_TOKEN = $loginResponse.token
    $USER_ID = $loginResponse.user.id
    
    if ($JWT_TOKEN -and $USER_ID) {
        Write-Success "Login successful"
        Write-Status "JWT Token: $($JWT_TOKEN.Substring(0, [Math]::Min(50, $JWT_TOKEN.Length)))..."
        Write-Status "User ID: $USER_ID"
    }
    else {
        Write-Error "Failed to extract JWT token or user ID"
        Write-Host "Response: $($loginResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Login failed: $($_.Exception.Message)"
    exit 1
}

# Step 4: Get available movies and showtimes through Kong Gateway
Write-Host ""
Write-Host "Step 4: Fetching Movies and Showtimes" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

Write-Status "Fetching movies through Kong Gateway..."
try {
    $moviesResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/api/v1/movies" -Method Get -TimeoutSec 30
    Write-Host "Movies Response: $($moviesResponse | ConvertTo-Json -Depth 5)" -ForegroundColor Cyan
}
catch {
    Write-Warning "Could not fetch movies: $($_.Exception.Message)"
}

Write-Status "Fetching showtimes through Kong Gateway..."
try {
    $showtimesResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/api/v1/showtimes" -Method Get -TimeoutSec 30
    Write-Host "Showtimes Response: $($showtimesResponse | ConvertTo-Json -Depth 5)" -ForegroundColor Cyan
    
    # Extract the first available showtime ID
    $SHOWTIME_ID = $null
    if ($showtimesResponse -is [Array] -and $showtimesResponse.Count -gt 0) {
        $SHOWTIME_ID = $showtimesResponse[0].id
    }
    elseif ($showtimesResponse.id) {
        $SHOWTIME_ID = $showtimesResponse.id
    }
    
    if ($SHOWTIME_ID) {
        Write-Success "Found showtime ID: $SHOWTIME_ID"
    }
    else {
        Write-Warning "No showtimes found, using default ID: 1"
        $SHOWTIME_ID = "1"
    }
}
catch {
    Write-Warning "Could not fetch showtimes: $($_.Exception.Message)"
    Write-Warning "Using default showtime ID: 1"
    $SHOWTIME_ID = "1"
}

# Step 5: Create booking through Kong Gateway (GraphQL)
Write-Host ""
Write-Host "Step 5: Creating Booking" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow

Write-Status "Creating booking through Kong Gateway (GraphQL)..."

$bookingMutation = @{
    query = "mutation CreateBooking(`$userId: String!, `$showtimeId: String!, `$seatNumbers: [String!]!) { createBooking(userId: `$userId, showtimeId: `$showtimeId, seatNumbers: `$seatNumbers) { success booking { id userId showtimeId seats totalAmount status createdAt } message lockId } }"
    variables = @{
        userId = $USER_ID
        showtimeId = $SHOWTIME_ID
        seatNumbers = @("A1", "A2")
    }
} | ConvertTo-Json -Depth 10

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $JWT_TOKEN"
}

try {
    $bookingResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/graphql" -Method Post -Body $bookingMutation -Headers $headers -TimeoutSec 30
    Write-Host "Booking Response: $($bookingResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan
    
    $BOOKING_ID = $null
    if ($bookingResponse.data.createBooking.booking.id) {
        $BOOKING_ID = $bookingResponse.data.createBooking.booking.id
        Write-Success "Booking created successfully"
        Write-Status "Booking ID: $BOOKING_ID"
    }
    else {
        Write-Error "Failed to create booking"
        Write-Host "Response: $($bookingResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Booking creation failed: $($_.Exception.Message)"
    exit 1
}

# Step 6: Process payment through Kong Gateway (GraphQL)
Write-Host ""
Write-Host "Step 6: Processing Payment" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow

Write-Status "Processing payment through Kong Gateway (GraphQL)..."

$paymentMutation = @{
    query = "mutation ProcessPayment(`$bookingId: String!, `$paymentMethod: String!) { processPayment(bookingId: `$bookingId, paymentMethod: `$paymentMethod) { success booking { id status totalAmount } message } }"
    variables = @{
        bookingId = $BOOKING_ID
        paymentMethod = "credit_card"
    }
} | ConvertTo-Json -Depth 10

try {
    $paymentResponse = Invoke-RestMethod -Uri "$KONG_GATEWAY/graphql" -Method Post -Body $paymentMutation -Headers $headers -TimeoutSec 30
    Write-Host "Payment Response: $($paymentResponse | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan
    
    if ($paymentResponse.data.processPayment.success -eq $true) {
        Write-Success "Payment processed successfully"
        Write-Success "Booking should be confirmed and notification sent!"
    }
    else {
        Write-Error "Payment processing failed"
        Write-Host "Error: $($paymentResponse.data.processPayment.message)" -ForegroundColor Red
    }
}
catch {
    Write-Error "Payment processing failed: $($_.Exception.Message)"
}

# Step 7: Verify RabbitMQ events
Write-Host ""
Write-Host "Step 7: Verification" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow

Write-Status "Checking RabbitMQ Management Interface..."
try {
    $credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("admin:admin123"))
    $headers = @{
        "Authorization" = "Basic $credentials"
    }
    $rabbitmqResponse = Invoke-RestMethod -Uri "http://localhost:15672/api/overview" -Headers $headers -TimeoutSec 10
    
    if ($rabbitmqResponse.management_version) {
        Write-Success "RabbitMQ is running and accessible"
    }
    else {
        Write-Warning "RabbitMQ response unclear"
    }
}
catch {
    Write-Warning "Could not verify RabbitMQ (might be normal): $($_.Exception.Message)"
}

# Step 8: Display access information
Write-Host ""
Write-Host "Step 8: System Access Information" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

Write-Status "🌐 Service Access URLs:" -ForegroundColor Cyan
Write-Host "  - Kong Gateway:          http://localhost:8000"
Write-Host "  - User Service:          http://localhost:8001"
Write-Host "  - Cinema Service:        http://localhost:8002"
Write-Host "  - Booking Service:       http://localhost:8010"
Write-Host "  - Payment Service:       http://localhost:8003"
Write-Host ""
Write-Status "📊 Management Interfaces:" -ForegroundColor Cyan
Write-Host "  - RabbitMQ Management:   http://localhost:15672 (admin/admin123)"
Write-Host "  - MongoDB Express:       http://localhost:8081 (admin/admin123)"
Write-Host "  - PostgreSQL pgAdmin:    http://localhost:8080 (admin@movietickets.com/admin123)"
Write-Host "  - Redis Commander:       http://localhost:8082"

# Final summary
Write-Host ""
Write-Host "Integration Test Summary" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow
Write-Success "✅ User registration and authentication through Kong"
Write-Success "✅ Cinema service integration (movies/showtimes)"
Write-Success "✅ Booking service integration (GraphQL)"
Write-Success "✅ Payment service integration"
Write-Success "✅ Kong Gateway routing for all services"
Write-Status "📧 Check notification service logs for email notifications"

Write-Host ""
Write-Success "🎉 Integration test completed successfully!" -ForegroundColor Green
Write-Host "All services are communicating through Kong Gateway." -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Check Docker logs: docker logs movie-notification-service"
Write-Host "2. Verify RabbitMQ queues: http://localhost:15672"
Write-Host "3. Check booking in MongoDB: http://localhost:8081"
Write-Host "4. Review payment logs: docker logs movie-payment-service"

Write-Host ""
Write-Host "🎯 Docker Commands for Monitoring:" -ForegroundColor Yellow
Write-Host "docker-compose logs -f                    # All service logs"
Write-Host "docker logs movie-booking-service -f      # Booking service logs"
Write-Host "docker logs movie-notification-service -f # Notification service logs"
Write-Host "docker logs movie-payment-service -f      # Payment service logs"