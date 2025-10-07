package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Email       string             `bson:"email" json:"email" validate:"required,email"`
	Password    string             `bson:"password" json:"-"` // Never return password in JSON
	FirstName   string             `bson:"first_name" json:"first_name" validate:"required"`
	LastName    string             `bson:"last_name" json:"last_name" validate:"required"`
	PhoneNumber string             `bson:"phone_number" json:"phone_number"`
	DateOfBirth *time.Time         `bson:"date_of_birth,omitempty" json:"date_of_birth,omitempty"`
	IsActive    bool               `bson:"is_active" json:"is_active"`
	CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt   time.Time          `bson:"updated_at" json:"updated_at"`
}

type RegisterRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required"`
	LastName  string `json:"last_name" validate:"required"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type UpdateUserRequest struct {
	FirstName   *string    `json:"first_name,omitempty"`
	LastName    *string    `json:"last_name,omitempty"`
	PhoneNumber *string    `json:"phone_number,omitempty"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
}
