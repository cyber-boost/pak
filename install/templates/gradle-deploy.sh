#!/bin/bash
# Gradle Plugin Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Gradle Plugin Portal..."

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
echo "🔨 Building plugin..."
gradle build

# Run tests
echo "🧪 Running tests..."
gradle test

# Publish plugin
echo "📤 Publishing to Gradle Plugin Portal..."
gradle publishPlugins

echo "✅ Successfully deployed to Gradle Plugin Portal!"
