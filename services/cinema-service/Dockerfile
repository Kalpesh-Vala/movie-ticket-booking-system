# Multi-stage build for Cinema Service
FROM ubuntu:22.04 AS build

# Install Java and Maven
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk maven && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better layer caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src
COPY proto ./proto

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM ubuntu:22.04

# Install Java runtime and curl
RUN apt-get update && \
    apt-get install -y openjdk-17-jre-headless curl && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN groupadd -r cinema && useradd -r -g cinema cinema

# Copy the built JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Copy database migration scripts
COPY --from=build /app/src/main/resources/db/migration/ ./db/migration/

# Change ownership to cinema user
RUN chown -R cinema:cinema /app

# Switch to non-root user
USER cinema

# Expose ports
EXPOSE 8002 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8002/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]