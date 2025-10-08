# Cinema Service API Documentation

## Overview
The Cinema Service is a Spring Boot microservice that manages cinemas, movies, screens, showtimes, and seat reservations. It provides both REST and gRPC APIs for seamless integration with other microservices in the movie ticket booking system.

## Service Information
- **Base URL**: `http://localhost:8002`
- **gRPC Port**: `9090`
- **Database**: PostgreSQL
- **Framework**: Spring Boot 3.2.0
- **Java Version**: 17

## Health Check

### Get Service Health
```http
GET /actuator/health
```

**Response:**
```json
{
  "status": "UP"
}
```

## Cinema Management

### Get All Cinemas
```http
GET /api/v1/cinemas
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Multiplex Downtown",
    "location": "123 Main Street, Downtown",
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

### Get Cinema by ID
```http
GET /api/v1/cinemas/{id}
```

**Parameters:**
- `id` (path) - Cinema ID

**Response:**
```json
{
  "id": 1,
  "name": "Multiplex Downtown",
  "location": "123 Main Street, Downtown",
  "createdAt": "2024-01-01T10:00:00",
  "updatedAt": "2024-01-01T10:00:00"
}
```

### Create Cinema
```http
POST /api/v1/cinemas
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "New Cinema",
  "location": "456 New Street, Uptown"
}
```

### Update Cinema
```http
PUT /api/v1/cinemas/{id}
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "Updated Cinema Name",
  "location": "Updated Location"
}
```

### Delete Cinema
```http
DELETE /api/v1/cinemas/{id}
```

## Movie Management

### Get All Movies
```http
GET /api/v1/movies
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "The Great Adventure",
    "description": "An epic adventure movie",
    "duration": 150,
    "genre": "Adventure",
    "rating": "PG-13",
    "language": "English",
    "releaseDate": "2024-01-15",
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

### Get Movie by ID
```http
GET /api/v1/movies/{id}
```

### Search Movies
```http
GET /api/v1/movies/search?title={searchTerm}
```

**Parameters:**
- `title` (query) - Search term for movie title

### Create Movie
```http
POST /api/v1/movies
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "New Movie",
  "description": "Movie description",
  "duration": 120,
  "genre": "Drama",
  "rating": "PG",
  "language": "English",
  "releaseDate": "2024-06-15"
}
```

### Update Movie
```http
PUT /api/v1/movies/{id}
Content-Type: application/json
```

### Delete Movie
```http
DELETE /api/v1/movies/{id}
```

## Screen Management

### Get Screens by Cinema
```http
GET /api/v1/cinemas/{cinemaId}/screens
```

**Parameters:**
- `cinemaId` (path) - Cinema ID

