#!/bin/bash

# List your machines here. Replace these with your actual hostnames or IP addresses.
machines1=(ttt-1 ttt-2 ttt-3 ttt-4 ttt-9 ttt-10)
machines2=(ttt-3 ttt-4 ttt-9 ttt-13 ttt-14 ttt-15)

machines=()
echo "hello"
if [[ "$1" == "1" ]]; then
	machines=("${machines1[@]}")
elif [[ "$1" == "2" ]]; then
	machines=("${machines2[@]}")
else
	kill $$
fi

for machine in "${machines[@]}"; do
    echo "Updating on ${machine}..."
    ssh "$machine" 'cd ~/ttte && git add . && git stash && git pull' &
    echo "Finished updating on ${machine}."
done

wait


