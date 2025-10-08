package com.movieticket.cinema.dto;

import java.time.LocalDateTime;

public class ScreenDTO {
    private String id;
    private String screenNumber;
    private Integer totalSeats;
    private String cinemaId;
    private String cinemaName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Constructors
    public ScreenDTO() {}

    public ScreenDTO(String id, String screenNumber, Integer totalSeats, String cinemaId) {
        this.id = id;
        this.screenNumber = screenNumber;
        this.totalSeats = totalSeats;
        this.cinemaId = cinemaId;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getScreenNumber() {
        return screenNumber;
    }

    public void setScreenNumber(String screenNumber) {
        this.screenNumber = screenNumber;
    }

    public Integer getTotalSeats() {
        return totalSeats;
    }

    public void setTotalSeats(Integer totalSeats) {
        this.totalSeats = totalSeats;
    }

    public String getCinemaId() {
        return cinemaId;
    }

    public void setCinemaId(String cinemaId) {
        this.cinemaId = cinemaId;
    }

    public String getCinemaName() {
        return cinemaName;
    }

    public void setCinemaName(String cinemaName) {
        this.cinemaName = cinemaName;
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
}