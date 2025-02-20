#!/bin/bash
SERVERS=("ttt-1" "ttt-2" "ttt-3" "ttt-4" "ttt-5" "ttt-6" "ttt-7" "ttt-8")
LOCAL_SSH_KEY="/Users/pun/.ssh/sf-compute"
REMOTE_USER="root"

# Check if local key exists
if [[ ! -f "$LOCAL_SSH_KEY" ]]; then
    echo "SSH key not found at $LOCAL_SSH_KEY"
    exit 1
fi

for SERVER in "${SERVERS[@]}"; do
    (
        echo "Copying SSH key to $SERVER..."
        # Create .ssh directory on remote and set permissions
        ssh "$REMOTE_USER@$SERVER" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
       
        # Copy the SSH key
        scp -O "$LOCAL_SSH_KEY" "$REMOTE_USER@$SERVER:~/.ssh/sf-compute"

        # Copy the SSH key
        scp -O "$LOCAL_SSH_KEY.pub" "$REMOTE_USER@$SERVER:~/.ssh/sf-compute.pub"
        
        # Set correct permissions on remote
        ssh -O "$REMOTE_USER@$SERVER" "chmod 600 ~/.ssh/sf-compute"
        
        echo "SSH key setup complete on $SERVER"
    ) &
done

