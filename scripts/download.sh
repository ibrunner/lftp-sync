#!/bin/bash

# Function to log messages
log_message() {
    echo "1:03"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Validate required environment variables
if [ -z "$FTP_HOST" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ]; then
    log_message "Error: Required environment variables FTP_HOST, FTP_USER, or FTP_PASS are not set"
    exit 1
fi

# Create lock file if it doesn't exist
LOCK_FILE="/config/last_run.lock"
touch "$LOCK_FILE"

# Main download logic
log_message "Starting download process..."

# Start LFTP session with built-in deletion
lftp -u "${FTP_USER},${FTP_PASS}" "${FTP_HOST}" << EOF
    # Log current directory and files
    !echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting mirror from ${REMOTE_DIR}/"
    
    # Mirror the files and remove from remote after successful download
    mirror \
        --verbose \
        --parallel=${PARALLEL_JOBS} \
        --use-pget-n=${CHUNKS_PER_FILE} \
        --only-newer \
        --Remove-source-files \
        --Remove-source-dirs \
        "${REMOTE_DIR}/" .
    
    quit
EOF

# Check if LFTP failed
if [ $? -ne 0 ]; then
    log_message "Error: LFTP mirror command failed"
    exit 1
fi

# Update lock file timestamp
touch "$LOCK_FILE"
log_message "Download process completed" 