#!/bin/bash
# PAK.sh Comprehensive Command Test Suite
# Tests every command in a safe, isolated environment

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PAK_DIR="$PROJECT_ROOT/pak"
TEST_DIR="$SCRIPT_DIR/test-env"
TEST_RESULTS="$SCRIPT_DIR/test-results.json"

# Test state
TOTAL_COMMANDS=0
PASSED_COMMANDS=0
FAILED_COMMANDS=0
SKIPPED_COMMANDS=0
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
declare -A COMMAND_RESULTS
declare -A COMMAND_ERRORS
declare -A COMMAND_OUTPUTS

# Initialize test environment
init_test_env() {
    echo -e "${BLUE}=== PAK.sh Comprehensive Command Test Suite ===${NC}"
    echo "Testing all commands in safe, isolated environment"
    echo "Test Directory: $TEST_DIR"
    echo "PAK Directory: $PAK_DIR"
    echo "Results File: $TEST_RESULTS"
    echo ""
    
    # Create isolated test environment
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"/{data,logs,config,modules,temp}
    
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
    export PAK_DRY_RUN=true  # Enable dry run mode for safety
    
    # Create minimal test configuration
    cat > "$TEST_DIR/config/pak.conf" << 'EOF'
PAK_DEFAULT_PLATFORMS="npm pypi"
PAK_PARALLEL_JOBS=1
PAK_CACHE_TTL=300
PAK_API_TIMEOUT=5
PAK_ENABLE_ANALYTICS=false
PAK_DRY_RUN=true
EOF
    
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
        WARN) echo -e "${PURPLE}[TEST WARN]${NC} $message" ;;
    esac
}

