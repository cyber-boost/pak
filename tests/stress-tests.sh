#!/bin/bash
# PAK.sh Stress Test Suite
# Tests PAK.sh under high load and concurrent conditions

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PAK_DIR="$PROJECT_ROOT/pak"
TEST_DIR="$SCRIPT_DIR/stress-test-env"
STRESS_RESULTS="$SCRIPT_DIR/stress-test-results.json"

# Test state
TOTAL_STRESS_TESTS=0
PASSED_STRESS_TESTS=0
FAILED_STRESS_TESTS=0
STRESS_START_TIME=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Stress test results tracking
declare -A STRESS_TEST_RESULTS
declare -A STRESS_TEST_ERRORS
declare -A STRESS_TEST_TIMINGS

# Initialize stress test environment
init_stress_test_env() {
    echo -e "${BLUE}=== PAK.sh Stress Test Suite ===${NC}"
    echo "Testing PAK.sh under high load and concurrent conditions"
    echo "Test Directory: $TEST_DIR"
    echo "PAK Directory: $PAK_DIR"
    echo "Results File: $STRESS_RESULTS"
    echo ""
    
    # Create isolated test environment
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"/{data,logs,config,modules,temp,packages}
    
    # Set up test environment variables
    export PAK_DIR="$PAK_DIR"
    export PAK_CONFIG_DIR="$TEST_DIR/config"
    export PAK_DATA_DIR="$TEST_DIR/data"
    export PAK_LOGS_DIR="$TEST_DIR/logs"
    export PAK_MODULES_DIR="$TEST_DIR/modules"
    export PAK_TEMPLATES_DIR="$TEST_DIR/templates"
    export PAK_SCRIPTS_DIR="$TEST_DIR/scripts"
    export PAK_DEBUG_MODE=false  # Disable debug for performance
    export PAK_QUIET_MODE=true   # Enable quiet mode for stress tests
    export PAK_DRY_RUN=true
    
    # Create minimal test configuration
    cat > "$TEST_DIR/config/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=4
PAK_CACHE_TTL=300
PAK_API_TIMEOUT=5
PAK_ENABLE_ANALYTICS=false
PAK_DRY_RUN=true
EOF
    
    # Create multiple test packages
    create_stress_test_packages
    
    echo "Stress test environment initialized"
    echo ""
}

# Create multiple test packages for stress testing
create_stress_test_packages() {
    echo "Creating stress test packages..."
    
    # Create 10 test packages
    for i in {1..10}; do
        mkdir -p "$TEST_DIR/packages/stress-package-$i"
        cat > "$TEST_DIR/packages/stress-package-$i/package.json" << EOF
{
  "name": "stress-package-$i",
  "version": "1.0.0",
  "description": "Stress test package $i",
  "main": "index.js",
  "scripts": {
    "test": "echo 'test'",
    "build": "echo 'build'"
  },
  "dependencies": {
    "lodash": "^4.17.21"
  },
  "keywords": ["stress", "test", "pak"],
  "author": "Stress Test",
  "license": "MIT"
}
EOF
    done
    
    echo "Created 10 stress test packages"
}

# Stress test utilities
log_stress_test() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO) echo -e "${BLUE}[STRESS TEST INFO]${NC} $message" ;;
        PASS) echo -e "${GREEN}[STRESS TEST PASS]${NC} $message" ;;
        FAIL) echo -e "${RED}[STRESS TEST FAIL]${NC} $message" ;;
        WARN) echo -e "${YELLOW}[STRESS TEST WARN]${NC} $message" ;;
    esac
}

