#!/bin/bash

# Send message to Claude agent in tmux window
# Usage: send-claude-message.sh <session:window> <message>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <session:window> <message>"
    echo "Example: $0 agentic-seek:3 'Hello Claude!'"
    exit 1
fi

WINDOW="$1"
shift  # Remove first argument, rest is the message
MESSAGE="$*"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Claude is running using the helper script
if ! "$SCRIPT_DIR/check-claude-running.sh" "$WINDOW" 2>/dev/null; then
    CURRENT_COMMAND=$(tmux display-message -t "$WINDOW" -p '#{pane_current_command}' 2>/dev/null)
    echo "ERROR: Claude does not appear to be running in $WINDOW"
    echo "Current command: $CURRENT_COMMAND"
    echo "Please start Claude first using: ./start-claude-agent.sh $WINDOW"
    exit 1
fi

# Send the message
tmux send-keys -t "$WINDOW" "$MESSAGE"

# Wait 0.5 seconds for UI to register
sleep 0.5

# Send Enter to submit
tmux send-keys -t "$WINDOW" Enter

echo "Message sent to $WINDOW: $MESSAGE"