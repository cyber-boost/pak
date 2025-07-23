#!/bin/bash
# JSR Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to JSR..."

# Pre-deployment checks
if [ ! -f "deno.json" ]; then
    echo "❌ deno.json not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/\"version\": \".*\"/\"version\": \"$PACKAGE_VERSION\"/" deno.json
fi

# Run tests
echo "🧪 Running tests..."
deno test

# Publish to JSR
echo "📤 Publishing to JSR..."
jsr publish

echo "✅ Successfully deployed to JSR!"
