#!/bin/bash
# Yarn Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION using Yarn..."

# Pre-deployment checks
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    yarn version --new-version "$PACKAGE_VERSION" --no-git-tag-version
fi

# Install dependencies
yarn install

# Run tests
echo "🧪 Running tests..."
yarn test

# Build
echo "🔨 Building package..."
yarn build

# Publish
echo "📤 Publishing to NPM registry..."
yarn publish --access public

echo "✅ Successfully deployed using Yarn!"
