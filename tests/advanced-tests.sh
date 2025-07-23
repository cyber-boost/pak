#!/bin/bash
# PAK.sh Advanced Test Suite
# Comprehensive testing with edge cases, error conditions, and integration tests

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PAK_DIR="$PROJECT_ROOT/pak"
TEST_DIR="$SCRIPT_DIR/advanced-test-env"
TEST_RESULTS="$SCRIPT_DIR/advanced-test-results.json"

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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
declare -A ADVANCED_TEST_RESULTS
declare -A ADVANCED_TEST_ERRORS
declare -A ADVANCED_TEST_OUTPUTS

# Initialize advanced test environment
init_advanced_test_env() {
    echo -e "${BLUE}=== PAK.sh Advanced Test Suite ===${NC}"
    echo "Testing edge cases, error conditions, and integration scenarios"
    echo "Test Directory: $TEST_DIR"
    echo "PAK Directory: $PAK_DIR"
    echo "Results File: $TEST_RESULTS"
    echo ""
    
    # Create isolated test environment
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"/{data,logs,config,modules,temp,packages,credentials}
    
    # Set up test environment variables
    export PAK_DIR="$PAK_DIR"
    export PAK_CONFIG_DIR="$TEST_DIR/config"
    export PAK_DATA_DIR="$TEST_DIR/data"
    export PAK_LOGS_DIR="$TEST_DIR/logs"
    export PAK_MODULES_DIR="$TEST_DIR/modules"
    export PAK_TEMPLATES_DIR="$TEST_DIR/templates"
    export PAK_SCRIPTS_DIR="$TEST_DIR/scripts"
    export PAK_DEBUG_MODE=true
    export PAK_QUIET_MODE=false
    export PAK_DRY_RUN=true
    
    # Create comprehensive test configuration
    cat > "$TEST_DIR/config/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi cargo nuget"
PAK_PARALLEL_JOBS=2
PAK_CACHE_TTL=300
PAK_API_TIMEOUT=10
PAK_ENABLE_ANALYTICS=true
PAK_DRY_RUN=true
PAK_LOG_LEVEL=DEBUG
PAK_MAX_RETRIES=3
PAK_BACKOFF_MULTIPLIER=2
PAK_CONNECT_TIMEOUT=5
PAK_READ_TIMEOUT=15
EOF
    
    # Create test packages
    create_test_packages
    
    # Create test credentials
    create_test_credentials
    
    echo "Advanced test environment initialized"
    echo ""
}

# Create test packages for testing
create_test_packages() {
    echo "Creating test packages..."
    
    # Create Node.js package
    mkdir -p "$TEST_DIR/packages/test-npm-package"
    cat > "$TEST_DIR/packages/test-npm-package/package.json" << 'EOF'
{
  "name": "test-npm-package",
  "version": "1.0.0",
  "description": "Test package for PAK.sh testing",
  "main": "index.js",
  "scripts": {
    "test": "echo 'test'",
    "build": "echo 'build'"
  },
  "dependencies": {
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  },
  "keywords": ["test", "pak"],
  "author": "Test Author",
  "license": "MIT"
}
EOF
    
    # Create Python package
    mkdir -p "$TEST_DIR/packages/test-python-package"
    cat > "$TEST_DIR/packages/test-python-package/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "test-python-package"
version = "1.0.0"
description = "Test Python package for PAK.sh testing"
authors = [{name = "Test Author", email = "test@example.com"}]
license = {text = "MIT"}
requires-python = ">=3.8"
dependencies = [
    "requests>=2.25.0",
    "click>=8.0.0"
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=22.0.0"
]
EOF
    
    # Create Rust package
    mkdir -p "$TEST_DIR/packages/test-rust-package"
    cat > "$TEST_DIR/packages/test-rust-package/Cargo.toml" << 'EOF'
[package]
name = "test-rust-package"
version = "1.0.0"
edition = "2021"
description = "Test Rust package for PAK.sh testing"
authors = ["Test Author <test@example.com>"]
license = "MIT"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }

[dev-dependencies]
tokio-test = "0.4"
EOF
    
    # Create .NET package
    mkdir -p "$TEST_DIR/packages/test-dotnet-package"
    cat > "$TEST_DIR/packages/test-dotnet-package/test-dotnet-package.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <PackageId>TestDotnetPackage</PackageId>
    <Version>1.0.0</Version>
    <Authors>Test Author</Authors>
    <Description>Test .NET package for PAK.sh testing</Description>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

