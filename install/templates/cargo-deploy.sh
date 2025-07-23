#!/bin/bash
# Cargo Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

# Pre-deployment checks
if [ ! -f "Cargo.toml" ]; then
    echo "❌ Cargo.toml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/^version = \".*\"/version = \"$PACKAGE_VERSION\"/" Cargo.toml
fi

# Publish
cargo publish

echo "✅ Cargo deployment successful"
