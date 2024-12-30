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

lftp -u "${FTP_USER},${FTP_PASS}" "${FTP_HOST}" << EOF
    # First, mirror the files
    cd "${REMOTE_DIR}"
    mirror \
        --verbose \
        --parallel=${PARALLEL_JOBS} \
        --use-pget-n=${CHUNKS_PER_FILE} \
        --only-newer \
        . "${LOCAL_DIR}"

    # Create a list of successfully downloaded files
    find "${LOCAL_DIR}" -type f -newer "$LOCK_FILE" > /tmp/downloaded_files.txt
    
    # Delete the remote files that were successfully downloaded
    while IFS= read -r local_file; do
        remote_file="\${local_file#${LOCAL_DIR}}"
        rm -f "${remote_file}"
    done < /tmp/downloaded_files.txt
    
    # Clean up empty directories
    for i in {1..5}; do
        find . -type d -empty -delete
    done
    
    quit
EOF

# Update lock file timestamp
touch "$LOCK_FILE"
log_message "Download process completed" 