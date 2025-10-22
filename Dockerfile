# --- Build stage ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY . .
RUN mvn -q -DskipTests clean package \
 && cp target/shipping-*.jar /src/shipping.jar

# --- Runtime stage (Debian/Corretto) ---
FROM docker.io/openjdk

RUN  useradd java
WORKDIR /home/java

# Create non-root user/group the Debian way


# Copy as root, then fix ownership
COPY --from=build /src/shipping.jar /app/shipping.jar




EXPOSE 8080
ENTRYPOINT ["java"]
CMD ["-jar","/app/shipping.jar"]
