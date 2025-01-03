#!/bin/bash

# Handle SIGTERM gracefully
trap 'exit 0' SIGTERM

# Validate environment variables
if [ -z "$FTP_HOST" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ]; then
    echo "Error: Required environment variables are not set"
    exit 1
fi

while true; do
    # Run the download script
    /app/download.sh
    
    # Wait before the next run
    sleep ${SLEEP_TIME:-90}
done