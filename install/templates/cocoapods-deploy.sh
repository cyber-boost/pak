#!/bin/bash
# CocoaPods Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to CocoaPods..."

# Pre-deployment checks
if [ ! -f "*.podspec" ]; then
    echo "❌ *.podspec not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/\.version\s*=.*/\.version = '$PACKAGE_VERSION'/" *.podspec
fi

# Lint podspec
echo "🔍 Linting podspec..."
pod spec lint *.podspec

# Push to trunk
echo "📤 Pushing to CocoaPods trunk..."
pod trunk push *.podspec

echo "✅ Successfully deployed to CocoaPods!"
