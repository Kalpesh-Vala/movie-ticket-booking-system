package com.movieticket.cinema.service;

import com.movieticket.cinema.entity.*;
import com.movieticket.cinema.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class CinemaService {

    @Autowired
    private CinemaRepository cinemaRepository;

    @Autowired
    private MovieRepository movieRepository;

    @Autowired
    private ScreenRepository screenRepository;

    @Autowired
    private ShowtimeRepository showtimeRepository;

    @Autowired
    private SeatRepository seatRepository;

    // Cinema operations
    public List<Cinema> getAllCinemas() {
        return cinemaRepository.findAll();
    }

    public Optional<Cinema> getCinemaById(String id) {
        return cinemaRepository.findById(id);
    }

    @Transactional
    public Cinema createCinema(Cinema cinema) {
        return cinemaRepository.save(cinema);
    }

    // Movie operations
    public List<Movie> getAllMovies() {
        return movieRepository.findAll();
    }

    public Optional<Movie> getMovieById(String id) {
        return movieRepository.findById(id);
    }

    @Transactional
    public Movie createMovie(Movie movie) {
        return movieRepository.save(movie);
    }

    // Screen operations
    public List<Screen> getScreensByCinemaId(String cinemaId) {
        return screenRepository.findByCinemaId(cinemaId);
    }

    public Optional<Screen> getScreenById(String id) {
        return screenRepository.findById(id);
    }

    // Showtime operations
    public List<Showtime> getAllShowtimes() {
        return showtimeRepository.findAll();
    }

    public Optional<Showtime> getShowtimeById(String id) {
        return showtimeRepository.findById(id);
    }

    public List<Showtime> getShowtimesByMovieId(String movieId) {
        return showtimeRepository.findByMovieId(movieId);
    }

    public List<Showtime> getShowtimesByScreenId(String screenId) {
        return showtimeRepository.findByScreenId(screenId);
    }

    @Transactional
    public Showtime createShowtime(Showtime showtime) {
        return showtimeRepository.save(showtime);
    }

    // Seat operations
    public List<Seat> getSeatsByShowtimeId(String showtimeId) {
        return seatRepository.findByShowtimeId(showtimeId);
    }

    public List<Seat> getSeatsByShowtimeIdAndStatus(String showtimeId, SeatStatus status) {
        return seatRepository.findByShowtimeIdAndStatus(showtimeId, status);
    }

    public List<Seat> getAvailableSeats(String showtimeId) {
        return seatRepository.findByShowtimeIdAndStatus(showtimeId, SeatStatus.AVAILABLE);
    }

    // Search operations
    public List<Movie> searchMoviesByTitle(String title) {
        return movieRepository.findByTitleContainingIgnoreCase(title);
    }

    public List<Showtime> searchShowtimes(String movieId, LocalDate date) {
        return showtimeRepository.findByMovieIdAndShowDate(movieId, date);
    }
}