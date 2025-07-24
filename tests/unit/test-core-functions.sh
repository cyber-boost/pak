#!/bin/bash
# Unit tests for PAK.sh core module functions
# Test-driven development approach with comprehensive coverage

set -euo pipefail

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAK_ROOT="$(dirname "$TEST_DIR")"
PAK_SCRIPT="$PAK_ROOT/pak.sh"

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test utilities
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

# Assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    ((TOTAL_TESTS++))
    
    if [[ "$expected" == "$actual" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Expected: '$expected', Got: '$actual'"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="$2"
    ((TOTAL_TESTS++))
    
    if [[ -n "$value" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Value is empty"
        return 1
    fi
}

# Test core module functions
test_core_load_version_info() {
    log_test "Testing core_load_version_info function"
    
    # Source the core module
    source "$PAK_ROOT/modules/core.module.sh"
    
    # Test function exists
    if declare -f core_load_version_info >/dev/null; then
        log_pass "core_load_version_info function exists"
    else
        log_fail "core_load_version_info function not found"
        return 1
    fi
    
    # Test function execution
    core_load_version_info
    
    # Verify version info is populated
    assert_not_empty "${CORE_VERSION_INFO[core]:-}" "Core version is set"
    assert_not_empty "${CORE_VERSION_INFO[bash]:-}" "Bash version is set"
}

test_core_validate_directories() {
    log_test "Testing core_validate_directories function"
    
    # Source the core module
    source "$PAK_ROOT/modules/core.module.sh"
    
    # Test function exists
    if declare -f core_validate_directories >/dev/null; then
        log_pass "core_validate_directories function exists"
    else
        log_fail "core_validate_directories function not found"
        return 1
    fi
}

# Main test runner
run_all_tests() {
    echo "=========================================="
    echo "PAK.sh Core Module Unit Tests"
    echo "=========================================="
    echo ""
    
    # Run all test functions
    test_core_load_version_info
    test_core_validate_directories
    
    # Print test summary
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed! ❌${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi 