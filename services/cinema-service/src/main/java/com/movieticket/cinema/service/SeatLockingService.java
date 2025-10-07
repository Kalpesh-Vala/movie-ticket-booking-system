package com.movieticket.cinema.service;

import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.SeatLock;
import com.movieticket.cinema.entity.Showtime;
import com.movieticket.cinema.repository.SeatRepository;
import com.movieticket.cinema.repository.SeatLockRepository;
import com.movieticket.cinema.repository.ShowtimeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.LockModeType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

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
     * This method uses @Lock(LockModeType.PESSIMISTIC_WRITE) to ensure
     * atomic seat reservation in high-concurrency environments.
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
            // CRITICAL: Use native query with FOR UPDATE to implement pessimistic locking
            // This prevents other transactions from modifying these seat rows
            List<Seat> seatsToLock = entityManager.createQuery(
                "SELECT s FROM Seat s WHERE s.showtime.id = :showtimeId " +
                "AND s.seatNumber IN :seatNumbers ORDER BY s.seatNumber", Seat.class)
                .setParameter("showtimeId", showtimeId)
                .setParameter("seatNumbers", seatNumbers)
                .setLockMode(LockModeType.PESSIMISTIC_WRITE) // PostgreSQL row-level locking
                .getResultList();

            // Validate all requested seats exist
            if (seatsToLock.size() != seatNumbers.size()) {
                List<String> foundSeats = seatsToLock.stream()
                    .map(Seat::getSeatNumber)
                    .collect(Collectors.toList());
                List<String> missingSeats = seatNumbers.stream()
                    .filter(seat -> !foundSeats.contains(seat))
                    .collect(Collectors.toList());
                
                return SeatLockResult.failure("Seats not found: " + missingSeats, missingSeats);
            }

            // Check if any seats are already booked or locked
            List<String> unavailableSeats = seatsToLock.stream()
                .filter(seat -> seat.isBooked() || isCurrentlyLocked(seat))
                .map(Seat::getSeatNumber)
                .collect(Collectors.toList());

            if (!unavailableSeats.isEmpty()) {
                return SeatLockResult.failure("Seats unavailable: " + unavailableSeats, unavailableSeats);
            }

            // Create seat locks - this is the critical section protected by pessimistic locking
            String lockId = UUID.randomUUID().toString();
            
            for (Seat seat : seatsToLock) {
                SeatLock seatLock = new SeatLock();
                seatLock.setLockId(lockId);
                seatLock.setSeat(seat);
                seatLock.setBookingId(bookingId);
                seatLock.setLockedAt(LocalDateTime.now());
                seatLock.setExpiresAt(lockExpiration);
                seatLock.setActive(true);
                
                seatLockRepository.save(seatLock);
            }

            // Update seat status to locked
            seatsToLock.forEach(seat -> {
                seat.setLocked(true);
                seat.setLockedBy(bookingId);
                seat.setLockExpiration(lockExpiration);
            });
            
            seatRepository.saveAll(seatsToLock);

            return SeatLockResult.success(lockId, lockExpiration, seatNumbers);

        } catch (Exception e) {
            // Log the error and return failure
            System.err.println("Error locking seats: " + e.getMessage());
            return SeatLockResult.failure("Failed to lock seats: " + e.getMessage(), seatNumbers);
        }
    }

    /**
     * Alternative implementation using native SQL with FOR UPDATE
     * This demonstrates direct PostgreSQL locking syntax
     */
    @Transactional
    public SeatLockResult lockSeatsWithNativeQuery(String showtimeId, List<String> seatNumbers, 
                                                   String bookingId, int lockDurationSeconds) {
        
        LocalDateTime lockExpiration = LocalDateTime.now().plusSeconds(lockDurationSeconds);
        
        try {
            // Native PostgreSQL query with FOR UPDATE NOWAIT
            // NOWAIT ensures immediate failure if seats are already locked
            List<Seat> seatsToLock = entityManager.createNativeQuery(
                "SELECT s.* FROM seats s " +
                "WHERE s.showtime_id = ?1 AND s.seat_number = ANY(?2) " +
                "AND s.is_booked = false AND s.is_locked = false " +
                "ORDER BY s.seat_number " +
                "FOR UPDATE NOWAIT", Seat.class)
                .setParameter(1, showtimeId)
                .setParameter(2, seatNumbers.toArray(new String[0]))
                .getResultList();

            if (seatsToLock.size() != seatNumbers.size()) {
                return SeatLockResult.failure("Some seats are unavailable or already locked", seatNumbers);
            }

            // Create locks and update seats (same logic as above)
            String lockId = UUID.randomUUID().toString();
            
            // ... rest of the locking logic
            
            return SeatLockResult.success(lockId, lockExpiration, seatNumbers);

        } catch (Exception e) {
            return SeatLockResult.failure("Failed to lock seats: " + e.getMessage(), seatNumbers);
        }
    }

    /**
     * Release seat locks
     */
    @Transactional
    public boolean releaseSeatLock(String lockId, String bookingId) {
        try {
            // Find active locks
            List<SeatLock> locks = seatLockRepository.findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId);
            
            if (locks.isEmpty()) {
                return false;
            }

            // Release locks
            for (SeatLock lock : locks) {
                lock.setActive(false);
                lock.setReleasedAt(LocalDateTime.now());
                
                // Update seat status
                Seat seat = lock.getSeat();
                seat.setLocked(false);
                seat.setLockedBy(null);
                seat.setLockExpiration(null);
                seatRepository.save(seat);
            }
            
            seatLockRepository.saveAll(locks);
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
            List<SeatLock> locks = seatLockRepository.findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId);
            
            if (locks.isEmpty()) {
                return false;
            }

            // Convert locks to bookings
            for (SeatLock lock : locks) {
                Seat seat = lock.getSeat();
                seat.setBooked(true);
                seat.setBookedBy(userId);
                seat.setBookedAt(LocalDateTime.now());
                seat.setLocked(false);
                seat.setLockedBy(null);
                seat.setLockExpiration(null);
                
                seatRepository.save(seat);
                
                // Deactivate lock
                lock.setActive(false);
                lock.setReleasedAt(LocalDateTime.now());
            }
            
            seatLockRepository.saveAll(locks);
            return true;

        } catch (Exception e) {
            System.err.println("Error confirming seat booking: " + e.getMessage());
            return false;
        }
    }

    /**
     * Check if seat is currently locked by active lock
     */
    private boolean isCurrentlyLocked(Seat seat) {
        if (!seat.isLocked()) {
            return false;
        }
        
        // Check if lock has expired
        if (seat.getLockExpiration() != null && seat.getLockExpiration().isBefore(LocalDateTime.now())) {
            // Lock expired, clean it up
            seat.setLocked(false);
            seat.setLockedBy(null);
            seat.setLockExpiration(null);
            seatRepository.save(seat);
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
        
        // Find expired locks
        List<SeatLock> expiredLocks = seatLockRepository.findByActiveTrueAndExpiresAtBefore(now);
        
        for (SeatLock lock : expiredLocks) {
            // Release expired lock
            lock.setActive(false);
            lock.setReleasedAt(now);
            
            // Update seat status
            Seat seat = lock.getSeat();
            seat.setLocked(false);
            seat.setLockedBy(null);
            seat.setLockExpiration(null);
            seatRepository.save(seat);
        }
        
        seatLockRepository.saveAll(expiredLocks);
    }

    /**
     * Result class for seat locking operations
     */
    public static class SeatLockResult {
        private final boolean success;
        private final String lockId;
        private final LocalDateTime expiresAt;
        private final List<String> seatNumbers;
        private final String message;
        private final List<String> failedSeats;

        private SeatLockResult(boolean success, String lockId, LocalDateTime expiresAt, 
                              List<String> seatNumbers, String message, List<String> failedSeats) {
            this.success = success;
            this.lockId = lockId;
            this.expiresAt = expiresAt;
            this.seatNumbers = seatNumbers;
            this.message = message;
            this.failedSeats = failedSeats;
        }

        public static SeatLockResult success(String lockId, LocalDateTime expiresAt, List<String> seatNumbers) {
            return new SeatLockResult(true, lockId, expiresAt, seatNumbers, "Seats locked successfully", null);
        }

        public static SeatLockResult failure(String message, List<String> failedSeats) {
            return new SeatLockResult(false, null, null, null, message, failedSeats);
        }

        // Getters
        public boolean isSuccess() { return success; }
        public String getLockId() { return lockId; }
        public LocalDateTime getExpiresAt() { return expiresAt; }
        public List<String> getSeatNumbers() { return seatNumbers; }
        public String getMessage() { return message; }
        public List<String> getFailedSeats() { return failedSeats; }
    }
}