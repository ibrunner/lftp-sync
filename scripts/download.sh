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
    cd "${REMOTE_DIR}"
    
    # Set LFTP options with size-based chunking
    set pget-min-size ${PGET_MIN_SIZE}
    set pget:min-chunk-size ${PGET_MIN_CHUNK_SIZE}
    
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
    
    # Clean up empty directories in the local directory
    for i in {1..5}; do
        find "${LOCAL_DIR}" -type d -empty -delete
    done
    
    # Keep checking for new files until none are found
    while true; do
        log_message "Performing additional check for new files..."
        
        # Create a temporary file to track if new files were downloaded
        rm -f /tmp/new_files_found
        
        mirror \
            --verbose \
            --parallel=${PARALLEL_JOBS} \
            --use-pget-n=${CHUNKS_PER_FILE} \
            --only-newer \
            . "${LOCAL_DIR}" || touch /tmp/new_files_found
            
        # If no new files were downloaded, break the loop
        if [ ! -f /tmp/new_files_found ]; then
            log_message "No new files found, finishing up..."
            break
        fi
        
        log_message "New files were found, continuing checks..."
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
log_message "Download process completed after ensuring all files were downloaded" 