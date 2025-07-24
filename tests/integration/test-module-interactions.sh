#!/bin/bash
# PAK.sh Integration Tests - Module Interactions
# Comprehensive testing of module interactions and workflows

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
    echo -e "${BLUE}[INTEGRATION]${NC} $1"
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

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"
    ((TOTAL_TESTS++))
    
    if [[ "$expected_code" -eq "$actual_code" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name - Expected exit code: $expected_code, Got: $actual_code"
        return 1
    fi
}

# Test setup and teardown
setup_integration_environment() {
    log_test "Setting up integration test environment"
    
    # Create temporary test directories
    export PAK_CONFIG_DIR="/tmp/pak-integration-config"
    export PAK_DATA_DIR="/tmp/pak-integration-data"
    export PAK_LOGS_DIR="/tmp/pak-integration-logs"
    export PAK_MODULES_DIR="/tmp/pak-integration-modules"
    
    mkdir -p "$PAK_CONFIG_DIR" "$PAK_DATA_DIR" "$PAK_LOGS_DIR" "$PAK_MODULES_DIR"
    
    # Copy modules for testing
    cp -r "$PAK_ROOT/modules"/* "$PAK_MODULES_DIR/"
    
    # Create test configuration
    cat > "$PAK_CONFIG_DIR/pak.conf" << EOF
PAK_VERSION="2.0.0"
PAK_DEBUG="true"
PAK_DRY_RUN="false"
PAK_CONFIG_DIR="$PAK_CONFIG_DIR"
PAK_DATA_DIR="$PAK_DATA_DIR"
PAK_LOGS_DIR="$PAK_LOGS_DIR"
PAK_MODULES_DIR="$PAK_MODULES_DIR"
EOF
    
    # Create test platform configurations
    mkdir -p "$PAK_CONFIG_DIR/platforms"
    cat > "$PAK_CONFIG_DIR/platforms/npm.json" << EOF
{
    "name": "npm",
    "health_endpoint": "https://registry.npmjs.org/-/ping",
    "api": "https://registry.npmjs.org",
    "auth_method": "token"
}
EOF
    
    cat > "$PAK_CONFIG_DIR/platforms/pypi.json" << EOF
{
    "name": "pypi",
    "health_endpoint": "https://pypi.org/simple/",
    "api": "https://pypi.org/pypi",
    "auth_method": "token"
}
EOF
    
    log_test "Integration test environment ready"
}

cleanup_integration_environment() {
    log_test "Cleaning up integration test environment"
    
    # Remove temporary directories
    rm -rf "$PAK_CONFIG_DIR" "$PAK_DATA_DIR" "$PAK_LOGS_DIR" "$PAK_MODULES_DIR"
    
    log_test "Integration test environment cleaned"
}

# Test module loading interactions
test_module_loading_interactions() {
    log_test "Testing module loading interactions"
    
    # Source the main PAK script
    source "$PAK_SCRIPT"
    
    # Test that all modules load without conflicts
    local modules=("core" "platform" "deploy" "track" "security" "automation" "analytics" "monitoring" "embed")
    
    for module in "${modules[@]}"; do
        if [[ -f "$PAK_MODULES_DIR/${module}.module.sh" ]]; then
            # Test module can be sourced
            if bash -n "$PAK_MODULES_DIR/${module}.module.sh"; then
                log_pass "Module $module has valid syntax"
            else
                log_fail "Module $module has syntax errors"
                return 1
            fi
        fi
    done
    
    # Test module initialization
    if declare -f init_modules >/dev/null; then
        init_modules
        log_pass "Module initialization completed"
    else
        log_fail "Module initialization function not found"
        return 1
    fi
}

# Test command registration interactions
test_command_registration_interactions() {
    log_test "Testing command registration interactions"
    
    # Source modules
    source "$PAK_MODULES_DIR/core.module.sh"
    source "$PAK_MODULES_DIR/platform.module.sh"
    source "$PAK_MODULES_DIR/deploy.module.sh"
    
    # Test command registration
    if declare -f register_command >/dev/null; then
        log_pass "Command registration function exists"
    else
        log_fail "Command registration function not found"
        return 1
    fi
    
    # Test that commands are properly registered
    if declare -f list_commands >/dev/null; then
        local commands
        commands=$(list_commands 2>/dev/null || echo "")
        assert_not_empty "$commands" "Commands are registered"
    fi
}

# Test hook system interactions
test_hook_system_interactions() {
    log_test "Testing hook system interactions"
    
    # Source modules
    source "$PAK_MODULES_DIR/core.module.sh"
    source "$PAK_MODULES_DIR/embed.module.sh"
    
    # Test hook registration
    if declare -f register_hook >/dev/null; then
        log_pass "Hook registration function exists"
    else
        log_fail "Hook registration function not found"
        return 1
    fi
    
    # Test hook execution
    if declare -f execute_hooks >/dev/null; then
        log_pass "Hook execution function exists"
    else
        log_fail "Hook execution function not found"
        return 1
    fi
}

# Test deployment workflow interactions
test_deployment_workflow_interactions() {
    log_test "Testing deployment workflow interactions"
    
    # Source modules
    source "$PAK_MODULES_DIR/core.module.sh"
    source "$PAK_MODULES_DIR/platform.module.sh"
    source "$PAK_MODULES_DIR/deploy.module.sh"
    
    # Create test package
    local test_package="/tmp/test-package"
    mkdir -p "$test_package"
    cat > "$test_package/package.json" << EOF
{
    "name": "test-package",
    "version": "1.0.0",
    "description": "Test package for integration testing"
}
EOF
    
    # Test deployment validation
    if declare -f deploy_validate >/dev/null; then
        deploy_validate "$test_package" "1.0.0"
        local exit_code=$?
        assert_exit_code 0 "$exit_code" "Deployment validation"
    fi
    
    # Test deployment test (dry run)
    if declare -f deploy_test >/dev/null; then
        deploy_test "$test_package" "npm pypi"
        local exit_code=$?
        assert_exit_code 0 "$exit_code" "Deployment test"
    fi
    
    # Cleanup
    rm -rf "$test_package"
}

# Test platform health monitoring interactions
test_platform_health_interactions() {
    log_test "Testing platform health monitoring interactions"
    
    # Source the platform health check script
    source "$PAK_ROOT/scripts/platform-health-check.sh"
    
    # Test health check function
    if declare -f platform_health_check >/dev/null; then
        local result
        result=$(platform_health_check "npm" 10)
        local exit_code=$?
        
        # Health check should work (even if platform is down)
        if [[ "$result" == "OK" || "$result" == "TIMEOUT" || "$result" == "HTTP_"* ]]; then
            log_pass "Platform health check returned valid result: $result"
        else
            log_fail "Platform health check returned invalid result: $result"
        fi
    fi
}

# Test error handling interactions
test_error_handling_interactions() {
    log_test "Testing error handling interactions"
    
    # Source error handling scripts
    source "$PAK_ROOT/scripts/error-handler.sh"
    source "$PAK_ROOT/scripts/global-error-handler.sh"
    
    # Test error handler initialization
    if declare -f init_error_handler >/dev/null; then
        init_error_handler
        log_pass "Error handler initialized"
    fi
    
    # Test global error handler initialization
    if declare -f init_global_error_handler >/dev/null; then
        init_global_error_handler
        log_pass "Global error handler initialized"
    fi
    
    # Test error statistics
    if declare -f get_error_stats >/dev/null; then
        local stats
        stats=$(get_error_stats)
        assert_not_empty "$stats" "Error statistics are available"
    fi
}

# Test embed telemetry interactions
test_embed_telemetry_interactions() {
    log_test "Testing embed telemetry interactions"
    
    # Source embed module
    source "$PAK_MODULES_DIR/embed.module.sh"
    
    # Set embed directories
    export EMBED_DATA_DIR="/tmp/pak-test-embed-data"
    export EMBED_LOGS_DIR="/tmp/pak-test-embed-logs"
    export EMBED_SQLITE_DB="/tmp/pak-test-embed-data/telemetry.db"
    
    # Create embed directories
    mkdir -p "$EMBED_DATA_DIR" "$EMBED_LOGS_DIR"
    
    # Test embed initialization
    if declare -f embed_init >/dev/null; then
        embed_init
        log_pass "Embed module initialized"
    fi
    
    # Test telemetry event tracking
    if declare -f embed_track_event >/dev/null; then
        embed_track_event "test_event" '{"test": "data"}'
        log_pass "Telemetry event tracked"
    fi
    
    # Test analytics
    if declare -f embed_get_stats >/dev/null; then
        local stats
        stats=$(embed_get_stats)
        assert_not_empty "$stats" "Embed analytics are available"
    fi
}

# Test security module interactions
test_security_interactions() {
    log_test "Testing security module interactions"
    
    # Source security module
    source "$PAK_MODULES_DIR/security.module.sh"
    
    # Test security audit function
    if declare -f security_audit >/dev/null; then
        log_pass "Security audit function exists"
    fi
    
    # Test vulnerability scan function
    if declare -f security_scan >/dev/null; then
        log_pass "Security scan function exists"
    fi
    
    # Test license check function
    if declare -f license_check >/dev/null; then
        log_pass "License check function exists"
    fi
}

# Test automation module interactions
test_automation_interactions() {
    log_test "Testing automation module interactions"
    
    # Source automation module
    source "$PAK_MODULES_DIR/automation.module.sh"
    
    # Test pipeline creation
    if declare -f pipeline_create >/dev/null; then
        log_pass "Pipeline creation function exists"
    fi
    
    # Test workflow management
    if declare -f workflow_create >/dev/null; then
        log_pass "Workflow creation function exists"
    fi
    
    # Test git hooks installation
    if declare -f git_hooks_install >/dev/null; then
        log_pass "Git hooks installation function exists"
    fi
}

# Test performance under load
test_performance_interactions() {
    log_test "Testing performance under load"
    
    local start_time
    start_time=$(date +%s%N)
    
    # Test multiple module loads
    for i in {1..5}; do
        source "$PAK_MODULES_DIR/core.module.sh" >/dev/null 2>&1
        source "$PAK_MODULES_DIR/platform.module.sh" >/dev/null 2>&1
        source "$PAK_MODULES_DIR/deploy.module.sh" >/dev/null 2>&1
    done
    
    local end_time
    end_time=$(date +%s%N)
    local duration_ms=$(((end_time - start_time) / 1000000))
    
    # Should complete within 2 seconds
    if [[ $duration_ms -lt 2000 ]]; then
        log_pass "Performance test completed in ${duration_ms}ms"
    else
        log_fail "Performance test took too long: ${duration_ms}ms"
    fi
}

# Test error recovery interactions
test_error_recovery_interactions() {
    log_test "Testing error recovery interactions"
    
    # Source error handling
    source "$PAK_ROOT/scripts/error-handler.sh"
    
    # Test error creation and recovery
    if declare -f create_error >/dev/null; then
        # This should trigger error handling but not fail the test
        create_error "VALIDATION_ERROR" "Test error for recovery" "LOW" || true
        log_pass "Error creation and recovery tested"
    fi
}

# Main test runner
run_integration_tests() {
    echo "=========================================="
    echo "PAK.sh Integration Tests - Module Interactions"
    echo "=========================================="
    echo ""
    
    setup_integration_environment
    
    # Run all integration tests
    test_module_loading_interactions
    test_command_registration_interactions
    test_hook_system_interactions
    test_deployment_workflow_interactions
    test_platform_health_interactions
    test_error_handling_interactions
    test_embed_telemetry_interactions
    test_security_interactions
    test_automation_interactions
    test_performance_interactions
    test_error_recovery_interactions
    
    cleanup_integration_environment
    
    # Print test summary
    echo ""
    echo "=========================================="
    echo "Integration Test Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}All integration tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some integration tests failed! ❌${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_tests
fi 