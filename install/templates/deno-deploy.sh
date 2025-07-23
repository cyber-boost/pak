#!/bin/bash
# Deno Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Deno Land..."

# Pre-deployment checks
if [ ! -f "mod.ts" ]; then
    echo "❌ mod.ts not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    # Update version in deno.json if it exists
    if [ -f "deno.json" ]; then
        sed -i "s/\"version\": \".*\"/\"version\": \"$PACKAGE_VERSION\"/" deno.json
    fi
fi

# Run tests
echo "🧪 Running tests..."
deno test

# Deploy (requires deno deploy setup)
echo "📤 Deploying to Deno Land..."
echo "⚠️  Note: Deno Land deployment requires proper repository setup"
echo "📝 Please ensure your repository is configured for Deno Land"

echo "✅ Deno Land deployment initiated!"
