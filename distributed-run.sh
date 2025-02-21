#!/bin/bash
# Save as ~/scripts/distributed-run
# Function to kill processes in all tmux sessions
kill_tmux_processes() {
    echo "Sending kill signal to all tmux sessions..."
    for ((id=0; id<NUM_MACHINES; id++)); do
        machine_name=${MACHINES[$id]}
        
        (
            echo "Sending Ctrl+C to $machine_name..."
            ssh -T "$machine_name" "tmux has-session -t 0 2>/dev/null && tmux send-keys -t 0 C-c" &
        )
    done
    wait
    echo "Kill signals sent to all machines."
}


safe_replace() {
    local template="$1"
    local match="$2"
    local expr="$3"
    
    # Escape special regex characters in match and expr
    local escaped_match=$(printf '%s' "$match" | sed 's/[]\[^$.*/]/\\&/g')
    local escaped_expr=$(printf '%s' "$expr" | sed 's/[]\[^$.*/]/\\&/g')
    
    # Perform global replacement using sed
    printf '%s' "$template" | sed "s/$escaped_match/$escaped_expr/g"
}



escape_dollars() {
    local input="$1"
    local escaped_string="${input//\$/\\$}"
    echo "$escaped_string"
}

# Check for kill command
if [[ "$1" == "--kill" ]]; then
    # Set machines from argument or default
    ARG2="${2:-"ttt-1 ttt-2 ttt-3 ttt-4 ttt-5 ttt-6 ttt-7 ttt-8"}"
    MACHINES=($ARG2)
    NUM_MACHINES=${#MACHINES[@]}
    
    kill_tmux_processes
    exit 0
fi
ARG1="$1"
# Set default for second argument if not provided
ARG2="${2:-"ttt-1 ttt-2 ttt-3 ttt-4 ttt-5 ttt-6 ttt-7 ttt-8"}"
# First argument is the command, second is space-separated machine names
COMMAND=$ARG1
MACHINES=($ARG2)

evaluate_math() {
    local expr=$1
    echo "scale=6; $expr" | bc | sed 's/^\./0./' | sed 's/^-\./-0./' | awk '{printf "%.6f\n", $0}' | sed 's/\.000000$//'
}

process_template() {
    local template=$1
    local id=$2
    local machine_name=${MACHINES[$id]}

    # Process the template to replace variables
    while [[ "$template" =~ \$\[([^]]*)\] ]]; do
        local match="${BASH_REMATCH[0]}"
        local expr="${BASH_REMATCH[1]}"
        
        expr=${expr//id/$id}
        expr=${expr//machine_name/$machine_name}

        if [[ $expr =~ [+\-*/%] ]]; then
            local result=$(evaluate_math "$expr")
	    template=$(safe_replace "$template" "$match" "$expr")
        else
	    template=$(safe_replace "$template" "$match" "$expr")
	    break
        fi
    done

    echo "$template $match $expr"
}

# Get number of machines
NUM_MACHINES=${#MACHINES[@]}
# Run commands on all machines simultaneously
for ((id=0; id<NUM_MACHINES; id++)); do
    machine_name=${MACHINES[$id]}
    processed_command=$(process_template "$COMMAND" "$id")
    echo "$processed_command"
    
    (
        ssh -T "$machine_name" << EOF &
            tmux has-session -t 0 2>/dev/null || tmux new-session -d -s 0
            tmux send-keys -t 0 "conda activate ttt" Enter
            tmux send-keys -t 0 "cd ~/ttte" Enter
            tmux send-keys -t 0 "$processed_command" Enter
	    EOF
    )
done
echo "Commands sent to all machines. To kill all processes, run: $(basename $0) --kill"
wait
