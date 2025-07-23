#!/bin/bash
# PAK.sh Test Runner
# Simple script to run the comprehensive test suite

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PAK.sh Test Runner${NC}"
echo "========================"
echo ""

# Check if PAK.sh exists
if [[ ! -f "$PROJECT_ROOT/pak/pak.sh" ]]; then
    echo "❌ Error: PAK.sh not found at $PROJECT_ROOT/pak/pak.sh"
    exit 1
fi

# Check if test script exists
if [[ ! -f "$SCRIPT_DIR/test-all-commands.sh" ]]; then
    echo "❌ Error: Test script not found at $SCRIPT_DIR/test-all-commands.sh"
    exit 1
fi

echo "✅ PAK.sh found at: $PROJECT_ROOT/pak/pak.sh"
echo "✅ Test script found at: $SCRIPT_DIR/test-all-commands.sh"
echo ""

# Ask user for confirmation
echo "This will test all PAK.sh commands in a safe, isolated environment."
echo "The test will:"
echo "  • Create a temporary test environment"
echo "  • Test all available commands"
echo "  • Skip commands that require external dependencies"
echo "  • Generate a detailed test report"
echo ""

read -p "Continue with testing? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting comprehensive test suite...${NC}"
echo ""

# Run the test suite
"$SCRIPT_DIR/test-all-commands.sh"

echo ""
echo -e "${GREEN}Test suite completed!${NC}"
echo "Check the test results in: $SCRIPT_DIR/test-results.json" 