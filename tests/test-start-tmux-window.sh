#!/bin/bash

# Test suite for start-tmux-window.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SESSION="test-window-$$"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track results
TESTS_PASSED=0
TESTS_FAILED=0

# Teardown - cleanup any test sessions
teardown() {
    echo "Cleaning up test sessions..."
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
    tmux kill-session -t "${TEST_SESSION}-2" 2>/dev/null || true
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

# Test 1: Script requires all arguments
test_requires_arguments() {
    echo "Test 1: Script requires all three arguments"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" 2>&1)
    if echo "$OUTPUT" | grep -q "Usage:"; then
        pass "Script shows usage when no arguments provided"
    else
        fail "Script should show usage when no arguments provided"
    fi
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "session:0" 2>&1)
    if echo "$OUTPUT" | grep -q "Usage:"; then
        pass "Script shows usage when only one argument provided"
    else
        fail "Script should show usage when insufficient arguments"
    fi
}

# Test 2: Script validates target format
test_validates_target_format() {
    echo "Test 2: Script validates session:window format"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "invalid-format" "WindowName" "/tmp" 2>&1)
    if echo "$OUTPUT" | grep -q "must be in format"; then
        pass "Script rejects invalid target format"
    else
        fail "Script should reject invalid target format"
    fi
}

# Test 3: Script detects non-existent session
test_nonexistent_session() {
    echo "Test 3: Script detects non-existent session"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "nonexistent-session:0" "Test" "/tmp" 2>&1)
    if echo "$OUTPUT" | grep -q "does not exist"; then
        pass "Script detects non-existent session"
    else
        fail "Script should detect non-existent session"
    fi
}

# Test 4: Script rejects invalid directory
test_invalid_directory() {
    echo "Test 4: Script rejects invalid directory"
    
    # Create a test session first
    tmux new-session -d -s "$TEST_SESSION" -c "/tmp"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:0" "Test" "/nonexistent/path" 2>&1)
    if echo "$OUTPUT" | grep -q "does not exist"; then
        pass "Script rejects invalid directory"
    else
        fail "Script should reject invalid directory"
    fi
}

# Test 5: Window 0 gets -Agent suffix
test_window_zero_agent_suffix() {
    echo "Test 5: Window 0 automatically gets -Agent suffix"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:0" "Developer" "/tmp" 2>&1)
    
    # Check the window name includes -Agent
    WINDOW_NAME=$(tmux list-windows -t "$TEST_SESSION" -F "#{window_name}" | head -1)
    if [ "$WINDOW_NAME" = "Developer-Agent" ]; then
        pass "Window 0 renamed to 'Developer-Agent'"
    else
        fail "Window 0 should be named 'Developer-Agent', got: $WINDOW_NAME"
    fi
    
    # Check output mentions the convention
    if echo "$OUTPUT" | grep -q "Agent Window Convention"; then
        pass "Output shows agent window convention reminder"
    else
        fail "Output should show agent window convention reminder"
    fi
}

# Test 6: Window 0 is in correct directory
test_window_zero_directory() {
    echo "Test 6: Window 0 is set to correct directory"
    
    # Window 0 already created in previous test, check its directory
    PANE_DIR=$(tmux display-message -t "$TEST_SESSION:0" -p '#{pane_current_path}')
    if [ "$PANE_DIR" = "/tmp" ] || [ "$PANE_DIR" = "/private/tmp" ]; then
        pass "Window 0 is in correct directory"
    else
        fail "Window 0 should be in /tmp, got: $PANE_DIR"
    fi
}

# Test 7: Create window 1 without -Agent suffix
test_window_one_no_suffix() {
    echo "Test 7: Window 1 does not get -Agent suffix"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:1" "Dev-Server" "/tmp" 2>&1)
    
    WINDOW_NAME=$(tmux list-windows -t "$TEST_SESSION" -F "#{window_index}:#{window_name}" | grep "^1:" | cut -d: -f2)
    if [ "$WINDOW_NAME" = "Dev-Server" ]; then
        pass "Window 1 named 'Dev-Server' (no -Agent suffix)"
    else
        fail "Window 1 should be named 'Dev-Server', got: $WINDOW_NAME"
    fi
}

