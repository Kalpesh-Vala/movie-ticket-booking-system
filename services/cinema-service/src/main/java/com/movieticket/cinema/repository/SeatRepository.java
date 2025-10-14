package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.Seat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SeatRepository extends JpaRepository<Seat, String> {
    
    List<Seat> findByShowtimeId(String showtimeId);
    
    // Find available seats (not booked and not locked)
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.isBooked = false AND s.isLocked = false")
    List<Seat> findAvailableSeatsByShowtimeId(@Param("showtimeId") String showtimeId);
    
    // Find locked seats (is_locked = true)
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.isLocked = true")
    List<Seat> findLockedSeatsByShowtimeId(@Param("showtimeId") String showtimeId);
    
    // Find booked seats (is_booked = true)
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.isBooked = true")
    List<Seat> findBookedSeatsByShowtimeId(@Param("showtimeId") String showtimeId);
    
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.seatNumber IN :seatNumbers")
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    List<Seat> findByShowtimeIdAndSeatNumberInWithLock(@Param("showtimeId") String showtimeId, 
                                                      @Param("seatNumbers") List<String> seatNumbers);
    
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.seatNumber IN :seatNumbers")
    List<Seat> findByShowtimeIdAndSeatNumberIn(@Param("showtimeId") String showtimeId, 
                                              @Param("seatNumbers") List<String> seatNumbers);
    
    @Query("SELECT s FROM Seat s WHERE s.isLocked = true AND s.lockExpiration < :currentTime")
    List<Seat> findExpiredLockedSeats(@Param("currentTime") LocalDateTime currentTime);
}