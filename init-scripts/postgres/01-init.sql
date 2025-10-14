-- Cinema database initialization script

-- Create cinema_db database (using psql meta-command to handle errors gracefully)
\set ON_ERROR_STOP off
CREATE DATABASE cinema_db;
\set ON_ERROR_STOP on

-- Switch to cinema_db
\c cinema_db;

-- Create cinemas table
CREATE TABLE IF NOT EXISTS cinemas (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(500) NOT NULL,
    total_screens INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create movies table
CREATE TABLE IF NOT EXISTS movies (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    duration_minutes INTEGER NOT NULL,
    rating VARCHAR(10),
    poster_url VARCHAR(500),
    description TEXT,
    release_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create screens table
CREATE TABLE IF NOT EXISTS screens (
    id VARCHAR(255) PRIMARY KEY,
    screen_number VARCHAR(255) NOT NULL,
    total_seats INTEGER DEFAULT 100,
    cinema_id VARCHAR(255) NOT NULL REFERENCES cinemas(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create showtimes table
CREATE TABLE IF NOT EXISTS showtimes (
    id VARCHAR(255) PRIMARY KEY,
    movie_id VARCHAR(255) NOT NULL REFERENCES movies(id),
    screen_id VARCHAR(255) NOT NULL REFERENCES screens(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    total_seats INTEGER NOT NULL DEFAULT 100,
    available_seats INTEGER NOT NULL DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create seats table
CREATE TABLE IF NOT EXISTS seats (
    id VARCHAR(255) PRIMARY KEY,
    showtime_id VARCHAR(255) NOT NULL REFERENCES showtimes(id),
    seat_number VARCHAR(10) NOT NULL,
    is_booked BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    locked_by VARCHAR(255),
    lock_expiration TIMESTAMP,
    booked_by VARCHAR(255),
    booked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(showtime_id, seat_number)
);

-- Create seat_locks table for tracking locks
CREATE TABLE IF NOT EXISTS seat_locks (
    id VARCHAR(255) PRIMARY KEY,
    lock_id VARCHAR(255) NOT NULL,
    seat_id VARCHAR(255) NOT NULL REFERENCES seats(id),
    booking_id VARCHAR(255) NOT NULL,
    locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    released_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_showtimes_movie_screen ON showtimes(movie_id, screen_id);
CREATE INDEX IF NOT EXISTS idx_showtimes_start_time ON showtimes(start_time);
CREATE INDEX IF NOT EXISTS idx_seats_showtime ON seats(showtime_id);
CREATE INDEX IF NOT EXISTS idx_seats_booking_status ON seats(showtime_id, is_booked, is_locked);
CREATE INDEX IF NOT EXISTS idx_seat_locks_active ON seat_locks(lock_id, is_active);
CREATE INDEX IF NOT EXISTS idx_seat_locks_expiry ON seat_locks(expires_at, is_active);

-- Insert sample data
INSERT INTO cinemas (id, name, location, total_screens) VALUES
('cinema-001', 'AMC Downtown', '123 Main St, Downtown', 8),
('cinema-002', 'Regal Uptown', '456 Oak Ave, Uptown', 12),
('cinema-003', 'Cinemark Plaza', '789 Pine Rd, Plaza District', 6)
ON CONFLICT (id) DO NOTHING;

INSERT INTO movies (id, title, genre, duration_minutes, rating, description) VALUES
('movie-001', 'The Matrix Resurrections', 'Sci-Fi', 148, 'R', 'Return to the world of The Matrix'),
('movie-002', 'Spider-Man: No Way Home', 'Action', 148, 'PG-13', 'The multiverse unleashed'),
('movie-003', 'Dune', 'Sci-Fi', 155, 'PG-13', 'Epic space adventure')
ON CONFLICT (id) DO NOTHING;

-- Insert screens
INSERT INTO screens (id, screen_number, total_seats, cinema_id) VALUES
('screen-001', 'Screen 1', 100, 'cinema-001'),
('screen-002', 'Screen 2', 120, 'cinema-001'),
('screen-003', 'Screen 1', 150, 'cinema-002'),
('screen-004', 'Screen 2', 100, 'cinema-002'),
('screen-005', 'Screen 1', 80, 'cinema-003')
ON CONFLICT (id) DO NOTHING;

-- Insert sample showtimes
INSERT INTO showtimes (id, movie_id, screen_id, start_time, end_time, base_price, total_seats, available_seats) VALUES
('showtime-001', 'movie-001', 'screen-001', 
 CURRENT_TIMESTAMP + INTERVAL '2 hours', CURRENT_TIMESTAMP + INTERVAL '4 hours 28 minutes', 15.99, 100, 100),
('showtime-002', 'movie-002', 'screen-002', 
 CURRENT_TIMESTAMP + INTERVAL '3 hours', CURRENT_TIMESTAMP + INTERVAL '5 hours 28 minutes', 17.99, 120, 120),
('showtime-003', 'movie-003', 'screen-003', 
 CURRENT_TIMESTAMP + INTERVAL '4 hours', CURRENT_TIMESTAMP + INTERVAL '6 hours 35 minutes', 16.99, 150, 150)
ON CONFLICT (id) DO NOTHING;

-- Generate seats for showtimes (A1-A10, B1-B10, etc.)
DO $$
DECLARE
    showtime_rec RECORD;
    row_char CHAR(1);
    seat_num INTEGER;
    seat_id VARCHAR(255);
BEGIN
    FOR showtime_rec IN SELECT id, total_seats FROM showtimes LOOP
        FOR i IN 1..(showtime_rec.total_seats / 10) LOOP
            row_char := CHR(64 + i); -- A, B, C, etc.
            FOR seat_num IN 1..10 LOOP
                seat_id := 'seat-' || showtime_rec.id || '-' || row_char || seat_num;
                INSERT INTO seats (id, showtime_id, seat_number) 
                VALUES (seat_id, showtime_rec.id, row_char || seat_num)
                ON CONFLICT (showtime_id, seat_number) DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;