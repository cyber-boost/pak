#!/bin/bash
# PEAR Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to PEAR..."

# Pre-deployment checks
if [ ! -f "package.xml" ]; then
    echo "❌ package.xml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/<version>.*<\/version>/<version>$PACKAGE_VERSION<\/version>/" package.xml
fi

# Package
echo "📦 Creating PEAR package..."
pear package

# Upload
echo "📤 Uploading to PEAR..."
pear upload *.tgz

echo "✅ Successfully deployed to PEAR!"