</Project>
EOF
    
    echo "Test packages created successfully"
}

# Create test credentials
create_test_credentials() {
    echo "Creating test credentials..."
    
    # Create test credentials file
    cat > "$TEST_DIR/credentials/test-credentials.json" << 'EOF'
{
  "npm": {
    "username": "test-user",
    "email": "test@example.com",
    "token": "test-npm-token"
  },
  "pypi": {
    "username": "test-user",
    "password": "test-pypi-password",
    "api_token": "test-pypi-token"
  },
  "cargo": {
    "api_token": "test-cargo-token"
  },
  "nuget": {
    "api_key": "test-nuget-key"
  }
}
EOF
    
    # Create test environment file
    cat > "$TEST_DIR/credentials/.env.test" << 'EOF'
NPM_TOKEN=test-npm-token
PYPI_TOKEN=test-pypi-token
CARGO_TOKEN=test-cargo-token
NUGET_API_KEY=test-nuget-key
EOF
    
    echo "Test credentials created successfully"
}

# Test utilities
log_test() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO) echo -e "${BLUE}[ADVANCED TEST INFO]${NC} $message" ;;
        PASS) echo -e "${GREEN}[ADVANCED TEST PASS]${NC} $message" ;;
        FAIL) echo -e "${RED}[ADVANCED TEST FAIL]${NC} $message" ;;
        SKIP) echo -e "${YELLOW}[ADVANCED TEST SKIP]${NC} $message" ;;
        WARN) echo -e "${PURPLE}[ADVANCED TEST WARN]${NC} $message" ;;
    esac
}

