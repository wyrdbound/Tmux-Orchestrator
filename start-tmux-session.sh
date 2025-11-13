#!/bin/bash

# Start a new tmux session and verify it was created
# Usage: start-tmux-session.sh <session-name> [working-directory]

set -e  # Exit on error

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "ERROR: tmux is not installed"
    echo "Please install tmux first:"
    echo "  macOS: brew install tmux"
    echo "  Ubuntu/Debian: sudo apt-get install tmux"
    echo "  Fedora: sudo dnf install tmux"
    exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <session-name> [working-directory]"
    echo "Example: $0 my-project /path/to/project"
    exit 1
fi

SESSION_NAME="$1"
WORKING_DIR="${2:-$PWD}"

# Validate session name (tmux doesn't allow certain characters)
if [[ "$SESSION_NAME" =~ [:.] ]]; then
    echo "ERROR: Session name cannot contain ':' or '.' characters"
    echo "Suggested name: ${SESSION_NAME//:/-}"
    exit 1
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "ERROR: Session '$SESSION_NAME' already exists"
    echo "Attach to it with: tmux attach-session -t $SESSION_NAME"
    echo "Or kill it first with: tmux kill-session -t $SESSION_NAME"
    exit 1
fi

# Validate working directory if provided
if [ ! -d "$WORKING_DIR" ]; then
    echo "ERROR: Directory '$WORKING_DIR' does not exist"
    exit 1
fi

# Create new tmux session
echo "Creating tmux session '$SESSION_NAME' in $WORKING_DIR..."
tmux new-session -d -s "$SESSION_NAME" -c "$WORKING_DIR"

# Verify session was created
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "✓ Session '$SESSION_NAME' created successfully"
    echo ""
    echo "Active tmux sessions:"
    tmux ls
    echo ""
    echo "Attach to session with: tmux attach-session -t $SESSION_NAME"
    exit 0
else
    echo "ERROR: Failed to create session '$SESSION_NAME'"
    exit 1
fi
