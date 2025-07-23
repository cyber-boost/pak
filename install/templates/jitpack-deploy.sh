#!/bin/bash
# JitPack Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to JitPack..."

# Pre-deployment checks
if [ ! -f "build.gradle" ] && [ ! -f "pom.xml" ]; then
    echo "❌ build.gradle or pom.xml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    if [ -f "build.gradle" ]; then
        sed -i "s/version = \".*\"/version = \"$PACKAGE_VERSION\"/" build.gradle
    fi
    if [ -f "pom.xml" ]; then
        mvn versions:set -DnewVersion="$PACKAGE_VERSION"
    fi
fi

# Create and push git tag
echo "🏷️  Creating git tag v$PACKAGE_VERSION..."
git add .
git commit -m "Release version $PACKAGE_VERSION"
git tag "v$PACKAGE_VERSION"
git push origin "v$PACKAGE_VERSION"

echo "✅ Successfully deployed to JitPack!"
echo "📝 JitPack will automatically build and publish the package"
