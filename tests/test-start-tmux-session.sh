#!/bin/bash

# Test suite for start-tmux-session.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SESSION="test-session-$$"
TEST_SESSION_2="test-session-2-$$"

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
    tmux kill-session -t "$TEST_SESSION_2" 2>/dev/null || true
    tmux kill-session -t "invalid:name" 2>/dev/null || true
    tmux kill-session -t "invalid.name" 2>/dev/null || true
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

# Test 1: Script requires session name argument
test_requires_argument() {
    echo "Test 1: Script requires session name argument"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" 2>&1)
    if echo "$OUTPUT" | grep -q "Usage:"; then
        pass "Script shows usage when no arguments provided"
    else
        fail "Script should show usage when no arguments provided"
    fi
}

# Test 2: Script creates session successfully
test_creates_session() {
    echo "Test 2: Script creates session successfully"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION" 2>&1)
    
    # Check if session was created
    if tmux has-session -t "$TEST_SESSION" 2>/dev/null; then
        pass "Session created successfully"
    else
        fail "Session should have been created"
        return
    fi
    
    # Check output contains success message
    if echo "$OUTPUT" | grep -q "created successfully"; then
        pass "Script outputs success message"
    else
        fail "Script should output success message"
    fi
    
    # Check output shows tmux ls
    if echo "$OUTPUT" | grep -q "$TEST_SESSION"; then
        pass "Script shows session in tmux ls output"
    else
        fail "Script should show session in tmux ls output"
    fi
}

# Test 3: Script creates session with custom directory
test_custom_directory() {
    echo "Test 3: Script creates session with custom directory"
    
    # Use /tmp as test directory
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION_2" "/tmp" 2>&1)
    
    if tmux has-session -t "$TEST_SESSION_2" 2>/dev/null; then
        # Check if session is in correct directory
        PANE_DIR=$(tmux display-message -t "$TEST_SESSION_2:0" -p '#{pane_current_path}')
        if [ "$PANE_DIR" = "/tmp" ] || [ "$PANE_DIR" = "/private/tmp" ]; then
            pass "Session created in custom directory"
        else
            fail "Session should be in /tmp, got: $PANE_DIR"
        fi
    else
        fail "Session with custom directory should have been created"
    fi
}

# Test 4: Script rejects invalid directory
test_invalid_directory() {
    echo "Test 4: Script rejects invalid directory"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "test-invalid-$$" "/nonexistent/path" 2>&1)
    
    if echo "$OUTPUT" | grep -q "does not exist"; then
        pass "Script rejects invalid directory"
    else
        fail "Script should reject invalid directory"
    fi
    
    # Ensure session was not created
    if ! tmux has-session -t "test-invalid-$$" 2>/dev/null; then
        pass "Session not created with invalid directory"
    else
        fail "Session should not be created with invalid directory"
        tmux kill-session -t "test-invalid-$$" 2>/dev/null
    fi
}

# Test 5: Script rejects duplicate session name
test_duplicate_session() {
    echo "Test 5: Script rejects duplicate session name"
    
    # First session already exists from test 2
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "$TEST_SESSION" 2>&1)
    
    if echo "$OUTPUT" | grep -q "already exists"; then
        pass "Script detects existing session"
    else
        fail "Script should detect existing session"
    fi
}

# Test 6: Script rejects invalid session names with colons
test_invalid_name_colon() {
    echo "Test 6: Script rejects session name with colon"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "invalid:name" 2>&1)
    
    if echo "$OUTPUT" | grep -q "cannot contain"; then
        pass "Script rejects session name with colon"
    else
        fail "Script should reject session name with colon"
    fi
}

# Test 7: Script rejects invalid session names with dots
test_invalid_name_dot() {
    echo "Test 7: Script rejects session name with dot"
    
    OUTPUT=$("$SCRIPT_DIR/start-tmux-session.sh" "invalid.name" 2>&1)
    
    if echo "$OUTPUT" | grep -q "cannot contain"; then
        pass "Script rejects session name with dot"
    else
        fail "Script should reject session name with dot"
    fi
}

# Test 8: Script exits with proper status codes
test_exit_codes() {
    echo "Test 8: Script returns proper exit codes"
    
    # Success case - create new session
    UNIQUE_SESSION="test-exit-$$"
    "$SCRIPT_DIR/start-tmux-session.sh" "$UNIQUE_SESSION" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        pass "Script returns 0 on success"
    else
        fail "Script should return 0 on success"
    fi
    tmux kill-session -t "$UNIQUE_SESSION" 2>/dev/null
    
    # Failure case - no arguments
    "$SCRIPT_DIR/start-tmux-session.sh" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        pass "Script returns non-zero on error"
    else
        fail "Script should return non-zero on error"
    fi
}

# Test 9: Check if tmux is installed (this should always pass in test environment)
test_tmux_check() {
    echo "Test 9: Script checks for tmux installation"
    
    # We can't easily test the actual failure case without uninstalling tmux,
    # but we can verify the script runs the check by looking at the code
    if grep -q "command -v tmux" "$SCRIPT_DIR/start-tmux-session.sh"; then
        pass "Script includes tmux installation check"
    else
        fail "Script should check for tmux installation"
    fi
}

# Run tests
echo "========================================="
echo "Testing start-tmux-session.sh"
echo "========================================="
echo ""

# Clean up any leftover sessions from previous runs
teardown

test_requires_argument
test_creates_session
test_custom_directory
test_invalid_directory
test_duplicate_session
test_invalid_name_colon
test_invalid_name_dot
test_exit_codes
test_tmux_check

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
