package com.movieticket.cinema.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDateTime;

@Entity
@Table(name = "seats")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Seat {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "seat_number", nullable = false)
    private String seatNumber;

    @Column(name = "is_booked")
    private Boolean isBooked = false;

    @Column(name = "is_locked")
    private Boolean isLocked = false;

    @Column(name = "locked_by")
    private String lockedBy;

    @Column(name = "lock_expiration")
    private LocalDateTime lockExpiration;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "booked_by")
    private String bookedBy;

    @Column(name = "booked_at")
    private LocalDateTime bookedAt;

    @Column(name = "booking_id")
    private String bookingId;

    @Column(name = "seat_type")
    private String seatType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "showtime_id", nullable = false)
    @JsonIgnore
    private Showtime showtime;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructors
    public Seat() {
        this.isBooked = false;
        this.isLocked = false;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Seat(String seatNumber, Showtime showtime) {
        this();
        this.seatNumber = seatNumber;
        this.showtime = showtime;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getSeatNumber() {
        return seatNumber;
    }

    public void setSeatNumber(String seatNumber) {
        this.seatNumber = seatNumber;
    }

    public Boolean getIsBooked() {
        return isBooked;
    }

    public void setIsBooked(Boolean isBooked) {
        this.isBooked = isBooked;
        if (isBooked) {
            this.updatedAt = LocalDateTime.now();
        }
    }

    public Boolean getIsLocked() {
        return isLocked;
    }

    public void setIsLocked(Boolean isLocked) {
        this.isLocked = isLocked;
        this.updatedAt = LocalDateTime.now();
    }

    public String getSeatType() {
        return seatType;
    }

    public void setSeatType(String seatType) {
        this.seatType = seatType;
    }

    public String getLockedBy() {
        return lockedBy;
    }

    public void setLockedBy(String lockedBy) {
        this.lockedBy = lockedBy;
    }

    public LocalDateTime getLockedUntil() {
        return lockedUntil;
    }

    public void setLockedUntil(LocalDateTime lockedUntil) {
        this.lockedUntil = lockedUntil;
    }

    public String getBookedBy() {
        return bookedBy;
    }

    public void setBookedBy(String bookedBy) {
        this.bookedBy = bookedBy;
    }

    public String getBookingId() {
        return bookingId;
    }

    public void setBookingId(String bookingId) {
        this.bookingId = bookingId;
    }

    public Showtime getShowtime() {
        return showtime;
    }

    public void setShowtime(Showtime showtime) {
        this.showtime = showtime;
    }

    public LocalDateTime getLockExpiration() {
        return lockExpiration;
    }

    public void setLockExpiration(LocalDateTime lockExpiration) {
        this.lockExpiration = lockExpiration;
    }

    public LocalDateTime getBookedAt() {
        return bookedAt;
    }

    public void setBookedAt(LocalDateTime bookedAt) {
        this.bookedAt = bookedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Business logic methods
    public boolean isAvailable() {
        return !isBooked && !isLocked;
    }

    public boolean isBooked() {
        return isBooked;
    }

    public boolean isLocked() {
        return isLocked;
    }

    public boolean isLockExpired() {
        return lockExpiration != null && LocalDateTime.now().isAfter(lockExpiration);
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}