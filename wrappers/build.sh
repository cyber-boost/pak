#!/bin/bash
# PAK.sh Wrapper Build Script
# Builds packages for all supported package managers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION="2.0.0"
PACKAGE_NAME="pak-sh"

# Cleanup function (only for errors)
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
    # Only remove temporary files, keep build artifacts
}

# Set trap to cleanup on exit (only for errors)
trap 'if [[ $? -ne 0 ]]; then cleanup; fi' EXIT

echo -e "${BLUE}🚀 PAK.sh Wrapper Build Script${NC}"
echo -e "${BLUE}==============================${NC}"
echo

# Create build directory
echo -e "${BLUE}📁 Creating build directory...${NC}"
mkdir -p "$BUILD_DIR"

# Function to build npm package
build_npm() {
    echo -e "${BLUE}📦 Building npm package...${NC}"
    
    local npm_dir="$BUILD_DIR/npm"
    mkdir -p "$npm_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$npm_dir/"
    cp "$SCRIPT_DIR/package.json" "$npm_dir/"
    cp "$SCRIPT_DIR/README.md" "$npm_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$npm_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Make executable
    chmod +x "$npm_dir/pak-sh"
    
    echo -e "${GREEN}✅ npm package built at: $npm_dir${NC}"
}

# Function to build Python package
build_python() {
    echo -e "${BLUE}🐍 Building Python package...${NC}"
    
    local python_dir="$BUILD_DIR/python"
    mkdir -p "$python_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$python_dir/"
    cp "$SCRIPT_DIR/setup.py" "$python_dir/"
    cp "$SCRIPT_DIR/README.md" "$python_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$python_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Make executable
    chmod +x "$python_dir/pak-sh"
    
    echo -e "${GREEN}✅ Python package built at: $python_dir${NC}"
}

# Function to build Rust package
build_rust() {
    echo -e "${BLUE}🦀 Building Rust package...${NC}"
    
    local rust_dir="$BUILD_DIR/rust"
    mkdir -p "$rust_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$rust_dir/"
    cp "$SCRIPT_DIR/Cargo.toml" "$rust_dir/"
    cp "$SCRIPT_DIR/README.md" "$rust_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$rust_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Create src directory and main.rs
    mkdir -p "$rust_dir/src"
    cat > "$rust_dir/src/main.rs" << 'EOF'
use std::process::Command;

fn main() {
    let status = Command::new("./pak-sh")
        .args(std::env::args().skip(1))
        .status()
        .expect("Failed to execute pak-sh");
    
    std::process::exit(status.code().unwrap_or(1));
}
EOF
    
    # Make executable
    chmod +x "$rust_dir/pak-sh"
    
    echo -e "${GREEN}✅ Rust package built at: $rust_dir${NC}"
}

# Function to build PHP Composer package
build_composer() {
    echo -e "${BLUE}🐘 Building PHP Composer package...${NC}"
    
    local composer_dir="$BUILD_DIR/composer"
    mkdir -p "$composer_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$composer_dir/"
    cp "$SCRIPT_DIR/composer.json" "$composer_dir/"
    cp "$SCRIPT_DIR/README.md" "$composer_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$composer_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Make executable
    chmod +x "$composer_dir/pak-sh"
    
    echo -e "${GREEN}✅ PHP Composer package built at: $composer_dir${NC}"
}

# Function to build Go package
build_go() {
    echo -e "${BLUE}🐹 Building Go package...${NC}"
    
    local go_dir="$BUILD_DIR/go"
    mkdir -p "$go_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$go_dir/"
    cp "$SCRIPT_DIR/go.mod" "$go_dir/"
    cp "$SCRIPT_DIR/main.go" "$go_dir/"
    cp "$SCRIPT_DIR/README.md" "$go_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$go_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Make executable
    chmod +x "$go_dir/pak-sh"
    
    echo -e "${GREEN}✅ Go package built at: $go_dir${NC}"
}

# Function to build RubyGems package
build_rubygems() {
    echo -e "${BLUE}💎 Building RubyGems package...${NC}"
    
    local rubygems_dir="$BUILD_DIR/rubygems"
    mkdir -p "$rubygems_dir"
    
    # Create directories
    mkdir -p "$rubygems_dir/lib"
    mkdir -p "$rubygems_dir/bin"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$rubygems_dir/bin/"
    cp "$SCRIPT_DIR/pak-sh.gemspec" "$rubygems_dir/"
    cp "$SCRIPT_DIR/README.md" "$rubygems_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$rubygems_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Create lib file
    cat > "$rubygems_dir/lib/pak_sh.rb" << 'EOF'
# PAK.sh Wrapper Ruby Library
# Provides Ruby interface for PAK.sh operations

module PakSh
  VERSION = "2.0.1"
  
  class Wrapper
    def self.install
      system("pak-sh install")
    end
    
    def self.status
      system("pak-sh status")
    end
    
    def self.run(command, *args)
      system("pak-sh run #{command}", *args)
    end
  end
end
EOF
    
    # Make executable
    chmod +x "$rubygems_dir/bin/pak-sh"
    
    echo -e "${GREEN}✅ RubyGems package built at: $rubygems_dir${NC}"
}

# Function to build Homebrew formula
build_homebrew() {
    echo -e "${BLUE}🍺 Building Homebrew formula...${NC}"
    
    local homebrew_dir="$BUILD_DIR/homebrew"
    mkdir -p "$homebrew_dir"
    
    # Copy formula
    cp "$SCRIPT_DIR/pak-sh.rb" "$homebrew_dir/"
    
    echo -e "${GREEN}✅ Homebrew formula built at: $homebrew_dir${NC}"
}

