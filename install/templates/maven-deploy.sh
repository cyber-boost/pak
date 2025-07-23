#!/bin/bash
# Maven Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to Maven Central..."

# Pre-deployment checks
if [ ! -f "pom.xml" ]; then
    echo "❌ pom.xml not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    mvn versions:set -DnewVersion="$PACKAGE_VERSION"
fi

# Clean and compile
echo "🔨 Building package..."
mvn clean compile

# Run tests
echo "🧪 Running tests..."
mvn test

# Package
echo "📦 Packaging..."
mvn package

# Deploy to Maven Central
echo "📤 Uploading to Maven Central..."
mvn deploy -DskipTests

echo "✅ Successfully deployed to Maven Central!"
