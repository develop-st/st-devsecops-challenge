FROM gradle:8.6-jdk21 AS build
WORKDIR /home/gradle/src
COPY . .
RUN gradle --no-daemon clean shadowJar -x test

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
# SECURITY: Use Alpine for smaller attack surface

WORKDIR /app

# SECURITY FIX: Create non-root user
# Original ran as root which is dangerous if container is compromised
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

COPY --from=build /home/gradle/src/build/libs/light-backend.jar /app/app.jar

# SECURITY: Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# SECURITY: Switch to non-root user
USER appuser

EXPOSE 8080

# ADDED: Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["java", "-jar", "/app/app.jar"]
