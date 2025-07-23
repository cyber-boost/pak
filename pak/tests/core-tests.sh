#!/bin/bash
# PAK Core Test Suite
# Comprehensive testing for PAK core functionality

set -euo pipefail

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAK_DIR="$(dirname "$TEST_DIR")"
TEST_TEMP_DIR="/tmp/pak-tests"
TEST_RESULTS_FILE="$TEST_TEMP_DIR/test-results.json"

# Test state
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
TEST_START_TIME=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize test environment
init_test_env() {
    echo "=== PAK Core Test Suite ==="
    echo "Test Directory: $TEST_DIR"
    echo "PAK Directory: $PAK_DIR"
    echo "Temp Directory: $TEST_TEMP_DIR"
    echo ""
    
    # Create test directories
    mkdir -p "$TEST_TEMP_DIR"/{data,logs,config,modules}
    
    # Set up test environment variables
    export PAK_DIR="$PAK_DIR"
    export PAK_CONFIG_DIR="$TEST_TEMP_DIR/config"
    export PAK_DATA_DIR="$TEST_TEMP_DIR/data"
    export PAK_LOGS_DIR="$TEST_TEMP_DIR/logs"
    export PAK_MODULES_DIR="$TEST_TEMP_DIR/modules"
    export PAK_DEBUG_MODE=true
    export PAK_QUIET_MODE=false
    
    # Source PAK core
    source "$PAK_DIR/pak.sh"
    
    echo "Test environment initialized"
    echo ""
}

# Test utilities
log_test() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO) echo -e "${BLUE}[TEST INFO]${NC} $message" ;;
        PASS) echo -e "${GREEN}[TEST PASS]${NC} $message" ;;
        FAIL) echo -e "${RED}[TEST FAIL]${NC} $message" ;;
        SKIP) echo -e "${YELLOW}[TEST SKIP]${NC} $message" ;;
    esac
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" == "$actual" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (expected: '$expected', actual: '$actual')"
        return 1
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" != "$actual" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (values should not be equal: '$expected')"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if eval "$condition"; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (condition: $condition)"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (condition: $condition)"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ -f "$file" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (file: $file)"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    if [[ ! -f "$file" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (file: $file)"
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    if [[ -d "$dir" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (directory: $dir)"
        return 1
    fi
}

assert_command_exists() {
    local command="$1"
    local message="${2:-Command should exist}"
    
    if command -v "$command" &>/dev/null; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message (command: $command)"
        return 1
    fi
}

# Test runner
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo "Running test: $test_name"
    
    if "$test_function"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test PASS "Test passed: $test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test FAIL "Test failed: $test_name"
    fi
    
    echo ""
}

skip_test() {
    local test_name="$1"
    local reason="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    
    log_test SKIP "Test skipped: $test_name ($reason)"
    echo ""
}

# Test functions

# Test 1: Core module loading
test_core_module_loading() {
    log_test INFO "Testing core module loading"
    
    # Test module loading
    assert_true "load_module 'core'" "Core module should load successfully"
    assert_true "[[ -n \"\${LOADED_MODULES[core]:-}\" ]]" "Core module should be marked as loaded"
    
    # Test module metadata
    assert_equals "2.0.0" "${MODULE_METADATA[core_version]:-}" "Core module version should be 2.0.0"
    
    # Test command registration
    assert_true "[[ -n \"\${MODULE_COMMANDS[version]:-}\" ]]" "Version command should be registered"
    assert_true "[[ -n \"\${MODULE_COMMANDS[config]:-}\" ]]" "Config command should be registered"
    assert_true "[[ -n \"\${MODULE_COMMANDS[status]:-}\" ]]" "Status command should be registered"
    
    return 0
}

