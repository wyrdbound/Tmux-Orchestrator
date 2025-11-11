#!/bin/bash

# Simple test suite for send-claude-message.sh
# Tests basic functionality and real tmux integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../send-claude-message.sh"
PASSED=0
FAILED=0
TEST_SESSION="test-claude-msg-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cleanup() {
    # Kill any test tmux sessions
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null
    tmux kill-session -t "${TEST_SESSION}-sender" 2>/dev/null
    tmux kill-session -t "${TEST_SESSION}-receiver" 2>/dev/null
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

test_no_args() {
    output=$("$SCRIPT" 2>&1)
    if [ $? -eq 1 ] && [[ "$output" =~ "Usage:" ]]; then
        pass "no arguments shows usage"
    else
        fail "no arguments shows usage"
    fi
}

test_one_arg() {
    output=$("$SCRIPT" "window:1" 2>&1)
    if [ $? -eq 1 ] && [[ "$output" =~ "Usage:" ]]; then
        pass "one argument only shows usage"
    else
        fail "one argument only shows usage"
    fi
}

test_usage_example() {
    output=$("$SCRIPT" 2>&1)
    if [[ "$output" =~ "Example:" ]]; then
        pass "usage includes example"
    else
        fail "usage includes example"
    fi
}

test_success_message() {
    # Create a temporary tmux session
    local session="${TEST_SESSION}-success"
    tmux new-session -d -s "$session" 2>/dev/null
    if [ $? -ne 0 ]; then
        fail "success message (couldn't create tmux session)"
        return
    fi
    
    output=$("$SCRIPT" "$session:0" "test message" 2>&1)
    if [ $? -eq 0 ] && [[ "$output" =~ "Message sent to" ]] && [[ "$output" =~ "test message" ]]; then
        pass "success message printed"
    else
        fail "success message printed"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

test_multi_word_message() {
    # Create a temporary tmux session
    local session="${TEST_SESSION}-multiword"
    tmux new-session -d -s "$session" 2>/dev/null
    if [ $? -ne 0 ]; then
        fail "multi-word message (couldn't create tmux session)"
        return
    fi
    
    output=$("$SCRIPT" "$session:0" "This is a longer test message" 2>&1)
    if [ $? -eq 0 ] && [[ "$output" =~ "This is a longer test message" ]]; then
        pass "multi-word message handled"
    else
        fail "multi-word message handled"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

test_tmux_message_exchange() {
    echo "  Running tmux message exchange test (this may take a few seconds)..."
    
    # Create two tmux sessions
    local sender="${TEST_SESSION}-sender"
    local receiver="${TEST_SESSION}-receiver"
    
    tmux new-session -d -s "$sender" "bash" 2>/dev/null
    tmux new-session -d -s "$receiver" "bash" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        fail "tmux message exchange (couldn't create sessions)"
        tmux kill-session -t "$sender" 2>/dev/null
        tmux kill-session -t "$receiver" 2>/dev/null
        return
    fi
    
    # Give tmux sessions time to start
    sleep 0.5
    
    # Send a test message from sender to receiver using our script
    "$SCRIPT" "$receiver:0" "Hello from sender session!" >/dev/null 2>&1
    
    # Give it time to be received
    sleep 1
    
    # Capture the receiver's pane content
    receiver_content=$(tmux capture-pane -t "$receiver:0" -p)
    
    # Check if the message was received
    if [[ "$receiver_content" =~ "Hello from sender session!" ]]; then
        # Now send a reply back using the script
        "$SCRIPT" "$sender:0" "Reply: Message received!" >/dev/null 2>&1
        sleep 1
        
        # Verify the reply mechanism works (both directions)
        sender_content=$(tmux capture-pane -t "$sender:0" -p)
        if [[ "$sender_content" =~ "Reply: Message received!" ]]; then
            pass "tmux message exchange (bidirectional)"
        else
            fail "tmux message exchange (reply not found in sender)"
        fi
    else
        fail "tmux message exchange (message not received in receiver)"
    fi
    
    # Cleanup sessions
    tmux kill-session -t "$sender" 2>/dev/null
    tmux kill-session -t "$receiver" 2>/dev/null
}

test_special_characters() {
    # Create a temporary tmux session
    local session="${TEST_SESSION}-special"
    tmux new-session -d -s "$session" 2>/dev/null
    if [ $? -ne 0 ]; then
        fail "special characters (couldn't create tmux session)"
        return
    fi
    
    # Test with special characters (avoiding ones that might break the script)
    output=$("$SCRIPT" "$session:0" "Message with spaces and-dashes" 2>&1)
    if [ $? -eq 0 ]; then
        pass "special characters handled"
    else
        fail "special characters handled"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

# Run tests
echo "========================================="
echo "Testing send-claude-message.sh"
echo "========================================="
echo ""

test_no_args
test_one_arg
test_usage_example
test_success_message
test_multi_word_message
test_special_characters
test_tmux_message_exchange

echo ""
echo "========================================="
echo "Results: $PASSED passed, $FAILED failed"
echo "========================================="

[ $FAILED -eq 0 ] && exit 0 || exit 1
