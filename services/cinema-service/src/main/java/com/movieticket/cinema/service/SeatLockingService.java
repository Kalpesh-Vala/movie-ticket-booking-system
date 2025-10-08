package com.movieticket.cinema.service;

import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.SeatLock;
import com.movieticket.cinema.entity.SeatStatus;
import com.movieticket.cinema.entity.Showtime;
import com.movieticket.cinema.repository.SeatRepository;
import com.movieticket.cinema.repository.SeatLockRepository;
import com.movieticket.cinema.repository.ShowtimeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.ArrayList;

/**
 * Critical seat locking service that uses PostgreSQL pessimistic locking
 * to prevent double-bookings in high-concurrency scenarios.
 */
@Service
public class SeatLockingService {

    @Autowired
    private SeatRepository seatRepository;

    @Autowired
    private SeatLockRepository seatLockRepository;

    @Autowired
    private ShowtimeRepository showtimeRepository;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Critical method: Lock seats with PostgreSQL pessimistic locking
     * This method uses pessimistic locking to ensure atomic seat reservation
     */
    @Transactional
    public SeatLockResult lockSeats(String showtimeId, List<String> seatNumbers, 
                                   String bookingId, int lockDurationSeconds) {
        
        // Validate showtime exists
        Showtime showtime = showtimeRepository.findById(showtimeId)
            .orElseThrow(() -> new IllegalArgumentException("Showtime not found"));

        // Get current time for lock expiration
        LocalDateTime lockExpiration = LocalDateTime.now().plusSeconds(lockDurationSeconds);
        
        try {
            // CRITICAL: Use pessimistic locking to prevent concurrent modifications
            List<Seat> seatsToLock = seatRepository.findByShowtimeIdAndSeatNumberInWithLock(showtimeId, seatNumbers);

            // Validate all requested seats exist
            if (seatsToLock.size() != seatNumbers.size()) {
                List<String> foundSeats = seatsToLock.stream()
                    .map(Seat::getSeatNumber)
                    .collect(Collectors.toList());
                List<String> missingSeats = seatNumbers.stream()
                    .filter(seat -> !foundSeats.contains(seat))
                    .collect(Collectors.toList());
                
                return new SeatLockResult(false, null, null, missingSeats, "Seats not found: " + missingSeats);
            }

            // Check if any seats are already booked or locked
            List<String> unavailableSeats = seatsToLock.stream()
                .filter(seat -> seat.getStatus() == SeatStatus.BOOKED || isCurrentlyLocked(seat))
                .map(Seat::getSeatNumber)
                .collect(Collectors.toList());

            if (!unavailableSeats.isEmpty()) {
                return new SeatLockResult(false, null, null, unavailableSeats, "Seats unavailable: " + unavailableSeats);
            }

            // Create seat lock record
            String lockId = UUID.randomUUID().toString();
            SeatLock seatLock = new SeatLock(lockId, bookingId, showtimeId, seatNumbers, lockExpiration);
            seatLockRepository.save(seatLock);

            // Update seat status to locked
            seatsToLock.forEach(seat -> {
                seat.setStatus(SeatStatus.LOCKED);
                seat.setLockedBy(bookingId);
                seat.setLockedUntil(lockExpiration);
            });
            
            seatRepository.saveAll(seatsToLock);

            return new SeatLockResult(true, lockId, lockExpiration, null, "Seats locked successfully");

        } catch (Exception e) {
            // Log the error and return failure
            System.err.println("Error locking seats: " + e.getMessage());
            return new SeatLockResult(false, null, null, seatNumbers, "Failed to lock seats: " + e.getMessage());
        }
    }

    /**
     * Release seat locks
     */
    @Transactional
    public boolean releaseSeatLock(String lockId, String bookingId) {
        try {
            // Find the lock
            SeatLock lock = seatLockRepository.findByLockId(lockId)
                .orElse(null);
            
            if (lock == null || !lock.getBookingId().equals(bookingId) || !lock.getIsActive()) {
                return false;
            }

            // Get seats to unlock
            List<Seat> seatsToUnlock = seatRepository.findByShowtimeIdAndSeatNumberIn(
                lock.getShowtimeId(), lock.getSeatNumbers());

            // Update seat status
            seatsToUnlock.forEach(seat -> {
                if (seat.getStatus() == SeatStatus.LOCKED && bookingId.equals(seat.getLockedBy())) {
                    seat.setStatus(SeatStatus.AVAILABLE);
                    seat.setLockedBy(null);
                    seat.setLockedUntil(null);
                }
            });
            
            seatRepository.saveAll(seatsToUnlock);

            // Deactivate lock
            lock.setIsActive(false);
            seatLockRepository.save(lock);
            
            return true;

        } catch (Exception e) {
            System.err.println("Error releasing seat lock: " + e.getMessage());
            return false;
        }
    }

