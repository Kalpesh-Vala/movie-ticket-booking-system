# 🚀 **Complete Postman API Testing Guide - Kong Gateway**

## 📋 **Overview**

This comprehensive guide covers testing all microservice APIs through Kong Gateway using Postman. All requests are routed through Kong Gateway at `http://localhost:8000` for unified access control, rate limiting, and CORS handling.

## 🌐 **Kong Gateway Configuration**

- **Kong Proxy URL**: `http://localhost:8000`
- **Kong Admin URL**: `http://localhost:8001`
- **Configuration Mode**: DB-less (Declarative)
- **Rate Limit**: 1000 requests/minute
- **CORS**: Enabled for all origins
- **Global Plugins**: CORS, Rate Limiting
- **Health Check Routes**: Service-specific (`/health/{service}`)

### **Health Check Endpoints**
| Service | Health Check URL | Maps to |
|---------|------------------|---------|
| User Service | `GET /health/user` | `/actuator/health` |
| Cinema Service | `GET /health/cinema` | `/actuator/health` |
| Booking Service | `GET /health/booking` | `/actuator/health` |
| Payment Service | `GET /health/payment` | `/actuator/health` |
| Notification Service | `GET /health/notification` | `/actuator/health` |

---

## 📚 **Service Architecture**

| Service | Direct URL | Kong Route | Technology | Database |
|---------|------------|------------|------------|----------|
| User Service | localhost:8080 | `/api/users/*`, `/health/user` | Go + Gin | MongoDB |
| Cinema Service | localhost:8002 | `/api/v1/cinemas/*`, `/api/v1/movies/*`, `/api/v1/screens/*`, `/api/v1/showtimes/*`, `/health/cinema` | Java + Spring Boot | PostgreSQL |
| Booking Service | localhost:8004 | `/api/bookings/*`, `/graphql`, `/health/booking` | Python + FastAPI + GraphQL | MongoDB |
| Payment Service | localhost:8003 | `/api/payments/*`, `/health/payment` | Python + FastAPI | MongoDB |
| Notification Service | localhost:8084 | `/api/notifications/*`, `/health/notification` | Python Worker | MongoDB + Redis |

---

## 🔧 **Postman Environment Setup**

### **Environment Variables**
Create a new environment in Postman with these variables:

```json
{
  "kong_url": "http://localhost:8000",
  "user_token": "",
  "user_id": "",
  "booking_id": "",
  "transaction_id": "",
  "cinema_id": "",
  "movie_id": "",
  "showtime_id": ""
}
```

### **Pre-request Scripts (Global)**
Add this to your collection's pre-request script for automatic token management:

```javascript
// Auto-set authorization header if token exists
if (pm.environment.get("user_token")) {
    pm.request.headers.add({
        key: "Authorization",
        value: "Bearer " + pm.environment.get("user_token")
    });
}
```

---

# 👤 **1. User Service API Testing**

## **Base URL**: `{{kong_url}}/api/users`

### **1.1 Health Check**
```http
GET {{kong_url}}/health/user
```

**Expected Response:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

### **1.2 User Registration**
```http
POST {{kong_url}}/api/v1/register
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Expected Response:**
```json
{
  "message": "User created successfully"
}
```

### **1.3 User Login**
```http
POST {{kong_url}}/api/v1/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Post-response Script:**
```javascript
// Save token for future requests
if (pm.response.json().token) {
    pm.environment.set("user_token", pm.response.json().token);
    pm.environment.set("user_id", pm.response.json().user.id);
}
```

### **1.4 Get Current User Profile** 🔒
```http
GET {{kong_url}}/api/v1/profile
Authorization: Bearer {{user_token}}
```

### **1.5 Update Profile** 🔒
```http
PUT {{kong_url}}/api/v1/profile
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "first_name": "John Updated",
  "last_name": "Doe Updated"
}
```

### **1.6 Get User by ID** 🔒
```http
GET {{kong_url}}/api/v1/users/{{user_id}}
Authorization: Bearer {{user_token}}
```

### **1.7 Update User by ID** 🔒
```http
PUT {{kong_url}}/api/v1/users/{{user_id}}
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "first_name": "Updated Name",
  "last_name": "Updated Last"
}
```

