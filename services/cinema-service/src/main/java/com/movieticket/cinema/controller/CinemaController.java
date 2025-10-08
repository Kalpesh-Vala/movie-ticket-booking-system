package com.movieticket.cinema.controller;

import com.movieticket.cinema.entity.*;
import com.movieticket.cinema.service.CinemaService;
import com.movieticket.cinema.service.SeatLockingService;
import com.movieticket.cinema.service.SeatLockResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
public class CinemaController {

    @Autowired
    private CinemaService cinemaService;

    @Autowired
    private SeatLockingService seatLockingService;

    // Cinema endpoints
    @GetMapping("/cinemas")
    public ResponseEntity<List<Cinema>> getAllCinemas() {
        List<Cinema> cinemas = cinemaService.getAllCinemas();
        return ResponseEntity.ok(cinemas);
    }

    @GetMapping("/cinemas/{id}")
    public ResponseEntity<Cinema> getCinemaById(@PathVariable String id) {
        Optional<Cinema> cinema = cinemaService.getCinemaById(id);
        return cinema.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/cinemas")
    public ResponseEntity<Cinema> createCinema(@RequestBody Cinema cinema) {
        Cinema savedCinema = cinemaService.createCinema(cinema);
        return ResponseEntity.ok(savedCinema);
    }

    // Movie endpoints
    @GetMapping("/movies")
    public ResponseEntity<List<Movie>> getAllMovies() {
        List<Movie> movies = cinemaService.getAllMovies();
        return ResponseEntity.ok(movies);
    }

    @GetMapping("/movies/{id}")
    public ResponseEntity<Movie> getMovieById(@PathVariable String id) {
        Optional<Movie> movie = cinemaService.getMovieById(id);
        return movie.map(ResponseEntity::ok)
                   .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/movies")
    public ResponseEntity<Movie> createMovie(@RequestBody Movie movie) {
        Movie savedMovie = cinemaService.createMovie(movie);
        return ResponseEntity.ok(savedMovie);
    }

    // Showtime endpoints
    @GetMapping("/showtimes")
    public ResponseEntity<List<Showtime>> getAllShowtimes() {
        List<Showtime> showtimes = cinemaService.getAllShowtimes();
        return ResponseEntity.ok(showtimes);
    }

    @GetMapping("/showtimes/{id}")
    public ResponseEntity<Showtime> getShowtimeById(@PathVariable String id) {
        Optional<Showtime> showtime = cinemaService.getShowtimeById(id);
        return showtime.map(ResponseEntity::ok)
                      .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/showtimes/movie/{movieId}")
    public ResponseEntity<List<Showtime>> getShowtimesByMovieId(@PathVariable String movieId) {
        List<Showtime> showtimes = cinemaService.getShowtimesByMovieId(movieId);
        return ResponseEntity.ok(showtimes);
    }

    @PostMapping("/showtimes")
    public ResponseEntity<Showtime> createShowtime(@RequestBody Showtime showtime) {
        Showtime savedShowtime = cinemaService.createShowtime(showtime);
        return ResponseEntity.ok(savedShowtime);
    }

    // Health check endpoint
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Cinema Service is running");
    }

    // Additional Cinema endpoints
    @GetMapping("/cinemas/{cinemaId}/screens")
    public ResponseEntity<List<Screen>> getScreensByCinemaId(@PathVariable String cinemaId) {
        List<Screen> screens = cinemaService.getScreensByCinemaId(cinemaId);
        return ResponseEntity.ok(screens);
    }

    // Screen endpoints
    @GetMapping("/screens/{id}")
    public ResponseEntity<Screen> getScreenById(@PathVariable String id) {
        Optional<Screen> screen = cinemaService.getScreenById(id);
        return screen.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/screens/{screenId}/showtimes")
    public ResponseEntity<List<Showtime>> getShowtimesByScreenId(@PathVariable String screenId) {
        List<Showtime> showtimes = cinemaService.getShowtimesByScreenId(screenId);
        return ResponseEntity.ok(showtimes);
    }

    // Seat endpoints
    @GetMapping("/showtimes/{showtimeId}/seats")
    public ResponseEntity<List<Seat>> getSeatsByShowtimeId(
            @PathVariable String showtimeId,
            @RequestParam(required = false) SeatStatus status) {
        List<Seat> seats;
        if (status != null) {
            seats = cinemaService.getSeatsByShowtimeIdAndStatus(showtimeId, status);
        } else {
            seats = cinemaService.getSeatsByShowtimeId(showtimeId);
        }
        return ResponseEntity.ok(seats);
    }

    @GetMapping("/showtimes/{showtimeId}/seats/available")
    public ResponseEntity<List<Seat>> getAvailableSeats(@PathVariable String showtimeId) {
        List<Seat> availableSeats = cinemaService.getAvailableSeats(showtimeId);
        return ResponseEntity.ok(availableSeats);
    }

    // Seat locking endpoints
    @PostMapping("/showtimes/{showtimeId}/seats/lock")
    public ResponseEntity<String> lockSeats(
            @PathVariable String showtimeId,
            @RequestBody List<String> seatNumbers,
            @RequestParam(defaultValue = "anonymous") String userId,
            @RequestParam(defaultValue = "300") int lockDurationSeconds) {
        try {
            SeatLockResult result = seatLockingService.lockSeats(showtimeId, seatNumbers, userId, lockDurationSeconds);
            if (result.isSuccess()) {
                return ResponseEntity.ok("Seats locked successfully. Lock ID: " + result.getLockId());
            } else {
                return ResponseEntity.badRequest().body("Failed to lock seats: " + result.getMessage());
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        }
    }

    @PostMapping("/showtimes/{showtimeId}/seats/release")
    public ResponseEntity<String> releaseSeats(
            @PathVariable String showtimeId,
            @RequestBody List<String> seatNumbers) {
        try {
            boolean success = seatLockingService.releaseSeats(showtimeId, seatNumbers);
            if (success) {
                return ResponseEntity.ok("Seats released successfully");
            } else {
                return ResponseEntity.badRequest().body("Failed to release seats");
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error: " + e.getMessage());
        }
    }

    // Search endpoints
    @GetMapping("/movies/search")
    public ResponseEntity<List<Movie>> searchMovies(@RequestParam String title) {
        List<Movie> movies = cinemaService.searchMoviesByTitle(title);
        return ResponseEntity.ok(movies);
    }

    @GetMapping("/showtimes/search")
    public ResponseEntity<List<Showtime>> searchShowtimes(
            @RequestParam(required = false) String movieId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<Showtime> showtimes;
        if (movieId != null && date != null) {
            showtimes = cinemaService.searchShowtimes(movieId, date);
        } else if (movieId != null) {
            showtimes = cinemaService.getShowtimesByMovieId(movieId);
        } else {
            showtimes = cinemaService.getAllShowtimes();
        }
        return ResponseEntity.ok(showtimes);
    }
}