# Safe command execution
safe_execute() {
    local command="$1"
    local description="$2"
    local timeout="${3:-30}"
    
    TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
    
    echo -e "${CYAN}Testing: $description${NC}"
    echo "Command: $command"
    
    # Execute command with timeout and capture output
    local output=""
    local exit_code=0
    
    # Use timeout to prevent hanging commands
    if output=$(timeout "$timeout" bash -c "cd '$TEST_DIR' && $command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Store results
    COMMAND_RESULTS["$command"]="$exit_code"
    COMMAND_OUTPUTS["$command"]="$output"
    
    # Evaluate result
    if [[ $exit_code -eq 0 ]]; then
        PASSED_COMMANDS=$((PASSED_COMMANDS + 1))
        log_test PASS "$description"
        echo "Output: ${output:0:200}..."
    elif [[ $exit_code -eq 124 ]]; then
        FAILED_COMMANDS=$((FAILED_COMMANDS + 1))
        COMMAND_ERRORS["$command"]="Command timed out after ${timeout}s"
        log_test FAIL "$description (TIMEOUT)"
    else
        FAILED_COMMANDS=$((FAILED_COMMANDS + 1))
        COMMAND_ERRORS["$command"]="Exit code: $exit_code"
        log_test FAIL "$description (Exit: $exit_code)"
        echo "Error: ${output:0:200}..."
    fi
    
    echo ""
}

# Skip command (for commands that can't be safely tested)
skip_command() {
    local command="$1"
    local description="$2"
    local reason="$3"
    
    TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
    SKIPPED_COMMANDS=$((SKIPPED_COMMANDS + 1))
    
    log_test SKIP "$description ($reason)"
    echo ""
}

# Test command categories

# 🚀 CORE COMMANDS
test_core_commands() {
    echo -e "${BLUE}=== Testing Core Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh version" "Version command"
    safe_execute "$PAK_DIR/pak.sh help" "Help command"
    safe_execute "$PAK_DIR/pak.sh status" "Status command"
    safe_execute "$PAK_DIR/pak.sh --version" "Version flag"
    safe_execute "$PAK_DIR/pak.sh --help" "Help flag"
    safe_execute "$PAK_DIR/pak.sh --debug version" "Debug mode"
    safe_execute "$PAK_DIR/pak.sh --quiet version" "Quiet mode"
    safe_execute "$PAK_DIR/pak.sh --dry-run version" "Dry run mode"
    
    # Skip init as it requires user interaction
    skip_command "$PAK_DIR/pak.sh init" "Init command" "Requires user interaction"
    
    echo ""
}

# 📦 DEPLOYMENT COMMANDS
test_deployment_commands() {
    echo -e "${BLUE}=== Testing Deployment Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh deploy --help" "Deploy help"
    safe_execute "$PAK_DIR/pak.sh deploy list" "Deploy list"
    safe_execute "$PAK_DIR/pak.sh deploy status" "Deploy status"
    safe_execute "$PAK_DIR/pak.sh deploy verify" "Deploy verify"
    safe_execute "$PAK_DIR/pak.sh deploy clean" "Deploy clean"
    
    # Skip actual deployments as they require credentials
    skip_command "$PAK_DIR/pak.sh deploy test-package" "Deploy package" "Requires credentials"
    skip_command "$PAK_DIR/pak.sh deploy test-package --version 1.0.0" "Deploy with version" "Requires credentials"
    skip_command "$PAK_DIR/pak.sh deploy test-package --platform npm" "Deploy to platform" "Requires credentials"
    
    echo ""
}

# 📊 TRACKING & ANALYTICS
test_tracking_commands() {
    echo -e "${BLUE}=== Testing Tracking & Analytics Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh track --help" "Track help"
    safe_execute "$PAK_DIR/pak.sh stats --help" "Stats help"
    safe_execute "$PAK_DIR/pak.sh analytics --help" "Analytics help"
    safe_execute "$PAK_DIR/pak.sh export --help" "Export help"
    
    # Skip actual tracking as it requires real packages
    skip_command "$PAK_DIR/pak.sh track test-package" "Track package" "Requires real package"
    skip_command "$PAK_DIR/pak.sh stats test-package" "Package stats" "Requires real package"
    skip_command "$PAK_DIR/pak.sh analytics test-package" "Package analytics" "Requires real package"
    
    echo ""
}

# 🔐 SECURITY COMMANDS
test_security_commands() {
    echo -e "${BLUE}=== Testing Security Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh security --help" "Security help"
    safe_execute "$PAK_DIR/pak.sh scan --help" "Scan help"
    safe_execute "$PAK_DIR/pak.sh license --help" "License help"
    
    # Create test package for security scanning
    mkdir -p "$TEST_DIR/temp/test-package"
    cat > "$TEST_DIR/temp/test-package/package.json" << 'EOF'
{
  "name": "test-package",
  "version": "1.0.0",
  "description": "Test package for security scanning",
  "main": "index.js",
  "scripts": {
    "test": "echo 'test'"
  },
  "dependencies": {
    "lodash": "^4.17.21"
  }
}
EOF
    
    safe_execute "$PAK_DIR/pak.sh security audit $TEST_DIR/temp/test-package" "Security audit"
    safe_execute "$PAK_DIR/pak.sh scan $TEST_DIR/temp/test-package" "Security scan"
    safe_execute "$PAK_DIR/pak.sh license check $TEST_DIR/temp/test-package" "License check"
    
    echo ""
}

# 🤖 AUTOMATION COMMANDS
test_automation_commands() {
    echo -e "${BLUE}=== Testing Automation Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh pipeline --help" "Pipeline help"
    safe_execute "$PAK_DIR/pak.sh workflow --help" "Workflow help"
    safe_execute "$PAK_DIR/pak.sh git --help" "Git help"
    
    safe_execute "$PAK_DIR/pak.sh pipeline list" "Pipeline list"
    safe_execute "$PAK_DIR/pak.sh workflow list" "Workflow list"
    safe_execute "$PAK_DIR/pak.sh git hooks list" "Git hooks list"
    
    # Skip pipeline creation as it requires configuration
    skip_command "$PAK_DIR/pak.sh pipeline create test-pipeline" "Create pipeline" "Requires configuration"
    skip_command "$PAK_DIR/pak.sh workflow create test-workflow" "Create workflow" "Requires configuration"
    
    echo ""
}

# 📈 MONITORING COMMANDS
test_monitoring_commands() {
    echo -e "${BLUE}=== Testing Monitoring Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh monitor --help" "Monitor help"
    safe_execute "$PAK_DIR/pak.sh health --help" "Health help"
    safe_execute "$PAK_DIR/pak.sh alerts --help" "Alerts help"
    
    safe_execute "$PAK_DIR/pak.sh monitor list" "Monitor list"
    safe_execute "$PAK_DIR/pak.sh health all" "Health check all"
    safe_execute "$PAK_DIR/pak.sh alerts list" "Alerts list"
    
    # Skip actual monitoring as it requires real packages
    skip_command "$PAK_DIR/pak.sh monitor test-package" "Monitor package" "Requires real package"
    skip_command "$PAK_DIR/pak.sh health test-package" "Health check package" "Requires real package"
    
    echo ""
}

# 👨‍💻 DEVELOPER EXPERIENCE
test_devex_commands() {
    echo -e "${BLUE}=== Testing Developer Experience Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh devex --help" "DevEx help"
    safe_execute "$PAK_DIR/pak.sh devex wizard --help" "DevEx wizard help"
    safe_execute "$PAK_DIR/pak.sh devex template --help" "DevEx template help"
    safe_execute "$PAK_DIR/pak.sh devex docs --help" "DevEx docs help"
    
    safe_execute "$PAK_DIR/pak.sh devex template list" "Template list"
    safe_execute "$PAK_DIR/pak.sh devex docs serve --help" "Docs serve help"
    
    # Skip wizard as it requires user interaction
    skip_command "$PAK_DIR/pak.sh devex wizard" "DevEx wizard" "Requires user interaction"
    skip_command "$PAK_DIR/pak.sh devex init" "DevEx init" "Requires user interaction"
    
    echo ""
}

# 🔧 INTEGRATION COMMANDS
test_integration_commands() {
    echo -e "${BLUE}=== Testing Integration Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh webhook --help" "Webhook help"
    safe_execute "$PAK_DIR/pak.sh api --help" "API help"
    safe_execute "$PAK_DIR/pak.sh plugin --help" "Plugin help"
    
    safe_execute "$PAK_DIR/pak.sh webhook list" "Webhook list"
    safe_execute "$PAK_DIR/pak.sh api status" "API status"
    safe_execute "$PAK_DIR/pak.sh plugin list" "Plugin list"
    
    # Skip actual integrations as they require external services
    skip_command "$PAK_DIR/pak.sh webhook add test-webhook http://example.com" "Add webhook" "Requires external service"
    skip_command "$PAK_DIR/pak.sh api start" "Start API" "Requires port binding"
    skip_command "$PAK_DIR/pak.sh plugin install test-plugin" "Install plugin" "Requires plugin source"
    
    echo ""
}

# 🏢 ENTERPRISE COMMANDS
test_enterprise_commands() {
    echo -e "${BLUE}=== Testing Enterprise Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh enterprise --help" "Enterprise help"
    safe_execute "$PAK_DIR/pak.sh team --help" "Team help"
    safe_execute "$PAK_DIR/pak.sh audit --help" "Audit help"
    
    safe_execute "$PAK_DIR/pak.sh enterprise status" "Enterprise status"
    safe_execute "$PAK_DIR/pak.sh team list" "Team list"
    safe_execute "$PAK_DIR/pak.sh audit report" "Audit report"
    
    # Skip enterprise setup as it requires configuration
    skip_command "$PAK_DIR/pak.sh enterprise setup" "Enterprise setup" "Requires configuration"
    skip_command "$PAK_DIR/pak.sh team add test-user" "Add team member" "Requires user management"
    
    echo ""
}

# 🎨 USER INTERFACE
test_ui_commands() {
    echo -e "${BLUE}=== Testing User Interface Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh ascii --help" "ASCII help"
    safe_execute "$PAK_DIR/pak.sh config --help" "Config help"
    safe_execute "$PAK_DIR/pak.sh db --help" "Database help"
    safe_execute "$PAK_DIR/pak.sh log --help" "Log help"
    
    safe_execute "$PAK_DIR/pak.sh ascii show PAK" "Show ASCII art"
    safe_execute "$PAK_DIR/pak.sh config list" "Config list"
    safe_execute "$PAK_DIR/pak.sh db status" "Database status"
    safe_execute "$PAK_DIR/pak.sh log show" "Show logs"
    
    echo ""
}

# 🔄 LIFECYCLE COMMANDS
test_lifecycle_commands() {
    echo -e "${BLUE}=== Testing Lifecycle Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh version --help" "Version help"
    safe_execute "$PAK_DIR/pak.sh release --help" "Release help"
    safe_execute "$PAK_DIR/pak.sh deps --help" "Dependencies help"
    
    safe_execute "$PAK_DIR/pak.sh version list" "Version list"
    safe_execute "$PAK_DIR/pak.sh release list" "Release list"
    safe_execute "$PAK_DIR/pak.sh deps list" "Dependencies list"
    
    # Skip version bumping as it requires git repository
    skip_command "$PAK_DIR/pak.sh version bump patch" "Version bump" "Requires git repository"
    skip_command "$PAK_DIR/pak.sh release create 1.0.0" "Create release" "Requires git repository"
    
    echo ""
}

# 🔍 DEBUGGING & PERFORMANCE
test_debug_commands() {
    echo -e "${BLUE}=== Testing Debugging & Performance Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh debug --help" "Debug help"
    safe_execute "$PAK_DIR/pak.sh troubleshoot --help" "Troubleshoot help"
    safe_execute "$PAK_DIR/pak.sh optimize --help" "Optimize help"
    safe_execute "$PAK_DIR/pak.sh perf --help" "Performance help"
    
    safe_execute "$PAK_DIR/pak.sh debug enable" "Enable debug"
    safe_execute "$PAK_DIR/pak.sh debug disable" "Disable debug"
    safe_execute "$PAK_DIR/pak.sh optimize cache" "Optimize cache"
    safe_execute "$PAK_DIR/pak.sh perf benchmark --help" "Performance benchmark help"
    
    echo ""
}

# 🌐 NETWORKING & API
test_networking_commands() {
    echo -e "${BLUE}=== Testing Networking & API Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh network --help" "Network help"
    safe_execute "$PAK_DIR/pak.sh api --help" "API help"
    
    safe_execute "$PAK_DIR/pak.sh network test" "Network test"
    safe_execute "$PAK_DIR/pak.sh api test" "API test"
    
    # Skip API key setting as it requires actual keys
    skip_command "$PAK_DIR/pak.sh api key test-key" "Set API key" "Requires actual API key"
    skip_command "$PAK_DIR/pak.sh api secret test-secret" "Set API secret" "Requires actual API secret"
    
    echo ""
}

# 📱 MOBILE & I18N
test_mobile_commands() {
    echo -e "${BLUE}=== Testing Mobile & I18N Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh mobile --help" "Mobile help"
    safe_execute "$PAK_DIR/pak.sh locale --help" "Locale help"
    safe_execute "$PAK_DIR/pak.sh timezone --help" "Timezone help"
    
    safe_execute "$PAK_DIR/pak.sh mobile status" "Mobile status"
    safe_execute "$PAK_DIR/pak.sh locale list" "Locale list"
    safe_execute "$PAK_DIR/pak.sh timezone list" "Timezone list"
    
    # Skip mobile setup as it requires mobile environment
    skip_command "$PAK_DIR/pak.sh mobile setup" "Mobile setup" "Requires mobile environment"
    skip_command "$PAK_DIR/pak.sh locale set en_US" "Set locale" "Requires locale support"
    
    echo ""
}

# 🔄 UPDATE & MAINTENANCE
test_update_commands() {
    echo -e "${BLUE}=== Testing Update & Maintenance Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh update --help" "Update help"
    safe_execute "$PAK_DIR/pak.sh maintenance --help" "Maintenance help"
    safe_execute "$PAK_DIR/pak.sh backup --help" "Backup help"
    
    safe_execute "$PAK_DIR/pak.sh update check" "Update check"
    safe_execute "$PAK_DIR/pak.sh maintenance status" "Maintenance status"
    safe_execute "$PAK_DIR/pak.sh backup list" "Backup list"
    
    # Skip actual updates as they require network access
    skip_command "$PAK_DIR/pak.sh update install" "Install updates" "Requires network access"
    skip_command "$PAK_DIR/pak.sh maintenance start" "Start maintenance" "Requires system access"
    
    echo ""
}

# 📊 REPORTING & COMPLIANCE
test_reporting_commands() {
    echo -e "${BLUE}=== Testing Reporting & Compliance Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh report --help" "Report help"
    safe_execute "$PAK_DIR/pak.sh gdpr --help" "GDPR help"
    safe_execute "$PAK_DIR/pak.sh policy --help" "Policy help"
    
    safe_execute "$PAK_DIR/pak.sh report list" "Report list"
    safe_execute "$PAK_DIR/pak.sh gdpr check" "GDPR check"
    safe_execute "$PAK_DIR/pak.sh policy list" "Policy list"
    
    # Skip report generation as it requires data
    skip_command "$PAK_DIR/pak.sh report generate test-report" "Generate report" "Requires data"
    skip_command "$PAK_DIR/pak.sh policy enforce test-policy" "Enforce policy" "Requires policy configuration"
    
    echo ""
}

# 🎯 SPECIALIZED COMMANDS
test_specialized_commands() {
    echo -e "${BLUE}=== Testing Specialized Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh unity --help" "Unity help"
    safe_execute "$PAK_DIR/pak.sh docker --help" "Docker help"
    safe_execute "$PAK_DIR/pak.sh aws --help" "AWS help"
    safe_execute "$PAK_DIR/pak.sh vscode --help" "VS Code help"
    
    safe_execute "$PAK_DIR/pak.sh docker build --help" "Docker build help"
    safe_execute "$PAK_DIR/pak.sh aws deploy --help" "AWS deploy help"
    safe_execute "$PAK_DIR/pak.sh vscode setup --help" "VS Code setup help"
    
    # Skip actual deployments as they require credentials
    skip_command "$PAK_DIR/pak.sh unity deploy test-asset" "Unity deploy" "Requires Unity credentials"
    skip_command "$PAK_DIR/pak.sh docker build test-image" "Docker build" "Requires Docker daemon"
    skip_command "$PAK_DIR/pak.sh aws deploy test-app" "AWS deploy" "Requires AWS credentials"
    
    echo ""
}

# 🔗 EMBED & TELEMETRY
test_embed_commands() {
    echo -e "${BLUE}=== Testing Embed & Telemetry Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh embed --help" "Embed help"
    safe_execute "$PAK_DIR/pak.sh embed init --help" "Embed init help"
    safe_execute "$PAK_DIR/pak.sh embed telemetry --help" "Embed telemetry help"
    safe_execute "$PAK_DIR/pak.sh embed analytics --help" "Embed analytics help"
    safe_execute "$PAK_DIR/pak.sh embed track --help" "Embed track help"
    safe_execute "$PAK_DIR/pak.sh embed report --help" "Embed report help"
    
    safe_execute "$PAK_DIR/pak.sh embed init" "Embed init"
    safe_execute "$PAK_DIR/pak.sh embed telemetry install" "Embed telemetry install"
    safe_execute "$PAK_DIR/pak.sh embed analytics setup" "Embed analytics setup"
    safe_execute "$PAK_DIR/pak.sh embed track pageview" "Embed track pageview"
    safe_execute "$PAK_DIR/pak.sh embed report generate" "Embed report generate"
    
    echo ""
}

# 📚 HELP & DOCUMENTATION
test_help_commands() {
    echo -e "${BLUE}=== Testing Help & Documentation Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh help" "General help"
    safe_execute "$PAK_DIR/pak.sh docs" "Documentation"
    safe_execute "$PAK_DIR/pak.sh docs search --help" "Docs search help"
    
    # Test help for specific commands
    safe_execute "$PAK_DIR/pak.sh help register" "Register help"
    safe_execute "$PAK_DIR/pak.sh help deploy" "Deploy help"
    safe_execute "$PAK_DIR/pak.sh help track" "Track help"
    safe_execute "$PAK_DIR/pak.sh help security" "Security help"
    
    echo ""
}

# 🔐 REGISTRATION COMMANDS
test_registration_commands() {
    echo -e "${BLUE}=== Testing Registration Commands ===${NC}"
    
    safe_execute "$PAK_DIR/pak.sh register --help" "Register help"
    safe_execute "$PAK_DIR/pak.sh register-list" "Register list"
    safe_execute "$PAK_DIR/pak.sh register-test --help" "Register test help"
    safe_execute "$PAK_DIR/pak.sh register-export --help" "Register export help"
    safe_execute "$PAK_DIR/pak.sh register-import --help" "Register import help"
    safe_execute "$PAK_DIR/pak.sh register-clear --help" "Register clear help"
    
    # Skip actual registration as it requires credentials
    skip_command "$PAK_DIR/pak.sh register" "Registration wizard" "Requires user interaction"
    skip_command "$PAK_DIR/pak.sh register-platform npm" "Register with NPM" "Requires NPM credentials"
    skip_command "$PAK_DIR/pak.sh register-platform pypi" "Register with PyPI" "Requires PyPI credentials"
    
    echo ""
}

# Generate test results
generate_test_results() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    
    # Create JSON results
    cat > "$TEST_RESULTS" << EOF
{
  "test_suite": "PAK.sh Comprehensive Command Test Suite",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "duration_seconds": $test_duration,
  "summary": {
    "total_commands": $TOTAL_COMMANDS,
    "passed": $PASSED_COMMANDS,
    "failed": $FAILED_COMMANDS,
    "skipped": $SKIPPED_COMMANDS,
    "success_rate": "$(printf "%.1f" $(echo "scale=2; $PASSED_COMMANDS * 100 / $TOTAL_COMMANDS" | bc))%"
  },
  "results": {
EOF
    
    # Add individual command results
    local first=true
    for command in "${!COMMAND_RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$TEST_RESULTS"
        fi
        
        local result="${COMMAND_RESULTS[$command]}"
        local error="${COMMAND_ERRORS[$command]:-}"
        local output="${COMMAND_OUTPUTS[$command]:-}"
        
        cat >> "$TEST_RESULTS" << EOF
    "$command": {
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

# Show test summary
show_test_summary() {
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - TEST_START_TIME))
    local success_rate=$(printf "%.1f" $(echo "scale=2; $PASSED_COMMANDS * 100 / $TOTAL_COMMANDS" | bc))
    
    echo "=========================================="
    echo "PAK.sh Comprehensive Command Test Results"
    echo "=========================================="
    echo "Total Commands Tested: $TOTAL_COMMANDS"
    echo "Passed: $PASSED_COMMANDS"
    echo "Failed: $FAILED_COMMANDS"
    echo "Skipped: $SKIPPED_COMMANDS"
    echo "Success Rate: ${success_rate}%"
    echo "Duration: ${test_duration}s"
    echo ""
    
    if [[ $FAILED_COMMANDS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All testable commands passed!${NC}"
        echo ""
        echo -e "${YELLOW}Note: Skipped commands require external dependencies, user interaction, or system access${NC}"
    else
        echo -e "${RED}❌ $FAILED_COMMANDS command(s) failed${NC}"
        echo ""
        echo "Failed commands:"
        for command in "${!COMMAND_RESULTS[@]}"; do
            if [[ "${COMMAND_RESULTS[$command]}" -ne 0 ]]; then
                echo -e "  ${RED}✗ $command${NC}"
                echo "    Error: ${COMMAND_ERRORS[$command]:-Unknown error}"
            fi
        done
    fi
    
    echo ""
    echo "Detailed results saved to: $TEST_RESULTS"
    echo ""
}

# Main test runner
main() {
    # Initialize test environment
    init_test_env
    
    # Run all test categories
    test_core_commands
    test_deployment_commands
    test_tracking_commands
    test_security_commands
    test_automation_commands
    test_monitoring_commands
    test_devex_commands
    test_integration_commands
    test_enterprise_commands
    test_ui_commands
    test_lifecycle_commands
    test_debug_commands
    test_networking_commands
    test_mobile_commands
    test_update_commands
    test_reporting_commands
    test_specialized_commands
    test_embed_commands
    test_help_commands
    test_registration_commands
    
    # Generate results and show summary
    generate_test_results
    show_test_summary
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