### **❌ Note: Missing Endpoints**
```
The following endpoints are documented but NOT IMPLEMENTED in the current User Service:
- POST /api/v1/change-password
- GET /api/v1/users (list all users)  
- GET /api/v1/users/search
- GET /api/v1/users/stats
- DELETE /api/v1/users/{id}

Remove these from your Postman collection as they will return 404 errors.
```

---

# 🎬 **2. Cinema Service API Testing**

## **Base URL**: `{{kong_url}}/api/v1/cinemas`, `{{kong_url}}/api/v1/movies`, `{{kong_url}}/api/v1/screens`, `{{kong_url}}/api/v1/showtimes`

### **2.1 Health Check**
```http
GET {{kong_url}}/health/cinema
```

**Expected Response:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

### **2.2 Get All Cinemas**
```http
GET {{kong_url}}/api/v1/cinemas
```

**Query Parameters:**
- `size` (optional) - Limit number of results (e.g., `?size=2`)
- `page` (optional) - Page number for pagination

**Expected Response:**
```json
[
  {
    "id": "cinema-001",
    "name": "Grand Cinema",
    "location": "123 Main Street, Downtown",
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

**Post-response Script:**
```javascript
// Save first cinema ID for future requests
if (pm.response.json().length > 0) {
    pm.environment.set("cinema_id", pm.response.json()[0].id);
}
```

### **2.3 Create Cinema**
```http
POST {{kong_url}}/api/v1/cinemas
Content-Type: application/json

{
  "name": "Multiplex Cinema",
  "location": "456 Oak Avenue, Uptown",
  "totalScreens": 5
}
```

**Response:**
```json
{
  "id": "f40f83c1-5127-4b50-a8b9-df2d578b6cec",
  "name": "Multiplex Cinema",
  "location": "456 Oak Avenue, Uptown",
  "totalScreens": 5,
  "createdAt": "2024-01-20T15:30:00",
  "updatedAt": "2024-01-20T15:30:00"
}
```

### **2.4 Get Cinema by ID**
```http
GET {{kong_url}}/api/v1/cinemas/{{cinema_id}}
```

### **2.5 Update Cinema**
```http
PUT {{kong_url}}/api/v1/cinemas/{{cinema_id}}
Content-Type: application/json

{
  "name": "Updated Cinema Name",
  "location": "Updated Location"
}
```

### **2.6 Get All Movies**
```http
GET {{kong_url}}/api/v1/movies
```

**Post-response Script:**
```javascript
// Save first movie ID
if (pm.response.json().length > 0) {
    pm.environment.set("movie_id", pm.response.json()[0].id);
}
```

### **2.7 Create Movie**
```http
POST {{kong_url}}/api/v1/movies
Content-Type: application/json

{
  "title": "Avengers: Endgame",
  "genre": "Action",
  "durationMinutes": 181,
  "rating": "PG-13",
  "description": "Epic superhero movie for testing"
}
```

**Response:**
```json
{
  "id": "e72fef90-138c-4257-8c3d-3e2bdaa763f9",
  "title": "Avengers: Endgame",
  "genre": "Action",
  "durationMinutes": 181,
  "rating": "PG-13",
  "description": "Epic superhero movie for testing",
  "createdAt": "2024-01-20T15:30:00",
  "updatedAt": "2024-01-20T15:30:00"
}
```

### **2.8 Search Movies**
```http
GET {{kong_url}}/api/v1/movies/search?title=Avengers
```

**Expected Response:**
```json
[
  {
    "id": "movie-001",
    "title": "Avengers: Endgame",
    "description": "The culmination of 22 interconnected films",
    "duration": 181,
    "genre": "Action", 
    "rating": "PG-13",
    "language": "English",
    "releaseDate": "2024-04-26"
  }
]
```

### **2.9 Get Screen by ID**
```http
GET {{kong_url}}/api/v1/screens/screen-001
```

**Expected Response:**
```json
{
  "id": "screen-001",
  "name": "Screen 1",
  "capacity": 150,
  "screenType": "REGULAR",
  "cinemaId": "cinema-001",
  "createdAt": "2024-01-01T10:00:00",
  "updatedAt": "2024-01-01T10:00:00"
}
```

### **2.10 Get Screens by Cinema**
```http
GET {{kong_url}}/api/v1/cinemas/{{cinema_id}}/screens
```

### **2.11 Get Showtimes for Screen**
```http
GET {{kong_url}}/api/v1/screens/screen-001/showtimes
```

### **2.12 Get All Showtimes**
```http
GET {{kong_url}}/api/v1/showtimes
```

**Post-response Script:**
```javascript
// Save first showtime ID
if (pm.response.json().length > 0) {
    pm.environment.set("showtime_id", pm.response.json()[0].id);
}
```

### **2.13 Get Showtime by ID**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}
```