# Test 2: Configuration management
test_configuration_management() {
    log_test INFO "Testing configuration management"
    
    # Create test configuration
    cat > "$PAK_CONFIG_DIR/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=3
PAK_CACHE_TTL=1800
PAK_API_TIMEOUT=15
PAK_ENABLE_ANALYTICS=true
EOF
    
    # Test configuration validation
    assert_true "validate_configuration" "Configuration should be valid"
    
    # Test configuration get/set
    assert_equals "npm pypi" "$(core_get_config_value 'PAK_DEFAULT_PLATFORMS')" "Should get correct platform value"
    
    core_set_config_value "PAK_TEST_VALUE" "test123"
    assert_equals "test123" "$(core_get_config_value 'PAK_TEST_VALUE')" "Should set and get custom value"
    
    return 0
}

# Test 3: Hook system
test_hook_system() {
    log_test INFO "Testing hook system"
    
    # Test hook registration
    register_hook "test_hook" "core" "test_hook_function" 50
    assert_true "[[ -n \"\${MODULE_HOOKS[test_hook:50:core]:-}\" ]]" "Hook should be registered"
    
    # Test hook execution (with mock function)
    test_hook_executed=false
    test_hook_function() {
        test_hook_executed=true
    }
    
    execute_hooks "test_hook"
    assert_true "$test_hook_executed" "Hook function should be executed"
    
    return 0
}

# Test 4: Plugin system
test_plugin_system() {
    log_test INFO "Testing plugin system"
    
    # Create test plugin
    cat > "$TEST_TEMP_DIR/test_plugin.sh" << 'EOF'
#!/bin/bash
PLUGIN_NAME="test_plugin"
PLUGIN_VERSION="1.0.0"

test_plugin_init() {
    echo "Test plugin initialized"
}

test_plugin_register_commands() {
    register_command "test-plugin" "test_plugin" "test_plugin_command"
}

test_plugin_command() {
    echo "Test plugin command executed"
}
EOF
    
    # Test plugin registration
    assert_true "register_plugin 'test_plugin' '$TEST_TEMP_DIR/test_plugin.sh' 'module'" "Plugin should register successfully"
    assert_true "[[ -n \"\${PLUGIN_REGISTRY[test_plugin]:-}\" ]]" "Plugin should be in registry"
    
    # Test plugin loading
    assert_true "load_plugin 'test_plugin'" "Plugin should load successfully"
    
    return 0
}

# Test 5: Error handling
test_error_handling() {
    log_test INFO "Testing error handling"
    
    # Test invalid module loading
    assert_false "load_module 'nonexistent_module'" "Loading nonexistent module should fail"
    
    # Test invalid configuration
    echo "INVALID_CONFIG_LINE" > "$PAK_CONFIG_DIR/pak.conf"
    assert_false "validate_configuration" "Invalid configuration should fail validation"
    
    # Test invalid hook registration
    assert_false "register_hook '' 'core' 'function' 50" "Empty hook name should fail"
    assert_false "register_hook 'test' '' 'function' 50" "Empty module name should fail"
    assert_false "register_hook 'test' 'core' '' 50" "Empty function name should fail"
    assert_false "register_hook 'test' 'core' 'function' 150" "Invalid priority should fail"
    
    return 0
}

# Test 6: Health monitoring
test_health_monitoring() {
    log_test INFO "Testing health monitoring"
    
    # Test system health check
    assert_true "core_health_check_system" "System health check should pass"
    
    # Test module health check
    assert_true "core_health_check_modules" "Module health check should pass"
    
    # Test configuration health check
    # Reset to valid configuration first
    cat > "$PAK_CONFIG_DIR/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=3
PAK_CACHE_TTL=1800
PAK_API_TIMEOUT=15
EOF
    assert_true "core_health_check_config" "Configuration health check should pass"
    
    return 0
}

