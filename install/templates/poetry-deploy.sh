#!/bin/bash
# Poetry Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION using Poetry..."

# Pre-deployment checks
if [ ! -f "pyproject.toml" ]; then
    echo "❌ pyproject.toml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    poetry version "$PACKAGE_VERSION"
fi

# Install dependencies
echo "📦 Installing dependencies..."
poetry install

# Run tests
echo "🧪 Running tests..."
poetry run pytest

# Build
echo "🔨 Building package..."
poetry build

# Publish
echo "📤 Publishing to PyPI..."
poetry publish

echo "✅ Successfully deployed using Poetry!"