### **2.14 Search Showtimes by Movie and Date**
```http
GET {{kong_url}}/api/v1/showtimes/search?movieId={{movie_id}}&date=2025-01-15
```

**Expected Response:**
```json
[
  {
    "id": "showtime-001",
    "movieId": "movie-001",
    "screenId": "screen-001",
    "startTime": "2025-01-15T19:30:00",
    "endTime": "2025-01-15T22:00:00",
    "price": 12.50,
    "availableSeats": 85
  }
]
```

### **2.15 Create Showtime**
```http
POST {{kong_url}}/api/v1/showtimes
Content-Type: application/json

{
  "movieId": "{{movie_id}}",
  "screenId": "screen-001",
  "startTime": "2024-12-20T19:30:00",
  "endTime": "2024-12-20T22:31:00",
  "price": 15.99
}
```

**Response:**
```json
{
  "id": "2db57aa5-66fc-4cbd-b3a1-2381361701d9",
  "movie": {
    "id": "movie-001",
    "title": "The Matrix Resurrections",
    "genre": "Sci-Fi",
    "durationMinutes": 148,
    "rating": "R",
    "description": "Return to the world of The Matrix",
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  },
  "startTime": "2024-12-20T19:30:00",
  "endTime": "2024-12-20T22:31:00",
  "basePrice": 15.99,
  "totalSeats": 100,
  "availableSeats": 100,
  "createdAt": "2024-01-20T15:30:00",
  "updatedAt": "2024-01-20T15:30:00"
}
```

### **2.16 Get Seats for Showtime**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats
```

**Query Parameters:**
- `status` (optional) - Filter by seat status: AVAILABLE, LOCKED, BOOKED

### **2.17 Get Available Seats**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/available
```

### **2.18 Lock Seats**
```http
POST {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/lock?userId={{user_id}}
Content-Type: application/json

["A1", "A2"]
```

**Expected Response:**
```json
"Seats locked successfully. Lock ID: 95f4dfba-0717-4030-87c1-1fdd2f6be4a4"
```

### **2.19 Release Seats**
```http
POST {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/release
Content-Type: application/json

["A1", "A2"]
```

**Expected Response:**
```json
"Seats released successfully"
```

### **2.20 Get Locked Seats**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/locked?userId={{user_id}}
```

**Expected Response:**
```json
[
  {
    "id": "83f3a143-6a15-4477-a4c7-17acd8d8fa76",
    "lockId": "0e97dc28-b624-4b65-82ec-4082ebd86cf8",
    "seatId": "seat-showtime-001-A1",
    "bookingId": "test-user",
    "showtimeId": "{{showtime_id}}",
    "lockedAt": "2024-01-20T15:30:00",
    "expiresAt": "2024-01-20T15:45:00",
    "isActive": true
  }
]
```

### **✅ Cinema Service Implementation Status**

**✅ Fully Implemented and Tested Endpoints:**
- ✅ Health check via `/health/cinema`
- ✅ Complete cinema management (GET, POST, PUT)
- ✅ Complete movie management (GET, POST) with search
- ✅ Complete showtime management (GET, POST) with search
- ✅ Complete screen management (GET)
- ✅ Comprehensive seat management with locking/releasing
- ✅ All search operations (movies by title, showtimes by movie/date)
- ✅ Error handling for non-existent resources

**❌ Not Implemented:**
- ❌ UPDATE movie endpoints (PUT /api/v1/movies/{id})
- ❌ UPDATE showtime endpoints (PUT /api/v1/showtimes/{id})
- ❌ DELETE endpoints for any resources (cinemas, movies, showtimes)

**Important Notes:**
- All Cinema Service endpoints listed in this guide have been thoroughly tested and validated
- Seat locking uses array format `["A1", "A2"]` with `userId` as query parameter
- IDs are string format (e.g., `"cinema-001"`, `"movie-001"`)
- Search endpoints support partial matching
- Pagination available on cinema list with `size` and `page` parameters
- Status filtering available on seat endpoints with `status` parameter

### **✅ Cinema Service API Updates**

**Tested and Validated Endpoints:**
- ✅ Health check via `/actuator/health`
- ✅ Complete cinema management (CRUD)
- ✅ Complete movie management with search
- ✅ Screen management with showtime relationships
- ✅ Showtime management with date search
- ✅ Comprehensive seat management with locking
- ✅ All search operations
- ✅ Error handling for non-existent resources

---

# 🎫 **3. Booking Service API Testing**

## **Base URL**: `{{kong_url}}/api/bookings` and `{{kong_url}}/graphql`

### **3.1 Health Check**
```http
GET {{kong_url}}/health/booking
```

**Expected Response:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

### **3.2 GraphQL Schema Introspection**
```http
POST {{kong_url}}/graphql
Content-Type: application/json

