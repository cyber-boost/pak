#!/bin/bash
# Go Modules Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Go Modules..."

# Pre-deployment checks
if [ ! -f "go.mod" ]; then
    echo "❌ go.mod not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    # Update version in go.mod
    sed -i "s/^module .*/module $PACKAGE_NAME/" go.mod
fi

# Run tests
echo "🧪 Running tests..."
go test ./...

# Build
echo "🔨 Building package..."
go build

# Create and push git tag
echo "🏷️  Creating git tag v$PACKAGE_VERSION..."
git add .
git commit -m "Release version $PACKAGE_VERSION"
git tag "v$PACKAGE_VERSION"
git push origin "v$PACKAGE_VERSION"

echo "✅ Successfully deployed to Go Modules!"
echo "📝 Go Modules will automatically recognize the new version"