# Advanced test execution
advanced_execute() {
    local test_name="$1"
    local command="$2"
    local expected_exit="${3:-0}"
    local timeout="${4:-60}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${CYAN}Advanced Testing: $test_name${NC}"
    echo "Command: $command"
    echo "Expected Exit: $expected_exit"
    echo "Timeout: ${timeout}s"
    
    # Execute command with timeout and capture output
    local output=""
    local exit_code=0
    
    if output=$(timeout "$timeout" bash -c "cd '$TEST_DIR' && $command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Store results
    ADVANCED_TEST_RESULTS["$test_name"]="$exit_code"
    ADVANCED_TEST_OUTPUTS["$test_name"]="$output"
    
    # Evaluate result
    if [[ $exit_code -eq $expected_exit ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test PASS "$test_name"
        echo "Output: ${output:0:300}..."
    elif [[ $exit_code -eq 124 ]]; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
        ADVANCED_TEST_ERRORS["$test_name"]="Command timed out after ${timeout}s"
        log_test FAIL "$test_name (TIMEOUT)"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        ADVANCED_TEST_ERRORS["$test_name"]="Exit code: $exit_code (Expected: $expected_exit)"
        log_test FAIL "$test_name (Exit: $exit_code, Expected: $expected_exit)"
        echo "Error Output: ${output:0:300}..."
    fi
    
    echo ""
}

# Skip advanced test
skip_advanced_test() {
    local test_name="$1"
    local reason="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    
    log_test SKIP "$test_name ($reason)"
    echo ""
}

# Test Categories

# 1. Edge Cases and Error Conditions
test_edge_cases() {
    echo -e "${BLUE}=== Testing Edge Cases and Error Conditions ===${NC}"
    
    # Test with invalid arguments
    advanced_execute "Invalid command" "$PAK_DIR/pak.sh nonexistent-command" 1
    advanced_execute "Empty command" "$PAK_DIR/pak.sh" 0
    advanced_execute "Multiple flags" "$PAK_DIR/pak.sh --debug --quiet --dry-run version" 0
    
    # Test with invalid configuration
    echo "INVALID_CONFIG" > "$TEST_DIR/config/pak.conf"
    advanced_execute "Invalid config file" "$PAK_DIR/pak.sh status" 1
    
    # Restore valid config
    cat > "$TEST_DIR/config/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=1
PAK_CACHE_TTL=300
PAK_API_TIMEOUT=5
PAK_ENABLE_ANALYTICS=false
PAK_DRY_RUN=true
EOF
    
    # Test with missing modules
    advanced_execute "Missing module directory" "$PAK_DIR/pak.sh version" 0
    
    # Test with very long arguments
    local long_arg=$(printf 'a%.0s' {1..1000})
    advanced_execute "Very long argument" "$PAK_DIR/pak.sh version $long_arg" 0
    
    # Test with special characters
    advanced_execute "Special characters" "$PAK_DIR/pak.sh version 'test@example.com'" 0
    advanced_execute "Unicode characters" "$PAK_DIR/pak.sh version '测试包'" 0
    
    echo ""
}

# 2. Performance and Load Testing
test_performance() {
    echo -e "${BLUE}=== Testing Performance and Load ===${NC}"
    
    # Test command execution time
    local start_time=$(date +%s.%N)
    advanced_execute "Version command performance" "$PAK_DIR/pak.sh version" 0
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "Version command took: ${duration}s"
    
    # Test help command performance
    start_time=$(date +%s.%N)
    advanced_execute "Help command performance" "$PAK_DIR/pak.sh help" 0
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "Help command took: ${duration}s"
    
    # Test multiple concurrent commands
    advanced_execute "Concurrent version commands" "for i in {1..5}; do $PAK_DIR/pak.sh version & done; wait" 0
    
    # Test memory usage
    advanced_execute "Memory usage test" "/usr/bin/time -v $PAK_DIR/pak.sh version 2>&1" 0
    
    echo ""
}

# 3. Integration Testing
test_integration() {
    echo -e "${BLUE}=== Testing Integration Scenarios ===${NC}"
    
    # Test module loading integration
    advanced_execute "Module loading integration" "$PAK_DIR/pak.sh --debug version" 0
    
    # Test configuration integration
    advanced_execute "Configuration integration" "$PAK_DIR/pak.sh config list" 0
    
    # Test logging integration
    advanced_execute "Logging integration" "$PAK_DIR/pak.sh log show" 0
    
    # Test database integration
    advanced_execute "Database integration" "$PAK_DIR/pak.sh db status" 0
    
    # Test embed system integration
    advanced_execute "Embed system integration" "$PAK_DIR/pak.sh embed init" 0
    
    # Test registration system integration
    advanced_execute "Registration system integration" "$PAK_DIR/pak.sh register-list" 0
    
    echo ""
}

# 4. Security Testing
test_security() {
    echo -e "${BLUE}=== Testing Security Features ===${NC}"
    
    # Test with test packages
    advanced_execute "Security audit test package" "$PAK_DIR/pak.sh security audit $TEST_DIR/packages/test-npm-package" 0
    advanced_execute "Security scan test package" "$PAK_DIR/pak.sh scan $TEST_DIR/packages/test-npm-package" 0
    advanced_execute "License check test package" "$PAK_DIR/pak.sh license check $TEST_DIR/packages/test-npm-package" 0
    
    # Test with Python package
    advanced_execute "Python package security audit" "$PAK_DIR/pak.sh security audit $TEST_DIR/packages/test-python-package" 0
    advanced_execute "Python package security scan" "$PAK_DIR/pak.sh scan $TEST_DIR/packages/test-python-package" 0
    
    # Test with Rust package
    advanced_execute "Rust package security audit" "$PAK_DIR/pak.sh security audit $TEST_DIR/packages/test-rust-package" 0
    advanced_execute "Rust package security scan" "$PAK_DIR/pak.sh scan $TEST_DIR/packages/test-rust-package" 0
    
    # Test with .NET package
    advanced_execute "Dotnet package security audit" "$PAK_DIR/pak.sh security audit $TEST_DIR/packages/test-dotnet-package" 0
    advanced_execute "Dotnet package security scan" "$PAK_DIR/pak.sh scan $TEST_DIR/packages/test-dotnet-package" 0
    
    echo ""
}

# 5. Deployment Testing
test_deployment() {
    echo -e "${BLUE}=== Testing Deployment Scenarios ===${NC}"
    
    # Test deployment with test packages
    advanced_execute "NPM package deployment test" "$PAK_DIR/pak.sh deploy $TEST_DIR/packages/test-npm-package --platform npm --dry-run" 0
    advanced_execute "PyPI package deployment test" "$PAK_DIR/pak.sh deploy $TEST_DIR/packages/test-python-package --platform pypi --dry-run" 0
    advanced_execute "Cargo package deployment test" "$PAK_DIR/pak.sh deploy $TEST_DIR/packages/test-rust-package --platform cargo --dry-run" 0
    advanced_execute "NuGet package deployment test" "$PAK_DIR/pak.sh deploy $TEST_DIR/packages/test-dotnet-package --platform nuget --dry-run" 0
    
    # Test deployment verification
    advanced_execute "Deployment verification test" "$PAK_DIR/pak.sh deploy verify $TEST_DIR/packages/test-npm-package" 0
    
    # Test deployment rollback
    advanced_execute "Deployment rollback test" "$PAK_DIR/pak.sh deploy rollback $TEST_DIR/packages/test-npm-package" 0
    
    # Test deployment cleanup
    advanced_execute "Deployment cleanup test" "$PAK_DIR/pak.sh deploy clean $TEST_DIR/packages/test-npm-package" 0
    
    echo ""
}

# 6. Tracking and Analytics Testing
test_tracking() {
    echo -e "${BLUE}=== Testing Tracking and Analytics ===${NC}"
    
    # Test package tracking
    advanced_execute "Package tracking test" "$PAK_DIR/pak.sh track $TEST_DIR/packages/test-npm-package" 0
    advanced_execute "Package stats test" "$PAK_DIR/pak.sh stats $TEST_DIR/packages/test-npm-package" 0
    advanced_execute "Package analytics test" "$PAK_DIR/pak.sh analytics $TEST_DIR/packages/test-npm-package" 0
    
    # Test data export
    advanced_execute "Data export JSON test" "$PAK_DIR/pak.sh export $TEST_DIR/packages/test-npm-package --format json" 0
    advanced_execute "Data export CSV test" "$PAK_DIR/pak.sh export $TEST_DIR/packages/test-npm-package --format csv" 0
    
    # Test tracking history
    advanced_execute "Tracking history test" "$PAK_DIR/pak.sh track $TEST_DIR/packages/test-npm-package --history" 0
    
    echo ""
}

# 7. Automation Testing
test_automation() {
    echo -e "${BLUE}=== Testing Automation Features ===${NC}"
    
    # Test pipeline operations
    advanced_execute "Pipeline list test" "$PAK_DIR/pak.sh pipeline list" 0
    advanced_execute "Pipeline status test" "$PAK_DIR/pak.sh pipeline status" 0
    
    # Test workflow operations
    advanced_execute "Workflow list test" "$PAK_DIR/pak.sh workflow list" 0
    advanced_execute "Workflow status test" "$PAK_DIR/pak.sh workflow status" 0
    
    # Test git hooks
    advanced_execute "Git hooks list test" "$PAK_DIR/pak.sh git hooks list" 0
    advanced_execute "Git hooks test test" "$PAK_DIR/pak.sh git hooks test" 0
    
    echo ""
}

# 8. Monitoring Testing
test_monitoring() {
    echo -e "${BLUE}=== Testing Monitoring Features ===${NC}"
    
    # Test health checks
    advanced_execute "Health check all test" "$PAK_DIR/pak.sh health all" 0
    advanced_execute "Health check detailed test" "$PAK_DIR/pak.sh health $TEST_DIR/packages/test-npm-package --detailed" 0
    
    # Test monitoring operations
    advanced_execute "Monitor list test" "$PAK_DIR/pak.sh monitor list" 0
    advanced_execute "Monitor status test" "$PAK_DIR/pak.sh monitor $TEST_DIR/packages/test-npm-package --status" 0
    
    # Test alerts
    advanced_execute "Alerts list test" "$PAK_DIR/pak.sh alerts list" 0
    
    echo ""
}

# 9. Developer Experience Testing
test_devex() {
    echo -e "${BLUE}=== Testing Developer Experience ===${NC}"
    
    # Test DevEx commands
    advanced_execute "DevEx help test" "$PAK_DIR/pak.sh devex --help" 0
    advanced_execute "DevEx template list test" "$PAK_DIR/pak.sh devex template list" 0
    advanced_execute "DevEx docs serve help test" "$PAK_DIR/pak.sh devex docs serve --help" 0
    
    # Test project setup
    advanced_execute "DevEx setup test" "$PAK_DIR/pak.sh devex setup" 0
    advanced_execute "DevEx validate test" "$PAK_DIR/pak.sh devex validate" 0
    
    echo ""
}

# 10. Enterprise Testing
test_enterprise() {
    echo -e "${BLUE}=== Testing Enterprise Features ===${NC}"
    
    # Test enterprise commands
    advanced_execute "Enterprise status test" "$PAK_DIR/pak.sh enterprise status" 0
    advanced_execute "Enterprise config test" "$PAK_DIR/pak.sh enterprise config" 0
    
    # Test team management
    advanced_execute "Team list test" "$PAK_DIR/pak.sh team list" 0
    
    # Test audit features
    advanced_execute "Audit report test" "$PAK_DIR/pak.sh audit report" 0
    advanced_execute "Audit search test" "$PAK_DIR/pak.sh audit search test" 0
    
    echo ""
}

# 11. Network and API Testing
test_network() {
    echo -e "${BLUE}=== Testing Network and API Features ===${NC}"
    
    # Test network connectivity
    advanced_execute "Network test" "$PAK_DIR/pak.sh network test" 0
    
    # Test API operations
    advanced_execute "API status test" "$PAK_DIR/pak.sh api status" 0
    advanced_execute "API test" "$PAK_DIR/pak.sh api test" 0
    
    # Test webhook operations
    advanced_execute "Webhook list test" "$PAK_DIR/pak.sh webhook list" 0
    
    # Test plugin operations
    advanced_execute "Plugin list test" "$PAK_DIR/pak.sh plugin list" 0
    
    echo ""
}

# 12. Lifecycle Testing
test_lifecycle() {
    echo -e "${BLUE}=== Testing Lifecycle Management ===${NC}"
    
    # Test version management
    advanced_execute "Version list test" "$PAK_DIR/pak.sh version list" 0
    advanced_execute "Version history test" "$PAK_DIR/pak.sh version history" 0
    
    # Test release management
    advanced_execute "Release list test" "$PAK_DIR/pak.sh release list" 0
    
    # Test dependency management
    advanced_execute "Dependencies list test" "$PAK_DIR/pak.sh deps list $TEST_DIR/packages/test-npm-package" 0
    advanced_execute "Dependencies check test" "$PAK_DIR/pak.sh deps check $TEST_DIR/packages/test-npm-package" 0
    
    echo ""
}

# 13. Debugging and Performance Testing
test_debugging() {
    echo -e "${BLUE}=== Testing Debugging and Performance ===${NC}"
    
    # Test debug commands
    advanced_execute "Debug enable test" "$PAK_DIR/pak.sh debug enable" 0
    advanced_execute "Debug disable test" "$PAK_DIR/pak.sh debug disable" 0
    advanced_execute "Debug log test" "$PAK_DIR/pak.sh debug log DEBUG" 0
    
    # Test troubleshooting
    advanced_execute "Troubleshoot test" "$PAK_DIR/pak.sh troubleshoot test" 0
    advanced_execute "Troubleshoot auto test" "$PAK_DIR/pak.sh troubleshoot auto" 0
    
    # Test optimization
    advanced_execute "Optimize cache test" "$PAK_DIR/pak.sh optimize cache" 0
    advanced_execute "Optimize memory test" "$PAK_DIR/pak.sh optimize memory" 0
    
    # Test performance
    advanced_execute "Performance benchmark help test" "$PAK_DIR/pak.sh perf benchmark --help" 0
    advanced_execute "Performance profile test" "$PAK_DIR/pak.sh perf profile $TEST_DIR/packages/test-npm-package" 0
    
    echo ""
}

# 14. Reporting and Compliance Testing
test_reporting() {
    echo -e "${BLUE}=== Testing Reporting and Compliance ===${NC}"
    
    # Test report generation
    advanced_execute "Report list test" "$PAK_DIR/pak.sh report list" 0
    advanced_execute "Report generate test" "$PAK_DIR/pak.sh report generate test" 0
    
    # Test compliance checks
    advanced_execute "GDPR check test" "$PAK_DIR/pak.sh gdpr check" 0
    advanced_execute "HIPAA check test" "$PAK_DIR/pak.sh hipaa check" 0
    advanced_execute "SOX check test" "$PAK_DIR/pak.sh sox check" 0
    
    # Test policy management
    advanced_execute "Policy list test" "$PAK_DIR/pak.sh policy list" 0
    advanced_execute "Policy enforce test" "$PAK_DIR/pak.sh policy enforce" 0
    
    echo ""
}

# 15. Specialized Platform Testing
test_specialized() {
    echo -e "${BLUE}=== Testing Specialized Platforms ===${NC}"
    
    # Test Unity
    advanced_execute "Unity help test" "$PAK_DIR/pak.sh unity --help" 0
    advanced_execute "Unity deploy help test" "$PAK_DIR/pak.sh unity deploy --help" 0
    
    # Test Docker
    advanced_execute "Docker help test" "$PAK_DIR/pak.sh docker --help" 0
    advanced_execute "Docker build help test" "$PAK_DIR/pak.sh docker build --help" 0
    
    # Test AWS
    advanced_execute "AWS help test" "$PAK_DIR/pak.sh aws --help" 0
    advanced_execute "AWS deploy help test" "$PAK_DIR/pak.sh aws deploy --help" 0
    
    # Test VS Code
    advanced_execute "VS Code help test" "$PAK_DIR/pak.sh vscode --help" 0
    advanced_execute "VS Code setup help test" "$PAK_DIR/pak.sh vscode setup --help" 0
    
    echo ""
}

# Generate advanced test results
generate_advanced_test_results() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    
    # Create JSON results
    cat > "$TEST_RESULTS" << EOF
{
  "test_suite": "PAK.sh Advanced Test Suite",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "duration_seconds": $test_duration,
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "skipped": $SKIPPED_TESTS,
    "success_rate": "$(printf "%.1f" $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc))%"
  },
  "test_categories": {
    "edge_cases": "Edge cases and error conditions",
    "performance": "Performance and load testing",
    "integration": "Integration scenarios",
    "security": "Security features",
    "deployment": "Deployment scenarios",
    "tracking": "Tracking and analytics",
    "automation": "Automation features",
    "monitoring": "Monitoring features",
    "devex": "Developer experience",
    "enterprise": "Enterprise features",
    "network": "Network and API",
    "lifecycle": "Lifecycle management",
    "debugging": "Debugging and performance",
    "reporting": "Reporting and compliance",
    "specialized": "Specialized platforms"
  },
  "results": {
EOF
    
    # Add individual test results
    local first=true
    for test_name in "${!ADVANCED_TEST_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$TEST_RESULTS"
        fi
        
        local result="${ADVANCED_TEST_RESULTS[$test_name]}"
        local error="${ADVANCED_TEST_ERRORS[$test_name]:-}"
        local output="${ADVANCED_TEST_OUTPUTS[$test_name]:-}"
        
        cat >> "$TEST_RESULTS" << EOF
    "$test_name": {
      "exit_code": $result,
      "status": "$([[ $result -eq 0 ]] && echo "passed" || echo "failed")",
      "error": "$error",
      "output": "$(echo "$output" | head -c 500 | sed 's/"/\\"/g')"
    }
EOF
    done
    
    cat >> "$TEST_RESULTS" << EOF
  }
}
EOF
}

# Show advanced test summary
show_advanced_test_summary() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    local success_rate=$(printf "%.1f" $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc))
    
    echo "=========================================="
    echo "PAK.sh Advanced Test Suite Results"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    echo "Success Rate: ${success_rate}%"
    echo "Duration: ${test_duration}s"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All advanced tests passed!${NC}"
        echo ""
        echo -e "${YELLOW}Advanced test categories covered:${NC}"
        echo "  • Edge Cases and Error Conditions"
        echo "  • Performance and Load Testing"
        echo "  • Integration Scenarios"
        echo "  • Security Features"
        echo "  • Deployment Scenarios"
        echo "  • Tracking and Analytics"
        echo "  • Automation Features"
        echo "  • Monitoring Features"
        echo "  • Developer Experience"
        echo "  • Enterprise Features"
        echo "  • Network and API"
        echo "  • Lifecycle Management"
        echo "  • Debugging and Performance"
        echo "  • Reporting and Compliance"
        echo "  • Specialized Platforms"
    else
        echo -e "${RED}❌ $FAILED_TESTS test(s) failed${NC}"
        echo ""
        echo "Failed tests:"
        for test_name in "${!ADVANCED_TEST_RESULTS[@]}"; do
            if [[ "${ADVANCED_TEST_RESULTS[$test_name]}" -ne 0 ]]; then
                echo -e "  ${RED}✗ $test_name${NC}"
                echo "    Error: ${ADVANCED_TEST_ERRORS[$test_name]:-Unknown error}"
            fi
        done
    fi
    
    echo ""
    echo "Detailed results saved to: $TEST_RESULTS"
    echo ""
}

# Main advanced test runner
main() {
    # Initialize advanced test environment
    init_advanced_test_env
    
    # Run all advanced test categories
    test_edge_cases
    test_performance
    test_integration
    test_security
    test_deployment
    test_tracking
    test_automation
    test_monitoring
    test_devex
    test_enterprise
    test_network
    test_lifecycle
    test_debugging
    test_reporting
    test_specialized
    
    # Generate results and show summary
    generate_advanced_test_results
    show_advanced_test_summary
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