{
  "query": "{ __schema { types { name } } }"
}
```

### **3.3 Create Booking (REST)**
```http
POST {{kong_url}}/api/bookings
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "user_id": "{{user_id}}",
  "movie_id": "{{movie_id}}",
  "showtime_id": "{{showtime_id}}",
  "seats": ["A1", "A2"],
  "total_amount": 30.00
}
```

**Post-response Script:**
```javascript
// Save booking ID
if (pm.response.json().booking_id) {
    pm.environment.set("booking_id", pm.response.json().booking_id);
}
```

### **3.4 Get All Bookings (REST)**
```http
GET {{kong_url}}/api/bookings
Authorization: Bearer {{user_token}}
```

### **3.5 Get Booking by ID (REST)**
```http
GET {{kong_url}}/api/bookings/{{booking_id}}
Authorization: Bearer {{user_token}}
```

### **3.6 Update Booking Status (REST)**
```http
PUT {{kong_url}}/api/bookings/{{booking_id}}/status
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "status": "confirmed"
}
```

### **3.7 Cancel Booking (REST)**
```http
DELETE {{kong_url}}/api/bookings/{{booking_id}}
Authorization: Bearer {{user_token}}
```

### **3.8 Create Booking (GraphQL)**
```http
POST {{kong_url}}/graphql
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "query": "mutation CreateBooking($input: CreateBookingInput!) { createBooking(input: $input) { id status user_id movie_id showtime_id seats total_amount created_at } }",
  "variables": {
    "input": {
      "user_id": "{{user_id}}",
      "movie_id": "{{movie_id}}",
      "showtime_id": "{{showtime_id}}",
      "seats": ["B1", "B2"],
      "total_amount": 30.00
    }
  }
}
```

### **3.9 Get Bookings (GraphQL)**
```http
POST {{kong_url}}/graphql
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "query": "query GetBookings { bookings { id status user_id movie_id showtime_id seats total_amount created_at updated_at } }"
}
```

### **3.10 Get Booking by ID (GraphQL)**
```http
POST {{kong_url}}/graphql
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "query": "query GetBooking($id: String!) { booking(id: $id) { id status user_id movie_id showtime_id seats total_amount created_at updated_at } }",
  "variables": {
    "id": "{{booking_id}}"
  }
}
```

### **3.11 Update Booking Status (GraphQL)**
```http
POST {{kong_url}}/graphql
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "query": "mutation UpdateBookingStatus($id: String!, $status: String!) { updateBookingStatus(id: $id, status: $status) { id status updated_at } }",
  "variables": {
    "id": "{{booking_id}}",
    "status": "confirmed"
  }
}
```

### **3.12 Cancel Booking (GraphQL)**
```http
POST {{kong_url}}/graphql
Authorization: Bearer {{user_token}}
Content-Type: application/json