# Function to build Chocolatey package
build_chocolatey() {
    echo -e "${BLUE}🍫 Building Chocolatey package...${NC}"
    
    local chocolatey_dir="$BUILD_DIR/chocolatey"
    mkdir -p "$chocolatey_dir"
    
    # Copy files
    cp "$SCRIPT_DIR/pak-sh" "$chocolatey_dir/"
    cp "$SCRIPT_DIR/pak-sh.nuspec" "$chocolatey_dir/"
    cp "$SCRIPT_DIR/README.md" "$chocolatey_dir/"
    cp "$SCRIPT_DIR/../LICENSE" "$chocolatey_dir/" 2>/dev/null || echo "LICENSE not found"
    
    # Make executable
    chmod +x "$chocolatey_dir/pak-sh"
    
    echo -e "${GREEN}✅ Chocolatey package built at: $chocolatey_dir${NC}"
}

# Function to build Scoop manifest
build_scoop() {
    echo -e "${BLUE}🥄 Building Scoop manifest...${NC}"
    
    local scoop_dir="$BUILD_DIR/scoop"
    mkdir -p "$scoop_dir"
    
    # Copy manifest
    cp "$SCRIPT_DIR/pak-sh.json" "$scoop_dir/"
    
    echo -e "${GREEN}✅ Scoop manifest built at: $scoop_dir${NC}"
}

# Function to create distribution packages
create_distributions() {
    echo -e "${BLUE}📦 Creating distribution packages...${NC}"
    
    # Create tarballs
    for pkg in npm python rust composer go rubygems; do
        if [[ -d "$BUILD_DIR/$pkg" ]]; then
            echo -e "${BLUE}📦 Creating $pkg tarball...${NC}"
            cd "$BUILD_DIR"
            tar -czf "$pkg-$VERSION.tar.gz" "$pkg/"
            echo -e "${GREEN}✅ Created: $BUILD_DIR/$pkg-$VERSION.tar.gz${NC}"
        fi
    done
    
    # Create zip files for Windows
    for pkg in chocolatey; do
        if [[ -d "$BUILD_DIR/$pkg" ]]; then
            echo -e "${BLUE}📦 Creating $pkg zip...${NC}"
            cd "$BUILD_DIR"
            zip -r "$pkg-$VERSION.zip" "$pkg/"
            echo -e "${GREEN}✅ Created: $BUILD_DIR/$pkg-$VERSION.zip${NC}"
        fi
    done
}

# Function to run tests
run_tests() {
    echo -e "${BLUE}🧪 Running tests...${NC}"
    
    # Test wrapper script
    if [[ -f "$SCRIPT_DIR/pak-sh" ]]; then
        echo -e "${BLUE}🧪 Testing wrapper script...${NC}"
        "$SCRIPT_DIR/pak-sh" --help >/dev/null 2>&1
        echo -e "${GREEN}✅ Wrapper script test passed${NC}"
    fi
    
    # Test package.json
    if [[ -f "$SCRIPT_DIR/package.json" ]]; then
        echo -e "${BLUE}🧪 Testing package.json...${NC}"
        if command -v node >/dev/null 2>&1; then
            node -e "JSON.parse(require('fs').readFileSync('$SCRIPT_DIR/package.json', 'utf8'))"
            echo -e "${GREEN}✅ package.json test passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Node.js not found, skipping package.json test${NC}"
        fi
    fi
    
    # Test setup.py
    if [[ -f "$SCRIPT_DIR/setup.py" ]]; then
        echo -e "${BLUE}🧪 Testing setup.py...${NC}"
        if command -v python3 >/dev/null 2>&1; then
            python3 -m py_compile "$SCRIPT_DIR/setup.py"
            echo -e "${GREEN}✅ setup.py test passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Python3 not found, skipping setup.py test${NC}"
        fi
    fi
}

# Main build process
main() {
    echo -e "${BLUE}🔨 Starting build process...${NC}"
    
    # Run tests first
    run_tests
    
    # Build all packages
    build_npm
    build_python
    build_rust
    build_composer
    build_go
    build_rubygems
    build_homebrew
    build_chocolatey
    build_scoop
    
    # Create distributions
    create_distributions
    
    echo
    echo -e "${GREEN}🎉 Build completed successfully!${NC}"
    echo -e "${CYAN}📁 Build artifacts: $BUILD_DIR${NC}"
    echo
    echo -e "${BLUE}📋 Package Summary:${NC}"
    echo -e "  📦 npm: $BUILD_DIR/npm-$VERSION.tar.gz"
    echo -e "  🐍 python: $BUILD_DIR/python-$VERSION.tar.gz"
    echo -e "  🦀 rust: $BUILD_DIR/rust-$VERSION.tar.gz"
    echo -e "  🐘 composer: $BUILD_DIR/composer-$VERSION.tar.gz"
    echo -e "  🐹 go: $BUILD_DIR/go-$VERSION.tar.gz"
    echo -e "  💎 rubygems: $BUILD_DIR/rubygems-$VERSION.tar.gz"
    echo -e "  🍺 homebrew: $BUILD_DIR/homebrew/"
    echo -e "  🍫 chocolatey: $BUILD_DIR/chocolatey-$VERSION.zip"
    echo -e "  🥄 scoop: $BUILD_DIR/scoop/"
}

# Run main function
main "$@" 