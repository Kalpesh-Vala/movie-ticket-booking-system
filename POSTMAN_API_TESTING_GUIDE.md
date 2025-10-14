# 🚀 **Complete Postman API Testing Guide - Kong Gateway**

## 📋 **Overview**

This comprehensive guide covers testing all microservice APIs through Kong Gateway using Postman. All requests are routed through Kong Gateway at `http://localhost:8000` for unified access control, rate limiting, and CORS handling.

## 🌐 **Kong Gateway Configuration**

- **Kong Proxy URL**: `http://localhost:8000`
- **Kong Admin URL**: `http://localhost:8001`
- **Rate Limit**: 1000 requests/minute
- **CORS**: Enabled for all origins
- **Global Plugins**: CORS, Rate Limiting

---

## 📚 **Service Architecture**

| Service | Direct URL | Kong Route | Technology | Database |
|---------|------------|------------|------------|----------|
| User Service | localhost:8080 | `/api/v1/*`, `/health` | Go + Gin | MongoDB |
| Cinema Service | localhost:8002 | `/api/v1/cinemas/*`, `/actuator/*` | Java + Spring Boot | PostgreSQL |
| Booking Service | localhost:8004 | `/api/bookings/*`, `/graphql` | Python + FastAPI + GraphQL | MongoDB |
| Payment Service | localhost:8003 | `/api/payments/*` | Python + FastAPI | MongoDB |
| Notification Service | localhost:8084 | `/api/notifications/*` | Python Worker | MongoDB + Redis |

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
GET {{kong_url}}/health
```

**Expected Response:**
```json
{
  "status": "healthy"
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

## **Base URL**: `{{kong_url}}/api/v1/cinemas` and `{{kong_url}}/actuator`

### **2.1 Health Check**
```http
GET {{kong_url}}/actuator/health
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

**Expected Response:**
```json
[
  {
    "id": 1,
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
  "location": "456 Oak Avenue, Uptown"
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
  "description": "Epic superhero movie",
  "genre": "Action",
  "duration": 181,
  "rating": "PG-13",
  "releaseDate": "2024-06-15"
}
```

### **2.8 Search Movies**
```http
GET {{kong_url}}/api/v1/movies/search?title=Avengers
```

### **2.9 Get Screens by Cinema**
```http
GET {{kong_url}}/api/v1/cinemas/{{cinema_id}}/screens
```

### **2.10 Get All Showtimes**
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

### **2.11 Create Showtime**
```http
POST {{kong_url}}/api/v1/showtimes
Content-Type: application/json

{
  "movieId": {{movie_id}},
  "screenId": 1,
  "startTime": "2024-12-20T19:30:00",
  "endTime": "2024-12-20T22:31:00",
  "price": 15.00
}
```

### **2.12 Get Showtimes by Date**
```http
GET {{kong_url}}/api/v1/showtimes/date/2024-12-20
```

### **2.13 Get Seats for Showtime**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats
```

### **2.14 Get Available Seats**
```http
GET {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/available
```

### **2.15 Lock Seats**
```http
POST {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/lock
Content-Type: application/json

{
  "seatIds": [1, 2, 3],
  "userId": "{{user_id}}"
}
```

### **2.16 Release Seats**
```http
POST {{kong_url}}/api/v1/showtimes/{{showtime_id}}/seats/release
Content-Type: application/json

{
  "seatIds": [1, 2, 3],
  "userId": "{{user_id}}"
}
```

---

# 🎫 **3. Booking Service API Testing**

## **Base URL**: `{{kong_url}}/api/bookings` and `{{kong_url}}/graphql`

### **3.1 Health Check**
```http
GET {{kong_url}}/api/bookings/health
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
GET {{kong_url}}/api/payments/health
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

### **5.1 Health Check (if available)**
```http
GET {{kong_url}}/api/notifications/health
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

## **End-to-End Booking Flow**

Follow this sequence to test the complete booking workflow:

### **Phase 1: User Setup**
1. **Register User** → `POST /api/users`
2. **Login User** → `POST /api/users/login` (save token)
3. **Get Profile** → `GET /api/users/profile`

### **Phase 2: Browse Movies**
4. **Get Cinemas** → `GET /api/v1/cinemas`
5. **Get Movies** → `GET /api/v1/movies`
6. **Search Movies** → `GET /api/v1/movies/search`
7. **Get Showtimes** → `GET /api/v1/showtimes`

### **Phase 3: Book Tickets**
8. **Get Available Seats** → `GET /api/v1/showtimes/{id}/seats/available`
9. **Lock Seats** → `POST /api/v1/showtimes/{id}/seats/lock`
10. **Create Booking** → `POST /api/bookings` or GraphQL mutation
11. **Get Booking Details** → `GET /api/bookings/{id}`

### **Phase 4: Process Payment**
12. **Get Payment Methods** → `GET /api/payments/methods`
13. **Process Payment** → `POST /api/payments/process`
14. **Check Payment Status** → `GET /api/payments/status/{id}`
15. **Update Booking Status** → `PUT /api/bookings/{id}/status`

### **Phase 5: Notifications (Automatic)**
16. Check notification logs in MongoDB or RabbitMQ management console

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
├── 📁 Environment Setup
│   ├── Kong Status Check
│   └── All Services Health Check
├── 📁 1. User Management
│   ├── Register User
│   ├── Login User
│   ├── Get Profile
│   ├── Update Profile
│   └── Change Password
├── 📁 2. Cinema & Movies
│   ├── Get Cinemas
│   ├── Create Cinema
│   ├── Get Movies
│   ├── Create Movie
│   └── Search Movies
├── 📁 3. Showtimes & Seats
│   ├── Get Showtimes
│   ├── Create Showtime
│   ├── Get Available Seats
│   ├── Lock Seats
│   └── Release Seats
├── 📁 4. Booking Management
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
├── 📁 5. Payment Processing
│   ├── Get Payment Methods
│   ├── Process Credit Card Payment
│   ├── Process PayPal Payment
│   ├── Get Payment Status
│   └── Process Refund
├── 📁 6. Notifications
│   ├── Send Test Notification
│   └── Get Notification History
└── 📁 7. Error Testing
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
- ✅ **Rate Limiting Protection**
- ✅ **CORS Handling**
- ✅ **Request/Response Logging**
- ✅ **Load Balancing**
- ✅ **Service Discovery**

**Happy Testing!** 🚀

For issues or questions, check the individual service documentation or Kong Gateway logs.