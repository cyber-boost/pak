#!/bin/bash
# Test script for PAK.sh registration functionality

echo "🧪 Testing PAK.sh Registration Module"
echo "====================================="
echo

# Test the registration wizard
echo "1. Testing registration wizard..."
./pak.sh register --help

echo
echo "2. Testing platform listing..."
./pak.sh register-list

echo
echo "3. Testing single platform registration..."
./pak.sh register-platform npm

echo
echo "4. Testing credential export..."
./pak.sh register-export test-credentials.json

echo
echo "✅ Registration module tests completed!"
echo
echo "To use the registration wizard:"
echo "  ./pak.sh register"
echo
echo "To register with specific platforms:"
echo "  ./pak.sh register-platform npm"
echo "  ./pak.sh register-platform pypi"
echo "  ./pak.sh register-platform cargo"
echo
echo "To test credentials:"
echo "  ./pak.sh register-test npm"
echo
echo "To list registered platforms:"
echo "  ./pak.sh register-list" 