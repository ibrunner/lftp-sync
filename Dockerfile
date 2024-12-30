FROM --platform=$TARGETPLATFORM alpine:latest

# Install required packages
RUN apk add --no-cache lftp bash

# Set up working directory
WORKDIR /app

# Copy configuration and scripts
COPY scripts/download.sh /app/
COPY scripts/run.sh /app/
COPY config/lftp.conf /root/.lftp/rc

# Make scripts executable
RUN chmod +x /app/download.sh /app/run.sh

# Set the entrypoint
CMD ["/app/run.sh"] 