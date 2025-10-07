# Cinema Service Dockerfile
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src
COPY ../../proto ./proto

# Install Maven
RUN apt-get update && apt-get install -y maven

# Build the application
RUN mvn clean package -DskipTests

# Final stage
FROM openjdk:17-jre-slim

WORKDIR /app

# Copy the JAR file from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose ports
EXPOSE 8002 9090

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]