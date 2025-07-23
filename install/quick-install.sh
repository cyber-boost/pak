#!/bin/bash

# Quick Install Script for Universal Package Tracker & Deployer
# One-liner installation for developers

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Quick Installing Universal Package Tracker & Deployer...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Installing system-wide...${NC}"
    ./install.sh
else
    echo -e "${YELLOW}⚠️  Installing locally (no sudo required)...${NC}"
    INSTALL_DIR=./bin CONFIG_DIR=./config DATA_DIR=./data LOG_DIR=./logs ./install.sh
fi

echo -e "${GREEN}✅ Quick installation complete!${NC}"
echo -e "${BLUE}💡 Next steps:${NC}"
echo -e "  1. Run: ${GREEN}pak --init${NC}"
echo -e "  2. Start tracking: ${GREEN}pak --package your-package --track-only${NC}"
echo -e "  3. Get help: ${GREEN}pak --help${NC}" 