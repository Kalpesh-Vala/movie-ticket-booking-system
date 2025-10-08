package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.SeatLock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SeatLockRepository extends JpaRepository<SeatLock, String> {
    
    Optional<SeatLock> findByLockId(String lockId);
    
    List<SeatLock> findByBookingId(String bookingId);
    
    @Query("SELECT sl FROM SeatLock sl WHERE sl.isActive = true AND sl.expiresAt < :currentTime")
    List<SeatLock> findExpiredLocks(@Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT sl FROM SeatLock sl WHERE sl.showtimeId = :showtimeId AND sl.isActive = true")
    List<SeatLock> findActiveLocksForShowtime(@Param("showtimeId") String showtimeId);
}