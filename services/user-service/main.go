package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/kalpesh-vala/movie-ticket-user-service/handlers"
	"github.com/kalpesh-vala/movie-ticket-user-service/middleware"
	"github.com/kalpesh-vala/movie-ticket-user-service/repository"
	"github.com/kalpesh-vala/movie-ticket-user-service/services"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Connect to MongoDB
	mongoClient, err := connectToMongoDB()
	if err != nil {
		log.Fatal("Failed to connect to MongoDB:", err)
	}
	defer mongoClient.Disconnect(context.Background())

	// Initialize repository
	userRepo := repository.NewUserRepository(mongoClient.Database("movie_booking"))

	// Initialize service
	userService := services.NewUserService(userRepo)

	// Initialize handlers
	userHandler := handlers.NewUserHandler(userService)

	// Setup router
	router := setupRouter(userHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	log.Printf("User service starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, router))
}

func connectToMongoDB() (*mongo.Client, error) {
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		return nil, err
	}

	// Test the connection
	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	return client, nil
}

func setupRouter(userHandler *handlers.UserHandler) *gin.Engine {
	router := gin.Default()

	// Middleware
	router.Use(middleware.CORS())
	router.Use(middleware.Logger())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Public routes
		v1.POST("/register", userHandler.Register)
		v1.POST("/login", userHandler.Login)

		// Protected routes
		protected := v1.Group("/")
		protected.Use(middleware.JWTAuth())
		{
			protected.GET("/users/:id", userHandler.GetUser)
			protected.PUT("/users/:id", userHandler.UpdateUser)
			protected.GET("/profile", userHandler.GetProfile)
			protected.PUT("/profile", userHandler.UpdateProfile)
		}
	}

	return router
}
