package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.Screen;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ScreenRepository extends JpaRepository<Screen, String> {
    List<Screen> findByCinemaId(String cinemaId);
}