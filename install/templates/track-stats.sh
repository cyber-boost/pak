#!/bin/bash
# Universal Statistics Tracker

set -euo pipefail

PACKAGE_NAME="$1"
PLATFORM="$2"
CONFIG_FILE="$3"

# Load platform configuration
PLATFORM_CONFIG=$(cat "$CONFIG_FILE")

# Extract tracking endpoints
ENDPOINTS=$(echo "$PLATFORM_CONFIG" | jq -r '.tracking_endpoints[]')

for endpoint in $ENDPOINTS; do
    # Replace {package} placeholder
    endpoint=$(echo "$endpoint" | sed "s/{package}/$PACKAGE_NAME/g")
    
    # Fetch data
    response=$(curl -s "$endpoint" 2>/dev/null || echo "{}")
    
    # Process response based on platform
    case $PLATFORM in
        "npm")
            downloads=$(echo "$response" | jq -r '.downloads // 0')
            ;;
        "pypi")
            downloads=$(echo "$response" | jq -r '.data[] | select(.category=="without_mirrors") | .downloads' | head -1 || echo "0")
            ;;
        "cargo")
            downloads=$(echo "$response" | jq -r '.crate.downloads // 0')
            ;;
        *)
            downloads=$(echo "$response" | jq -r '.downloads // 0')
            ;;
    esac
    
    echo "$downloads"
done
