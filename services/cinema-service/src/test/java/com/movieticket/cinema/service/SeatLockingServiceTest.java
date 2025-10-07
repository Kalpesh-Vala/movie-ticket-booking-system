package com.movieticket.cinema.service;

import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.SeatLock;
import com.movieticket.cinema.entity.Showtime;
import com.movieticket.cinema.repository.SeatRepository;
import com.movieticket.cinema.repository.SeatLockRepository;
import com.movieticket.cinema.repository.ShowtimeRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.context.ActiveProfiles;

import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for critical seat locking functionality
 * Tests the pessimistic locking mechanism to prevent double-bookings
 */
@ExtendWith(MockitoExtension.class)
@ActiveProfiles("test")
class SeatLockingServiceTest {

    @Mock
    private SeatRepository seatRepository;

    @Mock
    private SeatLockRepository seatLockRepository;

    @Mock
    private ShowtimeRepository showtimeRepository;

    @Mock
    private EntityManager entityManager;

    @Mock
    private TypedQuery<Seat> typedQuery;

    @InjectMocks
    private SeatLockingService seatLockingService;

    private Showtime testShowtime;
    private List<Seat> testSeats;

    @BeforeEach
    void setUp() {
        testShowtime = new Showtime();
        testShowtime.setId("showtime-1");
        testShowtime.setStartTime(LocalDateTime.now().plusHours(2));

        // Create test seats
        Seat seat1 = new Seat();
        seat1.setId("seat-1");
        seat1.setSeatNumber("A1");
        seat1.setShowtime(testShowtime);
        seat1.setBooked(false);
        seat1.setLocked(false);

        Seat seat2 = new Seat();
        seat2.setId("seat-2");
        seat2.setSeatNumber("A2");
        seat2.setShowtime(testShowtime);
        seat2.setBooked(false);
        seat2.setLocked(false);

        testSeats = Arrays.asList(seat1, seat2);
    }

