#!/bin/bash

# List of SSH endpoints (replace with your actual endpoints)
ENDPOINTS=("ttt-1" "ttt-2" "ttt-3" ttt-4" "ttt-5" "ttt-6" "ttt-7" ttt-8" "ttt-9" "ttt-10" "ttt-11" ttt-12" "ttt-13" "ttt-14" "ttt-15" ttt-16")

# Source path on remote machines
REMOTE_PATH="/root/ttte/ttte/mask_curriculum/logs"

# Base destination path on local machine
LOCAL_BASE_PATH="./downloaded_logs"

# Create base destination directory
mkdir -p "$LOCAL_BASE_PATH"

# Function to handle single SCP transfer
copy_from_endpoint() {
    endpoint=$1
    server_name=$(echo $endpoint | cut -d@ -f2)
    dest_path="${LOCAL_BASE_PATH}/${server_name}"
    
    echo "Starting transfer from ${endpoint}..."
    mkdir -p "$dest_path"
    
    # Perform SCP with error handling
    if scp -O -r "${endpoint}:${REMOTE_PATH}" "${dest_path}"; then
        echo "Successfully copied from ${endpoint}"
    else
        echo "Failed to copy from ${endpoint}"
    fi
}

# Launch all transfers in parallel
for endpoint in "${ENDPOINTS[@]}"; do
    copy_from_endpoint "$endpoint" &
done

# Wait for all background processes to complete
wait

echo "All transfers completed!"
