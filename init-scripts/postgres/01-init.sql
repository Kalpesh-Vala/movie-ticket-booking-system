-- Cinema database initialization script

-- Create cinema_db database (using psql meta-command to handle errors gracefully)
\set ON_ERROR_STOP off
CREATE DATABASE cinema_db;
\set ON_ERROR_STOP on

-- Switch to cinema_db
\c cinema_db;

-- Create cinemas table
CREATE TABLE IF NOT EXISTS cinemas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location VARCHAR(500) NOT NULL,
    total_screens INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create movies table
CREATE TABLE IF NOT EXISTS movies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Create showtimes table
CREATE TABLE IF NOT EXISTS showtimes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_id UUID NOT NULL REFERENCES movies(id),
    cinema_id UUID NOT NULL REFERENCES cinemas(id),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showtime_id UUID NOT NULL REFERENCES showtimes(id),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lock_id VARCHAR(255) NOT NULL,
    seat_id UUID NOT NULL REFERENCES seats(id),
    booking_id VARCHAR(255) NOT NULL,
    locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    released_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_showtimes_movie_cinema ON showtimes(movie_id, cinema_id);
CREATE INDEX IF NOT EXISTS idx_showtimes_start_time ON showtimes(start_time);
CREATE INDEX IF NOT EXISTS idx_seats_showtime ON seats(showtime_id);
CREATE INDEX IF NOT EXISTS idx_seats_booking_status ON seats(showtime_id, is_booked, is_locked);
CREATE INDEX IF NOT EXISTS idx_seat_locks_active ON seat_locks(lock_id, is_active);
CREATE INDEX IF NOT EXISTS idx_seat_locks_expiry ON seat_locks(expires_at, is_active);

-- Insert sample data
INSERT INTO cinemas (id, name, location, total_screens) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'AMC Downtown', '123 Main St, Downtown', 8),
('550e8400-e29b-41d4-a716-446655440002', 'Regal Uptown', '456 Oak Ave, Uptown', 12),
('550e8400-e29b-41d4-a716-446655440003', 'Cinemark Plaza', '789 Pine Rd, Plaza District', 6)
ON CONFLICT (id) DO NOTHING;

INSERT INTO movies (id, title, genre, duration_minutes, rating, description) VALUES
('650e8400-e29b-41d4-a716-446655440001', 'The Matrix Resurrections', 'Sci-Fi', 148, 'R', 'Return to the world of The Matrix'),
('650e8400-e29b-41d4-a716-446655440002', 'Spider-Man: No Way Home', 'Action', 148, 'PG-13', 'The multiverse unleashed'),
('650e8400-e29b-41d4-a716-446655440003', 'Dune', 'Sci-Fi', 155, 'PG-13', 'Epic space adventure')
ON CONFLICT (id) DO NOTHING;

-- Insert sample showtimes
INSERT INTO showtimes (id, movie_id, cinema_id, start_time, end_time, base_price, total_seats, available_seats) VALUES
('750e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 
 CURRENT_TIMESTAMP + INTERVAL '2 hours', CURRENT_TIMESTAMP + INTERVAL '4 hours 28 minutes', 15.99, 100, 100),
('750e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 
 CURRENT_TIMESTAMP + INTERVAL '3 hours', CURRENT_TIMESTAMP + INTERVAL '5 hours 28 minutes', 17.99, 120, 120),
('750e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 
 CURRENT_TIMESTAMP + INTERVAL '4 hours', CURRENT_TIMESTAMP + INTERVAL '6 hours 35 minutes', 16.99, 150, 150)
ON CONFLICT (id) DO NOTHING;

-- Generate seats for showtimes (A1-A10, B1-B10, etc.)
DO $$
DECLARE
    showtime_rec RECORD;
    row_char CHAR(1);
    seat_num INTEGER;
BEGIN
    FOR showtime_rec IN SELECT id, total_seats FROM showtimes LOOP
        FOR i IN 1..(showtime_rec.total_seats / 10) LOOP
            row_char := CHR(64 + i); -- A, B, C, etc.
            FOR seat_num IN 1..10 LOOP
                INSERT INTO seats (showtime_id, seat_number) 
                VALUES (showtime_rec.id, row_char || seat_num)
                ON CONFLICT (showtime_id, seat_number) DO NOTHING;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;