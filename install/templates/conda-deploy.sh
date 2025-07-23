#!/bin/bash
# Conda Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Conda..."

# Pre-deployment checks
if [ ! -f "meta.yaml" ]; then
    echo "❌ meta.yaml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/version:.*/version: $PACKAGE_VERSION/" meta.yaml
fi

# Build conda package
echo "🔨 Building conda package..."
conda build .

# Upload to Anaconda
echo "📤 Uploading to Anaconda..."
anaconda upload $(conda build . --output)

echo "✅ Successfully deployed to Conda!"
