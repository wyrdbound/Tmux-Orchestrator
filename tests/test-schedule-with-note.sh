#!/bin/bash

# Simple test suite for schedule-with-note.sh
# Tests basic functionality and real scheduling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../schedule-with-note.sh"
NOTE_FILE="$SCRIPT_DIR/../next_check_note.txt"
PASSED=0
FAILED=0
TEST_SESSION="test-schedule-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cleanup() {
    # Kill any test tmux sessions
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null
    tmux kill-session -t "${TEST_SESSION}-target" 2>/dev/null
    
    # Kill any remaining scheduled processes
    pkill -f "schedule-with-note.sh.*test" 2>/dev/null
    
    # Clean up test note file
    rm -f "$NOTE_FILE" 2>/dev/null
}

# Ensure cleanup on exit
trap cleanup EXIT

pass() {
    echo -e "${GREEN}✓${NC} Test passed: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} Test failed: $1"
    ((FAILED++))
}

test_creates_note_file() {
    # Run in test mode to avoid actual scheduling
    "$SCRIPT" 5 "Test note content" "dummy:0" --test-mode >/dev/null 2>&1
    
    if [ -f "$NOTE_FILE" ]; then
        pass "creates note file"
    else
        fail "creates note file (file not created)"
    fi
    
    rm -f "$NOTE_FILE"
}

test_note_file_contains_message() {
    "$SCRIPT" 10 "Custom test message" "dummy:0" --test-mode >/dev/null 2>&1
    
    if grep -q "Custom test message" "$NOTE_FILE" 2>/dev/null; then
        pass "note file contains custom message"
    else
        fail "note file contains custom message"
    fi
    
    rm -f "$NOTE_FILE"
}

test_note_file_contains_timestamp() {
    "$SCRIPT" 5 "Test" "dummy:0" --test-mode >/dev/null 2>&1
    
    if grep -q "Next Check Note" "$NOTE_FILE" 2>/dev/null; then
        pass "note file contains timestamp header"
    else
        fail "note file contains timestamp header"
    fi
    
    rm -f "$NOTE_FILE"
}

test_note_file_contains_duration() {
    "$SCRIPT" 15 "Test" "dummy:0" --test-mode >/dev/null 2>&1
    
    if grep -q "Scheduled for: 15 minutes" "$NOTE_FILE" 2>/dev/null; then
        pass "note file contains scheduled duration"
    else
        fail "note file contains scheduled duration"
    fi
    
    rm -f "$NOTE_FILE"
}

test_default_arguments() {
    output=$("$SCRIPT" --test-mode 2>&1)
    
    # Check for default values in output
    if [[ "$output" =~ "tmux-orc:0" ]] && [[ "$output" =~ "3 minutes" ]]; then
        pass "uses default arguments"
    else
        fail "uses default arguments"
    fi
    
    rm -f "$NOTE_FILE"
}

test_custom_target_window() {
    output=$("$SCRIPT" 5 "Test" "custom-session:2" --test-mode 2>&1)
    
    if [[ "$output" =~ "custom-session:2" ]]; then
        pass "accepts custom target window"
    else
        fail "accepts custom target window"
    fi
    
    rm -f "$NOTE_FILE"
}

test_test_mode_no_scheduling() {
    output=$("$SCRIPT" 1 "Test" "dummy:0" --test-mode 2>&1)
    
    # In test mode, should say "TEST MODE" and not create background process
    if [[ "$output" =~ "TEST MODE" ]] && ! [[ "$output" =~ "PID:" ]]; then
        pass "test mode doesn't create background process"
    else
        fail "test mode doesn't create background process"
    fi
    
    rm -f "$NOTE_FILE"
}

