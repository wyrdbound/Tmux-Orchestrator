#!/bin/bash

# Create a new tmux window
# Convention: Window 0 is always the Claude agent window for that session
# Usage: start-tmux-window.sh <session:window-index> <window-name> <working-directory>

set -e  # Exit on error

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "ERROR: tmux is not installed"
    echo "Please install tmux first"
    exit 1
fi

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <session:window-index> <window-name> <working-directory>"
    echo ""
    echo "Creates a new tmux window following conventions:"
    echo "  - Window 0 is always the Claude agent window (automatically suffixed with '-Agent')"
    echo "  - Other windows can be for dev servers, tests, shells, etc."
    echo ""
    echo "Arguments:"
    echo "  session:window-index  - Target session and window (e.g., 'my-project:0')"
    echo "  window-name          - Descriptive name for the window"
    echo "  working-directory    - Path where this window will work"
    echo ""
    echo "Examples:"
    echo "  # Create agent window (window 0)"
    echo "  $0 backend:0 Developer /path/to/backend"
    echo "    → Creates window named 'Developer-Agent'"
    echo ""
    echo "  # Create supporting windows"
    echo "  $0 backend:1 Dev-Server /path/to/backend"
    echo "  $0 backend:2 Tests /path/to/backend"
    echo "  $0 backend:3 Docker /path/to/backend"
    exit 1
fi

TARGET="$1"
WINDOW_NAME="$2"
WORKING_DIR="$3"

# Parse session and window from TARGET
if [[ ! "$TARGET" =~ ^([^:]+):([0-9]+)$ ]]; then
    echo "ERROR: Target must be in format 'session:window-index'"
    echo "Example: my-project:0"
    exit 1
fi

SESSION_NAME="${BASH_REMATCH[1]}"
WINDOW_INDEX="${BASH_REMATCH[2]}"

# Validate session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "ERROR: Session '$SESSION_NAME' does not exist"
    echo "Create it first with: ./start-tmux-session.sh $SESSION_NAME"
    exit 1
fi

# Validate working directory
if [ ! -d "$WORKING_DIR" ]; then
    echo "ERROR: Directory '$WORKING_DIR' does not exist"
    exit 1
fi

# Enforce convention: Window 0 must be agent window
if [ "$WINDOW_INDEX" -eq 0 ]; then
    FINAL_WINDOW_NAME="${WINDOW_NAME}-Agent"
    echo "Creating agent window (window 0): $WINDOW_NAME"
    echo "  → Window will be named: $FINAL_WINDOW_NAME"
else
    FINAL_WINDOW_NAME="${WINDOW_NAME}"
    echo "Creating window $WINDOW_INDEX: $WINDOW_NAME"
fi

# Check if window already exists (but skip this check for window 0, which we can rename)
if [ "$WINDOW_INDEX" -ne 0 ] && tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "^${WINDOW_INDEX}:"; then
    echo "ERROR: Window $WINDOW_INDEX already exists in session '$SESSION_NAME'"
    echo "Existing windows:"
    tmux list-windows -t "$SESSION_NAME" -F "  #{window_index}: #{window_name}"
    exit 1
fi

# Create the window
if [ "$WINDOW_INDEX" -eq 0 ]; then
    # For window 0, we need to rename the default window created with the session
    # Check if window 0 exists and rename it
    if tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "^0:"; then
        echo "Renaming existing window 0 to $FINAL_WINDOW_NAME..."
        # Set the working directory first
        tmux send-keys -t "$SESSION_NAME:0" "cd '$WORKING_DIR'" Enter
        sleep 0.1
        # Disable automatic-rename for this window before renaming
        tmux set-window-option -t "$SESSION_NAME:0" automatic-rename off
        tmux rename-window -t "$SESSION_NAME:0" "$FINAL_WINDOW_NAME"
    else
        # This shouldn't happen as tmux always creates window 0, but handle it
        echo "Creating window 0..."
        tmux new-window -d -t "$SESSION_NAME:0" -n "$FINAL_WINDOW_NAME" -c "$WORKING_DIR"
        tmux set-window-option -t "$SESSION_NAME:0" automatic-rename off
    fi
else
    # Create new window at specific index IN DETACHED MODE (don't switch to it)
    tmux new-window -d -t "$SESSION_NAME:$WINDOW_INDEX" -n "$FINAL_WINDOW_NAME" -c "$WORKING_DIR"
    # Disable automatic-rename to keep our chosen name
    tmux set-window-option -t "$SESSION_NAME:$WINDOW_INDEX" automatic-rename off
    # Brief pause to ensure tmux has processed the window creation
    sleep 0.1
fi

# Verify window was created/renamed
if tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "^${WINDOW_INDEX}:"; then
    echo "✓ Window created successfully: $SESSION_NAME:$WINDOW_INDEX ($FINAL_WINDOW_NAME)"
    
    # Show convention reminder for window 0
    if [ "$WINDOW_INDEX" -eq 0 ]; then
        echo ""
        echo "📋 Agent Window Convention:"
        echo "  - This is the Claude agent window for this session"
        echo "  - Start Claude here with: ./start-claude-agent.sh $SESSION_NAME:0"
        echo "  - Agent can create additional windows (1, 2, 3...) for:"
        echo "    • Dev servers (npm run dev, uvicorn, etc.)"
        echo "    • Test runners (pytest, jest, etc.)"
        echo "    • Docker containers or other services"
        echo "    • Shell access for running commands"
    fi
    
    echo ""
    echo "Current windows in session '$SESSION_NAME':"
    tmux list-windows -t "$SESSION_NAME" -F "  #{window_index}: #{window_name} (#{pane_current_path})"
    exit 0
else
    echo "ERROR: Failed to create window $WINDOW_INDEX"
    exit 1
fi
