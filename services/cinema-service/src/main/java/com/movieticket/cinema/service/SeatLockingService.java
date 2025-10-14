package com.movieticket.cinema.service;

import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.SeatLock;
import com.movieticket.cinema.repository.SeatRepository;
import com.movieticket.cinema.repository.SeatLockRepository;
import com.movieticket.cinema.repository.ShowtimeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
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
     * This method uses pessimistic locking to ensure atomic seat reservation
     */
    @Transactional
    public SeatLockResult lockSeats(String showtimeId, List<String> seatNumbers, 
                                   String bookingId, int lockDurationSeconds) {
        
        // Validate showtime exists
        showtimeRepository.findById(showtimeId)
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
                .filter(seat -> seat.getIsBooked() || isCurrentlyLocked(seat))
                .map(Seat::getSeatNumber)
                .collect(Collectors.toList());

            if (!unavailableSeats.isEmpty()) {
                return new SeatLockResult(false, null, null, unavailableSeats, "Seats unavailable: " + unavailableSeats);
            }

            // Create seat lock records - one for each seat
            String lockId = UUID.randomUUID().toString();
            List<SeatLock> seatLocks = new ArrayList<>();
            
            for (Seat seat : seatsToLock) {
                SeatLock seatLock = new SeatLock(lockId, seat.getId(), bookingId, showtimeId, lockExpiration);
                seatLocks.add(seatLock);
            }
            
            seatLockRepository.saveAll(seatLocks);

            // Update seat status to locked
            seatsToLock.forEach(seat -> {
                seat.setIsLocked(true);
                seat.setIsBooked(false);
                seat.setLockedBy(bookingId);
                seat.setLockExpiration(lockExpiration);
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
            // Find all locks with this lockId and bookingId
            List<SeatLock> locks = seatLockRepository.findByBookingId(bookingId).stream()
                .filter(lock -> lockId.equals(lock.getLockId()) && lock.getIsActive())
                .collect(Collectors.toList());
            
            if (locks.isEmpty()) {
                return false;
            }

            // Get seat IDs to unlock
            List<String> seatIds = locks.stream()
                .map(SeatLock::getSeatId)
                .collect(Collectors.toList());
            
            List<Seat> seatsToUnlock = seatRepository.findAllById(seatIds);

            // Update seat status
            seatsToUnlock.forEach(seat -> {
                if (seat.getIsLocked() && bookingId.equals(seat.getLockedBy())) {
                    seat.setIsLocked(false);
                    seat.setLockedBy(null);
                    seat.setLockExpiration(null);
                }
            });
            
            seatRepository.saveAll(seatsToUnlock);

            // Deactivate locks
            locks.forEach(lock -> {
                lock.setIsActive(false);
                lock.setReleasedAt(LocalDateTime.now());
            });
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
            // Find all locks with this lockId and bookingId
            List<SeatLock> locks = seatLockRepository.findByBookingId(bookingId).stream()
                .filter(lock -> lockId.equals(lock.getLockId()) && lock.getIsActive())
                .collect(Collectors.toList());
            
            if (locks.isEmpty()) {
                return false;
            }

            // Get seat IDs to book
            List<String> seatIds = locks.stream()
                .map(SeatLock::getSeatId)
                .collect(Collectors.toList());
            
            List<Seat> seatsToBook = seatRepository.findAllById(seatIds);

            // Convert locks to bookings
            seatsToBook.forEach(seat -> {
                if (seat.getIsLocked() && bookingId.equals(seat.getLockedBy())) {
                    seat.setIsBooked(true);
                    seat.setIsLocked(false);
                    seat.setBookedBy(userId);
                    seat.setBookedAt(LocalDateTime.now());
                    seat.setLockedBy(null);
                    seat.setLockExpiration(null);
                }
            });
            
            seatRepository.saveAll(seatsToBook);

            // Deactivate locks
            locks.forEach(lock -> {
                lock.setIsActive(false);
                lock.setReleasedAt(LocalDateTime.now());
            });
            seatLockRepository.saveAll(locks);
            
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
            !seat.getIsBooked() && !seat.getIsLocked());
    }

    /**
     * Check if seat is currently locked by active lock
     */
    private boolean isCurrentlyLocked(Seat seat) {
        if (!seat.getIsLocked()) {
            return false;
        }
        
        // Check if lock has expired
        if (seat.getLockExpiration() != null && seat.getLockExpiration().isBefore(LocalDateTime.now())) {
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
            // Get seat to unlock
            Seat seatToUnlock = seatRepository.findById(lock.getSeatId()).orElse(null);

            if (seatToUnlock != null && seatToUnlock.getIsLocked() && 
                lock.getBookingId().equals(seatToUnlock.getLockedBy())) {
                seatToUnlock.setIsLocked(false);
                seatToUnlock.setLockedBy(null);
                seatToUnlock.setLockExpiration(null);
                seatRepository.save(seatToUnlock);
            }

            // Deactivate lock
            lock.setIsActive(false);
            lock.setReleasedAt(now);
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
                if (seat.getIsLocked()) {
                    seat.setIsLocked(false);
                    seat.setLockedBy(null);
                    seat.setLockExpiration(null);
                }
            }
            
            seatRepository.saveAll(seats);
            
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get locked seats for a showtime, optionally filtered by user ID
     */
    public List<SeatLock> getLockedSeats(String showtimeId, String userId) {
        if (userId != null && !userId.isEmpty()) {
            return seatLockRepository.findActiveByShowtimeIdAndBookingId(showtimeId, userId);
        } else {
            return seatLockRepository.findActiveByShowtimeId(showtimeId);
        }
    }
}