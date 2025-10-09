# ---------- Build Stage ----------
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom.xml first (better caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src
COPY proto ./proto

# Build jar (skip tests for faster build)
RUN mvn clean package -DskipTests

# ---------- Runtime Stage ----------
FROM eclipse-temurin:17-jre

WORKDIR /app

# Install curl for healthchecks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r cinema && useradd -r -g cinema cinema
USER cinema

# Copy jar
COPY --from=build /app/target/*.jar app.jar

# Expose service ports
EXPOSE 8002 9090

# Healthcheck (Spring Boot actuator)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8002/actuator/health || exit 1

# Run application with docker profile
ENTRYPOINT ["java", "-Dspring.profiles.active=docker", "-jar", "app.jar"]
