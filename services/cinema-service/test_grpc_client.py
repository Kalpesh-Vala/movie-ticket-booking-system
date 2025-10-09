#!/usr/bin/env python3
"""
Python gRPC Client for Cinema Service
This script demonstrates how to interact with the Cinema Service gRPC API
"""

import grpc
import json
import sys
import time
from pathlib import Path

# Add the generated proto classes to the path
sys.path.append(str(Path(__file__).parent / "target/generated-sources/protobuf/python"))

try:
    import cinema_pb2
    import cinema_pb2_grpc
except ImportError:
    print("Error: Generated protobuf files not found.")
    print("Please run 'mvn clean compile' to generate the protobuf files.")
    sys.exit(1)

class CinemaServiceClient:
    def __init__(self, host='localhost', port=9090):
        self.channel = grpc.insecure_channel(f'{host}:{port}')
        self.stub = cinema_pb2_grpc.CinemaServiceStub(self.channel)
        
    def check_seat_availability(self, showtime_id, seat_numbers):
        """Check if seats are available for a showtime"""
        request = cinema_pb2.SeatAvailabilityRequest(
            showtime_id=showtime_id,
            seat_numbers=seat_numbers
        )
        
        try:
            response = self.stub.CheckSeatAvailability(request)
            return {
                'available': response.available,
                'message': response.message,
                'unavailable_seats': [
                    {
                        'seat_number': seat.seat_number,
                        'status': seat.status,
                        'locked_by': seat.locked_by if seat.locked_by else None,
                        'locked_until': seat.locked_until if seat.locked_until else None
                    }
                    for seat in response.unavailable_seats
                ]
            }
        except grpc.RpcError as e:
            return {'error': str(e)}
    
    def lock_seats(self, showtime_id, seat_numbers, booking_id, lock_duration_seconds=300):
        """Lock seats for a booking"""
        request = cinema_pb2.LockSeatsRequest(
            showtime_id=showtime_id,
            seat_numbers=seat_numbers,
            booking_id=booking_id,
            lock_duration_seconds=lock_duration_seconds
        )
        
        try:
            response = self.stub.LockSeats(request)
            return {
                'success': response.success,
                'lock_id': response.lock_id if response.lock_id else None,
                'expires_at': response.expires_at if response.expires_at else None,
                'message': response.message,
                'failed_seats': list(response.failed_seats) if response.failed_seats else []
            }
        except grpc.RpcError as e:
            return {'error': str(e)}
    
    def release_seat_lock(self, lock_id, booking_id):
        """Release a seat lock"""
        request = cinema_pb2.ReleaseSeatLockRequest(
            lock_id=lock_id,
            booking_id=booking_id
        )
        
        try:
            response = self.stub.ReleaseSeatLock(request)
            return {
                'success': response.success,
                'message': response.message
            }
        except grpc.RpcError as e:
            return {'error': str(e)}
    
    def confirm_seat_booking(self, lock_id, booking_id, user_id):
        """Confirm a seat booking"""
        request = cinema_pb2.ConfirmSeatBookingRequest(
            lock_id=lock_id,
            booking_id=booking_id,
            user_id=user_id
        )
        
        try:
            response = self.stub.ConfirmSeatBooking(request)
            return {
                'success': response.success,
                'message': response.message
            }
        except grpc.RpcError as e:
            return {'error': str(e)}
    
    def get_showtime_details(self, showtime_id):
        """Get details for a showtime"""
        request = cinema_pb2.ShowtimeDetailsRequest(
            showtime_id=showtime_id
        )
        
        try:
            response = self.stub.GetShowtimeDetails(request)
            return {
                'showtime': {
                    'id': response.showtime.id,
                    'movie_id': response.showtime.movie_id,
                    'cinema_id': response.showtime.cinema_id,
                    'start_time': response.showtime.start_time,
                    'end_time': response.showtime.end_time,
                    'base_price': response.showtime.base_price,
                    'total_seats': response.showtime.total_seats,
                    'available_seats': response.showtime.available_seats
                },
                'movie': {
                    'id': response.movie.id,
                    'title': response.movie.title,
                    'genre': response.movie.genre,
                    'duration_minutes': response.movie.duration_minutes,
                    'rating': response.movie.rating,
                    'poster_url': response.movie.poster_url
                },
                'cinema': {
                    'id': response.cinema.id,
                    'name': response.cinema.name,
                    'location': response.cinema.location,
                    'total_screens': response.cinema.total_screens
                }
            }
        except grpc.RpcError as e:
            return {'error': str(e)}
    
    def close(self):
        """Close the gRPC channel"""
        self.channel.close()

def run_demo():
    """Run a demonstration of the Cinema Service gRPC client"""
    print("=" * 60)
    print("Cinema Service gRPC Client Demo")
    print("=" * 60)
    
    client = CinemaServiceClient()
    
    try:
        # Test 1: Check seat availability
        print("\n1. Checking seat availability...")
        result = client.check_seat_availability("showtime-1", ["A01", "A02", "A03"])
        print(json.dumps(result, indent=2))
        
        # Test 2: Lock seats
        print("\n2. Locking seats...")
        booking_id = f"demo-booking-{int(time.time())}"
        lock_result = client.lock_seats("showtime-1", ["A01", "A02"], booking_id, 300)
        print(json.dumps(lock_result, indent=2))
        
        if lock_result.get('success'):
            lock_id = lock_result.get('lock_id')
            
            # Test 3: Check seat availability after lock
            print("\n3. Checking seat availability after lock...")
            result = client.check_seat_availability("showtime-1", ["A01", "A02"])
            print(json.dumps(result, indent=2))
            
            # Test 4: Release seat lock
            print("\n4. Releasing seat lock...")
            release_result = client.release_seat_lock(lock_id, booking_id)
            print(json.dumps(release_result, indent=2))
            
            # Test 5: Check seat availability after release
            print("\n5. Checking seat availability after release...")
            result = client.check_seat_availability("showtime-1", ["A01", "A02"])
            print(json.dumps(result, indent=2))
        
        # Test 6: Get showtime details
        print("\n6. Getting showtime details...")
        showtime_result = client.get_showtime_details("showtime-1")
        print(json.dumps(showtime_result, indent=2))
        
    except Exception as e:
        print(f"Error: {e}")
    
    finally:
        client.close()
        print("\n" + "=" * 60)
        print("Demo completed")
        print("=" * 60)

if __name__ == "__main__":
    run_demo()