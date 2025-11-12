#!/bin/bash

# Integration test: Full workflow of creating an agent
# This simulates what an Orchestrator would do

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SESSION="integration-test-$$"
PROJECT_PATH="$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

cleanup() {
    echo ""
    echo "Cleaning up..."
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
}

trap cleanup EXIT

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "========================================="
echo "Integration Test: Agent Creation Workflow"
echo "========================================="
echo ""

# Step 1: Create tmux session
info "Step 1: Creating tmux session '$TEST_SESSION'"
tmux new-session -d -s "$TEST_SESSION" -c "$PROJECT_PATH"
if [ $? -eq 0 ]; then
    pass "Tmux session created"
else
    fail "Tmux session creation failed"
    exit 1
fi

# Step 2: Create PM window
info "Step 2: Creating PM window"
tmux new-window -t "$TEST_SESSION" -n "PM" -c "$PROJECT_PATH"
if [ $? -eq 0 ]; then
    pass "PM window created"
else
    fail "PM window creation failed"
    exit 1
fi

# Step 3: Try to send message without starting Claude (should fail)
info "Step 3: Testing error handling (send message without Claude)"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION:1" "Test message" 2>&1)
if echo "$OUTPUT" | grep -q "ERROR.*does not appear to be running"; then
    pass "Script correctly detects Claude not running"
else
    fail "Script should detect Claude not running"
fi

# Step 4: Mock starting Claude
info "Step 4: Mocking Claude startup"
tmux send-keys -t "$TEST_SESSION:1" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
sleep 0.5

# Verify mock is working - check for child processes with "claude" in name
PANE_PID=$(tmux display-message -t "$TEST_SESSION:1" -p '#{pane_pid}')
CLAUDE_FOUND=false
for pid in $(pgrep -P "$PANE_PID" 2>/dev/null); do
    if ps -p "$pid" -o command= | grep -qi claude; then
        CLAUDE_FOUND=true
        break
    fi
done

if [ "$CLAUDE_FOUND" = true ]; then
    pass "Claude mocked successfully"
else
    fail "Claude mock failed"
fi

# Step 5: Send message should now work
info "Step 5: Sending message to mocked Claude"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION:1" "Hello PM!" 2>&1)
if echo "$OUTPUT" | grep -q "Message sent"; then
    pass "Message sent successfully"
else
    fail "Message sending failed"
    echo "Output: $OUTPUT"
fi

# Step 6: Verify message was received
info "Step 6: Verifying message delivery"
CONTENT=$(tmux capture-pane -t "$TEST_SESSION:1" -p)
if echo "$CONTENT" | grep -q "Hello PM!"; then
    pass "Message delivered to window"
else
    fail "Message not found in window"
    echo "Window content:"
    echo "$CONTENT"
fi

# Step 7: Create Developer window
info "Step 7: Creating Developer window (PM would do this)"
tmux new-window -t "$TEST_SESSION" -n "Developer" -c "$PROJECT_PATH"
if [ $? -eq 0 ]; then
    pass "Developer window created"
else
    fail "Developer window creation failed"
fi

# Step 8: Mock Claude in Developer window
info "Step 8: Mocking Claude in Developer window"
tmux send-keys -t "$TEST_SESSION:2" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
sleep 0.5

# Step 9: PM sends message to Developer
info "Step 9: PM sends message to Developer"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION:2" "Please analyze the codebase" 2>&1)
if echo "$OUTPUT" | grep -q "Message sent"; then
    pass "PM -> Developer communication works"
else
    fail "PM -> Developer communication failed"
fi

# Step 10: Verify cross-window communication
info "Step 10: Verifying cross-window message"
CONTENT=$(tmux capture-pane -t "$TEST_SESSION:2" -p)
if echo "$CONTENT" | grep -q "analyze the codebase"; then
    pass "Cross-window message delivered"
else
    fail "Cross-window message not delivered"
fi

echo ""
echo "========================================="
echo "Integration Test Results"
echo "========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Integration test passed!${NC}"
    echo ""
    echo "The agent creation workflow works correctly:"
    echo "  1. Create tmux session ✓"
    echo "  2. Create agent windows ✓"
    echo "  3. Error handling works ✓"
    echo "  4. Message sending works ✓"
    echo "  5. Cross-window communication works ✓"
    exit 0
else
    echo -e "${RED}💥 Integration test failed!${NC}"
    exit 1
fi
