#!/bin/bash
# Dynamic scheduler with note for next check
# Usage: ./schedule-with-note.sh <minutes> "<note>" [target_window] [--test-mode]

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTE_FILE="$SCRIPT_DIR/next_check_note.txt"

# Check for test mode flag first
TEST_MODE=""
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--test-mode" ]; then
        TEST_MODE="--test-mode"
    else
        ARGS+=("$arg")
    fi
done

# Now parse positional arguments (without --test-mode)
MINUTES=${ARGS[0]:-3}
NOTE=${ARGS[1]:-"Standard check-in"}
TARGET=${ARGS[2]:-"tmux-orc:0"}

# Create a note file for the next check
echo "=== Next Check Note ($(date)) ===" > "$NOTE_FILE"
echo "Scheduled for: $MINUTES minutes" >> "$NOTE_FILE"
echo "" >> "$NOTE_FILE"
echo "$NOTE" >> "$NOTE_FILE"

echo "Scheduling check in $MINUTES minutes with note: $NOTE"

# Calculate the exact time when the check will run
CURRENT_TIME=$(date +"%H:%M:%S")
RUN_TIME=$(date -v +${MINUTES}M +"%H:%M:%S" 2>/dev/null || date -d "+${MINUTES} minutes" +"%H:%M:%S" 2>/dev/null)

# Use nohup to completely detach the sleep process
# Use bc for floating point calculation
SECONDS=$(echo "$MINUTES * 60" | bc)

if [ "$TEST_MODE" = "--test-mode" ]; then
    # In test mode, just verify the command would work without actually scheduling
    echo "TEST MODE: Would schedule to run at $RUN_TIME (in $MINUTES minutes from $CURRENT_TIME)"
    echo "TEST MODE: Target window: $TARGET"
    echo "TEST MODE: Note file created at: $NOTE_FILE"
    exit 0
fi

# Create the command to run - escape properly for nohup
COMMAND="tmux send-keys -t $TARGET 'cat \"$NOTE_FILE\"' Enter"

nohup bash -c "sleep $SECONDS && $COMMAND" > /dev/null 2>&1 &

# Get the PID of the background process
SCHEDULE_PID=$!

echo "Scheduled successfully - process detached (PID: $SCHEDULE_PID)"
echo "SCHEDULED TO RUN AT: $RUN_TIME (in $MINUTES minutes from $CURRENT_TIME)"