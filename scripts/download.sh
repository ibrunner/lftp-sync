#!/bin/bash

# Function to log messages
log_message() {
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

# Create list of existing files before sync
# find "${LOCAL_DIR}" -type f > /tmp/files_before.txt

# Start LFTP session with built-in deletion
lftp -u "${FTP_USER},${FTP_PASS}" "${FTP_HOST}" << EOF
    # Change to remote directory
    cd "${REMOTE_DIR}"
    
    # Set LFTP options
    set pget:min-size ${PGET_MIN_SIZE}
    set pget:min-chunk-size ${PGET_MIN_CHUNK_SIZE}
    
    # Mirror the files and remove from remote after successful download
    mirror \
        --verbose \
        --parallel=${PARALLEL_JOBS} \
        --use-pget-n=${CHUNKS_PER_FILE} \
        --only-newer \
        --Remove-source-files \
        . "${LOCAL_DIR}"
    
    quit
EOF

# Check if LFTP failed
if [ $? -ne 0 ]; then
    log_message "Error: LFTP mirror command failed"
    exit 1
fi

# Clean up empty directories
log_message "Cleaning up empty directories..."
for i in {1..5}; do
    find "${LOCAL_DIR}" -type d -empty -delete
done

# Update lock file timestamp
touch "$LOCK_FILE"
log_message "Download process completed" 