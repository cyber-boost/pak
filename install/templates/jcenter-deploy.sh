#!/bin/bash
# JCenter Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to JCenter..."

# Pre-deployment checks
if [ ! -f "build.gradle" ]; then
    echo "❌ build.gradle not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/version = \".*\"/version = \"$PACKAGE_VERSION\"/" build.gradle
fi

# Build
echo "🔨 Building package..."
gradle build

# Run tests
echo "🧪 Running tests..."
gradle test

# Upload to JCenter
echo "📤 Uploading to JCenter..."
gradle bintrayUpload

echo "✅ Successfully deployed to JCenter!"
