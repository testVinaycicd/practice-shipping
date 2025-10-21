#FROM            redhat/ubi9
#RUN             dnf install mysql git -y
#RUN             mkdir /app
#WORKDIR         /app
#COPY            *.sql run.sh /app/
#ENTRYPOINT      ["bash", "run.sh"]


# Minimal base with mysql client and bash
FROM alpine:3.20

# Install mysql client + basics
RUN apk add --no-cache mysql-client bash ca-certificates curl

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /work

# Copy SQL and runner
COPY *.sql ./sql/
COPY run.sh ./run.sh

# Make script executable
RUN chmod +x ./run.sh

# Default envs (override via K8s)

USER appuser

# Run the migration script
ENTRYPOINT ["/work/run.sh"]
