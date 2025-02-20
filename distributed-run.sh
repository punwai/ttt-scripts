#!/bin/bash

# Save as ~/scripts/distributed-run

if [ "$#" -lt 2 ]; then
    echo "Usage: sh ~/scripts/distributed-run \"machine1 machine2 machine3...\" \"PYTHON_SCRIPT\""
    exit 1
fi

# First argument is space-separated machine names
MACHINES=($1)
# Second argument is the command
COMMAND=$2

evaluate_math() {
    local expr=$1
    echo "scale=6; $expr" | bc | sed 's/^\./0./' | sed 's/^-\./-0./' | awk '{printf "%.6f\n", $0}' | sed 's/\.000000$//'
}

process_template() {
    local template=$1
    local id=$2
    local machine_name=${MACHINES[$id]}
    
    while [[ "$template" =~ \$\{([^}]*)\} ]]; do
        local match="${BASH_REMATCH[0]}"
        local expr="${BASH_REMATCH[1]}"
        
        expr=${expr//id/$id}
        expr=${expr//machine_name/$machine_name}
        
        if [[ $expr =~ [+\-*/%] ]]; do
            local result=$(evaluate_math "$expr")
            template=${template//$match/$result}
        else
            case $expr in
                "id") template=${template//$match/$id};;
                "machine_name") template=${template//$match/$machine_name};;
                *) echo "Unknown variable: $expr"; exit 1;;
            esac
        fi
    done
    
    echo "$template"
}

# Get number of machines
NUM_MACHINES=${#MACHINES[@]}

# Run commands on all machines simultaneously
for ((id=0; id<NUM_MACHINES; id++)); do
    machine_name=${MACHINES[$id]}
    processed_command=$(process_template "$COMMAND" "$id")
    
    (
        ssh "$machine_name" << EOF &
            tmux send-keys -t 0 "conda activate ttt" Enter
            tmux send-keys -t 0 "cd ttte" Enter
            tmux send-keys -t 0 "$processed_command" Enter
EOF
    )
done

wait
