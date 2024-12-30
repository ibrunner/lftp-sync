#!/bin/bash
while true; do
    # Run the download script
    /app/download.sh
    
    # Wait for 5 minutes before the next run
    sleep 300
done