# Stress test execution with timing
stress_execute() {
    local test_name="$1"
    local command="$2"
    local expected_exit="${3:-0}"
    local timeout="${4:-120}"
    
    TOTAL_STRESS_TESTS=$((TOTAL_STRESS_TESTS + 1))
    
    echo -e "${CYAN}Stress Testing: $test_name${NC}"
    echo "Command: $command"
    echo "Expected Exit: $expected_exit"
    echo "Timeout: ${timeout}s"
    
    # Execute command with timing
    local start_time=$(date +%s.%N)
    local output=""
    local exit_code=0
    
    if output=$(timeout "$timeout" bash -c "cd '$TEST_DIR' && $command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Store results
    STRESS_TEST_RESULTS["$test_name"]="$exit_code"
    STRESS_TEST_TIMINGS["$test_name"]="$duration"
    
    # Evaluate result
    if [[ $exit_code -eq $expected_exit ]]; then
        PASSED_STRESS_TESTS=$((PASSED_STRESS_TESTS + 1))
        log_stress_test PASS "$test_name (${duration}s)"
    elif [[ $exit_code -eq 124 ]]; then
        FAILED_STRESS_TESTS=$((FAILED_STRESS_TESTS + 1))
        STRESS_TEST_ERRORS["$test_name"]="Command timed out after ${timeout}s"
        log_stress_test FAIL "$test_name (TIMEOUT after ${duration}s)"
    else
        FAILED_STRESS_TESTS=$((FAILED_STRESS_TESTS + 1))
        STRESS_TEST_ERRORS["$test_name"]="Exit code: $exit_code (Expected: $expected_exit)"
        log_stress_test FAIL "$test_name (Exit: $exit_code, Expected: $expected_exit, ${duration}s)"
    fi
    
    echo ""
}

# 1. Concurrent Command Testing
test_concurrent_commands() {
    echo -e "${BLUE}=== Testing Concurrent Commands ===${NC}"
    
    # Test multiple concurrent version commands
    stress_execute "Concurrent version commands (5)" "for i in {1..5}; do $PAK_DIR/pak.sh version & done; wait" 0
    
    # Test multiple concurrent help commands
    stress_execute "Concurrent help commands (10)" "for i in {1..10}; do $PAK_DIR/pak.sh help & done; wait" 0
    
    # Test multiple concurrent status commands
    stress_execute "Concurrent status commands (8)" "for i in {1..8}; do $PAK_DIR/pak.sh status & done; wait" 0
    
    # Test mixed concurrent commands
    stress_execute "Mixed concurrent commands (20)" "for i in {1..20}; do case \$((i % 3)) in 0) $PAK_DIR/pak.sh version ;; 1) $PAK_DIR/pak.sh help ;; 2) $PAK_DIR/pak.sh status ;; esac & done; wait" 0
    
    echo ""
}

# 2. High Load Testing
test_high_load() {
    echo -e "${BLUE}=== Testing High Load Scenarios ===${NC}"
    
    # Test rapid sequential commands
    stress_execute "Rapid sequential version commands (50)" "for i in {1..50}; do $PAK_DIR/pak.sh version > /dev/null; done" 0
    
    # Test rapid sequential help commands
    stress_execute "Rapid sequential help commands (30)" "for i in {1..30}; do $PAK_DIR/pak.sh help > /dev/null; done" 0
    
    # Test rapid sequential status commands
    stress_execute "Rapid sequential status commands (40)" "for i in {1..40}; do $PAK_DIR/pak.sh status > /dev/null; done" 0
    
    # Test rapid sequential config commands
    stress_execute "Rapid sequential config commands (25)" "for i in {1..25}; do $PAK_DIR/pak.sh config list > /dev/null; done" 0
    
    echo ""
}

# 3. Memory Stress Testing
test_memory_stress() {
    echo -e "${BLUE}=== Testing Memory Stress ===${NC}"
    
    # Test with large output
    stress_execute "Large help output stress" "$PAK_DIR/pak.sh help | wc -l" 0
    
    # Test with multiple large commands
    stress_execute "Multiple large commands stress" "for i in {1..20}; do $PAK_DIR/pak.sh help > /dev/null; $PAK_DIR/pak.sh version > /dev/null; done" 0
    
    # Test memory usage under load
    stress_execute "Memory usage stress test" "/usr/bin/time -v bash -c 'for i in {1..10}; do $PAK_DIR/pak.sh version > /dev/null; done' 2>&1" 0
    
    echo ""
}

# 4. CPU Stress Testing
test_cpu_stress() {
    echo -e "${BLUE}=== Testing CPU Stress ===${NC}"
    
    # Test CPU intensive operations
    stress_execute "CPU intensive version commands" "for i in {1..100}; do $PAK_DIR/pak.sh version > /dev/null; done" 0
    
    # Test CPU intensive help commands
    stress_execute "CPU intensive help commands" "for i in {1..50}; do $PAK_DIR/pak.sh help > /dev/null; done" 0
    
    # Test CPU intensive status commands
    stress_execute "CPU intensive status commands" "for i in {1..75}; do $PAK_DIR/pak.sh status > /dev/null; done" 0
    
    echo ""
}

# 5. I/O Stress Testing
test_io_stress() {
    echo -e "${BLUE}=== Testing I/O Stress ===${NC}"
    
    # Test with multiple package operations
    stress_execute "I/O stress with multiple packages" "for i in {1..10}; do $PAK_DIR/pak.sh security audit $TEST_DIR/packages/stress-package-\$i > /dev/null; done" 0
    
    # Test with multiple file operations
    stress_execute "I/O stress with file operations" "for i in {1..20}; do $PAK_DIR/pak.sh config list > /dev/null; done" 0
    
    # Test with log operations
    stress_execute "I/O stress with log operations" "for i in {1..15}; do $PAK_DIR/pak.sh log show > /dev/null; done" 0
    
    echo ""
}

# 6. Network Stress Testing
test_network_stress() {
    echo -e "${BLUE}=== Testing Network Stress ===${NC}"
    
    # Test network connectivity under load
    stress_execute "Network stress test" "for i in {1..10}; do $PAK_DIR/pak.sh network test > /dev/null; done" 0
    
    # Test API operations under load
    stress_execute "API stress test" "for i in {1..10}; do $PAK_DIR/pak.sh api test > /dev/null; done" 0
    
    echo ""
}

# 7. Module Loading Stress Testing
test_module_stress() {
    echo -e "${BLUE}=== Testing Module Loading Stress ===${NC}"
    
    # Test module loading under load
    stress_execute "Module loading stress test" "for i in {1..20}; do $PAK_DIR/pak.sh --debug version > /dev/null; done" 0
    
    # Test module operations under load
    stress_execute "Module operations stress test" "for i in {1..15}; do $PAK_DIR/pak.sh embed init > /dev/null; done" 0
    
    echo ""
}

# 8. Configuration Stress Testing
test_config_stress() {
    echo -e "${BLUE}=== Testing Configuration Stress ===${NC}"
    
    # Test configuration operations under load
    stress_execute "Config operations stress test" "for i in {1..25}; do $PAK_DIR/pak.sh config list > /dev/null; done" 0
    
    # Test configuration changes under load
    stress_execute "Config changes stress test" "for i in {1..10}; do echo 'PAK_TEST_VALUE=\$i' >> $TEST_DIR/config/pak.conf; $PAK_DIR/pak.sh config list > /dev/null; done" 0
    
    echo ""
}

# 9. Database Stress Testing
test_database_stress() {
    echo -e "${BLUE}=== Testing Database Stress ===${NC}"
    
    # Test database operations under load
    stress_execute "Database operations stress test" "for i in {1..20}; do $PAK_DIR/pak.sh db status > /dev/null; done" 0
    
    echo ""
}

# 10. Embed System Stress Testing
test_embed_stress() {
    echo -e "${BLUE}=== Testing Embed System Stress ===${NC}"
    
    # Test embed operations under load
    stress_execute "Embed operations stress test" "for i in {1..15}; do $PAK_DIR/pak.sh embed init > /dev/null; done" 0
    
    # Test telemetry operations under load
    stress_execute "Telemetry operations stress test" "for i in {1..20}; do $PAK_DIR/pak.sh embed telemetry install > /dev/null; done" 0
    
    echo ""
}

# 11. Security Stress Testing
test_security_stress() {
    echo -e "${BLUE}=== Testing Security Stress ===${NC}"
    
    # Test security operations under load
    stress_execute "Security operations stress test" "for i in {1..10}; do $PAK_DIR/pak.sh security audit $TEST_DIR/packages/stress-package-\$i > /dev/null; done" 0
    
    # Test scan operations under load
    stress_execute "Scan operations stress test" "for i in {1..10}; do $PAK_DIR/pak.sh scan $TEST_DIR/packages/stress-package-\$i > /dev/null; done" 0
    
    echo ""
}

# 12. Deployment Stress Testing
test_deployment_stress() {
    echo -e "${BLUE}=== Testing Deployment Stress ===${NC}"
    
    # Test deployment operations under load
    stress_execute "Deployment operations stress test" "for i in {1..5}; do $PAK_DIR/pak.sh deploy $TEST_DIR/packages/stress-package-\$i --dry-run > /dev/null; done" 0
    
    # Test deployment verification under load
    stress_execute "Deployment verification stress test" "for i in {1..5}; do $PAK_DIR/pak.sh deploy verify $TEST_DIR/packages/stress-package-\$i > /dev/null; done" 0
    
    echo ""
}

# 13. Monitoring Stress Testing
test_monitoring_stress() {
    echo -e "${BLUE}=== Testing Monitoring Stress ===${NC}"
    
    # Test monitoring operations under load
    stress_execute "Monitoring operations stress test" "for i in {1..15}; do $PAK_DIR/pak.sh monitor list > /dev/null; done" 0
    
    # Test health check operations under load
    stress_execute "Health check operations stress test" "for i in {1..20}; do $PAK_DIR/pak.sh health all > /dev/null; done" 0
    
    echo ""
}

# 14. Enterprise Stress Testing
test_enterprise_stress() {
    echo -e "${BLUE}=== Testing Enterprise Stress ===${NC}"
    
    # Test enterprise operations under load
    stress_execute "Enterprise operations stress test" "for i in {1..10}; do $PAK_DIR/pak.sh enterprise status > /dev/null; done" 0
    
    # Test team operations under load
    stress_execute "Team operations stress test" "for i in {1..10}; do $PAK_DIR/pak.sh team list > /dev/null; done" 0
    
    # Test audit operations under load
    stress_execute "Audit operations stress test" "for i in {1..10}; do $PAK_DIR/pak.sh audit report > /dev/null; done" 0
    
    echo ""
}

# 15. Performance Benchmarking
test_performance_benchmark() {
    echo -e "${BLUE}=== Performance Benchmarking ===${NC}"
    
    # Benchmark version command
    stress_execute "Version command benchmark (100 iterations)" "for i in {1..100}; do $PAK_DIR/pak.sh version > /dev/null; done" 0
    
    # Benchmark help command
    stress_execute "Help command benchmark (50 iterations)" "for i in {1..50}; do $PAK_DIR/pak.sh help > /dev/null; done" 0
    
    # Benchmark status command
    stress_execute "Status command benchmark (75 iterations)" "for i in {1..75}; do $PAK_DIR/pak.sh status > /dev/null; done" 0
    
    # Benchmark config command
    stress_execute "Config command benchmark (60 iterations)" "for i in {1..60}; do $PAK_DIR/pak.sh config list > /dev/null; done" 0
    
    echo ""
}

# Generate stress test results
generate_stress_test_results() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - STRESS_START_TIME))
    
    # Calculate average timing
    local total_time=0
    local count=0
    for timing in "${STRESS_TEST_TIMINGS[@]}"; do
        total_time=$(echo "$total_time + $timing" | bc)
        count=$((count + 1))
    done
    local avg_time=0
    if [[ $count -gt 0 ]]; then
        avg_time=$(echo "scale=3; $total_time / $count" | bc)
    fi
    
    # Create JSON results
    cat > "$STRESS_RESULTS" << EOF
{
  "test_suite": "PAK.sh Stress Test Suite",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "duration_seconds": $test_duration,
  "summary": {
    "total_tests": $TOTAL_STRESS_TESTS,
    "passed": $PASSED_STRESS_TESTS,
    "failed": $FAILED_STRESS_TESTS,
    "success_rate": "$(printf "%.1f" $(echo "scale=2; $PASSED_STRESS_TESTS * 100 / $TOTAL_STRESS_TESTS" | bc))%",
    "average_test_time": "$avg_time",
    "total_test_time": "$total_time"
  },
  "performance_metrics": {
    "concurrent_tests": "Multiple concurrent command execution",
    "high_load_tests": "Rapid sequential command execution",
    "memory_stress": "Memory usage under load",
    "cpu_stress": "CPU intensive operations",
    "io_stress": "I/O operations under load",
    "network_stress": "Network operations under load",
    "module_stress": "Module loading under load",
    "config_stress": "Configuration operations under load",
    "database_stress": "Database operations under load",
    "embed_stress": "Embed system under load",
    "security_stress": "Security operations under load",
    "deployment_stress": "Deployment operations under load",
    "monitoring_stress": "Monitoring operations under load",
    "enterprise_stress": "Enterprise operations under load",
    "performance_benchmark": "Performance benchmarking"
  },
  "results": {
EOF
    
    # Add individual test results
    local first=true
    for test_name in "${!STRESS_TEST_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$STRESS_RESULTS"
        fi
        
        local result="${STRESS_TEST_RESULTS[$test_name]}"
        local error="${STRESS_TEST_ERRORS[$test_name]:-}"
        local timing="${STRESS_TEST_TIMINGS[$test_name]:-0}"
        
        cat >> "$STRESS_RESULTS" << EOF
    "$test_name": {
      "exit_code": $result,
      "status": "$([[ $result -eq 0 ]] && echo "passed" || echo "failed")",
      "error": "$error",
      "duration": "$timing"
    }
EOF
    done
    
    cat >> "$STRESS_RESULTS" << EOF
  }
}
EOF
}

