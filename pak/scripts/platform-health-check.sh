#!/bin/bash
# Platform health monitoring script

PLATFORM="$1"
CONFIG_FILE="$PAK_CONFIG_DIR/platforms/${PLATFORM}.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Platform not found: $PLATFORM"
    exit 1
fi

HEALTH_ENDPOINT=$(jq -r '.health_endpoint' "$CONFIG_FILE")
if [[ "$HEALTH_ENDPOINT" == "null" ]]; then
    echo "No health endpoint configured for $PLATFORM"
    exit 1
fi

# Test health endpoint
if curl -s --max-time 10 "$HEALTH_ENDPOINT" >/dev/null; then
    echo "OK"
    exit 0
else
    echo "FAILED"
    exit 1
fi
