#!/bin/bash

# Test suite for start-claude-agent.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SESSION="test-start-agent-$$"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track results
TESTS_PASSED=0
TESTS_FAILED=0

# Setup
setup() {
    echo "Setting up test session: $TEST_SESSION"
    tmux new-session -d -s "$TEST_SESSION" -n "test-window"
    sleep 1
}

# Teardown
teardown() {
    echo "Cleaning up test session: $TEST_SESSION"
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
}

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

# Ensure cleanup happens even if script is interrupted
trap teardown EXIT

# Test 1: Script requires at least one argument
test_requires_argument() {
    echo "Test 1: Script requires window argument"
    
    OUTPUT=$("$SCRIPT_DIR/start-claude-agent.sh" 2>&1)
    if echo "$OUTPUT" | grep -q "Usage:"; then
        pass "Script shows usage when no arguments provided"
    else
        fail "Script should show usage when no arguments provided"
    fi
}

# Test 2: Script detects non-existent window
test_nonexistent_window() {
    echo "Test 2: Script detects non-existent window"
    
    OUTPUT=$("$SCRIPT_DIR/start-claude-agent.sh" "nonexistent:99" 2>&1)
    if echo "$OUTPUT" | grep -q "ERROR:.*does not exist"; then
        pass "Script detects non-existent window"
    else
        fail "Script should detect non-existent window"
    fi
}

# Test 3: Script works with existing window (mock test - won't actually start Claude)
test_existing_window() {
    echo "Test 3: Script accepts valid window format"
    
    # This test would actually try to start Claude, so we'll just verify
    # the window format is accepted (would fail at Claude verification stage)
    OUTPUT=$("$SCRIPT_DIR/start-claude-agent.sh" "$TEST_SESSION:0" 2>&1)
    
    # Should get to the "Starting Claude" message
    if echo "$OUTPUT" | grep -q "Starting Claude"; then
        pass "Script accepts valid window and attempts to start Claude"
    else
        fail "Script should accept valid window format"
    fi
}

# Run tests
echo "========================================="
echo "Testing start-claude-agent.sh"
echo "========================================="
echo ""

setup

test_requires_argument
test_nonexistent_window
test_existing_window

# Summary
echo ""
echo "========================================="
echo "Test Results"
echo "========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
