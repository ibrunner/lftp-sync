# Main download logic
log_message "Starting download process..."

lftp -u "${FTP_USER},${FTP_PASS}" "${FTP_HOST}" << EOF
    # First, mirror the files
    cd "${REMOTE_DIR}"
    mirror \
        --verbose \
        --parallel=${PARALLEL_JOBS} \
        --only-newer \
        . "${LOCAL_DIR}"

    # Create a list of successfully downloaded files
    find "${LOCAL_DIR}" -type f -newer "$LOCK_FILE" > /tmp/downloaded_files.txt
    
    # Delete the remote files that were successfully downloaded
    while IFS= read -r local_file; do
        remote_file="\${local_file#${LOCAL_DIR}}"
        rm -f "${remote_file}"
    done < /tmp/downloaded_files.txt
    
    # Clean up empty directories (runs multiple times to handle nested empty dirs)
    for i in {1..5}; do
        find . -type d -empty -delete
    done
    
    quit
EOF 