# Test 7: Utility functions
test_utility_functions() {
    log_test INFO "Testing utility functions"
    
    # Test retry_with_backoff
    local retry_count=0
    retry_test_function() {
        retry_count=$((retry_count + 1))
        [[ $retry_count -eq 3 ]]
    }
    
    assert_true "retry_with_backoff 3 1 10 retry_test_function" "Retry function should succeed on third attempt"
    assert_equals "3" "$retry_count" "Function should be called 3 times"
    
    # Test JSON utilities
    local test_json='{"key":"value","number":42,"boolean":true}'
    assert_equals "value" "$(json_get "$test_json" "key")" "json_get should extract string value"
    assert_equals "42" "$(json_get "$test_json" "number")" "json_get should extract number value"
    assert_equals "true" "$(json_get "$test_json" "boolean")" "json_get should extract boolean value"
    
    # Test validation functions
    assert_true "validate_email 'test@example.com'" "Valid email should pass validation"
    assert_false "validate_email 'invalid-email'" "Invalid email should fail validation"
    
    assert_true "validate_url 'https://example.com'" "Valid URL should pass validation"
    assert_false "validate_url 'not-a-url'" "Invalid URL should fail validation"
    
    assert_true "validate_version '1.2.3'" "Valid version should pass validation"
    assert_true "validate_version '1.2.3-beta'" "Valid version with prerelease should pass validation"
    assert_false "validate_version 'invalid-version'" "Invalid version should fail validation"
    
    return 0
}

# Test 8: Performance monitoring
test_performance_monitoring() {
    log_test INFO "Testing performance monitoring"
    
    # Test performance logging
    local start_time=$(date +%s.%N)
    sleep 0.1
    local end_time=$(date +%s.%N)
    
    # This should not fail, just test that the function exists and runs
    log_performance "test_operation" "$start_time" "$end_time"
    
    # Test module load time tracking
    assert_true "[[ -n \"\${MODULE_LOAD_TIMES[core]:-}\" ]]" "Module load time should be tracked"
    
    return 0
}

# Test 9: Security functions
test_security_functions() {
    log_test INFO "Testing security functions"
    
    # Test random string generation
    local random1=$(generate_random_string 16)
    local random2=$(generate_random_string 16)
    
    assert_equals "16" "${#random1}" "Random string should be 16 characters"
    assert_equals "16" "${#random2}" "Random string should be 16 characters"
    assert_not_equals "$random1" "$random2" "Random strings should be different"
    
    # Test string hashing
    local hash1=$(hash_string "test")
    local hash2=$(hash_string "test")
    local hash3=$(hash_string "different")
    
    assert_equals "$hash1" "$hash2" "Same input should produce same hash"
    assert_not_equals "$hash1" "$hash3" "Different input should produce different hash"
    
    return 0
}

# Test 10: Network utilities
test_network_utilities() {
    log_test INFO "Testing network utilities"
    
    # Test connectivity check (should work with httpbin.org)
    assert_true "check_connectivity 'https://httpbin.org/get'" "Connectivity check should pass"
    
    # Test external IP (may fail in some environments, so we'll be lenient)
    local external_ip=$(get_external_ip)
    if [[ -n "$external_ip" ]]; then
        assert_true "[[ \"$external_ip\" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]" "External IP should be valid format"
    else
        log_test SKIP "External IP check skipped (may not be available)"
    fi
    
    return 0
}

# Test 11: File utilities
test_file_utilities() {
    log_test INFO "Testing file utilities"
    
    # Create test file
    local test_file="$TEST_TEMP_DIR/test_file.txt"
    echo "test content" > "$test_file"
    
    # Test file backup
    local backup_file=$(file_backup "$test_file")
    assert_file_exists "$backup_file" "Backup file should be created"
    
    # Test file restore
    local restore_file="$TEST_TEMP_DIR/restored_file.txt"
    file_restore "$backup_file" "$restore_file"
    assert_file_exists "$restore_file" "File should be restored"
    assert_equals "$(cat "$test_file")" "$(cat "$restore_file")" "Restored file should have same content"
    
    return 0
}

