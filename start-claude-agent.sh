#!/bin/bash

# Start Claude agent in tmux window and optionally send initial message
# Usage: start-claude-agent.sh <session:window> [initial-message]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <session:window> [initial-message]"
    echo "Example: $0 project:0 'You are the PM for this project'"
    exit 1
fi

WINDOW="$1"
INITIAL_MESSAGE="${2:-}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if window exists
if ! tmux list-windows -t "${WINDOW%:*}" 2>/dev/null | grep -q "^${WINDOW#*:}:"; then
    echo "ERROR: Window $WINDOW does not exist"
    echo "Create the window first with: tmux new-window -t session -n 'window-name' -c '/path'"
    exit 1
fi

# Start Claude
echo "Starting Claude in $WINDOW..."
tmux send-keys -t "$WINDOW" "claude" Enter

# Wait for Claude to fully start (increased time for reliability)
echo "Waiting for Claude to initialize..."
sleep 7

# Verify Claude started by checking with the helper script
if ! "$SCRIPT_DIR/check-claude-running.sh" "$WINDOW" >/dev/null 2>&1; then
    CURRENT_COMMAND=$(tmux display-message -t "$WINDOW" -p '#{pane_current_command}' 2>/dev/null)
    echo "WARNING: Claude may not have started properly"
    echo "Current command: $CURRENT_COMMAND"
    echo "Last 10 lines:"
    tmux capture-pane -t "$WINDOW" -p | tail -10
    exit 1
fi

echo "✓ Claude started successfully in $WINDOW"

# Send initial message if provided
if [ -n "$INITIAL_MESSAGE" ]; then
    echo "Sending initial briefing..."
    sleep 1
    
    # Use the send-claude-message script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/send-claude-message.sh" "$WINDOW" "$INITIAL_MESSAGE"
    
    echo "✓ Initial message sent"
fi
