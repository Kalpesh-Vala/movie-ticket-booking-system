package com.movieticket.cinema.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class CreateShowtimeRequest {
    private String movieId;
    private String screenId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BigDecimal price;

    // Constructors
    public CreateShowtimeRequest() {}

    public CreateShowtimeRequest(String movieId, String screenId, LocalDateTime startTime, LocalDateTime endTime, BigDecimal price) {
        this.movieId = movieId;
        this.screenId = screenId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.price = price;
    }

    // Getters and Setters
    public String getMovieId() {
        return movieId;
    }

    public void setMovieId(String movieId) {
        this.movieId = movieId;
    }

    public String getScreenId() {
        return screenId;
    }

    public void setScreenId(String screenId) {
        this.screenId = screenId;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }
}