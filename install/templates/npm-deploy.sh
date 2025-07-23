#!/bin/bash
# NPM Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

# Pre-deployment checks
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    npm version "$PACKAGE_VERSION" --no-git-tag-version
fi

# Build if build script exists
if grep -q '"build"' package.json; then
    npm run build
fi

# Run tests if test script exists
if grep -q '"test"' package.json; then
    npm test
fi

# Publish
npm publish

echo "✅ NPM deployment successful"
