#!/bin/bash
# Pre-deployment template for composer

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

echo "🔍 Pre-deployment checks for composer..."

# Platform-specific pre-deployment logic
case "composer" in
    npm)
        [[ -f "package.json" ]] || { echo "❌ package.json not found"; exit 1; }
        npm install
        npm test
        npm run build
        ;;
    pypi)
        [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || { echo "❌ setup.py or pyproject.toml not found"; exit 1; }
        pip install -e .
        python -m pytest
        python -m build
        ;;
    cargo)
        [[ -f "Cargo.toml" ]] || { echo "❌ Cargo.toml not found"; exit 1; }
        cargo build
        cargo test
        cargo build --release
        ;;
    dockerhub)
        [[ -f "Dockerfile" ]] || { echo "❌ Dockerfile not found"; exit 1; }
        docker build -t "$PACKAGE_NAME:$PACKAGE_VERSION" .
        docker run --rm "$PACKAGE_NAME:$PACKAGE_VERSION" test
        ;;
    maven)
        [[ -f "pom.xml" ]] || { echo "❌ pom.xml not found"; exit 1; }
        mvn install
        mvn test
        mvn clean package
        ;;
    composer)
        [[ -f "composer.json" ]] || { echo "❌ composer.json not found"; exit 1; }
        composer install
        composer test
        composer build
        ;;
esac

echo "✅ Pre-deployment checks passed for composer"
