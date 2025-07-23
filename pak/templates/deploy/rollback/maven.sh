#!/bin/bash
# Rollback template for maven

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PREVIOUS_VERSION="$3"

echo "🔄 Rolling back maven deployment..."

# Platform-specific rollback logic
case "maven" in
    npm)
        echo "⚠️  NPM rollback: Manual intervention required"
        echo "   Run: npm unpublish $PACKAGE_NAME@$PACKAGE_VERSION"
        ;;
    pypi)
        echo "⚠️  PyPI rollback: Manual intervention required"
        echo "   Run: twine delete $PACKAGE_NAME $PACKAGE_VERSION"
        ;;
    cargo)
        echo "⚠️  Cargo rollback: Manual intervention required"
        echo "   Run: cargo yank $PACKAGE_NAME $PACKAGE_VERSION"
        ;;
    dockerhub)
        echo "🔄 Docker rollback: Tagging previous version"
        docker tag "$PACKAGE_NAME:$PREVIOUS_VERSION" "$PACKAGE_NAME:latest"
        docker push "$PACKAGE_NAME:latest"
        ;;
    maven)
        echo "⚠️  Maven rollback: Manual intervention required"
        ;;
    composer)
        echo "⚠️  Composer rollback: Manual intervention required"
        ;;
esac

echo "✅ Rollback completed for maven"
