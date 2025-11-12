#!/bin/bash

# Check if Claude is running in a tmux window
# Usage: check-claude-running.sh <session:window>
# Exit codes:
#   0 - Claude is running
#   1 - Claude is not running
#   2 - Error (window doesn't exist, etc.)

if [ $# -lt 1 ]; then
    echo "Usage: $0 <session:window>" >&2
    echo "Example: $0 agentic-seek:3" >&2
    exit 2
fi

WINDOW="$1"

# Check if window exists
if ! tmux list-windows -t "${WINDOW%:*}" 2>/dev/null | grep -q "^${WINDOW#*:}:"; then
    echo "ERROR: Window $WINDOW does not exist" >&2
    exit 2
fi

# Get the PID of the process running in the pane
PANE_PID=$(tmux display-message -t "$WINDOW" -p '#{pane_pid}' 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Could not get pane PID from $WINDOW" >&2
    exit 2
fi

# Get the full command line of processes in this pane
# We look for child processes of the pane's shell that contain "claude"
# Use pgrep to find processes whose parent is the pane PID, then check their command lines
CLAUDE_PIDS=$(pgrep -P "$PANE_PID" 2>/dev/null)
COMMAND_LINE=""

if [ -n "$CLAUDE_PIDS" ]; then
    # Check each child process to see if it's claude-related
    for pid in $CLAUDE_PIDS; do
        CMD=$(ps -p "$pid" -o command= 2>/dev/null)
        if echo "$CMD" | grep -qi claude; then
            COMMAND_LINE="$CMD"
            break
        fi
    done
fi

# Check if Claude is actually running
if [ -z "$COMMAND_LINE" ]; then
    exit 1  # Not running
else
    exit 0  # Running
fi