{
  "query": "mutation CancelBooking($id: String!) { cancelBooking(id: $id) { id status cancelled_at } }",
  "variables": {
    "id": "{{booking_id}}"
  }
}
```

---

# 💳 **4. Payment Service API Testing**

## **Base URL**: `{{kong_url}}/api/payments`

### **4.1 Health Check**
```http
GET {{kong_url}}/health/payment
```

**Expected Response:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

### **4.2 Get Payment Methods**
```http
GET {{kong_url}}/api/payments/methods
```

### **4.3 Process Credit Card Payment**
```http
POST {{kong_url}}/api/payments/process
Content-Type: application/json

{
  "user_id": "{{user_id}}",
  "booking_id": "{{booking_id}}",
  "amount": 30.00,
  "payment_method": "credit_card",
  "card_details": {
    "card_number": "4111111111111111",
    "expiry_month": "12",
    "expiry_year": "2025",
    "cvv": "123",
    "cardholder_name": "John Doe"
  }
}
```

**Post-response Script:**
```javascript
// Save transaction ID
if (pm.response.json().transaction_id) {
    pm.environment.set("transaction_id", pm.response.json().transaction_id);
}
```

### **4.4 Process PayPal Payment**
```http
POST {{kong_url}}/api/payments/process
Content-Type: application/json

{
  "user_id": "{{user_id}}",
  "booking_id": "{{booking_id}}",
  "amount": 30.00,
  "payment_method": "paypal",
  "paypal_details": {
    "email": "john.doe@example.com",
    "payment_id": "PAYID-123456789"
  }
}
```

### **4.5 Get Payment Status**
```http
GET {{kong_url}}/api/payments/status/{{transaction_id}}
```

### **4.6 Process Refund**
```http
POST {{kong_url}}/api/payments/refund
Content-Type: application/json

{
  "booking_id": "{{booking_id}}",
  "original_transaction_id": "{{transaction_id}}",
  "refund_amount": 30.00,
  "reason": "Customer cancellation",
  "user_id": "{{user_id}}"
}
```

---

# 📧 **5. Notification Service API Testing**

## **Base URL**: `{{kong_url}}/api/notifications`

**Note**: The Notification Service primarily works as a background worker consuming RabbitMQ events. These endpoints may be limited or for testing purposes only.

### **5.1 Health Check**
```http
GET {{kong_url}}/health/notification
```

**Expected Response:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

### **5.2 Send Test Notification (if available)**
```http
POST {{kong_url}}/api/notifications/send
Content-Type: application/json

{
  "user_id": "{{user_id}}",
  "type": "booking_confirmation",
  "title": "Booking Confirmed",
  "message": "Your movie ticket booking has been confirmed.",
  "email": "john.doe@example.com"
}
```

### **5.3 Get Notification History (if available)**
```http
GET {{kong_url}}/api/notifications?user_id={{user_id}}
```

---

# 🧪 **Complete Testing Workflow**

## **Service Health Checks**

Start with health checks to verify all services are running:

### **System Health Verification**
1. **User Service Health** → `GET {{kong_url}}/health/user`
2. **Cinema Service Health** → `GET {{kong_url}}/health/cinema`
3. **Booking Service Health** → `GET {{kong_url}}/health/booking`
4. **Payment Service Health** → `GET {{kong_url}}/health/payment`
5. **Notification Service Health** → `GET {{kong_url}}/health/notification`

**Expected Response for all health checks:**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

## **End-to-End Booking Flow**

Follow this sequence to test the complete booking workflow:

### **Phase 1: User Setup**
6. **Register User** → `POST {{kong_url}}/api/v1/register`
7. **Login User** → `POST {{kong_url}}/api/v1/login` (save token)
8. **Get Profile** → `GET {{kong_url}}/api/v1/profile`

### **Phase 2: Browse Movies**
9. **Get Cinemas** → `GET {{kong_url}}/api/v1/cinemas`
10. **Get Cinema Details** → `GET {{kong_url}}/api/v1/cinemas/{id}`
11. **Get Screens** → `GET {{kong_url}}/api/v1/cinemas/{id}/screens`
12. **Get Movies** → `GET {{kong_url}}/api/v1/movies`
13. **Search Movies** → `GET {{kong_url}}/api/v1/movies/search?title=Avengers`
14. **Get Showtimes** → `GET {{kong_url}}/api/v1/showtimes`
15. **Search Showtimes** → `GET {{kong_url}}/api/v1/showtimes/search?movieId={id}&date=2025-01-15`

### **Phase 3: Book Tickets**
16. **Get Available Seats** → `GET {{kong_url}}/api/v1/showtimes/{id}/seats/available`
17. **Lock Seats** → `POST {{kong_url}}/api/v1/showtimes/{id}/seats/lock?userId={id}` (Body: `["A1", "A2"]`)
18. **Verify Locked Status** → `GET {{kong_url}}/api/v1/showtimes/{id}/seats/locked?userId={id}`
19. **Create Booking** → `POST {{kong_url}}/api/bookings` or GraphQL mutation
20. **Get Booking Details** → `GET {{kong_url}}/api/bookings/{id}`

### **Phase 4: Process Payment**
21. **Get Payment Methods** → `GET {{kong_url}}/api/payments/methods`
22. **Process Payment** → `POST {{kong_url}}/api/payments/process`
23. **Check Payment Status** → `GET {{kong_url}}/api/payments/status/{id}`
24. **Update Booking Status** → `PUT {{kong_url}}/api/bookings/{id}/status`

### **Phase 5: Clean Up (Optional)**
25. **Release Seats** → `POST {{kong_url}}/api/v1/showtimes/{id}/seats/release` (Body: `["A1", "A2"]`)
26. **Cancel Booking** → `DELETE {{kong_url}}/api/bookings/{id}`

### **Phase 6: Notifications (Automatic)**
27. Check notification logs in MongoDB or RabbitMQ management console

---

# 🚨 **Error Testing Scenarios**

## **Authentication Errors**
```http
# Test without token
GET {{kong_url}}/api/users/profile

