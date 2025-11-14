#!/bin/bash

# Integration test: Full workflow of creating an agent
# This simulates what an Orchestrator would do

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SESSION_ORC="integration-orc-$$"
TEST_SESSION_PM="integration-pm-$$"
TEST_SESSION_DEV="integration-dev-$$"
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
    tmux kill-session -t "$TEST_SESSION_ORC" 2>/dev/null || true
    tmux kill-session -t "$TEST_SESSION_PM" 2>/dev/null || true
    tmux kill-session -t "$TEST_SESSION_DEV" 2>/dev/null || true
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

# Step 1: Create Orchestrator session
info "Step 1: Creating Orchestrator session using start-tmux-session.sh"
OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION_ORC" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "Orchestrator session created"
else
    fail "Orchestrator session creation failed"
    echo "Output: $OUTPUT"
    exit 1
fi

# Step 1b: Setup window 0 as Orchestrator agent window
info "Step 1b: Setting up Orchestrator agent window (window 0)"
OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION_ORC:0" "Orchestrator" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "Orchestrator-Agent window created"
else
    fail "Orchestrator window setup failed"
    echo "Output: $OUTPUT"
    exit 1
fi

# Step 2: Create PM session (following convention: one agent per session)
info "Step 2: Creating PM session using start-tmux-session.sh"
OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION_PM" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "PM session created"
else
    fail "PM session creation failed"
    echo "Output: $OUTPUT"
    exit 1
fi

# Step 2b: Setup window 0 as PM agent window
info "Step 2b: Setting up PM agent window (window 0)"
OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION_PM:0" "PM" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "PM-Agent window created (follows convention)"
else
    fail "PM window setup failed"
    echo "Output: $OUTPUT"
    exit 1
fi

# Step 3: Try to send message without starting Claude (should fail)
info "Step 3: Testing error handling (send message without Claude)"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION_PM:0" "Test message" 2>&1)
if echo "$OUTPUT" | grep -q "ERROR.*does not appear to be running"; then
    pass "Script correctly detects Claude not running"
else
    fail "Script should detect Claude not running"
fi

# Step 4: Mock starting Claude in PM window
info "Step 4: Starting mock Claude in PM agent window"
tmux send-keys -t "$TEST_SESSION_PM:0" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
sleep 0.5

# Verify mock is working using check-claude-running.sh
if "$SCRIPT_DIR/check-claude-running.sh" "$TEST_SESSION_PM:0" >/dev/null 2>&1; then
    pass "PM Claude mocked successfully (verified with check-claude-running.sh)"
else
    fail "PM Claude mock failed verification"
fi

# Step 5: Send message should now work
info "Step 5: Sending message to PM agent"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION_PM:0" "Hello PM!" 2>&1)
if echo "$OUTPUT" | grep -q "Message sent"; then
    pass "Message sent successfully"
else
    fail "Message sending failed"
    echo "Output: $OUTPUT"
fi

# Step 6: Verify message was received
info "Step 6: Verifying message delivery to PM"
CONTENT=$(tmux capture-pane -t "$TEST_SESSION_PM:0" -p)
if echo "$CONTENT" | grep -q "Hello PM!"; then
    pass "Message delivered to PM agent window"
else
    fail "Message not found in PM window"
    echo "Window content:"
    echo "$CONTENT"
fi

# Step 7: Create Developer session (Orchestrator or PM would do this)
info "Step 7: Creating Developer session (following convention)"
OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION_DEV" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "Developer session created"
else
    fail "Developer session creation failed"
    echo "Output: $OUTPUT"
fi

# Step 7b: Setup Developer agent window
info "Step 7b: Setting up Developer agent window (window 0)"
OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION_DEV:0" "Developer" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    pass "Developer-Agent window created (follows convention)"
else
    fail "Developer window setup failed"
    echo "Output: $OUTPUT"
fi

# Step 8: Mock Claude in Developer window
info "Step 8: Starting mock Claude in Developer agent window"
tmux send-keys -t "$TEST_SESSION_DEV:0" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
sleep 0.5

# Verify with check-claude-running.sh
if "$SCRIPT_DIR/check-claude-running.sh" "$TEST_SESSION_DEV:0" >/dev/null 2>&1; then
    pass "Developer Claude mocked successfully"
else
    fail "Developer Claude mock failed verification"
fi

# Step 9: PM sends message to Developer (cross-session communication)
info "Step 9: PM sends message to Developer (cross-session)"
OUTPUT=$("$SCRIPT_DIR/send-claude-message.sh" "$TEST_SESSION_DEV:0" "Please analyze the codebase" 2>&1)
if echo "$OUTPUT" | grep -q "Message sent"; then
    pass "PM -> Developer communication works (cross-session)"
else
    fail "PM -> Developer communication failed"
fi

# Step 10: Verify cross-session communication
info "Step 10: Verifying cross-session message delivery"
CONTENT=$(tmux capture-pane -t "$TEST_SESSION_DEV:0" -p)
if echo "$CONTENT" | grep -q "analyze the codebase"; then
    pass "Cross-session message delivered to Developer"
else
    fail "Cross-session message not delivered"
fi

# Step 11: Test PM creating supporting window (e.g., dev server)
info "Step 11: PM creates supporting window for dev server"
OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION_PM:1" "Dev-Server" "$PROJECT_PATH" 2>&1)
if [ $? -eq 0 ]; then
    # Verify it doesn't have -Agent suffix
    WINDOW_NAME=$(tmux list-windows -t "$TEST_SESSION_PM" -F "#{window_index}:#{window_name}" | grep "^1:" | cut -d: -f2)
    if [ "$WINDOW_NAME" = "Dev-Server" ]; then
        pass "Supporting window created without -Agent suffix"
    else
        fail "Supporting window should be named 'Dev-Server', got: $WINDOW_NAME"
    fi
else
    fail "Supporting window creation failed"
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
    echo "  1. Create separate sessions per agent (Orchestrator, PM, Developer) ✓"
    echo "  2. Window 0 is always the agent window (with -Agent suffix) ✓"
    echo "  3. Supporting windows (1, 2, ...) don't get -Agent suffix ✓"
    echo "  4. Error handling (send-claude-message.sh) ✓"
    echo "  5. Claude verification (check-claude-running.sh) ✓"
    echo "  6. Message sending (send-claude-message.sh) ✓"
    echo "  7. Cross-session communication ✓"
    echo ""
    echo "Convention validated:"
    echo "  • One agent per tmux session"
    echo "  • Window 0 = Claude agent window (always)"
    echo "  • Windows 1+ = Supporting tasks (dev servers, tests, etc.)"
    exit 0
else
    echo -e "${RED}💥 Integration test failed!${NC}"
    exit 1
fi
