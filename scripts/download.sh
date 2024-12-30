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

# Validate remote directory exists
lftp -u "${FTP_USER},${FTP_PASS}" "${FTP_HOST}" << EOF
    # Test if directory exists and is accessible
    cd "${REMOTE_DIR}" 2>/tmp/cd_error || {
        cat /tmp/cd_error
        log_message "Error: Cannot access remote directory '${REMOTE_DIR}'. Please check if the path exists and is accessible."
        exit 1
    }
    log_message "Successfully connected to remote directory: ${REMOTE_DIR}"

    # First, mirror the files
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

# Check if lftp exited with error
if [ $? -ne 0 ]; then
    log_message "Error: LFTP command failed. Check the logs above for details."
    exit 1
fi

# Update lock file timestamp
touch "$LOCK_FILE"
log_message "Download process completed" 