# Test Suite Documentation

This directory contains test suites for the Tmux Orchestrator bash scripts.

## Running Tests

Run all tests:

```bash
./tests/test-send-claude-message.sh
./tests/test-schedule-with-note.sh
```

Or run them together:

```bash
./tests/test-send-claude-message.sh && ./tests/test-schedule-with-note.sh
```

## Test Files

### test-send-claude-message.sh

Tests for the `send-claude-message.sh` script.

**Tests (7 total):**

- ✓ No arguments shows usage
- ✓ One argument only shows usage
- ✓ Usage includes example
- ✓ Success message printed
- ✓ Multi-word message handled
- ✓ Special characters handled
- ✓ Bidirectional tmux message exchange

**Key Features:**

- Creates temporary tmux sessions for testing
- Tests actual message delivery between sessions
- Verifies bidirectional communication
- Automatic cleanup with trap EXIT

### test-schedule-with-note.sh

Tests for the `schedule-with-note.sh` script.

**Tests (10 total):**

- ✓ Creates note file
- ✓ Note file contains custom message
- ✓ Note file contains timestamp header
- ✓ Note file contains scheduled duration
- ✓ Uses default arguments
- ✓ Accepts custom target window
- ✓ Test mode doesn't create background process
- ✓ Actual scheduling (message delivered)
- ✓ Multiple schedules to different windows
- ✓ Note file readable by scheduled command

**Key Features:**

- Uses `--test-mode` flag for safe testing
- Tests actual background scheduling with short delays
- Verifies multiple simultaneous schedules
- Tests note file creation and delivery
- Automatic cleanup of processes and sessions

## Test Design Principles

### 1. No External Dependencies

Tests use only bash built-ins and tmux (already required by the project).

### 2. Automatic Cleanup

All tests use `trap cleanup EXIT` to ensure:

- Tmux sessions are killed
- Background processes are terminated
- Temporary files are removed

### 3. Unique Session Names

Session names include `$$` (process ID) to avoid conflicts:

```bash
TEST_SESSION="test-schedule-$$"
```

### 4. Color-Coded Output

- ✓ Green checkmark for passing tests
- ✗ Red X for failing tests
- Clear summary at the end

### 5. Fast Execution

- Use minimal sleep times
- Run tests in parallel where possible
- Short scheduling delays (0.033 minutes ≈ 2 seconds)

### 6. Test Mode Support

Scripts support `--test-mode` flag to verify behavior without side effects:

```bash
./schedule-with-note.sh 5 "Test" "session:0" --test-mode
```

## Writing New Tests

Template for a new test function:

```bash
test_feature_name() {
    # Optional: explain what's happening
    echo "  Running specific test..."

    # Create test resources
    local session="${TEST_SESSION}-feature"
    tmux new-session -d -s "$session" 2>/dev/null

    # Run the test
    output=$("$SCRIPT" args 2>&1)

    # Verify results
    if [[ "$output" =~ "expected" ]]; then
        pass "feature name works"
    else
        fail "feature name (specific reason)"
    fi

    # Cleanup (or rely on trap EXIT)
    tmux kill-session -t "$session" 2>/dev/null
}
```

## Debugging Failed Tests

If a test fails:

1. **Run the specific test in isolation** - Comment out other tests
2. **Check tmux sessions** - `tmux list-sessions` to see if cleanup worked
3. **Increase sleep times** - Some systems may need longer delays
4. **Check file permissions** - Ensure scripts are executable
5. **Verify tmux version** - Tests require tmux 2.0+

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```bash
#!/bin/bash
# Run all tests and exit with failure if any fail
set -e

echo "Running Tmux Orchestrator Tests..."
./tests/test-send-claude-message.sh
./tests/test-schedule-with-note.sh

echo "All tests passed!"
```

## Test Coverage

Current coverage:

- **Argument validation**: ✓
- **File operations**: ✓
- **Tmux integration**: ✓
- **Background processes**: ✓
- **Error handling**: ✓
- **Multiple simultaneous operations**: ✓

Future test ideas:

- Error conditions (invalid session names, etc.)
- Performance under load
- Integration tests with actual Claude agents
- Network partition scenarios