# Show stress test summary
show_stress_test_summary() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - STRESS_START_TIME))
    local success_rate=$(printf "%.1f" $(echo "scale=2; $PASSED_STRESS_TESTS * 100 / $TOTAL_STRESS_TESTS" | bc))
    
    # Calculate average timing
    local total_time=0
    local count=0
    for timing in "${STRESS_TEST_TIMINGS[@]}"; do
        total_time=$(echo "$total_time + $timing" | bc)
        count=$((count + 1))
    done
    local avg_time=0
    if [[ $count -gt 0 ]]; then
        avg_time=$(echo "scale=3; $total_time / $count" | bc)
    fi
    
    echo "=========================================="
    echo "PAK.sh Stress Test Suite Results"
    echo "=========================================="
    echo "Total Tests: $TOTAL_STRESS_TESTS"
    echo "Passed: $PASSED_STRESS_TESTS"
    echo "Failed: $FAILED_STRESS_TESTS"
    echo "Success Rate: ${success_rate}%"
    echo "Total Duration: ${test_duration}s"
    echo "Average Test Time: ${avg_time}s"
    echo "Total Test Time: ${total_time}s"
    echo ""
    
    if [[ $FAILED_STRESS_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All stress tests passed!${NC}"
        echo ""
        echo -e "${YELLOW}Stress test categories covered:${NC}"
        echo "  • Concurrent Command Testing"
        echo "  • High Load Scenarios"
        echo "  • Memory Stress Testing"
        echo "  • CPU Stress Testing"
        echo "  • I/O Stress Testing"
        echo "  • Network Stress Testing"
        echo "  • Module Loading Stress"
        echo "  • Configuration Stress"
        echo "  • Database Stress"
        echo "  • Embed System Stress"
        echo "  • Security Stress"
        echo "  • Deployment Stress"
        echo "  • Monitoring Stress"
        echo "  • Enterprise Stress"
        echo "  • Performance Benchmarking"
    else
        echo -e "${RED}❌ $FAILED_STRESS_TESTS test(s) failed${NC}"
        echo ""
        echo "Failed tests:"
        for test_name in "${!STRESS_TEST_RESULTS[@]}"; do
            if [[ "${STRESS_TEST_RESULTS[$test_name]}" -ne 0 ]]; then
                echo -e "  ${RED}✗ $test_name${NC}"
                echo "    Error: ${STRESS_TEST_ERRORS[$test_name]:-Unknown error}"
                echo "    Duration: ${STRESS_TEST_TIMINGS[$test_name]:-0}s"
            fi
        done
    fi
    
    echo ""
    echo "Detailed results saved to: $STRESS_RESULTS"
    echo ""
}

# Main stress test runner
main() {
    # Initialize stress test environment
    init_stress_test_env
    
    # Run all stress test categories
    test_concurrent_commands
    test_high_load
    test_memory_stress
    test_cpu_stress
    test_io_stress
    test_network_stress
    test_module_stress
    test_config_stress
    test_database_stress
    test_embed_stress
    test_security_stress
    test_deployment_stress
    test_monitoring_stress
    test_enterprise_stress
    test_performance_benchmark
    
    # Generate results and show summary
    generate_stress_test_results
    show_stress_test_summary
}

# Cleanup function
cleanup() {
    # Keep test results but clean up test environment
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main "$@" 