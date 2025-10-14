package com.movieticket.cinema.repository;

import com.movieticket.cinema.entity.Showtime;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShowtimeRepository extends JpaRepository<Showtime, String> {
    
    List<Showtime> findByMovieId(String movieId);
    
    List<Showtime> findByScreenId(String screenId);
    
    @Query("SELECT s FROM Showtime s WHERE s.startTime >= :startTime AND s.startTime <= :endTime")
    List<Showtime> findByStartTimeBetween(@Param("startTime") LocalDateTime startTime, 
                                        @Param("endTime") LocalDateTime endTime);
    
    @Query("SELECT s FROM Showtime s WHERE s.movie.id = :movieId AND DATE(s.startTime) = :date")
    List<Showtime> findByMovieIdAndShowDate(@Param("movieId") String movieId, @Param("date") LocalDate date);
    
    @Query("SELECT s FROM Showtime s " +
           "LEFT JOIN FETCH s.movie " +
           "LEFT JOIN FETCH s.screen sc " +
           "LEFT JOIN FETCH sc.cinema " +
           "WHERE s.id = :id")
    Optional<Showtime> findByIdWithDetails(@Param("id") String id);
}