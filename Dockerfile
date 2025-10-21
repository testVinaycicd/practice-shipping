# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /src

# If you have a pom.xml + sources locally, copy and build:
# (If you don't have the source locally and only rely on the ZIP artifact,
#  see the alternate path below.)
COPY . .
# Download deps first (better layer cache), then compile
RUN mvn -q -e -DskipTests dependency:go-offline
RUN mvn -q -e -DskipTests clean package \
  && mv target/shipping-*.jar shipping.jar

# ---- Alternate path: build from the ZIP artifact (uncomment this block and comment out COPY . above) ----
# RUN apt-get update && apt-get install -y unzip curl && rm -rf /var/lib/apt/lists/*
# RUN mkdir -p /src/app && \
#     curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip && \
#     unzip -q /tmp/shipping.zip -d /src/app && \
#     cd /src/app && mvn -q -e -DskipTests clean package && \
#     mv target/shipping-*.jar /src/shipping.jar

# ---- Runtime stage ----
FROM eclipse-temurin:11-jre-alpine
# Create nonroot user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=build /src/shipping.jar /app/shipping.jar

# (Optional) If you want the SQL files inside the image (not required if using ConfigMaps):
# COPY db/ /app/db/

ENV JAVA_OPTS="-Xms256m -Xmx512m"
USER appuser

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1

ENTRYPOINT [ "sh", "-lc", "exec java $JAVA_OPTS -jar /app/shipping.jar" ]
