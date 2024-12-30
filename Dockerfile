# Specify the target platform explicitly
FROM --platform=$TARGETPLATFORM alpine:latest AS builder

# Install required packages
RUN apk add --no-cache lftp bash

# Create necessary directories
RUN mkdir -p /app /config /downloads

# Set up working directory
WORKDIR /app

# Copy configuration and scripts
COPY scripts/download.sh /app/
COPY scripts/run.sh /app/
COPY config/lftp.conf /config/lftp.conf

# Create symlink for lftp config
RUN mkdir -p /root/.lftp && ln -sf /config/lftp.conf /root/.lftp/rc

# Make scripts executable
RUN chmod +x /app/download.sh /app/run.sh

# Set default environment variables
ENV FTP_HOST=""
ENV FTP_USER=""
ENV FTP_PASS=""
ENV REMOTE_DIR="private/transmission/data"
ENV LOCAL_DIR="/downloads"
ENV PARALLEL_JOBS="3"
ENV CHUNKS_PER_FILE="15"
ENV PGET_MIN_CHUNK_SIZE="10M"
ENV SLEEP_TIME="90"

# Set the entrypoint
ENTRYPOINT ["/app/run.sh"] 