# Test 8: Create multiple windows
test_multiple_windows() {
    echo "Test 8: Can create multiple windows"
    
    "$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:2" "Tests" "/tmp" >/dev/null 2>&1
    "$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:3" "Docker" "/tmp" >/dev/null 2>&1
    
    WINDOW_COUNT=$(tmux list-windows -t "$TEST_SESSION" | wc -l | tr -d ' ')
    if [ "$WINDOW_COUNT" -eq 4 ]; then
        pass "Created 4 windows (0, 1, 2, 3)"
    else
        fail "Should have 4 windows, got: $WINDOW_COUNT"
    fi
}

# Test 9: Cannot create duplicate window index
test_duplicate_window() {
    echo "Test 9: Cannot create duplicate window index"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:1" "Duplicate" "/tmp" 2>&1)
    if echo "$OUTPUT" | grep -q "already exists"; then
        pass "Script detects duplicate window index"
    else
        fail "Script should detect duplicate window index"
    fi
}

# Test 10: Window list is shown in output
test_shows_window_list() {
    echo "Test 10: Output shows current window list"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:4" "Shell" "/tmp" 2>&1)
    
    if echo "$OUTPUT" | grep -q "Current windows"; then
        pass "Output shows current window list"
    else
        fail "Output should show current window list"
    fi
    
    # Verify the list contains our windows
    if echo "$OUTPUT" | grep -q "Developer-Agent" && echo "$OUTPUT" | grep -q "Dev-Server"; then
        pass "Window list includes created windows"
    else
        fail "Window list should include created windows"
    fi
}

# Test 11: Success message includes window details
test_success_message() {
    echo "Test 11: Success message includes window details"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:5" "Logs" "/tmp" 2>&1)
    
    if echo "$OUTPUT" | grep -q "Window created successfully"; then
        pass "Success message displayed"
    else
        fail "Should show success message"
    fi
    
    if echo "$OUTPUT" | grep -q "$TEST_SESSION:5"; then
        pass "Success message includes session:window"
    else
        fail "Success message should include session:window"
    fi
}

# Test 12: Different session can have window 0
test_different_session_window_zero() {
    echo "Test 12: Different sessions can each have window 0"
    
    # Create second session
    TEST_SESSION_2="${TEST_SESSION}-2"
    tmux new-session -d -s "$TEST_SESSION_2" -c "/tmp"
    
    # Setup window 0 in second session
    OUTPUT=$("$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION_2:0" "PM" "/tmp" 2>&1)
    
    WINDOW_NAME=$(tmux list-windows -t "$TEST_SESSION_2" -F "#{window_name}" | head -1)
    if [ "$WINDOW_NAME" = "PM-Agent" ]; then
        pass "Second session has its own window 0 with -Agent suffix"
    else
        fail "Second session window 0 should be named 'PM-Agent', got: $WINDOW_NAME"
    fi
}

# Test 13: Exit codes
test_exit_codes() {
    echo "Test 13: Proper exit codes"
    
    # Success case
    "$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:6" "Test" "/tmp" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        pass "Returns 0 on success"
    else
        fail "Should return 0 on success"
    fi
    
    # Failure case - invalid directory
    "$SCRIPT_DIR/start-tmux-window.sh" "$TEST_SESSION:7" "Test" "/nonexistent" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        pass "Returns non-zero on error"
    else
        fail "Should return non-zero on error"
    fi
}

# Run tests
echo "========================================="
echo "Testing start-tmux-window.sh"
echo "========================================="
echo ""

# Clean up any leftover sessions
teardown

test_requires_arguments
test_validates_target_format
test_nonexistent_session
test_invalid_directory
test_window_zero_agent_suffix
test_window_zero_directory
test_window_one_no_suffix
test_multiple_windows
test_duplicate_window
test_shows_window_list
test_success_message
test_different_session_window_zero
test_exit_codes

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
