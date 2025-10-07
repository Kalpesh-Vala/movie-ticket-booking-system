package services

import (
	"errors"
	"os"
	"time"

	"github.com/kalpesh-vala/movie-ticket-user-service/models"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type UserService struct {
	userRepo UserRepository
}

type UserRepository interface {
	CreateUser(user *models.User) error
	GetUserByEmail(email string) (*models.User, error)
	GetUserByID(id primitive.ObjectID) (*models.User, error)
	UpdateUser(id primitive.ObjectID, updates map[string]interface{}) error
}

func NewUserService(userRepo UserRepository) *UserService {
	return &UserService{
		userRepo: userRepo,
	}
}

// JWT Claims structure
type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// GenerateJWTToken creates a JWT token for authenticated user
// This is the critical function for JWT token generation upon successful login
func (s *UserService) GenerateJWTToken(user *models.User) (string, error) {
	// Get JWT secret from environment
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "your-super-secret-jwt-key-change-in-production" // Default for development
	}

	// Token expiration time (24 hours)
	expirationTime := time.Now().Add(24 * time.Hour)

	// Create JWT claims
	claims := &JWTClaims{
		UserID: user.ID.Hex(),
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "movie-ticket-booking-system",
			Subject:   user.ID.Hex(),
		},
	}

	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Generate encoded token string
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ValidateJWTToken validates and parses JWT token
func (s *UserService) ValidateJWTToken(tokenString string) (*JWTClaims, error) {
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "your-super-secret-jwt-key-change-in-production"
	}

	// Parse token
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(jwtSecret), nil
	})

	if err != nil {
		return nil, err
	}

	// Extract and validate claims
	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// AuthenticateUser validates user credentials and returns JWT token
func (s *UserService) AuthenticateUser(email, password string) (*models.LoginResponse, error) {
	// Get user by email
	user, err := s.userRepo.GetUserByEmail(email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Verify password (assuming you have a password verification function)
	if !s.verifyPassword(password, user.Password) {
		return nil, errors.New("invalid credentials")
	}

	// Check if user is active
	if !user.IsActive {
		return nil, errors.New("user account is deactivated")
	}

	// Generate JWT token
	token, err := s.GenerateJWTToken(user)
	if err != nil {
		return nil, errors.New("failed to generate token")
	}

	return &models.LoginResponse{
		Token: token,
		User:  *user,
	}, nil
}

// Helper function to verify password (implement based on your hashing strategy)
func (s *UserService) verifyPassword(plainPassword, hashedPassword string) bool {
	// Implementation depends on your password hashing strategy
	// For example, using bcrypt:
	// return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(plainPassword)) == nil
	return true // Placeholder - implement proper password verification
}

// RegisterUser creates a new user account
func (s *UserService) RegisterUser(req *models.RegisterRequest) (*models.User, error) {
	// Check if user already exists
	existingUser, _ := s.userRepo.GetUserByEmail(req.Email)
	if existingUser != nil {
		return nil, errors.New("user already exists with this email")
	}

	// Hash password (implement based on your hashing strategy)
	hashedPassword := s.hashPassword(req.Password)

	// Create user
	user := &models.User{
		Email:     req.Email,
		Password:  hashedPassword,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := s.userRepo.CreateUser(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

// Helper function to hash password
func (s *UserService) hashPassword(password string) string {
	// Implementation depends on your password hashing strategy
	// For example, using bcrypt:
	// hashedBytes, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	// return string(hashedBytes)
	return password // Placeholder - implement proper password hashing
}

// GetUserByID retrieves user by ID
func (s *UserService) GetUserByID(id primitive.ObjectID) (*models.User, error) {
	return s.userRepo.GetUserByID(id)
}

// UpdateUser updates user information
func (s *UserService) UpdateUser(id primitive.ObjectID, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()
	return s.userRepo.UpdateUser(id, updates)
}

// GetUserByEmail retrieves user by email
func (s *UserService) GetUserByEmail(email string) (*models.User, error) {
	return s.userRepo.GetUserByEmail(email)
}

// CreateUser creates a new user
func (s *UserService) CreateUser(user *models.User) error {
	return s.userRepo.CreateUser(user)
}