# Test with invalid token
GET {{kong_url}}/api/users/profile
Authorization: Bearer invalid_token_here
```

## **Validation Errors**
```http
# Invalid email format
POST {{kong_url}}/api/users
{
  "email": "invalid-email",
  "password": "short"
}

# Insufficient payment amount
POST {{kong_url}}/api/payments/process
{
  "amount": -10.00
}
```

## **Rate Limiting Test**
```javascript
// Run this in Postman Tests tab to test rate limiting
for (let i = 0; i < 1100; i++) {
    pm.sendRequest({
        url: pm.environment.get("kong_url") + "/api/users/health",
        method: "GET"
    });
}
```

---

# 📊 **Monitoring and Debugging**

## **Kong Admin API Endpoints**
```http
# Check Kong services
GET http://localhost:8001/services

# Check Kong routes
GET http://localhost:8001/routes

# Check Kong plugins
GET http://localhost:8001/plugins

# Monitor Kong metrics
GET http://localhost:8001/status
```

## **Health Check All Services**
```http
GET {{kong_url}}/health
GET {{kong_url}}/actuator/health
GET {{kong_url}}/api/bookings/health
GET {{kong_url}}/api/payments/health
```

---

# 🔍 **Postman Collection Structure**

## **Recommended Folder Organization**

```
📁 Movie Ticket Booking System
├── 📁 0. System Health Checks
│   ├── User Service Health
│   ├── Cinema Service Health
│   ├── Booking Service Health
│   ├── Payment Service Health
│   ├── Notification Service Health
│   └── Kong Gateway Status
├── 📁 1. User Management
│   ├── User Service Health
│   ├── Register User
│   ├── Login User
│   ├── Get Profile
│   ├── Update Profile
│   └── Change Password
├── 📁 2. Cinema & Movies
│   ├── Cinema Service Health
│   ├── Get Cinemas
│   ├── Create Cinema
│   ├── Update Cinema
│   ├── Delete Cinema
│   ├── Get Movies
│   ├── Search Movies
│   ├── Create Movie
│   ├── Update Movie
│   ├── Delete Movie
│   ├── Get Screens
│   ├── Create Screen
│   ├── Update Screen
│   ├── Delete Screen
│   ├── Get Showtimes
│   ├── Get Showtime by ID
│   ├── Create Showtime
│   ├── Update Showtime
│   ├── Delete Showtime
│   ├── Get Available Seats
│   ├── Lock Seats
│   └── Release Seats
├── 📁 3. Booking Management
│   ├── Booking Service Health
│   ├── 📁 REST API
│   │   ├── Create Booking
│   │   ├── Get Bookings
│   │   ├── Update Booking
│   │   └── Cancel Booking
│   └── 📁 GraphQL API
│       ├── Create Booking (GraphQL)
│       ├── Get Bookings (GraphQL)
│       ├── Update Booking (GraphQL)
│       └── Cancel Booking (GraphQL)
├── 📁 4. Payment Processing
│   ├── Payment Service Health
│   ├── Get Payment Methods
│   ├── Process Credit Card Payment
│   ├── Process PayPal Payment
│   ├── Get Payment Status
│   └── Process Refund
├── 📁 5. Notifications
│   ├── Notification Service Health
│   ├── Send Test Notification
│   └── Get Notification History
└── 📁 6. Error Testing
    ├── Authentication Errors
    ├── Validation Errors
    └── Rate Limiting Tests
