#!/bin/bash

# Define your server list
servers=("ttt-1" "ttt-2" "ttt-3" "ttt-4" "ttt-5" "ttt-6" "ttt-7" "ttt-8")

# Open iTerm2 and create a new window
osascript <<EOF
tell application "iTerm2"
  create window with default profile
end tell
EOF

# Iterate over each server and open a new tab
for server in "${servers[@]}"; do
  osascript <<EOF
  tell application "iTerm2"
    tell current window
      create tab with default profile
      tell current session of current tab
        write text "ssh $server -t '(tmux attach || tmux new -s 0) && (git add . && git stash && git pull.rebase true && git pull)'"
      end tell
    end tell
  end tell
EOF
done
