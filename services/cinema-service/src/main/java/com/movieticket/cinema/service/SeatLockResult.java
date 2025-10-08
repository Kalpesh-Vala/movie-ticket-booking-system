package com.movieticket.cinema.service;

import java.time.LocalDateTime;
import java.util.List;

public class SeatLockResult {
    private boolean success;
    private String lockId;
    private LocalDateTime expiresAt;
    private List<String> failedSeats;
    private String message;

    public SeatLockResult(boolean success, String message) {
        this.success = success;
        this.message = message;
    }

    public SeatLockResult(boolean success, String lockId, LocalDateTime expiresAt, String message) {
        this.success = success;
        this.lockId = lockId;
        this.expiresAt = expiresAt;
        this.message = message;
    }

    public SeatLockResult(boolean success, String lockId, LocalDateTime expiresAt, List<String> failedSeats, String message) {
        this.success = success;
        this.lockId = lockId;
        this.expiresAt = expiresAt;
        this.failedSeats = failedSeats;
        this.message = message;
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getLockId() {
        return lockId;
    }

    public void setLockId(String lockId) {
        this.lockId = lockId;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public List<String> getFailedSeats() {
        return failedSeats;
    }

    public void setFailedSeats(List<String> failedSeats) {
        this.failedSeats = failedSeats;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}