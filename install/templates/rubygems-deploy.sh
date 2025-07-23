#!/bin/bash
# RubyGems Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to RubyGems..."

# Pre-deployment checks
if [ ! -f "*.gemspec" ]; then
    echo "❌ *.gemspec not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    sed -i "s/\.version\s*=.*/\.version = '$PACKAGE_VERSION'/" *.gemspec
fi

# Install dependencies
echo "📦 Installing dependencies..."
bundle install

# Run tests
echo "🧪 Running tests..."
bundle exec rspec

# Build gem
echo "🔨 Building gem..."
gem build *.gemspec

# Push to RubyGems
echo "📤 Uploading to RubyGems..."
gem push *.gem

echo "✅ Successfully deployed to RubyGems!"