test_actual_scheduling() {
    echo "  Running actual scheduling test (this will take ~3 seconds)..."
    
    # Create a test tmux session
    local target="${TEST_SESSION}-target"
    tmux new-session -d -s "$target" "bash" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        fail "actual scheduling (couldn't create tmux session)"
        return
    fi
    
    sleep 0.5
    
    # Schedule a message to appear in 2 seconds
    output=$("$SCRIPT" 0.033 "Scheduled test message" "$target:0" 2>&1)
    
    # Check that it reported successful scheduling
    if ! [[ "$output" =~ "Scheduled successfully" ]] || ! [[ "$output" =~ "PID:" ]]; then
        fail "actual scheduling (didn't report success)"
        tmux kill-session -t "$target" 2>/dev/null
        return
    fi
    
    # Wait for the scheduled command to execute
    sleep 3
    
    # Check if the cat command was executed (look for note file content)
    target_content=$(tmux capture-pane -t "$target:0" -p)
    
    if [[ "$target_content" =~ "Next Check Note" ]] || [[ "$target_content" =~ "cat" ]]; then
        pass "actual scheduling (message delivered)"
    else
        fail "actual scheduling (message not delivered)"
    fi
    
    tmux kill-session -t "$target" 2>/dev/null
    rm -f "$NOTE_FILE"
}

test_multiple_schedules_different_windows() {
    echo "  Testing multiple simultaneous schedules..."
    
    # Create two test tmux sessions
    local target1="${TEST_SESSION}-multi1"
    local target2="${TEST_SESSION}-multi2"
    
    tmux new-session -d -s "$target1" "bash" 2>/dev/null
    tmux new-session -d -s "$target2" "bash" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        fail "multiple schedules (couldn't create tmux sessions)"
        tmux kill-session -t "$target1" 2>/dev/null
        tmux kill-session -t "$target2" 2>/dev/null
        return
    fi
    
    sleep 0.5
    
    # Schedule to both windows
    output1=$("$SCRIPT" 0.033 "Message for window 1" "$target1:0" 2>&1)
    output2=$("$SCRIPT" 0.033 "Message for window 2" "$target2:0" 2>&1)
    
    # Both should report success
    if ! [[ "$output1" =~ "Scheduled successfully" ]] || ! [[ "$output2" =~ "Scheduled successfully" ]]; then
        fail "multiple schedules (scheduling failed)"
        tmux kill-session -t "$target1" 2>/dev/null
        tmux kill-session -t "$target2" 2>/dev/null
        return
    fi
    
    # Wait for execution
    sleep 3
    
    # Check both windows received cat commands
    content1=$(tmux capture-pane -t "$target1:0" -p)
    content2=$(tmux capture-pane -t "$target2:0" -p)
    
    if [[ "$content1" =~ "cat" ]] && [[ "$content2" =~ "cat" ]]; then
        pass "multiple schedules to different windows"
    else
        fail "multiple schedules to different windows"
    fi
    
    tmux kill-session -t "$target1" 2>/dev/null
    tmux kill-session -t "$target2" 2>/dev/null
    rm -f "$NOTE_FILE"
}

test_note_file_readable_by_scheduled_command() {
    echo "  Testing note file accessibility in scheduled command..."
    
    local target="${TEST_SESSION}-notefile"
    tmux new-session -d -s "$target" "bash" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        fail "note file accessibility (couldn't create tmux session)"
        return
    fi
    
    sleep 0.5
    
    # Schedule with a unique message
    local unique_msg="Unique test message $$"
    "$SCRIPT" 0.033 "$unique_msg" "$target:0" >/dev/null 2>&1
    
    # Wait for execution
    sleep 3
    
    # The scheduled command tries to cat the note file
    # Check if our unique message appears in the window
    content=$(tmux capture-pane -t "$target:0" -p)
    
    if [[ "$content" =~ "$unique_msg" ]]; then
        pass "note file readable by scheduled command"
    else
        fail "note file readable by scheduled command"
    fi
    
    tmux kill-session -t "$target" 2>/dev/null
    rm -f "$NOTE_FILE"
}

# Run tests
echo "========================================="
echo "Testing schedule-with-note.sh"
echo "========================================="
echo ""

test_creates_note_file
test_note_file_contains_message
test_note_file_contains_timestamp
test_note_file_contains_duration
test_default_arguments
test_custom_target_window
test_test_mode_no_scheduling
test_actual_scheduling
test_multiple_schedules_different_windows
test_note_file_readable_by_scheduled_command

echo ""
echo "========================================="
echo "Results: $PASSED passed, $FAILED failed"
echo "========================================="

[ $FAILED -eq 0 ] && exit 0 || exit 1
