# Movie Ticket Booking System Architecture

## System Architecture Diagram

```mermaid
graph TB
    %% External Clients
    Client[Web/Mobile Client]
    
    %% API Gateway
    Kong[Kong API Gateway<br/>Single GraphQL Endpoint<br/>JWT Auth + Rate Limiting]
    
    %% Microservices
    UserService[User Service<br/>Go + MongoDB<br/>REST API]
    CinemaService[Cinema Service<br/>Java Spring Boot + PostgreSQL<br/>gRPC Server]
    BookingService[Booking Service<br/>Python FastAPI + MongoDB<br/>GraphQL Aggregator]
    PaymentService[Payment Service<br/>Python FastAPI + MongoDB<br/>REST API]
    NotificationService[Notification Service<br/>Python Worker + Redis + MongoDB<br/>Event Consumer]
    
    %% Message Broker
    RabbitMQ[RabbitMQ<br/>Topic Exchange<br/>movie_app_events]
    
    %% Databases
    UserDB[(MongoDB<br/>User Data)]
    CinemaDB[(PostgreSQL<br/>Cinema/Movie/Showtime<br/>Seat Inventory)]
    BookingDB[(MongoDB<br/>Booking Data)]
    PaymentDB[(MongoDB<br/>Transaction Logs)]
    NotificationCache[(Redis<br/>Idempotency Cache)]
    NotificationDB[(MongoDB<br/>Notification Logs)]
    
    %% Client Interactions
    Client -->|GraphQL Queries/Mutations| Kong
    Kong -->|GraphQL| BookingService
    
    %% Internal Service Communications
    BookingService -.->|REST<br/>User Details| UserService
    BookingService -.->|gRPC<br/>Seat Locking| CinemaService
    BookingService -.->|REST<br/>Payment Processing| PaymentService
    
    %% Asynchronous Events
    BookingService -->|Publish Events| RabbitMQ
    PaymentService -->|Publish Events| RabbitMQ
    RabbitMQ -->|Consume Events| NotificationService
    
    %% Database Connections
    UserService --- UserDB
    CinemaService --- CinemaDB
    BookingService --- BookingDB
    PaymentService --- PaymentDB
    NotificationService --- NotificationCache
    NotificationService --- NotificationDB
    
    %% Styling
    classDef external fill:#e1f5fe
    classDef gateway fill:#f3e5f5
    classDef microservice fill:#e8f5e8
    classDef database fill:#fff3e0
    classDef messagebroker fill:#fce4ec
    
    class Client external
    class Kong gateway
    class UserService,CinemaService,BookingService,PaymentService,NotificationService microservice
    class UserDB,CinemaDB,BookingDB,PaymentDB,NotificationCache,NotificationDB database
    class RabbitMQ messagebroker
```

## Communication Protocol Matrix

| Source Service | Target Service | Protocol | Use Case |
|---------------|---------------|----------|----------|
| Client | Kong Gateway | GraphQL over HTTP | External API access |
| Kong | Booking Service | GraphQL | Request routing |
| Booking Service | Cinema Service | gRPC | High-performance seat locking |
| Booking Service | User Service | REST | User data retrieval |
| Booking Service | Payment Service | REST | Payment processing |
| All Services | RabbitMQ | AMQP | Asynchronous events |
| Notification Service | RabbitMQ | AMQP | Event consumption |

## Database Strategy: Polyglot Persistence

| Service | Database | Rationale |
|---------|----------|-----------|
| User Service | MongoDB | Flexible user profiles, social login data |
| Cinema Service | PostgreSQL | ACID transactions for seat inventory, complex relational queries |
| Booking Service | MongoDB | Flexible booking documents with embedded data |
| Payment Service | MongoDB | Transaction logs with varying payment method data |
| Notification Service | Redis + MongoDB | Redis for fast idempotency checks, MongoDB for audit logs |