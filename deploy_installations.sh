#!/bin/bash
# List of remote servers
SERVERS=("ttt-1" "ttt-2" "ttt-3" "ttt-4" "ttt-5" "ttt-6" "ttt-7" "ttt-8")



# Path to the script
SCRIPT="./scripts/install.sh"
REMOTE_PATH="~/install_miniforge.sh"
# Remote user (change if necessary)
REMOTE_USER="root"



#!/bin/bash
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
        ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$SERVER" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
       
        # Copy the SSH key
        scp -O "$LOCAL_SSH_KEY" "$REMOTE_USER@$SERVER:~/.ssh/sf-compute"

        # Copy the SSH key
        scp -O "$LOCAL_SSH_KEY.pub" "$REMOTE_USER@$SERVER:~/.ssh/sf-compute.pub"
        
        # Set correct permissions on remote
        ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$SERVER" "chmod 600 ~/.ssh/sf-compute"

        ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$SERVER" "ssh-add ~/.ssh/sf-compute"
        
        echo "SSH key setup complete on $SERVER"
    ) &
done


Push script and execute on each server in parallel
for SERVER in "${SERVERS[@]}"; do
    (
        echo "Deploying to $SERVER..."
        # Copy the script to the remote server with strict host key checking disabled
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -O "$SCRIPT" "$REMOTE_USER@$SERVER:$REMOTE_PATH"
        # Run the script remotely with strict host key checking disabled
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$REMOTE_USER@$SERVER" "chmod +x $REMOTE_PATH && $REMOTE_PATH"
        echo "Finished setup on $SERVER!"
    ) &
done

# Wait for all background processes to complete
wait
echo "Deployment complete on all servers!"
