# --- Build stage ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY . .
RUN mvn -q -DskipTests clean package \
 && cp target/shipping-*.jar /src/shipping.jar

# --- Runtime stage (Debian/Corretto) ---
FROM amazoncorretto:17
WORKDIR /app

# Create non-root user/group the Debian way
RUN groupadd -r appgroup \
 && useradd -r -u 10001 -g appgroup appuser \
 && mkdir -p /app \
 && chown -R appuser:appgroup /app

# Copy as root, then fix ownership
COPY --from=build /src/shipping.jar /app/shipping.jar
RUN chown appuser:appgroup /app/shipping.jar

USER appuser

ENV JAVA_OPTS="-XX:+UseContainerSupport -Xms256m -Xmx512m"
EXPOSE 8083
ENTRYPOINT ["java"]
CMD ["-jar","/app/shipping.jar"]
