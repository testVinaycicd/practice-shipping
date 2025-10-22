FROM          docker.io/openjdk
RUN           useradd java
WORKDIR       /home/java
COPY          target/shipping-1.0.jar shipping.jar
ENTRYPOINT    ["java", "-jar", "shipping.jar"]
