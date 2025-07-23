#!/bin/bash
# Swift Package Manager Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Swift Package Manager..."

# Pre-deployment checks
if [ ! -f "Package.swift" ]; then
    echo "❌ Package.swift not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/let version = \".*\"/let version = \"$PACKAGE_VERSION\"/" Package.swift
fi

# Resolve dependencies
echo "📦 Resolving dependencies..."
swift package --allow-writing-to-package-directory resolve

# Run tests
echo "🧪 Running tests..."
swift test

# Build
echo "🔨 Building package..."
swift build

# Create and push git tag
echo "🏷️  Creating git tag v$PACKAGE_VERSION..."
git add .
git commit -m "Release version $PACKAGE_VERSION"
git tag "v$PACKAGE_VERSION"
git push origin "v$PACKAGE_VERSION"

echo "✅ Successfully deployed to Swift Package Manager!"