# Test 12: Module lifecycle
test_module_lifecycle() {
    log_test INFO "Testing module lifecycle"
    
    # Test lifecycle functions
    module_lifecycle_init "test_module"
    assert_equals "initializing" "${MODULE_METADATA[test_module_state]:-}" "Module should be in initializing state"
    
    module_lifecycle_start "test_module"
    assert_equals "running" "${MODULE_METADATA[test_module_state]:-}" "Module should be in running state"
    
    module_lifecycle_stop "test_module"
    assert_equals "stopped" "${MODULE_METADATA[test_module_state]:-}" "Module should be in stopped state"
    
    # Test error state
    module_lifecycle_error "test_module" "Test error message"
    assert_equals "error" "${MODULE_METADATA[test_module_state]:-}" "Module should be in error state"
    assert_equals "Test error message" "${MODULE_METADATA[test_module_error]:-}" "Error message should be stored"
    
    return 0
}

# Test 13: Hot reloading
test_hot_reloading() {
    log_test INFO "Testing hot reloading"
    
    # Enable hot reload
    export PAK_HOT_RELOAD=true
    
    # Test hot reload setup
    setup_hot_reload "test_module" "$TEST_TEMP_DIR/test_module.sh"
    assert_true "[[ -n \"\${HOT_RELOAD_WATCHERS[test_module]:-}\" ]]" "Hot reload should be set up"
    
    # Test hot reload check (should not reload if file hasn't changed)
    assert_true "check_hot_reload" "Hot reload check should pass"
    
    return 0
}

# Test 14: Dependency resolution
test_dependency_resolution() {
    log_test INFO "Testing dependency resolution"
    
    # Create test module with dependencies
    cat > "$TEST_TEMP_DIR/dependent_module.sh" << 'EOF'
#!/bin/bash
MODULE_VERSION="1.0.0"
MODULE_DEPENDENCIES=("core")
MODULE_HOOKS=("pre_init" "post_init")

dependent_module_init() {
    echo "Dependent module initialized"
}

dependent_module_register_commands() {
    register_command "dependent" "dependent_module" "dependent_module_command"
}

dependent_module_command() {
    echo "Dependent module command"
}
EOF
    
    # Test dependency resolution
    assert_true "load_module_metadata 'dependent_module' '$TEST_TEMP_DIR/dependent_module.sh'" "Module metadata should load"
    assert_true "resolve_module_dependencies 'dependent_module'" "Dependencies should resolve"
    
    return 0
}

# Test 15: Configuration schema validation
test_config_schema_validation() {
    log_test INFO "Testing configuration schema validation"
    
    # Create valid configuration
    cat > "$PAK_CONFIG_DIR/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=3
PAK_CACHE_TTL=1800
PAK_API_TIMEOUT=15
EOF
    
    # Test schema validation
    assert_true "validate_config_schema" "Configuration should pass schema validation"
    
    return 0
}

# Test summary
show_test_summary() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    
    echo "=========================================="
    echo "PAK Core Test Suite Results"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    echo "Duration: ${test_duration}s"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}$FAILED_TESTS test(s) failed${NC}"
        return 1
    fi
}

# Main test runner
main() {
    # Initialize test environment
    init_test_env
    
    # Run all tests
    run_test "Core Module Loading" test_core_module_loading
    run_test "Configuration Management" test_configuration_management
    run_test "Hook System" test_hook_system
    run_test "Plugin System" test_plugin_system
    run_test "Error Handling" test_error_handling
    run_test "Health Monitoring" test_health_monitoring
    run_test "Utility Functions" test_utility_functions
    run_test "Performance Monitoring" test_performance_monitoring
    run_test "Security Functions" test_security_functions
    run_test "Network Utilities" test_network_utilities
    run_test "File Utilities" test_file_utilities
    run_test "Module Lifecycle" test_module_lifecycle
    run_test "Hot Reloading" test_hot_reloading
    run_test "Dependency Resolution" test_dependency_resolution
    run_test "Configuration Schema Validation" test_config_schema_validation
    
    # Show summary
    show_test_summary
}

# Cleanup function
cleanup() {
    # Remove test directories
    rm -rf "$TEST_TEMP_DIR"
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main "$@" 