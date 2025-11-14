#!/bin/bash

# Test suite for check-claude-running.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$SCRIPT_DIR/check-claude-running.sh"
TEST_SESSION="test-check-claude-$$"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track results
TESTS_PASSED=0
TESTS_FAILED=0

cleanup() {
    # Kill any test tmux sessions
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null
    tmux kill-session -t "${TEST_SESSION}-claude" 2>/dev/null
    tmux kill-session -t "${TEST_SESSION}-no-claude" 2>/dev/null
}

trap cleanup EXIT

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

echo "========================================="
echo "Testing check-claude-running.sh"
echo "========================================="
echo ""

# Test 1: No arguments shows usage
test_no_args() {
    output=$("$SCRIPT" 2>&1)
    if [ $? -eq 2 ] && [[ "$output" =~ "Usage:" ]]; then
        pass "No arguments shows usage and exits with code 2"
    else
        fail "No arguments should show usage and exit with code 2"
    fi
}

# Test 2: Non-existent window returns error
test_nonexistent_window() {
    output=$("$SCRIPT" "nonexistent:99" 2>&1)
    exit_code=$?
    if [ $exit_code -eq 2 ] && [[ "$output" =~ "does not exist" ]]; then
        pass "Non-existent window returns error (exit code 2)"
    else
        fail "Non-existent window should return exit code 2"
    fi
}

# Test 3: Window without Claude returns exit code 1
test_window_without_claude() {
    local session="${TEST_SESSION}-no-claude"
    tmux new-session -d -s "$session" 2>/dev/null
    sleep 0.3
    
    "$SCRIPT" "$session:0" >/dev/null 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 1 ]; then
        pass "Window without Claude returns exit code 1"
    else
        fail "Window without Claude should return exit code 1 (got $exit_code)"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

# Test 4: Window with Claude returns exit code 0
test_window_with_claude() {
    local session="${TEST_SESSION}-claude"
    tmux new-session -d -s "$session" 2>/dev/null
    sleep 0.3
    
    # Start mock claude
    tmux send-keys -t "$session:0" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
    sleep 0.5
    
    "$SCRIPT" "$session:0" >/dev/null 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        pass "Window with Claude returns exit code 0"
    else
        fail "Window with Claude should return exit code 0 (got $exit_code)"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

# Test 5: Can be used in conditionals (if statement)
test_conditional_usage() {
    local session="${TEST_SESSION}"
    tmux new-session -d -s "$session" 2>/dev/null
    sleep 0.3
    
    # Start mock claude
    tmux send-keys -t "$session:0" "$SCRIPT_DIR/tests/mock-claude.sh" Enter
    sleep 0.5
    
    # Test if statement usage
    if "$SCRIPT" "$session:0" >/dev/null 2>&1; then
        pass "Can be used in if statement (Claude running)"
    else
        fail "Should work in if statement when Claude is running"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

# Test 6: Can be used in conditionals (negative check)
test_conditional_negative() {
    local session="${TEST_SESSION}"
    tmux new-session -d -s "$session" 2>/dev/null
    sleep 0.3
    
    # Don't start Claude
    
    # Test if statement usage
    if ! "$SCRIPT" "$session:0" >/dev/null 2>&1; then
        pass "Can be used in if statement (Claude not running)"
    else
        fail "Should work in if statement when Claude is not running"
    fi
    
    tmux kill-session -t "$session" 2>/dev/null
}

# Run all tests
test_no_args
test_nonexistent_window
test_window_without_claude
test_window_with_claude
test_conditional_usage
test_conditional_negative

echo ""
echo "========================================="
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "========================================="

[ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
