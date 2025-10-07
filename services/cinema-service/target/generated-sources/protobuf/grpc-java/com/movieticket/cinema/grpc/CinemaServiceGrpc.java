package com.movieticket.cinema.grpc;

import static io.grpc.MethodDescriptor.generateFullMethodName;

/**
 * <pre>
 * Cinema gRPC Service Definition
 * </pre>
 */
@javax.annotation.Generated(
    value = "by gRPC proto compiler (version 1.58.0)",
    comments = "Source: cinema.proto")
@io.grpc.stub.annotations.GrpcGenerated
public final class CinemaServiceGrpc {

  private CinemaServiceGrpc() {}

  public static final java.lang.String SERVICE_NAME = "cinema.CinemaService";

  // Static method descriptors that strictly reflect the proto.
  private static volatile io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> getCheckSeatAvailabilityMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "CheckSeatAvailability",
      requestType = com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest.class,
      responseType = com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> getCheckSeatAvailabilityMethod() {
    io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest, com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> getCheckSeatAvailabilityMethod;
    if ((getCheckSeatAvailabilityMethod = CinemaServiceGrpc.getCheckSeatAvailabilityMethod) == null) {
      synchronized (CinemaServiceGrpc.class) {
        if ((getCheckSeatAvailabilityMethod = CinemaServiceGrpc.getCheckSeatAvailabilityMethod) == null) {
          CinemaServiceGrpc.getCheckSeatAvailabilityMethod = getCheckSeatAvailabilityMethod =
              io.grpc.MethodDescriptor.<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest, com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "CheckSeatAvailability"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CinemaServiceMethodDescriptorSupplier("CheckSeatAvailability"))
              .build();
        }
      }
    }
    return getCheckSeatAvailabilityMethod;
  }

  private static volatile io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> getLockSeatsMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "LockSeats",
      requestType = com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest.class,
      responseType = com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> getLockSeatsMethod() {
    io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest, com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> getLockSeatsMethod;
    if ((getLockSeatsMethod = CinemaServiceGrpc.getLockSeatsMethod) == null) {
      synchronized (CinemaServiceGrpc.class) {
        if ((getLockSeatsMethod = CinemaServiceGrpc.getLockSeatsMethod) == null) {
          CinemaServiceGrpc.getLockSeatsMethod = getLockSeatsMethod =
              io.grpc.MethodDescriptor.<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest, com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "LockSeats"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CinemaServiceMethodDescriptorSupplier("LockSeats"))
              .build();
        }
      }
    }
    return getLockSeatsMethod;
  }

  private static volatile io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> getReleaseSeatLockMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "ReleaseSeatLock",
      requestType = com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest.class,
      responseType = com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> getReleaseSeatLockMethod() {
    io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> getReleaseSeatLockMethod;
    if ((getReleaseSeatLockMethod = CinemaServiceGrpc.getReleaseSeatLockMethod) == null) {
      synchronized (CinemaServiceGrpc.class) {
        if ((getReleaseSeatLockMethod = CinemaServiceGrpc.getReleaseSeatLockMethod) == null) {
          CinemaServiceGrpc.getReleaseSeatLockMethod = getReleaseSeatLockMethod =
              io.grpc.MethodDescriptor.<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "ReleaseSeatLock"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CinemaServiceMethodDescriptorSupplier("ReleaseSeatLock"))
              .build();
        }
      }
    }
    return getReleaseSeatLockMethod;
  }

  private static volatile io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> getConfirmSeatBookingMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "ConfirmSeatBooking",
      requestType = com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest.class,
      responseType = com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> getConfirmSeatBookingMethod() {
    io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> getConfirmSeatBookingMethod;
    if ((getConfirmSeatBookingMethod = CinemaServiceGrpc.getConfirmSeatBookingMethod) == null) {
      synchronized (CinemaServiceGrpc.class) {
        if ((getConfirmSeatBookingMethod = CinemaServiceGrpc.getConfirmSeatBookingMethod) == null) {
          CinemaServiceGrpc.getConfirmSeatBookingMethod = getConfirmSeatBookingMethod =
              io.grpc.MethodDescriptor.<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "ConfirmSeatBooking"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CinemaServiceMethodDescriptorSupplier("ConfirmSeatBooking"))
              .build();
        }
      }
    }
    return getConfirmSeatBookingMethod;
  }

  private static volatile io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> getGetShowtimeDetailsMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "GetShowtimeDetails",
      requestType = com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest.class,
      responseType = com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest,
      com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> getGetShowtimeDetailsMethod() {
    io.grpc.MethodDescriptor<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> getGetShowtimeDetailsMethod;
    if ((getGetShowtimeDetailsMethod = CinemaServiceGrpc.getGetShowtimeDetailsMethod) == null) {
      synchronized (CinemaServiceGrpc.class) {
        if ((getGetShowtimeDetailsMethod = CinemaServiceGrpc.getGetShowtimeDetailsMethod) == null) {
          CinemaServiceGrpc.getGetShowtimeDetailsMethod = getGetShowtimeDetailsMethod =
              io.grpc.MethodDescriptor.<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest, com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "GetShowtimeDetails"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CinemaServiceMethodDescriptorSupplier("GetShowtimeDetails"))
              .build();
        }
      }
    }
    return getGetShowtimeDetailsMethod;
  }

  /**
   * Creates a new async stub that supports all call types for the service
   */
  public static CinemaServiceStub newStub(io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CinemaServiceStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CinemaServiceStub>() {
        @java.lang.Override
        public CinemaServiceStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CinemaServiceStub(channel, callOptions);
        }
      };
    return CinemaServiceStub.newStub(factory, channel);
  }

  /**
   * Creates a new blocking-style stub that supports unary and streaming output calls on the service
   */
  public static CinemaServiceBlockingStub newBlockingStub(
      io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CinemaServiceBlockingStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CinemaServiceBlockingStub>() {
        @java.lang.Override
        public CinemaServiceBlockingStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CinemaServiceBlockingStub(channel, callOptions);
        }
      };
    return CinemaServiceBlockingStub.newStub(factory, channel);
  }

  /**
   * Creates a new ListenableFuture-style stub that supports unary calls on the service
   */
  public static CinemaServiceFutureStub newFutureStub(
      io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CinemaServiceFutureStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CinemaServiceFutureStub>() {
        @java.lang.Override
        public CinemaServiceFutureStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CinemaServiceFutureStub(channel, callOptions);
        }
      };
    return CinemaServiceFutureStub.newStub(factory, channel);
  }

  /**
   * <pre>
   * Cinema gRPC Service Definition
   * </pre>
   */
  public interface AsyncService {

    /**
     * <pre>
     * Check seat availability for a specific showtime
     * </pre>
     */
    default void checkSeatAvailability(com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> responseObserver) {
      io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall(getCheckSeatAvailabilityMethod(), responseObserver);
    }

    /**
     * <pre>
     * Lock seats for booking (with timeout)
     * </pre>
     */
    default void lockSeats(com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> responseObserver) {
      io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall(getLockSeatsMethod(), responseObserver);
    }

    /**
     * <pre>
     * Release locked seats (in case of booking failure)
     * </pre>
     */
    default void releaseSeatLock(com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> responseObserver) {
      io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall(getReleaseSeatLockMethod(), responseObserver);
    }

    /**
     * <pre>
     * Confirm seat booking (finalize the reservation)
     * </pre>
     */
    default void confirmSeatBooking(com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> responseObserver) {
      io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall(getConfirmSeatBookingMethod(), responseObserver);
    }

    /**
     * <pre>
     * Get showtime details
     * </pre>
     */
    default void getShowtimeDetails(com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> responseObserver) {
      io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall(getGetShowtimeDetailsMethod(), responseObserver);
    }
  }

  /**
   * Base class for the server implementation of the service CinemaService.
   * <pre>
   * Cinema gRPC Service Definition
   * </pre>
   */
  public static abstract class CinemaServiceImplBase
      implements io.grpc.BindableService, AsyncService {

    @java.lang.Override public final io.grpc.ServerServiceDefinition bindService() {
      return CinemaServiceGrpc.bindService(this);
    }
  }

  /**
   * A stub to allow clients to do asynchronous rpc calls to service CinemaService.
   * <pre>
   * Cinema gRPC Service Definition
   * </pre>
   */
  public static final class CinemaServiceStub
      extends io.grpc.stub.AbstractAsyncStub<CinemaServiceStub> {
    private CinemaServiceStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CinemaServiceStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CinemaServiceStub(channel, callOptions);
    }

    /**
     * <pre>
     * Check seat availability for a specific showtime
     * </pre>
     */
    public void checkSeatAvailability(com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> responseObserver) {
      io.grpc.stub.ClientCalls.asyncUnaryCall(
          getChannel().newCall(getCheckSeatAvailabilityMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     * <pre>
     * Lock seats for booking (with timeout)
     * </pre>
     */
    public void lockSeats(com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> responseObserver) {
      io.grpc.stub.ClientCalls.asyncUnaryCall(
          getChannel().newCall(getLockSeatsMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     * <pre>
     * Release locked seats (in case of booking failure)
     * </pre>
     */
    public void releaseSeatLock(com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> responseObserver) {
      io.grpc.stub.ClientCalls.asyncUnaryCall(
          getChannel().newCall(getReleaseSeatLockMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     * <pre>
     * Confirm seat booking (finalize the reservation)
     * </pre>
     */
    public void confirmSeatBooking(com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> responseObserver) {
      io.grpc.stub.ClientCalls.asyncUnaryCall(
          getChannel().newCall(getConfirmSeatBookingMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     * <pre>
     * Get showtime details
     * </pre>
     */
    public void getShowtimeDetails(com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest request,
        io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> responseObserver) {
      io.grpc.stub.ClientCalls.asyncUnaryCall(
          getChannel().newCall(getGetShowtimeDetailsMethod(), getCallOptions()), request, responseObserver);
    }
  }

  /**
   * A stub to allow clients to do synchronous rpc calls to service CinemaService.
   * <pre>
   * Cinema gRPC Service Definition
   * </pre>
   */
  public static final class CinemaServiceBlockingStub
      extends io.grpc.stub.AbstractBlockingStub<CinemaServiceBlockingStub> {
    private CinemaServiceBlockingStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CinemaServiceBlockingStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CinemaServiceBlockingStub(channel, callOptions);
    }

    /**
     * <pre>
     * Check seat availability for a specific showtime
     * </pre>
     */
    public com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse checkSeatAvailability(com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest request) {
      return io.grpc.stub.ClientCalls.blockingUnaryCall(
          getChannel(), getCheckSeatAvailabilityMethod(), getCallOptions(), request);
    }

    /**
     * <pre>
     * Lock seats for booking (with timeout)
     * </pre>
     */
    public com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse lockSeats(com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest request) {
      return io.grpc.stub.ClientCalls.blockingUnaryCall(
          getChannel(), getLockSeatsMethod(), getCallOptions(), request);
    }

    /**
     * <pre>
     * Release locked seats (in case of booking failure)
     * </pre>
     */
    public com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse releaseSeatLock(com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest request) {
      return io.grpc.stub.ClientCalls.blockingUnaryCall(
          getChannel(), getReleaseSeatLockMethod(), getCallOptions(), request);
    }

    /**
     * <pre>
     * Confirm seat booking (finalize the reservation)
     * </pre>
     */
    public com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse confirmSeatBooking(com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest request) {
      return io.grpc.stub.ClientCalls.blockingUnaryCall(
          getChannel(), getConfirmSeatBookingMethod(), getCallOptions(), request);
    }

    /**
     * <pre>
     * Get showtime details
     * </pre>
     */
    public com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse getShowtimeDetails(com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest request) {
      return io.grpc.stub.ClientCalls.blockingUnaryCall(
          getChannel(), getGetShowtimeDetailsMethod(), getCallOptions(), request);
    }
  }

  /**
   * A stub to allow clients to do ListenableFuture-style rpc calls to service CinemaService.
   * <pre>
   * Cinema gRPC Service Definition
   * </pre>
   */
  public static final class CinemaServiceFutureStub
      extends io.grpc.stub.AbstractFutureStub<CinemaServiceFutureStub> {
    private CinemaServiceFutureStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CinemaServiceFutureStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CinemaServiceFutureStub(channel, callOptions);
    }

    /**
     * <pre>
     * Check seat availability for a specific showtime
     * </pre>
     */
    public com.google.common.util.concurrent.ListenableFuture<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse> checkSeatAvailability(
        com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest request) {
      return io.grpc.stub.ClientCalls.futureUnaryCall(
          getChannel().newCall(getCheckSeatAvailabilityMethod(), getCallOptions()), request);
    }

    /**
     * <pre>
     * Lock seats for booking (with timeout)
     * </pre>
     */
    public com.google.common.util.concurrent.ListenableFuture<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse> lockSeats(
        com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest request) {
      return io.grpc.stub.ClientCalls.futureUnaryCall(
          getChannel().newCall(getLockSeatsMethod(), getCallOptions()), request);
    }

    /**
     * <pre>
     * Release locked seats (in case of booking failure)
     * </pre>
     */
    public com.google.common.util.concurrent.ListenableFuture<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse> releaseSeatLock(
        com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest request) {
      return io.grpc.stub.ClientCalls.futureUnaryCall(
          getChannel().newCall(getReleaseSeatLockMethod(), getCallOptions()), request);
    }

    /**
     * <pre>
     * Confirm seat booking (finalize the reservation)
     * </pre>
     */
    public com.google.common.util.concurrent.ListenableFuture<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse> confirmSeatBooking(
        com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest request) {
      return io.grpc.stub.ClientCalls.futureUnaryCall(
          getChannel().newCall(getConfirmSeatBookingMethod(), getCallOptions()), request);
    }

    /**
     * <pre>
     * Get showtime details
     * </pre>
     */
    public com.google.common.util.concurrent.ListenableFuture<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse> getShowtimeDetails(
        com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest request) {
      return io.grpc.stub.ClientCalls.futureUnaryCall(
          getChannel().newCall(getGetShowtimeDetailsMethod(), getCallOptions()), request);
    }
  }

  private static final int METHODID_CHECK_SEAT_AVAILABILITY = 0;
  private static final int METHODID_LOCK_SEATS = 1;
  private static final int METHODID_RELEASE_SEAT_LOCK = 2;
  private static final int METHODID_CONFIRM_SEAT_BOOKING = 3;
  private static final int METHODID_GET_SHOWTIME_DETAILS = 4;

  private static final class MethodHandlers<Req, Resp> implements
      io.grpc.stub.ServerCalls.UnaryMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.ServerStreamingMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.ClientStreamingMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.BidiStreamingMethod<Req, Resp> {
    private final AsyncService serviceImpl;
    private final int methodId;

    MethodHandlers(AsyncService serviceImpl, int methodId) {
      this.serviceImpl = serviceImpl;
      this.methodId = methodId;
    }

    @java.lang.Override
    @java.lang.SuppressWarnings("unchecked")
    public void invoke(Req request, io.grpc.stub.StreamObserver<Resp> responseObserver) {
      switch (methodId) {
        case METHODID_CHECK_SEAT_AVAILABILITY:
          serviceImpl.checkSeatAvailability((com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest) request,
              (io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse>) responseObserver);
          break;
        case METHODID_LOCK_SEATS:
          serviceImpl.lockSeats((com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest) request,
              (io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse>) responseObserver);
          break;
        case METHODID_RELEASE_SEAT_LOCK:
          serviceImpl.releaseSeatLock((com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest) request,
              (io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse>) responseObserver);
          break;
        case METHODID_CONFIRM_SEAT_BOOKING:
          serviceImpl.confirmSeatBooking((com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest) request,
              (io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse>) responseObserver);
          break;
        case METHODID_GET_SHOWTIME_DETAILS:
          serviceImpl.getShowtimeDetails((com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest) request,
              (io.grpc.stub.StreamObserver<com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse>) responseObserver);
          break;
        default:
          throw new AssertionError();
      }
    }

    @java.lang.Override
    @java.lang.SuppressWarnings("unchecked")
    public io.grpc.stub.StreamObserver<Req> invoke(
        io.grpc.stub.StreamObserver<Resp> responseObserver) {
      switch (methodId) {
        default:
          throw new AssertionError();
      }
    }
  }

  public static final io.grpc.ServerServiceDefinition bindService(AsyncService service) {
    return io.grpc.ServerServiceDefinition.builder(getServiceDescriptor())
        .addMethod(
          getCheckSeatAvailabilityMethod(),
          io.grpc.stub.ServerCalls.asyncUnaryCall(
            new MethodHandlers<
              com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityRequest,
              com.movieticket.cinema.grpc.CinemaServiceProto.SeatAvailabilityResponse>(
                service, METHODID_CHECK_SEAT_AVAILABILITY)))
        .addMethod(
          getLockSeatsMethod(),
          io.grpc.stub.ServerCalls.asyncUnaryCall(
            new MethodHandlers<
              com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsRequest,
              com.movieticket.cinema.grpc.CinemaServiceProto.LockSeatsResponse>(
                service, METHODID_LOCK_SEATS)))
        .addMethod(
          getReleaseSeatLockMethod(),
          io.grpc.stub.ServerCalls.asyncUnaryCall(
            new MethodHandlers<
              com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockRequest,
              com.movieticket.cinema.grpc.CinemaServiceProto.ReleaseSeatLockResponse>(
                service, METHODID_RELEASE_SEAT_LOCK)))
        .addMethod(
          getConfirmSeatBookingMethod(),
          io.grpc.stub.ServerCalls.asyncUnaryCall(
            new MethodHandlers<
              com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingRequest,
              com.movieticket.cinema.grpc.CinemaServiceProto.ConfirmSeatBookingResponse>(
                service, METHODID_CONFIRM_SEAT_BOOKING)))
        .addMethod(
          getGetShowtimeDetailsMethod(),
          io.grpc.stub.ServerCalls.asyncUnaryCall(
            new MethodHandlers<
              com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsRequest,
              com.movieticket.cinema.grpc.CinemaServiceProto.ShowtimeDetailsResponse>(
                service, METHODID_GET_SHOWTIME_DETAILS)))
        .build();
  }

  private static abstract class CinemaServiceBaseDescriptorSupplier
      implements io.grpc.protobuf.ProtoFileDescriptorSupplier, io.grpc.protobuf.ProtoServiceDescriptorSupplier {
    CinemaServiceBaseDescriptorSupplier() {}

    @java.lang.Override
    public com.google.protobuf.Descriptors.FileDescriptor getFileDescriptor() {
      return com.movieticket.cinema.grpc.CinemaServiceProto.getDescriptor();
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.ServiceDescriptor getServiceDescriptor() {
      return getFileDescriptor().findServiceByName("CinemaService");
    }
  }

  private static final class CinemaServiceFileDescriptorSupplier
      extends CinemaServiceBaseDescriptorSupplier {
    CinemaServiceFileDescriptorSupplier() {}
  }

  private static final class CinemaServiceMethodDescriptorSupplier
      extends CinemaServiceBaseDescriptorSupplier
      implements io.grpc.protobuf.ProtoMethodDescriptorSupplier {
    private final java.lang.String methodName;

    CinemaServiceMethodDescriptorSupplier(java.lang.String methodName) {
      this.methodName = methodName;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.MethodDescriptor getMethodDescriptor() {
      return getServiceDescriptor().findMethodByName(methodName);
    }
  }

  private static volatile io.grpc.ServiceDescriptor serviceDescriptor;

  public static io.grpc.ServiceDescriptor getServiceDescriptor() {
    io.grpc.ServiceDescriptor result = serviceDescriptor;
    if (result == null) {
      synchronized (CinemaServiceGrpc.class) {
        result = serviceDescriptor;
        if (result == null) {
          serviceDescriptor = result = io.grpc.ServiceDescriptor.newBuilder(SERVICE_NAME)
              .setSchemaDescriptor(new CinemaServiceFileDescriptorSupplier())
              .addMethod(getCheckSeatAvailabilityMethod())
              .addMethod(getLockSeatsMethod())
              .addMethod(getReleaseSeatLockMethod())
              .addMethod(getConfirmSeatBookingMethod())
              .addMethod(getGetShowtimeDetailsMethod())
              .build();
        }
      }
    }
    return result;
  }
}
