package com.movieticket.cinema.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "seat_locks")
public class SeatLock {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "lock_id", unique = true, nullable = false)
    private String lockId;

    @Column(name = "booking_id", nullable = false)
    private String bookingId;

    @Column(name = "showtime_id", nullable = false)
    private String showtimeId;

    @ElementCollection
    @CollectionTable(name = "seat_lock_seats", joinColumns = @JoinColumn(name = "seat_lock_id"))
    @Column(name = "seat_number")
    private List<String> seatNumbers;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "is_active")
    private Boolean isActive;

    // Constructors
    public SeatLock() {
        this.createdAt = LocalDateTime.now();
        this.isActive = true;
    }

    public SeatLock(String lockId, String bookingId, String showtimeId, List<String> seatNumbers, LocalDateTime expiresAt) {
        this();
        this.lockId = lockId;
        this.bookingId = bookingId;
        this.showtimeId = showtimeId;
        this.seatNumbers = seatNumbers;
        this.expiresAt = expiresAt;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getLockId() {
        return lockId;
    }

    public void setLockId(String lockId) {
        this.lockId = lockId;
    }

    public String getBookingId() {
        return bookingId;
    }

    public void setBookingId(String bookingId) {
        this.bookingId = bookingId;
    }

    public String getShowtimeId() {
        return showtimeId;
    }

    public void setShowtimeId(String showtimeId) {
        this.showtimeId = showtimeId;
    }

    public List<String> getSeatNumbers() {
        return seatNumbers;
    }

    public void setSeatNumbers(List<String> seatNumbers) {
        this.seatNumbers = seatNumbers;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(this.expiresAt);
    }
}