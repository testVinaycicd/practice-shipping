# --- Build stage ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY . .
RUN mvn -q -DskipTests clean package \
 && cp target/shipping-*.jar /src/shipping.jar

# --- Runtime stage ---
# Tip: use a JRE-only base to shrink size (alpine also available if you prefer)
FROM amazoncorretto:17-alpine-jre
WORKDIR /app

# Create non-root user & make sure /app is writable by it
RUN addgroup -S appgroup && adduser -S -u 10001 -G appgroup appuser \
 && chown -R appuser:appuser /app

# Copy as root, then drop privileges
COPY --from=build /src/shipping.jar /app/shipping.jar
RUN chown appuser:appuser /app/shipping.jar

USER appuser



EXPOSE 8083
# Split ENTRYPOINT/CMD so you can do: `docker run image -version`
ENTRYPOINT ["java"]
CMD ["-jar","/app/shipping.jar"]