**Response:**
```json
[
  {
    "id": 1,
    "name": "Screen 1",
    "capacity": 150,
    "cinemaId": 1,
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

## Showtime Management

### Get All Showtimes
```http
GET /api/v1/showtimes
```

**Response:**
```json
[
  {
    "id": 1,
    "movieId": 1,
    "screenId": 1,
    "showDate": "2024-01-20",
    "showTime": "18:00:00",
    "price": 12.50,
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

### Get Showtimes by Movie
```http
GET /api/v1/movies/{movieId}/showtimes
```

### Get Showtimes by Screen
```http
GET /api/v1/screens/{screenId}/showtimes
```

### Get Showtimes by Date
```http
GET /api/v1/showtimes/date/{date}
```

**Parameters:**
- `date` (path) - Date in YYYY-MM-DD format

### Create Showtime
```http
POST /api/v1/showtimes
Content-Type: application/json
```

**Request Body:**
```json
{
  "movieId": 1,
  "screenId": 1,
  "showDate": "2024-01-25",
  "showTime": "20:00:00",
  "price": 15.00
}
```

### Update Showtime
```http
PUT /api/v1/showtimes/{id}
Content-Type: application/json
```

### Delete Showtime
```http
DELETE /api/v1/showtimes/{id}
```

## Seat Management

### Get Seats for Showtime
```http
GET /api/v1/showtimes/{showtimeId}/seats
```

**Response:**
```json
[
  {
    "id": 1,
    "seatNumber": "A01",
    "row": "A",
    "column": 1,
    "seatType": "REGULAR",
    "status": "AVAILABLE",
    "screenId": 1,
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

### Get Available Seats
```http
GET /api/v1/showtimes/{showtimeId}/seats/available
```

**Response:**
```json
[
  {
    "id": 1,
    "seatNumber": "A01",
    "row": "A",
    "column": 1,
    "seatType": "REGULAR",
    "status": "AVAILABLE",
    "screenId": 1
  }
]
```

### Lock Seats
```http
POST /api/v1/showtimes/{showtimeId}/seats/lock
Content-Type: application/json
```

**Request Body:**
```json
{
  "seatIds": [1, 2, 3],
  "userId": "user123"
}
```

**Response:**
```json
{
  "success": true,
  "lockedSeats": [
    {
      "id": 1,
      "seatId": 1,
      "showtimeId": 1,
      "userId": "user123",
      "lockedAt": "2024-01-20T15:30:00",
      "expiresAt": "2024-01-20T15:45:00"
    }
  ]
}
```

### Release Seats
```http
POST /api/v1/showtimes/{showtimeId}/seats/release
Content-Type: application/json
```

**Request Body:**
```json
{
  "seatIds": [1, 2, 3],
  "userId": "user123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Seats released successfully"
}
```

### Get Locked Seats
```http
GET /api/v1/showtimes/{showtimeId}/seats/locked?userId={userId}
```

**Parameters:**
- `userId` (query) - User ID to filter locked seats

## gRPC Service

The Cinema Service also provides a gRPC interface with the following methods:

### Service Definition
```protobuf
service CinemaService {
  rpc GetCinemas(Empty) returns (CinemaList);
  rpc GetCinema(CinemaRequest) returns (Cinema);
  rpc GetMovies(Empty) returns (MovieList);
  rpc GetMovie(MovieRequest) returns (Movie);
  rpc GetScreens(CinemaRequest) returns (ScreenList);
  rpc GetShowtimes(Empty) returns (ShowtimeList);
  rpc GetSeats(ShowtimeRequest) returns (SeatList);
  rpc LockSeats(LockSeatsRequest) returns (LockSeatsResponse);
  rpc ReleaseSeatLocks(ReleaseSeatLocksRequest) returns (ReleaseSeatLocksResponse);
}
```

### gRPC Server
- **Host**: `localhost`
- **Port**: `9090`

## Error Responses

### 404 Not Found
```json
{
  "timestamp": "2024-01-20T15:30:00.000+00:00",
  "status": 404,
  "error": "Not Found",
  "path": "/api/v1/cinemas/999"
}
```

### 400 Bad Request
```json
{
  "timestamp": "2024-01-20T15:30:00.000+00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/v1/movies"
}
```

### 500 Internal Server Error
```json
{
  "timestamp": "2024-01-20T15:30:00.000+00:00",
  "status": 500,
  "error": "Internal Server Error",
  "message": "An unexpected error occurred",
  "path": "/api/v1/cinemas"
}
```

## Data Models

### Cinema
```json
{
  "id": "Long",
  "name": "String",
  "location": "String",
  "createdAt": "LocalDateTime",
  "updatedAt": "LocalDateTime"
}
```

### Movie
```json
{
  "id": "Long",
  "title": "String",
  "description": "String",
  "duration": "Integer (minutes)",
  "genre": "String",
  "rating": "String",
  "language": "String",
  "releaseDate": "LocalDate",
  "createdAt": "LocalDateTime",
  "updatedAt": "LocalDateTime"
}
```

### Screen
```json
{
  "id": "Long",
  "name": "String",
  "capacity": "Integer",
  "cinemaId": "Long",
  "createdAt": "LocalDateTime",
  "updatedAt": "LocalDateTime"
}
```

### Showtime
```json
{
  "id": "Long",
  "movieId": "Long",
  "screenId": "Long",
  "showDate": "LocalDate",
  "showTime": "LocalTime",
  "price": "BigDecimal",
  "createdAt": "LocalDateTime",
  "updatedAt": "LocalDateTime"
}
```

### Seat
```json
{
  "id": "Long",
  "seatNumber": "String",
  "row": "String",
  "column": "Integer",
  "seatType": "SeatType (REGULAR, PREMIUM, VIP)",
  "status": "SeatStatus (AVAILABLE, BOOKED, MAINTENANCE)",
  "screenId": "Long",
  "createdAt": "LocalDateTime",
  "updatedAt": "LocalDateTime"
}
```

### SeatLock
```json
{
  "id": "Long",
  "seatId": "Long",
  "showtimeId": "Long",
  "userId": "String",
  "lockedAt": "LocalDateTime",
  "expiresAt": "LocalDateTime"
}
```

## Testing

### Run Validation Tests
```bash
./validate_service.sh
```

This script runs comprehensive tests covering all API endpoints including:
- Health checks
- CRUD operations for all entities
- Seat locking and releasing
- Search functionality
- Error handling

### Test Coverage
- **15 test cases** covering all major functionality
- **Unit tests** available in `src/test/java`
- **Integration tests** with database operations
- **gRPC tests** for service communication

## Configuration

### Application Properties
- **Server Port**: 8002
- **gRPC Port**: 9090
- **Database**: PostgreSQL on localhost:5432
- **Database Name**: cinema_db

### Environment Variables
- `SPRING_DATASOURCE_URL`: Database connection URL
- `SPRING_DATASOURCE_USERNAME`: Database username
- `SPRING_DATASOURCE_PASSWORD`: Database password

## Dependencies

### Key Dependencies
- Spring Boot 3.2.0
- Spring Data JPA
- PostgreSQL Driver
- gRPC Spring Boot Starter
- Protocol Buffers
- Jackson for JSON processing

## Development

### Build and Run
```bash
# Build the project
mvn clean compile

# Run the service
mvn spring-boot:run

# Run tests
mvn test
```

### Database Setup
```bash
# Create database and tables
docker exec -it movie-postgres psql -U postgres -d cinema_db -f /docker-entrypoint-initdb.d/schema.sql

# Insert sample data
docker exec -it movie-postgres psql -U postgres -d cinema_db -f /docker-entrypoint-initdb.d/sample_data.sql
```

## API Rate Limiting
Currently, no rate limiting is implemented. For production deployment, consider implementing:
- Request rate limiting per IP/user
- Circuit breaker patterns
- Caching for frequently accessed data

## Security Considerations
- Input validation on all endpoints
- SQL injection prevention through JPA
- Proper error handling without sensitive data exposure
- CORS configuration for web clients

## Monitoring and Observability
- Health check endpoint for service monitoring
- Logging with configurable levels
- Database connection monitoring
- gRPC service metrics