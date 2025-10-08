package com.movieticket.cinema.grpc;

import com.movieticket.cinema.grpc.CinemaServiceProto.*;
import com.movieticket.cinema.grpc.CinemaServiceGrpc.CinemaServiceImplBase;
import com.movieticket.cinema.entity.Seat;
import com.movieticket.cinema.entity.Showtime;
import com.movieticket.cinema.entity.Movie;
import com.movieticket.cinema.entity.Cinema;
import com.movieticket.cinema.entity.SeatStatus;
import com.movieticket.cinema.service.SeatLockingService;
import com.movieticket.cinema.service.CinemaService;
import com.movieticket.cinema.service.SeatLockResult;
import com.movieticket.cinema.repository.SeatRepository;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CinemaServiceImpl extends CinemaServiceImplBase {

    @Autowired
    private SeatLockingService seatLockingService;

    @Autowired
    private CinemaService cinemaService;

    @Autowired
    private SeatRepository seatRepository;

    @Override
    public void checkSeatAvailability(SeatAvailabilityRequest request, 
                                    StreamObserver<SeatAvailabilityResponse> responseObserver) {
        try {
            String showtimeId = request.getShowtimeId();
            List<String> seatNumbers = request.getSeatNumbersList();

            boolean available = seatLockingService.areSeatsAvailable(showtimeId, seatNumbers);
            
            SeatAvailabilityResponse.Builder responseBuilder = SeatAvailabilityResponse.newBuilder()
                .setAvailable(available);

            if (!available) {
                // Get details of unavailable seats
                List<Seat> seats = seatRepository.findByShowtimeIdAndSeatNumberIn(showtimeId, seatNumbers);
                List<SeatInfo> unavailableSeats = seats.stream()
                    .filter(seat -> seat.getStatus() != SeatStatus.AVAILABLE)
                    .map(this::convertToSeatInfo)
                    .collect(Collectors.toList());
                
                responseBuilder.addAllUnavailableSeats(unavailableSeats)
                    .setMessage("Some seats are not available");
            } else {
                responseBuilder.setMessage("All seats are available");
            }

            responseObserver.onNext(responseBuilder.build());
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                .withDescription("Error checking seat availability: " + e.getMessage())
                .asException());
        }
    }

    @Override
    public void lockSeats(LockSeatsRequest request, StreamObserver<LockSeatsResponse> responseObserver) {
        try {
            String showtimeId = request.getShowtimeId();
            List<String> seatNumbers = request.getSeatNumbersList();
            String bookingId = request.getBookingId();
            int lockDurationSeconds = request.getLockDurationSeconds() > 0 ? 
                request.getLockDurationSeconds() : 300; // Default 5 minutes

            SeatLockResult result = seatLockingService.lockSeats(showtimeId, seatNumbers, 
                                                               bookingId, lockDurationSeconds);

            LockSeatsResponse.Builder responseBuilder = LockSeatsResponse.newBuilder()
                .setSuccess(result.isSuccess())
                .setMessage(result.getMessage());

            if (result.isSuccess()) {
                responseBuilder.setLockId(result.getLockId())
                    .setExpiresAt(result.getExpiresAt().toEpochSecond(ZoneOffset.UTC));
            } else if (result.getFailedSeats() != null) {
                responseBuilder.addAllFailedSeats(result.getFailedSeats());
            }

            responseObserver.onNext(responseBuilder.build());
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                .withDescription("Error locking seats: " + e.getMessage())
                .asException());
        }
    }

    @Override
    public void releaseSeatLock(ReleaseSeatLockRequest request, 
                              StreamObserver<ReleaseSeatLockResponse> responseObserver) {
        try {
            String lockId = request.getLockId();
            String bookingId = request.getBookingId();

            boolean success = seatLockingService.releaseSeatLock(lockId, bookingId);

            ReleaseSeatLockResponse response = ReleaseSeatLockResponse.newBuilder()
                .setSuccess(success)
                .setMessage(success ? "Seat lock released successfully" : "Failed to release seat lock")
                .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                .withDescription("Error releasing seat lock: " + e.getMessage())
                .asException());
        }
    }

    @Override
    public void confirmSeatBooking(ConfirmSeatBookingRequest request, 
                                 StreamObserver<ConfirmSeatBookingResponse> responseObserver) {
        try {
            String lockId = request.getLockId();
            String bookingId = request.getBookingId();
            String userId = request.getUserId();

            boolean success = seatLockingService.confirmSeatBooking(lockId, bookingId, userId);

            ConfirmSeatBookingResponse.Builder responseBuilder = ConfirmSeatBookingResponse.newBuilder()
                .setSuccess(success);

            if (success) {
                // Get confirmed seats for response
                // This is a simplified implementation - in reality you'd get the actual seat numbers
                responseBuilder.setMessage("Booking confirmed successfully");
            } else {
                responseBuilder.setMessage("Failed to confirm booking");
            }

            responseObserver.onNext(responseBuilder.build());
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                .withDescription("Error confirming seat booking: " + e.getMessage())
                .asException());
        }
    }

    @Override
    public void getShowtimeDetails(ShowtimeDetailsRequest request, 
                                 StreamObserver<ShowtimeDetailsResponse> responseObserver) {
        try {
            String showtimeId = request.getShowtimeId();

            Optional<Showtime> showtimeOpt = cinemaService.getShowtimeById(showtimeId);
            if (!showtimeOpt.isPresent()) {
                responseObserver.onError(Status.NOT_FOUND
                    .withDescription("Showtime not found")
                    .asException());
                return;
            }

            Showtime showtime = showtimeOpt.get();
            ShowtimeInfo showtimeInfo = convertToShowtimeInfo(showtime);
            MovieInfo movieInfo = convertToMovieInfo(showtime.getMovie());
            CinemaInfo cinemaInfo = convertToCinemaInfo(showtime.getScreen().getCinema());

            ShowtimeDetailsResponse response = ShowtimeDetailsResponse.newBuilder()
                .setShowtime(showtimeInfo)
                .setMovie(movieInfo)
                .setCinema(cinemaInfo)
                .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(Status.INTERNAL
                .withDescription("Error getting showtime details: " + e.getMessage())
                .asException());
        }
    }

    // Helper methods to convert entities to protobuf messages
    private SeatInfo convertToSeatInfo(Seat seat) {
        SeatInfo.Builder builder = SeatInfo.newBuilder()
            .setSeatNumber(seat.getSeatNumber())
            .setStatus(convertSeatStatus(seat.getStatus()));

        if (seat.getLockedBy() != null) {
            builder.setLockedBy(seat.getLockedBy());
        }
        if (seat.getLockedUntil() != null) {
            builder.setLockedUntil(seat.getLockedUntil().toEpochSecond(ZoneOffset.UTC));
        }

        return builder.build();
    }

    private com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus convertSeatStatus(SeatStatus status) {
        switch (status) {
            case AVAILABLE:
                return com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus.AVAILABLE;
            case LOCKED:
                return com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus.LOCKED;
            case BOOKED:
                return com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus.BOOKED;
            case MAINTENANCE:
                return com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus.MAINTENANCE;
            default:
                return com.movieticket.cinema.grpc.CinemaServiceProto.SeatStatus.AVAILABLE;
        }
    }

    private ShowtimeInfo convertToShowtimeInfo(Showtime showtime) {
        return ShowtimeInfo.newBuilder()
            .setId(showtime.getId())
            .setMovieId(showtime.getMovie().getId())
            .setCinemaId(showtime.getScreen().getCinema().getId())
            .setStartTime(showtime.getStartTime().toEpochSecond(ZoneOffset.UTC))
            .setEndTime(showtime.getEndTime().toEpochSecond(ZoneOffset.UTC))
            .setBasePrice(showtime.getBasePrice().doubleValue())
            .setTotalSeats(showtime.getTotalSeats())
            .setAvailableSeats(showtime.getAvailableSeats())
            .build();
    }

    private MovieInfo convertToMovieInfo(Movie movie) {
        MovieInfo.Builder builder = MovieInfo.newBuilder()
            .setId(movie.getId())
            .setTitle(movie.getTitle())
            .setDurationMinutes(movie.getDurationMinutes())
            .setRating(movie.getRating());

        if (movie.getGenre() != null) {
            builder.setGenre(movie.getGenre());
        }
        if (movie.getPosterUrl() != null) {
            builder.setPosterUrl(movie.getPosterUrl());
        }

        return builder.build();
    }

    private CinemaInfo convertToCinemaInfo(Cinema cinema) {
        return CinemaInfo.newBuilder()
            .setId(cinema.getId())
            .setName(cinema.getName())
            .setLocation(cinema.getLocation())
            .setTotalScreens(cinema.getTotalScreens())
            .build();
    }
}