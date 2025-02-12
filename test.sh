#!/bin/bash
# Test Script for CSC139 'snice' command
# by Brynn Crowley *created leveraging generative ai

#!/bin/bash

# Create and compile a temporary C program to get the system values
EXIT_VALUES=$(mktemp)
cat << 'EOF' > ${EXIT_VALUES}.c
#include <stdlib.h>
#include <stdio.h>
int main() {
    printf("EXIT_SUCCESS=%d\n", EXIT_SUCCESS);
    printf("EXIT_FAILURE=%d\n", EXIT_FAILURE);
    return EXIT_SUCCESS;  
}
EOF

gcc ${EXIT_VALUES}.c -o ${EXIT_VALUES}
eval $(${EXIT_VALUES})

# Clean up the temporary files
rm ${EXIT_VALUES}.c ${EXIT_VALUES}

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECK_MARK="✓"
CROSS_MARK="✗"
ARROW="→"

# Counter for tests
TESTS_PASSED=0
TOTAL_TESTS=0

# Print header
print_header() {
    local title="$1"
    local width=50
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo
    printf "%${width}s\n" | tr ' ' '='
    printf "%${padding}s%s%${padding}s\n" "" "$title" ""
    printf "%${width}s\n" | tr ' ' '='
    echo
}

# Print section
print_section() {
    local title="$1"
    echo -e "\n${CYAN}${BOLD}$title${NC}"
    echo -e "${CYAN}$(printf '%.s-' $(seq 1 ${#title}))${NC}"
}

# Function to run a test case
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Print test number and name
    printf "${BOLD}Test #%-2d${NC} ${YELLOW}%s${NC}\n" $TOTAL_TESTS "$test_name"
    printf "  ${BLUE}$ARROW Command:${NC} %s\n" "$command"
    
    # Run the command
    eval "$command" > /dev/null 2>&1
    local actual_exit=$?
    
    # Print result
    if [ $actual_exit -eq $expected_exit ]; then
        printf "  ${GREEN}$CHECK_MARK Result:${NC} Passed (exit code: %d)\n" $actual_exit
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        printf "  ${RED}$CROSS_MARK Result:${NC} Failed\n"
        printf "    Expected exit code: %d\n" $expected_exit
        printf "    Actual exit code:   %d\n" $actual_exit
    fi
    echo
}

# Start testing
print_header "SNICE Test Suite"

# Check for compilation
print_section "Compilation Check"
if [ ! -f "./snice" ]; then
    echo -e "${BLUE}$ARROW Compiling snice...${NC}"
    gcc -o snice snice.c
    if [ $? -ne 0 ]; then
        echo -e "${RED}$CROSS_MARK Compilation failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}$CHECK_MARK Compilation successful${NC}"
fi

# Basic Usage Tests
print_section "Basic Usage Tests"
run_test "TestShouldFailWithNoArguments" \
    "./snice" $EXIT_FAILURE

run_test "TestShouldFailWithMissingPriority" \
    "./snice -n" $EXIT_FAILURE

run_test "TestShouldFailWithMissingCommand" \
    "./snice -n 0" $EXIT_FAILURE

# Priority Value Tests
print_section "Priority Value Tests"
run_test "TestShouldFailWithTooHighPriority" \
    "./snice -n 20 sleep 1" $EXIT_FAILURE

run_test "TestShouldFailWithTooLowPriority" \
    "./snice -n -21 sleep 1" $EXIT_FAILURE

run_test "TestShouldFailWithNonNumericPriority" \
    "./snice -n abc sleep 1" $EXIT_FAILURE

run_test "TestShouldSucceedWithValidPriority" \
    "./snice -n 10 sleep 1" $EXIT_SUCCESS

# Process ID Tests
print_section "Process ID Tests"
run_test "TestShouldFailWithInvalidPIDFormat" \
    "./snice -n 0 -p abc" $EXIT_FAILURE

run_test "TestShouldFailWithNonexistentPID" \
    "./snice -n 0 -p 999999" $EXIT_FAILURE

run_test "TestShouldSucceedWithCurrentPID" \
    "./snice -n 0 -p $$" $EXIT_SUCCESS

# Command Execution Tests
print_section "Command Execution Tests"
run_test "TestShouldFailWithNonexistentCommand" \
    "./snice -n 0 nonexistentcommand" $EXIT_FAILURE

run_test "TestShouldSucceedWithValidCommand" \
    "./snice -n 0 echo hello world" $EXIT_SUCCESS

# Dynamic Priority Test
print_section "Dynamic Priority Test"
echo -e "${BLUE}$ARROW Creating background process...${NC}"
sleep 10 &
bg_pid=$!
echo -e "${BLUE}$ARROW Changing priority...${NC}"
./snice -n 10 -p $bg_pid

if [ $? -eq 0 ]; then
    actual_priority=$(ps -o nice= -p $bg_pid)
    if [ "$actual_priority" -eq 10 ]; then
        echo -e "${GREEN}$CHECK_MARK TestShouldSucceedWithPriorityChange: Passed${NC}"
        echo "   Expected priority: 10"
        echo "   Actual priority:   $actual_priority"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}$CROSS_MARK TestShouldSucceedWithPriorityChange: Failed${NC}"
        echo "   Expected priority: 10"
        echo "   Actual priority:   $actual_priority"
    fi
else
    echo -e "${RED}$CROSS_MARK TestShouldSucceedWithPriorityChange: Failed${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Kill background process
kill $bg_pid 2>/dev/null

# Print test summary
print_header "Test Summary"
echo -e "${BOLD}Results:${NC}"
echo -e "  ${BLUE}$ARROW Total tests:   ${NC}$TOTAL_TESTS"
echo -e "  ${GREEN}$CHECK_MARK Tests passed:  ${NC}$TESTS_PASSED"
echo -e "  ${RED}$CROSS_MARK Tests failed:  ${NC}$((TOTAL_TESTS - TESTS_PASSED))"
echo

# Print final status
if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}${BOLD}All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}Some tests failed - please check the output above.${NC}"
    exit 1
fi
