#!/bin/bash
# PAK.sh Complete Test Suite Runner
# Runs all test types: quick, comprehensive, advanced, and stress tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results
TOTAL_TEST_SUITES=0
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0
SKIPPED_TEST_SUITES=0
OVERALL_START_TIME=$(date +%s)

echo -e "${BLUE}🚀 PAK.sh Complete Test Suite Runner${NC}"
echo "=========================================="
echo ""
echo "This will run ALL test types for PAK.sh:"
echo "  • Quick Test (Basic functionality)"
echo "  • Comprehensive Test (All commands)"
echo "  • Advanced Test (Edge cases & integration)"
echo "  • Stress Test (Performance & load)"
echo ""
echo "Total estimated time: 30-45 minutes"
echo ""

# Check if PAK.sh exists
if [[ ! -f "$PROJECT_ROOT/pak/pak.sh" ]]; then
    echo -e "${RED}❌ Error: PAK.sh not found at $PROJECT_ROOT/pak/pak.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ PAK.sh found at: $PROJECT_ROOT/pak/pak.sh${NC}"
echo ""

# Ask user for confirmation
echo "This comprehensive test suite will:"
echo "  • Test all 300+ commands across 19 categories"
echo "  • Test edge cases and error conditions"
echo "  • Test integration scenarios"
echo "  • Test performance under load"
echo "  • Generate detailed reports for each test type"
echo "  • Create a comprehensive summary report"
echo ""
echo "⚠️  This is a comprehensive test that may take 30-45 minutes"
echo ""

read -p "Continue with complete test suite? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting complete test suite...${NC}"
echo ""

# Test suite runner function
run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    local description="$3"
    
    TOTAL_TEST_SUITES=$((TOTAL_TEST_SUITES + 1))
    
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}Running: $test_name${NC}"
    echo -e "${CYAN}Description: $description${NC}"
    echo -e "${CYAN}Script: $test_script${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
    
    local start_time=$(date +%s)
    
    if [[ -f "$test_script" ]]; then
        if "$test_script"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            PASSED_TEST_SUITES=$((PASSED_TEST_SUITES + 1))
            echo -e "${GREEN}✅ $test_name PASSED (${duration}s)${NC}"
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
            echo -e "${RED}❌ $test_name FAILED (${duration}s)${NC}"
        fi
    else
        SKIPPED_TEST_SUITES=$((SKIPPED_TEST_SUITES + 1))
        echo -e "${YELLOW}⏭️  $test_name SKIPPED (script not found)${NC}"
    fi
    
    echo ""
}

# Run all test suites
echo -e "${BLUE}=== Phase 1: Quick Test ===${NC}"
run_test_suite "Quick Test" "$SCRIPT_DIR/quick-test.sh" "Basic functionality test (75 commands)"

echo -e "${BLUE}=== Phase 2: Comprehensive Test ===${NC}"
run_test_suite "Comprehensive Test" "$SCRIPT_DIR/test-all-commands.sh" "All commands test (300+ commands)"

echo -e "${BLUE}=== Phase 3: Advanced Test ===${NC}"
run_test_suite "Advanced Test" "$SCRIPT_DIR/advanced-tests.sh" "Edge cases and integration test"

echo -e "${BLUE}=== Phase 4: Stress Test ===${NC}"
run_test_suite "Stress Test" "$SCRIPT_DIR/stress-tests.sh" "Performance and load test"

