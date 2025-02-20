#!/bin/bash

# Define base variables
LOCAL_PORT_START=2223
SSH_CONFIG_FILE="$HOME/.ssh/config"

# Ensure SSH config file exists
touch "$SSH_CONFIG_FILE"

# Loop to configure SSH for 8 pods
for i in {1..16}; do
    LOCAL_PORT=$((LOCAL_PORT_START + i - 1))
    HOST_ALIAS="ttt-$i"

    # Check if SSH config for this host already exists
    if ! grep -q "^Host $HOST_ALIAS\$" "$SSH_CONFIG_FILE"; then
        echo "Adding SSH config for $HOST_ALIAS..."
        cat <<EOF >> "$SSH_CONFIG_FILE"

Host $HOST_ALIAS
    HostName 127.0.0.1
    User root
    Port $LOCAL_PORT
EOF
    else
        echo "SSH config for $HOST_ALIAS already exists, skipping."
    fi
done

echo "SSH config updated. You can now SSH into the pods using: ssh ttt-1, ssh ttt-2, etc."