    /**
     * Confirm seat booking (convert lock to booking)
     */
    @Transactional
    public boolean confirmSeatBooking(String lockId, String bookingId, String userId) {
        try {
            // Find the lock
            SeatLock lock = seatLockRepository.findByLockId(lockId)
                .orElse(null);
            
            if (lock == null || !lock.getBookingId().equals(bookingId) || !lock.getIsActive()) {
                return false;
            }

            // Get seats to book
            List<Seat> seatsToBook = seatRepository.findByShowtimeIdAndSeatNumberIn(
                lock.getShowtimeId(), lock.getSeatNumbers());

            // Convert locks to bookings
            seatsToBook.forEach(seat -> {
                if (seat.getStatus() == SeatStatus.LOCKED && bookingId.equals(seat.getLockedBy())) {
                    seat.setStatus(SeatStatus.BOOKED);
                    seat.setBookedBy(userId);
                    seat.setBookingId(bookingId);
                    seat.setLockedBy(null);
                    seat.setLockedUntil(null);
                }
            });
            
            seatRepository.saveAll(seatsToBook);

            // Deactivate lock
            lock.setIsActive(false);
            seatLockRepository.save(lock);
            
            return true;

        } catch (Exception e) {
            System.err.println("Error confirming seat booking: " + e.getMessage());
            return false;
        }
    }

    /**
     * Check seat availability
     */
    public boolean areSeatsAvailable(String showtimeId, List<String> seatNumbers) {
        List<Seat> seats = seatRepository.findByShowtimeIdAndSeatNumberIn(showtimeId, seatNumbers);
        
        if (seats.size() != seatNumbers.size()) {
            return false; // Some seats don't exist
        }
        
        return seats.stream().allMatch(seat -> 
            seat.getStatus() == SeatStatus.AVAILABLE && !isCurrentlyLocked(seat));
    }

    /**
     * Check if seat is currently locked by active lock
     */
    private boolean isCurrentlyLocked(Seat seat) {
        if (seat.getStatus() != SeatStatus.LOCKED) {
            return false;
        }
        
        // Check if lock has expired
        if (seat.getLockedUntil() != null && seat.getLockedUntil().isBefore(LocalDateTime.now())) {
            return false;
        }
        
        return true;
    }

    /**
     * Clean up expired locks (should be run periodically)
     */
    @Transactional
    public void cleanupExpiredLocks() {
        LocalDateTime now = LocalDateTime.now();
        
        // Find expired seat locks
        List<SeatLock> expiredLocks = seatLockRepository.findExpiredLocks(now);
        
        for (SeatLock lock : expiredLocks) {
            // Get seats to unlock
            List<Seat> seatsToUnlock = seatRepository.findByShowtimeIdAndSeatNumberIn(
                lock.getShowtimeId(), lock.getSeatNumbers());

            // Update seat status
            seatsToUnlock.forEach(seat -> {
                if (seat.getStatus() == SeatStatus.LOCKED && 
                    lock.getBookingId().equals(seat.getLockedBy())) {
                    seat.setStatus(SeatStatus.AVAILABLE);
                    seat.setLockedBy(null);
                    seat.setLockedUntil(null);
                }
            });
            
            seatRepository.saveAll(seatsToUnlock);

            // Deactivate lock
            lock.setIsActive(false);
        }
        
        seatLockRepository.saveAll(expiredLocks);
    }

    /**
     * Release seats by showtime and seat numbers (for REST API convenience)
     */
    @Transactional
    public boolean releaseSeats(String showtimeId, List<String> seatNumbers) {
        try {
            // Find and release all seats for these seat numbers in this showtime
            List<Seat> seats = seatRepository.findByShowtimeIdAndSeatNumberIn(showtimeId, seatNumbers);
            
            for (Seat seat : seats) {
                if (seat.getStatus() == SeatStatus.LOCKED) {
                    seat.setStatus(SeatStatus.AVAILABLE);
                    seat.setLockedBy(null);
                    seat.setLockedUntil(null);
                }
            }
            
            seatRepository.saveAll(seats);
            
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}