-- Sample data for cinema service testing
-- This script inserts sample data into all tables

-- Insert sample cinemas
INSERT INTO cinemas (id, name, location, total_screens) VALUES
('cinema-1', 'PVR Cinemas - Phoenix Mall', 'Phoenix Mall, Bangalore', 8),
('cinema-2', 'INOX - Forum Mall', 'Forum Mall, Bangalore', 6),
('cinema-3', 'Cinepolis - Orion Mall', 'Orion Mall, Bangalore', 10)
ON CONFLICT (id) DO NOTHING;

-- Insert sample movies
INSERT INTO movies (id, title, genre, duration_minutes, rating, poster_url, description) VALUES
('movie-1', 'Avengers: Endgame', 'Action/Sci-Fi', 181, 'PG-13', 'https://example.com/avengers-endgame.jpg', 'The epic conclusion to the Infinity Saga'),
('movie-2', 'Spider-Man: No Way Home', 'Action/Adventure', 148, 'PG-13', 'https://example.com/spiderman-nwh.jpg', 'Spider-Man faces his greatest challenge yet'),
('movie-3', 'The Dark Knight', 'Action/Crime', 152, 'PG-13', 'https://example.com/dark-knight.jpg', 'Batman faces the Joker in this epic showdown'),
('movie-4', 'Inception', 'Sci-Fi/Thriller', 148, 'PG-13', 'https://example.com/inception.jpg', 'A mind-bending thriller about dreams within dreams'),
('movie-5', 'Interstellar', 'Sci-Fi/Drama', 169, 'PG-13', 'https://example.com/interstellar.jpg', 'A journey through space and time')
ON CONFLICT (id) DO NOTHING;

-- Insert sample screens
INSERT INTO screens (id, screen_number, total_seats, cinema_id) VALUES
('screen-1', 'Screen 1', 120, 'cinema-1'),
('screen-2', 'Screen 2', 100, 'cinema-1'),
('screen-3', 'Screen 3', 150, 'cinema-1'),
('screen-4', 'Screen 1', 130, 'cinema-2'),
('screen-5', 'Screen 2', 110, 'cinema-2'),
('screen-6', 'Screen 1', 140, 'cinema-3'),
('screen-7', 'Screen 2', 120, 'cinema-3'),
('screen-8', 'Screen 3', 160, 'cinema-3')
ON CONFLICT (id) DO NOTHING;

-- Insert sample showtimes for today and tomorrow
INSERT INTO showtimes (id, movie_id, screen_id, start_time, end_time, base_price, total_seats, available_seats) VALUES
-- Today's shows
('showtime-1', 'movie-1', 'screen-1', CURRENT_TIMESTAMP + INTERVAL '2 hours', CURRENT_TIMESTAMP + INTERVAL '5 hours', 250.00, 120, 120),
('showtime-2', 'movie-2', 'screen-2', CURRENT_TIMESTAMP + INTERVAL '3 hours', CURRENT_TIMESTAMP + INTERVAL '5.5 hours', 280.00, 100, 100),
('showtime-3', 'movie-3', 'screen-3', CURRENT_TIMESTAMP + INTERVAL '4 hours', CURRENT_TIMESTAMP + INTERVAL '6.5 hours', 220.00, 150, 150),
('showtime-4', 'movie-4', 'screen-4', CURRENT_TIMESTAMP + INTERVAL '2.5 hours', CURRENT_TIMESTAMP + INTERVAL '5 hours', 300.00, 130, 130),
('showtime-5', 'movie-5', 'screen-5', CURRENT_TIMESTAMP + INTERVAL '6 hours', CURRENT_TIMESTAMP + INTERVAL '9 hours', 350.00, 110, 110),

-- Tomorrow's shows
('showtime-6', 'movie-1', 'screen-6', CURRENT_TIMESTAMP + INTERVAL '1 day 2 hours', CURRENT_TIMESTAMP + INTERVAL '1 day 5 hours', 250.00, 140, 140),
('showtime-7', 'movie-2', 'screen-7', CURRENT_TIMESTAMP + INTERVAL '1 day 4 hours', CURRENT_TIMESTAMP + INTERVAL '1 day 6.5 hours', 280.00, 120, 120),
('showtime-8', 'movie-3', 'screen-8', CURRENT_TIMESTAMP + INTERVAL '1 day 6 hours', CURRENT_TIMESTAMP + INTERVAL '1 day 8.5 hours', 220.00, 160, 160),
('showtime-9', 'movie-4', 'screen-1', CURRENT_TIMESTAMP + INTERVAL '1 day 8 hours', CURRENT_TIMESTAMP + INTERVAL '1 day 10.5 hours', 300.00, 120, 120),
('showtime-10', 'movie-5', 'screen-2', CURRENT_TIMESTAMP + INTERVAL '1 day 10 hours', CURRENT_TIMESTAMP + INTERVAL '1 day 13 hours', 350.00, 100, 100)
ON CONFLICT (id) DO NOTHING;