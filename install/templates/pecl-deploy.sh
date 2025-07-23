#!/bin/bash
# PECL Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to PECL..."

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
echo "📦 Creating PECL package..."
pecl package

# Upload
echo "📤 Uploading to PECL..."
pecl upload *.tgz

echo "✅ Successfully deployed to PECL!"
