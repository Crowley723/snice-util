#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counter for tests
TESTS_PASSED=0
TOTAL_TESTS=0

# Function to run a test case
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    eval "$command"
    local actual_exit=$?
    
    if [ $actual_exit -eq $expected_exit ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "Expected exit code: $expected_exit"
        echo "Actual exit code: $actual_exit"
    fi
}

# Ensure snice is compiled
if [ ! -f "./snice" ]; then
    echo "Compiling snice..."
    gcc -o snice snice.c
    if [ $? -ne 0 ]; then
        echo "Compilation failed!"
        exit 1
    fi
fi

# Test 1: Invalid usage (no arguments)
run_test "no arguments" \
    "./snice" 1

# Test 2: Invalid usage (missing priority)
run_test "missing priority" \
    "./snice -n" 1

# Test 3: Invalid priority (too high)
run_test "priority too high" \
    "./snice -n 20 sleep 1" 1

# Test 4: Invalid priority (too low)
run_test "priority too low" \
    "./snice -n -21 sleep 1" 1

# Test 5: Invalid priority (non-numeric)
run_test "non-numeric priority" \
    "./snice -n abc sleep 1" 1

# Test 6: Valid priority with command
run_test "valid priority with command" \
    "./snice -n 10 sleep 1" 0

# Test 7: Invalid PID
run_test "invalid PID" \
    "./snice -n 0 -p abc" 1

# Test 8: Test with non-existent command
run_test "non-existent command" \
    "./snice -n 0 nonexistentcommand" 1

# Test 9: Test with valid PID (using current process)
run_test "valid PID (current process)" \
    "./snice -n 0 -p $$" 0

# Test 10: Multiple arguments
run_test "multiple arguments" \
    "./snice -n 0 echo hello world" 0

# Create a background process and test priority change
echo "Testing priority change on running process..."
sleep 10 &
bg_pid=$!
./snice -n 10 -p $bg_pid
if [ $? -eq 0 ]; then
    actual_priority=$(ps -o nice= -p $bg_pid)
    if [ "$actual_priority" -eq 10 ]; then
        echo -e "${GREEN}Priority change test PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}Priority change test FAILED${NC}"
        echo "Expected priority: 10"
        echo "Actual priority: $actual_priority"
    fi
else
    echo -e "${RED}Priority change test FAILED${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Kill background process
kill $bg_pid 2>/dev/null

# Print summary
echo
echo "Test Summary:"
echo "-------------"
echo "Total tests: $TOTAL_TESTS"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TOTAL_TESTS - TESTS_PASSED))"

if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