```

---

# 🎯 **Testing Best Practices**

## **1. Environment Management**
- Use different environments for development, staging, and production
- Never hardcode sensitive data in requests
- Use environment variables for all dynamic values

## **2. Authentication Testing**
- Test with valid tokens, invalid tokens, and no tokens
- Verify token expiry handling
- Test different user roles and permissions

## **3. Data Validation**
- Test with valid data, invalid data, and edge cases
- Verify error messages are clear and helpful
- Test field validation rules

## **4. Performance Testing**
- Test rate limiting behavior
- Monitor response times
- Test with large datasets

## **5. Error Handling**
- Test all error scenarios
- Verify proper HTTP status codes
- Check error response formats

---

# 📝 **Collection Export Instructions**

1. **Create New Collection**: "Movie Ticket Booking System API Tests"
2. **Set Collection Variables**: Add the environment variables listed above
3. **Import Requests**: Copy each request from this guide
4. **Add Tests**: Include the post-response scripts for variable management
5. **Export Collection**: Share with team members

## **Sample Postman Test Script**
Add this to collection or individual requests:

```javascript
// Test for successful response
pm.test("Status code is success", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 201, 202]);
});

// Test response time
pm.test("Response time is less than 2000ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(2000);
});

// Test content type
pm.test("Content-Type is JSON", function () {
    pm.expect(pm.response.headers.get("Content-Type")).to.include("application/json");
});

// Test Kong headers
pm.test("Kong headers present", function () {
    pm.expect(pm.response.headers.has("X-Kong-Upstream-Latency")).to.be.true;
});
```

---

# 🎉 **Conclusion**

This comprehensive guide covers all API endpoints across all microservices in the movie ticket booking system. Use Kong Gateway as the single entry point for all requests, which provides:

- ✅ **Unified Access Control**
- ✅ **Rate Limiting & CORS**
- ✅ **Service Health Monitoring**
- ✅ **Declarative Configuration (DB-less mode)**
- ✅ **Request Transformation for Health Checks**

## **Kong Gateway Updates Applied**

### **Configuration Mode**: 
- **Changed from**: Database mode (PostgreSQL)
- **Changed to**: DB-less mode (Declarative configuration)
- **Benefit**: Faster startup, simpler deployment, version-controlled configuration

### **Health Check Routes Added**:
All services now have dedicated health check routes that map to their `/actuator/health` endpoints:

| Kong Route | Service Health URL |
|------------|-------------------|
| `/health/user` | `http://user-service:8080/actuator/health` |
| `/health/cinema` | `http://cinema-service:8002/actuator/health` |
| `/health/booking` | `http://booking-service:8004/actuator/health` |
| `/health/payment` | `http://payment-service:8003/actuator/health` |
| `/health/notification` | `http://notification-service:8084/actuator/health` |

### **Path Transformation**:
Kong uses the `request-transformer` plugin to convert service-specific health check paths to the standard `/actuator/health` endpoint that Spring Boot services expect.

**Remember**: Always start your testing workflow with the System Health Checks (Phase 0) to ensure all services are operational before proceeding with functional testing.
- ✅ **Rate Limiting Protection**
- ✅ **CORS Handling**
- ✅ **Request/Response Logging**
- ✅ **Load Balancing**
- ✅ **Service Discovery**

**Happy Testing!** 🚀

For issues or questions, check the individual service documentation or Kong Gateway logs.