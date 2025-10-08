package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.Movie;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MovieRepository extends JpaRepository<Movie, String> {
    List<Movie> findByTitleContainingIgnoreCase(String title);
}