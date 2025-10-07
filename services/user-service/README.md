# Movie Ticket User Service

A Go-based microservice for user management in the movie ticket booking system. This service handles user authentication, registration, and profile management.

## Features

- User registration and authentication
- JWT-based authentication
- Password hashing with bcrypt
- MongoDB integration
- RESTful API endpoints
- Input validation
- CORS support
- Structured logging

## Technologies Used

- **Go 1.21+**
- **Gin** - HTTP web framework
- **MongoDB** - Database
- **JWT** - Authentication tokens
- **bcrypt** - Password hashing
- **Docker** - Containerization

## Project Structure

```
user-service/
├── handlers/          # HTTP request handlers
│   └── user_handler.go
├── middleware/        # HTTP middleware
│   ├── auth.go       # JWT authentication middleware
│   ├── cors.go       # CORS middleware
│   └── logger.go     # Logging middleware
├── models/           # Data models and DTOs
│   └── user.go
├── repository/       # Data access layer
│   └── user_repository.go
├── services/         # Business logic layer
│   └── user_service.go
├── .env             # Environment variables
├── go.mod           # Go module file
├── go.sum           # Go module checksum
├── main.go          # Application entry point
├── Dockerfile       # Docker configuration
└── README.md        # This file
```

## Dependencies

- `github.com/gin-gonic/gin` - HTTP web framework
- `github.com/golang-jwt/jwt/v5` - JWT implementation
- `go.mongodb.org/mongo-driver` - MongoDB driver
- `golang.org/x/crypto` - Cryptography package (bcrypt)
- `github.com/joho/godotenv` - Environment variable loader
- `github.com/go-playground/validator/v10` - Input validation

## API Endpoints

### Public Endpoints

- `POST /api/v1/register` - Register a new user
- `POST /api/v1/login` - Login user and get JWT token
- `GET /health` - Health check endpoint

### Protected Endpoints (Require JWT Token)

- `GET /api/v1/users/:id` - Get user by ID
- `PUT /api/v1/users/:id` - Update user by ID
- `GET /api/v1/profile` - Get current user profile
- `PUT /api/v1/profile` - Update current user profile

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Server Configuration
PORT=8001

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Environment
ENVIRONMENT=development
```

## Installation and Setup

### Prerequisites

- Go 1.21 or higher
- MongoDB
- Git

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd movie-ticket-booking-system/services/user-service
   ```

2. **Install dependencies:**
   ```bash
   go mod tidy
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run MongoDB:**
   ```bash
   # Using Docker
   docker run -d -p 27017:27017 --name mongodb mongo:latest
   
   # Or use existing MongoDB installation
   ```

5. **Run the service:**
   ```bash
   go run main.go
   ```

   The service will start on `http://localhost:8001`

## Docker Usage

### Build Docker Image

```bash
docker build -t movie-ticket-user-service .
```

### Run with Docker

```bash
docker run -p 8001:8001 \
  -e MONGODB_URI=mongodb://host.docker.internal:27017 \
  -e JWT_SECRET=your-secret-key \
  movie-ticket-user-service
```

### Run with Docker Compose

```bash
docker-compose up -d
```

## API Usage Examples

### Register a new user

```bash
curl -X POST http://localhost:8001/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Login

```bash
curl -X POST http://localhost:8001/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Get user profile (requires JWT token)

```bash
curl -X GET http://localhost:8001/api/v1/profile \
  -H "Authorization: Bearer <your-jwt-token>"
```

## Development

### Running Tests

```bash
go test ./...
```

### Code Formatting

```bash
go fmt ./...
```

### Code Linting

```bash
golangci-lint run
```

## Security Features

- Password hashing using bcrypt
- JWT token-based authentication
- Input validation and sanitization
- CORS protection
- Secure headers

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please contact [your-email@example.com]

## Changelog

### v1.0.0
- Initial release
- User registration and authentication
- JWT token management
- Basic CRUD operations
- MongoDB integration