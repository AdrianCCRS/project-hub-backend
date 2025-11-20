# Multi-stage Dockerfile for Spring Boot Application

# Stage 1: Build stage
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy Maven wrapper and pom.xml first for better layer caching
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Give execution permissions to mvnw
RUN chmod +x mvnw

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application (skip tests for faster builds, run tests in CI/CD)
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Create a non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Copy the JAR file from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose application port
EXPOSE 8080

# Health check (si se añade actuator)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
#   CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application without options (could have memory issues)
# ENTRYPOINT ["java", "-jar", "app.jar"]

# Optional: JVM tuning for containerized environments
# You can override these with environment variables
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

