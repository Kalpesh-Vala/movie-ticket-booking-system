-- Generate seats for all showtimes
-- This script creates seat layout for each showtime

DO $$
DECLARE
    showtime_record RECORD;
    screen_record RECORD;
    seat_count INTEGER;
    row_char CHAR;
    seat_num INTEGER;
    seat_number_var VARCHAR(10);
    seats_per_row INTEGER := 12;
    row_count INTEGER;
BEGIN
    -- Loop through all showtimes
    FOR showtime_record IN SELECT id, screen_id, total_seats FROM showtimes LOOP
        -- Get screen details
        SELECT total_seats INTO seat_count FROM screens WHERE id = showtime_record.screen_id;
        
        -- Calculate number of rows needed
        row_count := CEIL(seat_count::DECIMAL / seats_per_row);
        
        -- Generate seats for this showtime
        FOR i IN 1..row_count LOOP
            row_char := CHR(64 + i); -- A, B, C, etc.
            
            FOR j IN 1..seats_per_row LOOP
                EXIT WHEN (i-1) * seats_per_row + j > seat_count;
                
                seat_number_var := row_char || LPAD(j::TEXT, 2, '0');
                
                INSERT INTO seats (
                    id, 
                    seat_number, 
                    row_name, 
                    seat_type, 
                    status, 
                    showtime_id, 
                    screen_id
                ) VALUES (
                    'seat-' || showtime_record.id || '-' || seat_number_var,
                    seat_number_var,
                    row_char,
                    CASE WHEN j IN (1, seats_per_row) THEN 'PREMIUM' 
                         WHEN j IN (2, seats_per_row-1) THEN 'VIP'
                         ELSE 'REGULAR' END,
                    'AVAILABLE',
                    showtime_record.id,
                    showtime_record.screen_id
                ) ON CONFLICT (showtime_id, seat_number) DO NOTHING;
            END LOOP;
        END LOOP;
        
        RAISE NOTICE 'Generated seats for showtime: %', showtime_record.id;
    END LOOP;
END $$;