#!/bin/bash
# GoCenter Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to GoCenter..."

# Pre-deployment checks
if [ ! -f "go.mod" ]; then
    echo "❌ go.mod not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
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

echo "✅ Successfully deployed to GoCenter!"
echo "📝 GoCenter will automatically index the new version"
