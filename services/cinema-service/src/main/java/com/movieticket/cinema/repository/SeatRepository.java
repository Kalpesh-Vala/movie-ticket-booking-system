package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.SeatStatus;
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
    
    List<Seat> findByShowtimeIdAndStatus(String showtimeId, SeatStatus status);
    
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.seatNumber IN :seatNumbers")
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    List<Seat> findByShowtimeIdAndSeatNumberInWithLock(@Param("showtimeId") String showtimeId, 
                                                      @Param("seatNumbers") List<String> seatNumbers);
    
    @Query("SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId AND s.seatNumber IN :seatNumbers")
    List<Seat> findByShowtimeIdAndSeatNumberIn(@Param("showtimeId") String showtimeId, 
                                              @Param("seatNumbers") List<String> seatNumbers);
    
    @Query("SELECT s FROM Seat s WHERE s.status = 'LOCKED' AND s.lockedUntil < :currentTime")
    List<Seat> findExpiredLockedSeats(@Param("currentTime") LocalDateTime currentTime);
}