#!/bin/bash
# Post-deployment template for npm

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"
DEPLOY_ID="$4"

cd "$PACKAGE_DIR"

echo "✅ Post-deployment tasks for npm..."

# Platform-specific post-deployment logic
case "npm" in
    npm)
        echo "📊 NPM package published: $PACKAGE_NAME@$PACKAGE_VERSION"
        npm view "$PACKAGE_NAME@$PACKAGE_VERSION" version
        ;;
    pypi)
        echo "📊 PyPI package published: $PACKAGE_NAME==$PACKAGE_VERSION"
        pip show "$PACKAGE_NAME" | grep Version
        ;;
    cargo)
        echo "📊 Cargo package published: $PACKAGE_NAME $PACKAGE_VERSION"
        cargo search "$PACKAGE_NAME" | head -1
        ;;
    dockerhub)
        echo "📊 Docker image published: $PACKAGE_NAME:$PACKAGE_VERSION"
        docker images "$PACKAGE_NAME" | grep "$PACKAGE_VERSION"
        ;;
    maven)
        echo "📊 Maven artifact published: $PACKAGE_NAME $PACKAGE_VERSION"
        ;;
    composer)
        echo "📊 Composer package published: $PACKAGE_NAME $PACKAGE_VERSION"
        ;;
esac

# Update deployment record
jq --arg platform "npm" --arg status "completed" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"    '.platforms[npm] = {"status": , "completed_at": }'    "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json"

echo "✅ Post-deployment tasks completed for npm"
