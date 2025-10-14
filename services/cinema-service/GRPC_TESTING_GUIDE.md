# gRPC Testing Guide for Cinema Service

This directory contains comprehensive testing scripts for all gRPC endpoints in the Cinema Service.

## Available Test Scripts

### 1. `test_grpc_endpoints_final.sh` (Recommended for Linux/Mac)
- **Purpose**: Comprehensive bash script for testing all gRPC endpoints
- **Requirements**: grpcurl installed
- **Features**: 
  - Automatic grpcurl installation instructions
  - 11 different test scenarios
  - Complete booking workflow testing
  - Error handling verification
  - Colored output and detailed reporting

### 2. `test_grpc_windows.bat` (Recommended for Windows)
- **Purpose**: Windows batch script with automatic grpcurl installation
- **Requirements**: Windows command prompt
- **Features**:
  - Automatic grpcurl download and installation
  - Fallback installation methods (Go, Chocolatey)
  - Step-by-step test execution
  - Manual command examples

### 3. `test_grpc_python.py` (Cross-platform alternative)
- **Purpose**: Python-based testing using grpcio library
- **Requirements**: `pip install grpcio grpcio-tools`
- **Features**:
  - No grpcurl dependency
  - Direct Python gRPC client
  - Comprehensive test coverage
  - Works on all platforms

## Quick Start

### Option 1: Linux/Mac Users
```bash
# Make script executable
chmod +x test_grpc_endpoints_final.sh

# Run tests
./test_grpc_endpoints_final.sh
```

### Option 2: Windows Users
```cmd
# Run the batch script
test_grpc_windows.bat
```

### Option 3: Python Users (Any platform)
```bash
# Install requirements
pip install grpcio grpcio-tools

# Generate protobuf files (if needed)
python -m grpc_tools.protoc --proto_path=./proto --python_out=. --grpc_python_out=. cinema.proto

# Run tests
python test_grpc_python.py
```

## Available gRPC Endpoints

The Cinema Service exposes the following gRPC methods:

### 1. CheckSeatAvailability
- **Purpose**: Check if specific seats are available for booking
- **Input**: showtime_id, seat_numbers[]
- **Output**: available (boolean), unavailable_seats[], message

**Example:**
```bash
grpcurl -plaintext -d '{"showtime_id": "showtime-001", "seat_numbers": ["A7", "A8"]}' localhost:9090 cinema.CinemaService/CheckSeatAvailability
```

### 2. LockSeats
- **Purpose**: Lock seats for a specific duration during booking process
- **Input**: showtime_id, seat_numbers[], booking_id, lock_duration_seconds
- **Output**: success (boolean), lock_id, message

**Example:**
```bash
grpcurl -plaintext -d '{"showtime_id": "showtime-001", "seat_numbers": ["B5", "B6"], "booking_id": "test-booking-123", "lock_duration_seconds": 300}' localhost:9090 cinema.CinemaService/LockSeats
```

### 3. ReleaseSeatLock
- **Purpose**: Release previously locked seats
- **Input**: lock_id, booking_id
- **Output**: success (boolean), message

**Example:**
```bash
grpcurl -plaintext -d '{"lock_id": "your-lock-id", "booking_id": "test-booking-123"}' localhost:9090 cinema.CinemaService/ReleaseSeatLock
```

### 4. ConfirmSeatBooking
- **Purpose**: Confirm and finalize seat booking
- **Input**: lock_id, booking_id, user_id
- **Output**: success (boolean), message

**Example:**
```bash
grpcurl -plaintext -d '{"lock_id": "your-lock-id", "booking_id": "test-booking-123", "user_id": "test-user"}' localhost:9090 cinema.CinemaService/ConfirmSeatBooking
```

### 5. GetShowtimeDetails
- **Purpose**: Get detailed information about a showtime
- **Input**: showtime_id
- **Output**: showtime (with movie, screen, and seat information)

**Example:**
```bash
grpcurl -plaintext -d '{"showtime_id": "showtime-001"}' localhost:9090 cinema.CinemaService/GetShowtimeDetails
```

## Installation Guides

### Installing grpcurl

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install grpcurl
```

#### macOS
```bash
brew install grpcurl
```

#### Windows
1. **Using Go** (if Go is installed):
   ```cmd
   go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
   ```

2. **Direct Download**:
   - Download from: https://github.com/fullstorydev/grpcurl/releases/latest
   - Extract and add to PATH

3. **Using Chocolatey**:
   ```cmd
   choco install grpcurl
   ```

### Installing Python gRPC Tools
```bash
pip install grpcio grpcio-tools
```

## Test Scenarios Covered

1. **Basic Functionality Tests**:
   - Seat availability checking
   - Seat locking
   - Lock release
   - Booking confirmation
   - Showtime details retrieval

2. **Error Handling Tests**:
   - Invalid showtime IDs
   - Non-existent locks
   - Empty seat numbers
   - Duplicate bookings

3. **Workflow Tests**:
   - Complete booking flow (check → lock → confirm)
   - Seat availability verification after locking
   - Lock expiration handling

4. **Concurrent Testing**:
   - Multiple simultaneous lock requests
   - Race condition handling

## Troubleshooting

### Common Issues

1. **Connection Refused**:
   ```bash
   # Check if service is running
   docker-compose logs cinema-service
   docker-compose restart cinema-service
   ```

2. **Port Not Accessible**:
   ```bash
   # Test port connectivity
   curl telnet://localhost:9090
   ```

3. **gRPC Method Not Found**:
   ```bash
   # List available services
   grpcurl -plaintext localhost:9090 list
   
   # List methods for specific service
   grpcurl -plaintext localhost:9090 list cinema.CinemaService
   ```

4. **Protobuf Generation Issues**:
   ```bash
   # Regenerate protobuf files
   python -m grpc_tools.protoc --proto_path=./proto --python_out=. --grpc_python_out=. cinema.proto
   ```

### Service Status Check
```bash
# Check if cinema service is running
docker-compose ps cinema-service

# View service logs
docker-compose logs -f cinema-service

# Restart service if needed
docker-compose restart cinema-service
```

## Expected Test Results

When all tests pass, you should see:
- ✅ All gRPC endpoints responding correctly
- ✅ Proper error handling for invalid inputs
- ✅ Successful seat locking and release workflow
- ✅ Booking confirmation working
- ✅ Showtime details retrieval functional

## Manual Testing Commands

For manual testing and experimentation:

```bash
# Check server health
grpcurl -plaintext localhost:9090 list

# Test with your own data
grpcurl -plaintext -d '{"showtime_id": "YOUR_SHOWTIME", "seat_numbers": ["YOUR_SEATS"]}' localhost:9090 cinema.CinemaService/CheckSeatAvailability
```

## Integration with Other Services

The gRPC endpoints are designed to work with:
- **Booking Service**: For seat reservation workflows
- **Payment Service**: For booking confirmation events
- **User Service**: For user authentication in bookings
- **Notification Service**: For booking confirmations

## Performance Testing

For load testing the gRPC endpoints:
```bash
# Use ghz for gRPC load testing
go install github.com/bojand/ghz/cmd/ghz@latest

# Example load test
ghz --insecure --proto ./proto/cinema.proto --call cinema.CinemaService.CheckSeatAvailability -d '{"showtime_id": "showtime-001", "seat_numbers": ["A1"]}' -c 10 -n 100 localhost:9090
```

---

For more information about the Cinema Service implementation, see the main project documentation.