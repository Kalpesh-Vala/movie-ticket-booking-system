-- Cinema Database Schema
-- This script creates all the necessary tables for the cinema service

-- Create cinemas table
CREATE TABLE IF NOT EXISTS cinemas (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    total_screens INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create movies table
CREATE TABLE IF NOT EXISTS movies (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    duration_minutes INTEGER,
    rating VARCHAR(10),
    poster_url VARCHAR(500),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create screens table
CREATE TABLE IF NOT EXISTS screens (
    id VARCHAR(36) PRIMARY KEY,
    screen_number VARCHAR(50) NOT NULL,
    total_seats INTEGER,
    cinema_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cinema_id) REFERENCES cinemas(id) ON DELETE CASCADE
);

-- Create showtimes table
CREATE TABLE IF NOT EXISTS showtimes (
    id VARCHAR(36) PRIMARY KEY,
    movie_id VARCHAR(36) NOT NULL,
    screen_id VARCHAR(36) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    total_seats INTEGER,
    available_seats INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (screen_id) REFERENCES screens(id) ON DELETE CASCADE
);

-- Create seats table with seat status
CREATE TABLE IF NOT EXISTS seats (
    id VARCHAR(36) PRIMARY KEY,
    seat_number VARCHAR(10) NOT NULL,
    row_name VARCHAR(10) NOT NULL,
    seat_type VARCHAR(20) DEFAULT 'REGULAR',
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    showtime_id VARCHAR(36) NOT NULL,
    screen_id VARCHAR(36) NOT NULL,
    locked_by VARCHAR(36),
    locked_until TIMESTAMP,
    booked_by VARCHAR(36),
    booking_id VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (showtime_id) REFERENCES showtimes(id) ON DELETE CASCADE,
    FOREIGN KEY (screen_id) REFERENCES screens(id) ON DELETE CASCADE,
    UNIQUE(showtime_id, seat_number)
);

-- Create seat_locks table for tracking seat locks
CREATE TABLE IF NOT EXISTS seat_locks (
    id VARCHAR(36) PRIMARY KEY,
    lock_id VARCHAR(36) UNIQUE NOT NULL,
    booking_id VARCHAR(36) NOT NULL,
    showtime_id VARCHAR(36) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (showtime_id) REFERENCES showtimes(id) ON DELETE CASCADE
);

-- Create seat_lock_seats table for mapping lock to specific seats
CREATE TABLE IF NOT EXISTS seat_lock_seats (
    seat_lock_id VARCHAR(36) NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    PRIMARY KEY (seat_lock_id, seat_number),
    FOREIGN KEY (seat_lock_id) REFERENCES seat_locks(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_seats_showtime_status ON seats(showtime_id, status);
CREATE INDEX IF NOT EXISTS idx_seats_locked_until ON seats(locked_until);
CREATE INDEX IF NOT EXISTS idx_seat_locks_expires_at ON seat_locks(expires_at, is_active);
CREATE INDEX IF NOT EXISTS idx_showtimes_movie_id ON showtimes(movie_id);
CREATE INDEX IF NOT EXISTS idx_showtimes_screen_id ON showtimes(screen_id);
CREATE INDEX IF NOT EXISTS idx_showtimes_start_time ON showtimes(start_time);
CREATE INDEX IF NOT EXISTS idx_screens_cinema_id ON screens(cinema_id);