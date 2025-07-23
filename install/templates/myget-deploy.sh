#!/bin/bash
# MyGet Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🚀 Deploying $PACKAGE_NAME v$PACKAGE_VERSION to MyGet..."

# Pre-deployment checks
if [ ! -f "*.csproj" ] && [ ! -f "*.nuspec" ]; then
    echo "❌ *.csproj or *.nuspec not found"
    exit 1
fi

# Update version if specified
if [ -n "$PACKAGE_VERSION" ]; then
    if [ -f "*.csproj" ]; then
        sed -i "s/<Version>.*<\/Version>/<Version>$PACKAGE_VERSION<\/Version>/" *.csproj
    fi
    if [ -f "*.nuspec" ]; then
        sed -i "s/<version>.*<\/version>/<version>$PACKAGE_VERSION<\/version>/" *.nuspec
    fi
fi

# Restore dependencies
echo "📦 Restoring dependencies..."
dotnet restore

# Build
echo "🔨 Building package..."
dotnet build --configuration Release

# Pack
echo "📦 Packing NuGet package..."
dotnet pack --configuration Release --output nupkgs

# Push to MyGet
echo "📤 Uploading to MyGet..."
dotnet nuget push nupkgs/*.nupkg --source https://www.myget.org/F/{feed}/api/v2/package --api-key "$MYGET_API_KEY"

echo "✅ Successfully deployed to MyGet!"
