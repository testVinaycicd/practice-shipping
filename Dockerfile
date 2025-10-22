# ---- Build stage (Maven + JDK) ----
FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /src

# 1) Prime the cache with deps first
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline

# 2) Then copy sources and build
COPY . .
RUN mvn -q -e -DskipTests clean package \
 && find target -name "shipping-*.jar" -maxdepth 1 -print -quit | xargs -I{} cp {} /src/app.jar

# ---- Create minimal JRE with jlink ----
# ---- Create minimal JRE with jlink ----
FROM eclipse-temurin:11-jdk AS jre
WORKDIR /opt
COPY --from=build /src/app.jar /opt/app.jar

# Add critical modules explicitly so reflection/JNDI don't break
# Start with jdeps result, then add must-haves: java.naming (JNDI), java.sql (JDBC), java.xml (XML), jdk.crypto.ec (TLS), jdk.unsupported (Unsafe)
RUN DEPS="$(jdeps --ignore-missing-deps --print-module-deps /opt/app.jar),java.naming,java.sql,java.xml,jdk.crypto.ec,jdk.unsupported" \
 && jlink \
    --add-modules "${DEPS}" \
    --strip-debug --no-man-pages --no-header-files --compress=2 \
    --output /opt/jre


# ---- Runtime: distroless (no shell, minimal attack surface) ----
FROM gcr.io/distroless/base-debian12
USER 65532:65532
WORKDIR /app
COPY --from=jre /opt/jre /opt/jre
COPY --from=build /src/app.jar /app/app.jar

ENV JAVA_OPTS="-XX:+UseContainerSupport -Xms256m -Xmx512m" \
    PATH="/opt/jre/bin:${PATH}"
EXPOSE 8083

# ENTRYPOINT runs java; CMD supplies default args to run the app
ENTRYPOINT ["java"]
CMD ["-jar","/app/app.jar"]
