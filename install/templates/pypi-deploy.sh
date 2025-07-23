#!/bin/bash
# PyPI Deployment Template

set -euo pipefail

PACKAGE_NAME="$1"
PACKAGE_VERSION="$2"
PACKAGE_DIR="$3"

cd "$PACKAGE_DIR"

# Pre-deployment checks
if [ ! -f "setup.py" ] && [ ! -f "pyproject.toml" ]; then
    echo "❌ setup.py or pyproject.toml not found"
    exit 1
fi

# Build distribution
python -m build

# Upload to PyPI
twine upload dist/*

echo "✅ PyPI deployment successful"