    @Test
    void testLockSeats_Success() {
        // Arrange
        String showtimeId = "showtime-1";
        List<String> seatNumbers = Arrays.asList("A1", "A2");
        String bookingId = "booking-123";
        int lockDuration = 300;

        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.of(testShowtime));
        when(entityManager.createQuery(anyString(), eq(Seat.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), any())).thenReturn(typedQuery);
        when(typedQuery.setLockMode(any())).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testSeats);
        when(seatLockRepository.save(any(SeatLock.class))).thenReturn(new SeatLock());
        when(seatRepository.saveAll(any())).thenReturn(testSeats);

        // Act
        SeatLockingService.SeatLockResult result = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId, lockDuration
        );

        // Assert
        assertTrue(result.isSuccess());
        assertNotNull(result.getLockId());
        assertNotNull(result.getExpiresAt());
        assertEquals(seatNumbers, result.getSeatNumbers());

        // Verify interactions
        verify(showtimeRepository).findById(showtimeId);
        verify(entityManager).createQuery(anyString(), eq(Seat.class));
        verify(seatLockRepository, times(2)).save(any(SeatLock.class));
        verify(seatRepository).saveAll(testSeats);

        // Verify seats are marked as locked
        for (Seat seat : testSeats) {
            assertTrue(seat.isLocked());
            assertEquals(bookingId, seat.getLockedBy());
            assertNotNull(seat.getLockExpiration());
        }
    }

    @Test
    void testLockSeats_ShowtimeNotFound() {
        // Arrange
        String showtimeId = "invalid-showtime";
        List<String> seatNumbers = Arrays.asList("A1", "A2");
        String bookingId = "booking-123";

        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            seatLockingService.lockSeats(showtimeId, seatNumbers, bookingId, 300);
        });

        verify(showtimeRepository).findById(showtimeId);
        verifyNoMoreInteractions(entityManager, seatLockRepository, seatRepository);
    }

    @Test
    void testLockSeats_SeatsAlreadyBooked() {
        // Arrange
        String showtimeId = "showtime-1";
        List<String> seatNumbers = Arrays.asList("A1", "A2");
        String bookingId = "booking-123";

        // Mark one seat as already booked
        testSeats.get(0).setBooked(true);

        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.of(testShowtime));
        when(entityManager.createQuery(anyString(), eq(Seat.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), any())).thenReturn(typedQuery);
        when(typedQuery.setLockMode(any())).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testSeats);

        // Act
        SeatLockingService.SeatLockResult result = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId, 300
        );

        // Assert
        assertFalse(result.isSuccess());
        assertNull(result.getLockId());
        assertTrue(result.getMessage().contains("unavailable"));
        assertEquals(Arrays.asList("A1"), result.getFailedSeats());

        verify(showtimeRepository).findById(showtimeId);
        verify(entityManager).createQuery(anyString(), eq(Seat.class));
        verifyNoInteractions(seatLockRepository, seatRepository);
    }

    @Test
    void testLockSeats_SeatsAlreadyLocked() {
        // Arrange
        String showtimeId = "showtime-1";
        List<String> seatNumbers = Arrays.asList("A1", "A2");
        String bookingId = "booking-123";

        // Mark one seat as already locked with future expiration
        testSeats.get(0).setLocked(true);
        testSeats.get(0).setLockExpiration(LocalDateTime.now().plusMinutes(5));

        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.of(testShowtime));
        when(entityManager.createQuery(anyString(), eq(Seat.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), any())).thenReturn(typedQuery);
        when(typedQuery.setLockMode(any())).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(testSeats);

        // Act
        SeatLockingService.SeatLockResult result = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId, 300
        );

        // Assert
        assertFalse(result.isSuccess());
        assertNull(result.getLockId());
        assertTrue(result.getMessage().contains("unavailable"));
        assertEquals(Arrays.asList("A1"), result.getFailedSeats());
    }

    @Test
    void testLockSeats_ExpiredLockIsCleanedUp() {
        // Arrange
        String showtimeId = "showtime-1";
        List<String> seatNumbers = Arrays.asList("A1");
        String bookingId = "booking-123";

        // Mark seat as locked but with expired lock
        Seat expiredLockSeat = testSeats.get(0);
        expiredLockSeat.setLocked(true);
        expiredLockSeat.setLockExpiration(LocalDateTime.now().minusMinutes(1)); // Expired

        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.of(testShowtime));
        when(entityManager.createQuery(anyString(), eq(Seat.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), any())).thenReturn(typedQuery);
        when(typedQuery.setLockMode(any())).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(Arrays.asList(expiredLockSeat));
        when(seatRepository.save(any(Seat.class))).thenReturn(expiredLockSeat);
        when(seatLockRepository.save(any(SeatLock.class))).thenReturn(new SeatLock());
        when(seatRepository.saveAll(any())).thenReturn(Arrays.asList(expiredLockSeat));

        // Act
        SeatLockingService.SeatLockResult result = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId, 300
        );

        // Assert
        assertTrue(result.isSuccess());
        assertNotNull(result.getLockId());

        // Verify expired lock was cleaned up during availability check
        verify(seatRepository, atLeastOnce()).save(expiredLockSeat);
    }

    @Test
    void testReleaseSeatLock_Success() {
        // Arrange
        String lockId = "lock-123";
        String bookingId = "booking-123";

        SeatLock activeLock1 = new SeatLock();
        activeLock1.setLockId(lockId);
        activeLock1.setBookingId(bookingId);
        activeLock1.setActive(true);
        activeLock1.setSeat(testSeats.get(0));

        SeatLock activeLock2 = new SeatLock();
        activeLock2.setLockId(lockId);
        activeLock2.setBookingId(bookingId);
        activeLock2.setActive(true);
        activeLock2.setSeat(testSeats.get(1));

        List<SeatLock> activeLocks = Arrays.asList(activeLock1, activeLock2);

        when(seatLockRepository.findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId))
            .thenReturn(activeLocks);
        when(seatRepository.save(any(Seat.class))).thenReturn(new Seat());
        when(seatLockRepository.saveAll(activeLocks)).thenReturn(activeLocks);

        // Act
        boolean result = seatLockingService.releaseSeatLock(lockId, bookingId);

        // Assert
        assertTrue(result);

        // Verify locks are deactivated
        for (SeatLock lock : activeLocks) {
            assertFalse(lock.isActive());
            assertNotNull(lock.getReleasedAt());
        }

        // Verify seats are unlocked
        verify(seatRepository, times(2)).save(any(Seat.class));
        verify(seatLockRepository).saveAll(activeLocks);
    }

    @Test
    void testReleaseSeatLock_NoActiveLocks() {
        // Arrange
        String lockId = "invalid-lock";
        String bookingId = "booking-123";

        when(seatLockRepository.findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId))
            .thenReturn(Arrays.asList());

        // Act
        boolean result = seatLockingService.releaseSeatLock(lockId, bookingId);

        // Assert
        assertFalse(result);

        verify(seatLockRepository).findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId);
        verifyNoMoreInteractions(seatRepository, seatLockRepository);
    }

    @Test
    void testConfirmSeatBooking_Success() {
        // Arrange
        String lockId = "lock-123";
        String bookingId = "booking-123";
        String userId = "user-123";

        SeatLock activeLock = new SeatLock();
        activeLock.setLockId(lockId);
        activeLock.setBookingId(bookingId);
        activeLock.setActive(true);
        activeLock.setSeat(testSeats.get(0));

        when(seatLockRepository.findByLockIdAndBookingIdAndActiveTrue(lockId, bookingId))
            .thenReturn(Arrays.asList(activeLock));
        when(seatRepository.save(any(Seat.class))).thenReturn(new Seat());
        when(seatLockRepository.saveAll(any())).thenReturn(Arrays.asList(activeLock));

        // Act
        boolean result = seatLockingService.confirmSeatBooking(lockId, bookingId, userId);

        // Assert
        assertTrue(result);

        // Verify seat is marked as booked
        Seat seat = activeLock.getSeat();
        assertTrue(seat.isBooked());
        assertEquals(userId, seat.getBookedBy());
        assertNotNull(seat.getBookedAt());
        assertFalse(seat.isLocked());
        assertNull(seat.getLockedBy());

        // Verify lock is deactivated
        assertFalse(activeLock.isActive());
        assertNotNull(activeLock.getReleasedAt());
    }

    @Test
    void testConcurrentLockingScenario() {
        // This test simulates concurrent access to the same seats
        // In a real scenario, the pessimistic locking would prevent this
        // but we can test the business logic

        String showtimeId = "showtime-1";
        List<String> seatNumbers = Arrays.asList("A1");
        String bookingId1 = "booking-123";
        String bookingId2 = "booking-456";

        // First booking attempt
        when(showtimeRepository.findById(showtimeId)).thenReturn(Optional.of(testShowtime));
        when(entityManager.createQuery(anyString(), eq(Seat.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), any())).thenReturn(typedQuery);
        when(typedQuery.setLockMode(any())).thenReturn(typedQuery);
        when(typedQuery.getResultList()).thenReturn(Arrays.asList(testSeats.get(0)));
        when(seatLockRepository.save(any(SeatLock.class))).thenReturn(new SeatLock());
        when(seatRepository.saveAll(any())).thenReturn(Arrays.asList(testSeats.get(0)));

        // First booking succeeds
        SeatLockingService.SeatLockResult result1 = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId1, 300
        );

        assertTrue(result1.isSuccess());

        // Now the seat is locked, simulate second booking attempt
        testSeats.get(0).setLocked(true);
        testSeats.get(0).setLockExpiration(LocalDateTime.now().plusMinutes(5));
        
        when(typedQuery.getResultList()).thenReturn(Arrays.asList(testSeats.get(0)));

        // Second booking should fail
        SeatLockingService.SeatLockResult result2 = seatLockingService.lockSeats(
            showtimeId, seatNumbers, bookingId2, 300
        );

        assertFalse(result2.isSuccess());
        assertTrue(result2.getMessage().contains("unavailable"));
    }
}