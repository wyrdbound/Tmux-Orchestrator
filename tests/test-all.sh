#!/bin/bash

# test-all.sh - Run all bash tests in the tests directory
# Usage: ./tests/test-all.sh

set -uo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🧪 Running all tests in the Tmux Orchestrator project${NC}"
echo "=================================================="

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_TEST_NAMES=()

# Function to run a single test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)

    echo -e "${YELLOW}Running: $test_name${NC}"

    # Change to project root so tests can find scripts
    cd "$PROJECT_ROOT"

    # Run test in a subshell to prevent EXIT traps from affecting this script
    if (timeout 60 bash "$test_file"); then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
    fi

    echo ""
    ((TOTAL_TESTS++))
}

# Find all test files (executable bash scripts starting with "test-" but exclude test-all.sh)
echo "Discovering test files..."
TEST_FILES=()
while IFS= read -r -d '' file; do
    # Skip test-all.sh to avoid infinite recursion
    if [[ "$(basename "$file")" != "test-all.sh" ]]; then
        TEST_FILES+=("$file")
    fi
done < <(find "$SCRIPT_DIR" -name "test-*.sh" -type f -perm +111 -print0 | sort -z)

if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No test files found matching pattern 'test-*.sh'${NC}"
    exit 0
fi

echo "Found ${#TEST_FILES[@]} test file(s):"
for test_file in "${TEST_FILES[@]}"; do
    echo "  - $(basename "$test_file")"
done
echo ""

# Run each test
for test_file in "${TEST_FILES[@]}"; do
    run_test "$test_file"
done

# Print summary
echo "=================================================="
echo -e "${BLUE}📊 Test Summary${NC}"
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed:${NC}"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}- $failed_test${NC}"
    done
    exit 1
fi