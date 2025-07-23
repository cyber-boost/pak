#!/bin/bash
# Packagist Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Packagist..."

# Pre-deployment checks
if [ ! -f "composer.json" ]; then
    echo "❌ composer.json not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/\"version\": \".*\"/\"version\": \"$PACKAGE_VERSION\"/" composer.json
fi

# Install dependencies
echo "📦 Installing dependencies..."
composer install --no-dev --optimize-autoloader

# Run tests
echo "🧪 Running tests..."
composer test

# Build
echo "🔨 Building package..."
composer build

# Publish (requires webhook setup)
echo "📤 Publishing to Packagist..."
echo "⚠️  Note: Packagist requires webhook setup for automatic deployment"
echo "📝 Please ensure your repository is connected to Packagist"

echo "✅ Packagist deployment initiated!"
