package com.movieticket.cinema.dto;

import java.time.LocalDateTime;
import java.util.List;

public class CinemaDTO {
    private String id;
    private String name;
    private String location;
    private Integer totalScreens;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<ScreenDTO> screens;

    // Constructors
    public CinemaDTO() {}

    public CinemaDTO(String id, String name, String location, Integer totalScreens) {
        this.id = id;
        this.name = name;
        this.location = location;
        this.totalScreens = totalScreens;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Integer getTotalScreens() {
        return totalScreens;
    }

    public void setTotalScreens(Integer totalScreens) {
        this.totalScreens = totalScreens;
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

    public List<ScreenDTO> getScreens() {
        return screens;
    }

    public void setScreens(List<ScreenDTO> screens) {
        this.screens = screens;
    }
}