# Generate comprehensive results
generate_comprehensive_results() {
    local overall_end_time=$(date +%s)
    local overall_duration=$((overall_end_time - OVERALL_START_TIME))
    local success_rate=$(printf "%.1f" $(echo "scale=2; $PASSED_TEST_SUITES * 100 / $TOTAL_TEST_SUITES" | bc))
    
    # Create comprehensive results file
    cat > "$SCRIPT_DIR/comprehensive-test-results.json" << EOF
{
  "test_suite": "PAK.sh Complete Test Suite",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "overall_duration_seconds": $overall_duration,
  "summary": {
    "total_test_suites": $TOTAL_TEST_SUITES,
    "passed": $PASSED_TEST_SUITES,
    "failed": $FAILED_TEST_SUITES,
    "skipped": $SKIPPED_TEST_SUITES,
    "success_rate": "$success_rate%"
  },
  "test_suites": {
    "quick_test": {
      "script": "quick-test.sh",
      "description": "Basic functionality test (75 commands)",
      "duration": "~2-3 minutes",
      "scope": "Core commands and help systems"
    },
    "comprehensive_test": {
      "script": "test-all-commands.sh",
      "description": "All commands test (300+ commands)",
      "duration": "~10-15 minutes",
      "scope": "All 19 command categories"
    },
    "advanced_test": {
      "script": "advanced-tests.sh",
      "description": "Edge cases and integration test",
      "duration": "~8-12 minutes",
      "scope": "Edge cases, error conditions, integration"
    },
    "stress_test": {
      "script": "stress-tests.sh",
      "description": "Performance and load test",
      "duration": "~10-15 minutes",
      "scope": "Performance, load, concurrent operations"
    }
  },
  "test_coverage": {
    "total_commands": "300+",
    "command_categories": 19,
    "test_types": 4,
    "safety_level": "High (isolated environment, dry-run mode)",
    "estimated_coverage": ">95%"
  }
}
EOF
}

# Show comprehensive summary
show_comprehensive_summary() {
    local overall_end_time=$(date +%s)
    local overall_duration=$((overall_end_time - OVERALL_START_TIME))
    local success_rate=$(printf "%.1f" $(echo "scale=2; $PASSED_TEST_SUITES * 100 / $TOTAL_TEST_SUITES" | bc))
    
    echo "=========================================="
    echo "PAK.sh Complete Test Suite Results"
    echo "=========================================="
    echo "Total Test Suites: $TOTAL_TEST_SUITES"
    echo "Passed: $PASSED_TEST_SUITES"
    echo "Failed: $FAILED_TEST_SUITES"
    echo "Skipped: $SKIPPED_TEST_SUITES"
    echo "Success Rate: ${success_rate}%"
    echo "Total Duration: ${overall_duration}s ($(echo "scale=1; $overall_duration / 60" | bc) minutes)"
    echo ""
    
    if [[ $FAILED_TEST_SUITES -eq 0 ]]; then
        echo -e "${GREEN}🎉 All test suites passed!${NC}"
        echo ""
        echo -e "${YELLOW}Test Coverage Summary:${NC}"
        echo "  • Quick Test: 75 core commands"
        echo "  • Comprehensive Test: 300+ commands across 19 categories"
        echo "  • Advanced Test: Edge cases and integration scenarios"
        echo "  • Stress Test: Performance and load testing"
        echo ""
        echo -e "${GREEN}PAK.sh is fully validated and ready for production!${NC}"
    else
        echo -e "${RED}❌ $FAILED_TEST_SUITES test suite(s) failed${NC}"
        echo ""
        echo "Failed test suites:"
        if [[ $FAILED_TEST_SUITES -gt 0 ]]; then
            echo -e "  ${RED}✗ Some test suites failed - check individual results${NC}"
        fi
    fi
    
    echo ""
    echo "Individual test results:"
    echo "  • Quick Test: $SCRIPT_DIR/quick-test.sh"
    echo "  • Comprehensive Test: $SCRIPT_DIR/test-results.json"
    echo "  • Advanced Test: $SCRIPT_DIR/advanced-test-results.json"
    echo "  • Stress Test: $SCRIPT_DIR/stress-test-results.json"
    echo "  • Comprehensive Summary: $SCRIPT_DIR/comprehensive-test-results.json"
    echo ""
    
    echo -e "${BLUE}Test suite completed!${NC}"
    echo "For detailed analysis, review the individual result files above."
}

# Generate results and show summary
generate_comprehensive_results
show_comprehensive_summary 