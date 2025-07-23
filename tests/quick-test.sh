#!/bin/bash
# PAK.sh Quick Test
# Basic functionality test for PAK.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PAK_DIR="$PROJECT_ROOT/pak"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test utilities
log_test() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        INFO) echo -e "${BLUE}[TEST INFO]${NC} $message" ;;
        PASS) echo -e "${GREEN}[TEST PASS]${NC} $message" ;;
        FAIL) echo -e "${RED}[TEST FAIL]${NC} $message" ;;
    esac
}

run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="${3:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    echo "Command: $command"
    
    if eval "$command" >/dev/null 2>&1; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    if [[ $exit_code -eq $expected_exit ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test PASS "$test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_test FAIL "$test_name (Exit: $exit_code, Expected: $expected_exit)"
    fi
    
    echo ""
}

echo -e "${BLUE}=== PAK.sh Quick Test ===${NC}"
echo "Testing basic functionality"
echo "PAK Directory: $PAK_DIR"
echo ""

# Check if PAK.sh exists
if [[ ! -f "$PAK_DIR/pak.sh" ]]; then
    echo -e "${RED}❌ Error: PAK.sh not found at $PAK_DIR/pak.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ PAK.sh found${NC}"
echo ""

# Test basic commands
run_test "Version command" "$PAK_DIR/pak.sh version"
run_test "Help command" "$PAK_DIR/pak.sh help"
run_test "Version flag" "$PAK_DIR/pak.sh --version"
run_test "Help flag" "$PAK_DIR/pak.sh --help"

# Test debug mode
run_test "Debug mode" "$PAK_DIR/pak.sh --debug version"
run_test "Quiet mode" "$PAK_DIR/pak.sh --quiet version"
run_test "Dry run mode" "$PAK_DIR/pak.sh --dry-run version"

# Test help for specific commands
run_test "Register help" "$PAK_DIR/pak.sh register --help"
run_test "Deploy help" "$PAK_DIR/pak.sh deploy --help"
run_test "Track help" "$PAK_DIR/pak.sh track --help"
run_test "Security help" "$PAK_DIR/pak.sh security --help"
run_test "Embed help" "$PAK_DIR/pak.sh embed --help"

# Test list commands
run_test "Register list" "$PAK_DIR/pak.sh register-list"
run_test "Deploy list" "$PAK_DIR/pak.sh deploy list"
run_test "Monitor list" "$PAK_DIR/pak.sh monitor list"
run_test "Alerts list" "$PAK_DIR/pak.sh alerts list"

# Test status commands
run_test "Status command" "$PAK_DIR/pak.sh status"
run_test "Deploy status" "$PAK_DIR/pak.sh deploy status"
run_test "API status" "$PAK_DIR/pak.sh api status"
run_test "Enterprise status" "$PAK_DIR/pak.sh enterprise status"

# Test embed commands
run_test "Embed init" "$PAK_DIR/pak.sh embed init"
run_test "Embed telemetry install" "$PAK_DIR/pak.sh embed telemetry install"
run_test "Embed analytics setup" "$PAK_DIR/pak.sh embed analytics setup"
run_test "Embed track pageview" "$PAK_DIR/pak.sh embed track pageview"
run_test "Embed report generate" "$PAK_DIR/pak.sh embed report generate"

# Test utility commands
run_test "ASCII show" "$PAK_DIR/pak.sh ascii show PAK"
run_test "Config list" "$PAK_DIR/pak.sh config list"
run_test "DB status" "$PAK_DIR/pak.sh db status"
run_test "Log show" "$PAK_DIR/pak.sh log show"

# Test debug commands
run_test "Debug enable" "$PAK_DIR/pak.sh debug enable"
run_test "Debug disable" "$PAK_DIR/pak.sh debug disable"
run_test "Optimize cache" "$PAK_DIR/pak.sh optimize cache"

# Test network commands
run_test "Network test" "$PAK_DIR/pak.sh network test"
run_test "API test" "$PAK_DIR/pak.sh api test"

# Test update commands
run_test "Update check" "$PAK_DIR/pak.sh update check"
run_test "Maintenance status" "$PAK_DIR/pak.sh maintenance status"
run_test "Backup list" "$PAK_DIR/pak.sh backup list"

# Test reporting commands
run_test "Report list" "$PAK_DIR/pak.sh report list"
run_test "GDPR check" "$PAK_DIR/pak.sh gdpr check"
run_test "Policy list" "$PAK_DIR/pak.sh policy list"

# Test specialized commands
run_test "Unity help" "$PAK_DIR/pak.sh unity --help"
run_test "Docker help" "$PAK_DIR/pak.sh docker --help"
run_test "AWS help" "$PAK_DIR/pak.sh aws --help"
run_test "VS Code help" "$PAK_DIR/pak.sh vscode --help"

# Test mobile commands
run_test "Mobile status" "$PAK_DIR/pak.sh mobile status"
run_test "Locale list" "$PAK_DIR/pak.sh locale list"
run_test "Timezone list" "$PAK_DIR/pak.sh timezone list"

# Test lifecycle commands
run_test "Version list" "$PAK_DIR/pak.sh version list"
run_test "Release list" "$PAK_DIR/pak.sh release list"
run_test "Deps list" "$PAK_DIR/pak.sh deps list"

# Test automation commands
run_test "Pipeline list" "$PAK_DIR/pak.sh pipeline list"
run_test "Workflow list" "$PAK_DIR/pak.sh workflow list"
run_test "Git hooks list" "$PAK_DIR/pak.sh git hooks list"

# Test integration commands
run_test "Webhook list" "$PAK_DIR/pak.sh webhook list"
run_test "Plugin list" "$PAK_DIR/pak.sh plugin list"

# Test enterprise commands
run_test "Team list" "$PAK_DIR/pak.sh team list"
run_test "Audit report" "$PAK_DIR/pak.sh audit report"

# Test devex commands
run_test "DevEx help" "$PAK_DIR/pak.sh devex --help"
run_test "DevEx template list" "$PAK_DIR/pak.sh devex template list"
run_test "DevEx docs serve help" "$PAK_DIR/pak.sh devex docs serve --help"

# Test monitoring commands
run_test "Health all" "$PAK_DIR/pak.sh health all"

# Test performance commands
run_test "Perf benchmark help" "$PAK_DIR/pak.sh perf benchmark --help"

# Show results
echo "=========================================="
echo "PAK.sh Quick Test Results"
echo "=========================================="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo -e "${YELLOW}Note: This is a basic functionality test.${NC}"
    echo "For comprehensive testing, run: ./tests/run-tests.sh"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS test(s) failed${NC}"
    echo ""
    echo "For detailed testing, run: ./tests/run-tests.sh"
    exit 1
fi 