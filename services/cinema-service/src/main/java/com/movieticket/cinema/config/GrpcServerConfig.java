package com.movieticket.cinema.config;

import com.movieticket.cinema.grpc.CinemaServiceImpl;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.protobuf.services.ProtoReflectionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.io.IOException;

@Configuration
public class GrpcServerConfig {

    @Value("${grpc.server.port:9090}")
    private int grpcPort;

    @Autowired
    private CinemaServiceImpl cinemaServiceImpl;

    private Server server;

    @PostConstruct
    public void start() throws IOException {
        server = ServerBuilder.forPort(grpcPort)
            .addService(cinemaServiceImpl)
            .addService(ProtoReflectionService.newInstance())
            .build()
            .start();

        System.out.println("gRPC server started on port " + grpcPort);
        System.out.println("gRPC reflection service enabled");

        // Shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down gRPC server...");
            GrpcServerConfig.this.stop();
            System.out.println("gRPC server shut down.");
        }));
    }

    @PreDestroy
    public void stop() {
        if (server != null) {
            server.shutdown();
        }
    }

    @Bean
    public Server grpcServer() {
        return server;
    }
}