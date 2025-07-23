#!/bin/bash
# JSPM Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION using JSPM..."

# Pre-deployment checks
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    npm version "$PACKAGE_VERSION" --no-git-tag-version
fi

# Install dependencies
npm install

# Run tests
echo "🧪 Running tests..."
npm test

# Build
echo "🔨 Building package..."
jspm build

# Publish
echo "📤 Publishing to JSPM..."
jspm publish

echo "✅ Successfully deployed using JSPM!"
