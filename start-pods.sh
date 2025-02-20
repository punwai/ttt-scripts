#!/bin/bash

# Define the base pod name and port mapping
BASE_NAME="ttt-reasoning"
LOCAL_PORT_START=2223
REMOTE_PORT=22

for port in $(seq 2223 2243); do
    # Find process ID using the port and kill it
    pid=$(lsof -ti :$port)
    if [ ! -z "$pid" ]; then
        echo "Killing process on port $port (PID: $pid)"
        kill -9 $pid
    else
        echo "No process found on port $port"
    fi
done


# Loop to start port-forwarding for 8 pods
for i in {1..16}; do
    POD_NAME="pod/${BASE_NAME}-$i"
    LOCAL_PORT=$((LOCAL_PORT_START + i - 1))

    echo "Starting port-forward for $POD_NAME on local port $LOCAL_PORT..."
    
    # Run port-forward in the background
    kubectl port-forward $POD_NAME $LOCAL_PORT:$REMOTE_PORT &

    # Give a small delay to prevent race conditions
    sleep .1
done

echo "All port-forwards started."

# Keep the script running to prevent background jobs from stopping
wait

