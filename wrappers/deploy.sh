#!/bin/bash
# PAK.sh Wrapper Deployment Script
# Deploys to all supported package managers automatically

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
VERSION="2.0.1"
PACKAGE_NAME="pak-sh"
DEPLOY_LOG="$SCRIPT_DIR/deploy.log"

# Deployment status tracking
declare -A DEPLOY_STATUS
DEPLOY_STATUS=()

# Cleanup function
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up deployment artifacts...${NC}"
    rm -rf "$BUILD_DIR"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo -e "[$timestamp] [$level] $message" | tee -a "$DEPLOY_LOG"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking deployment prerequisites...${NC}"
    
    local missing_tools=()
    
    # Check for required tools
    local tools=("curl" "git" "tar" "zip")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    # Check for package manager tools
    if ! command -v npm >/dev/null 2>&1; then
        log "WARN" "npm not found - npm deployment will be skipped"
    fi
    
    if ! command -v pip >/dev/null 2>&1; then
        log "WARN" "pip not found - pip deployment will be skipped"
    fi
    
    if ! command -v cargo >/dev/null 2>&1; then
        log "WARN" "cargo not found - cargo deployment will be skipped"
    fi
    
    if ! command -v composer >/dev/null 2>&1; then
        log "WARN" "composer not found - composer deployment will be skipped"
    fi
    
    if ! command -v go >/dev/null 2>&1; then
        log "WARN" "go not found - go deployment will be skipped"
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to build packages
build_packages() {
    echo -e "${BLUE}🔨 Building packages...${NC}"
    
    if [[ -f "$SCRIPT_DIR/build.sh" ]]; then
        "$SCRIPT_DIR/build.sh"
        echo -e "${GREEN}✅ Packages built successfully${NC}"
    else
        echo -e "${RED}❌ Build script not found${NC}"
        exit 1
    fi
}

# Function to deploy to npm
deploy_npm() {
    echo -e "${BLUE}📦 Deploying to npm...${NC}"
    
    if ! command -v npm >/dev/null 2>&1; then
        log "WARN" "npm not available, skipping npm deployment"
        DEPLOY_STATUS["npm"]="skipped"
        return
    fi
    
    local npm_dir="$BUILD_DIR/npm"
    if [[ ! -d "$npm_dir" ]]; then
        log "ERROR" "npm package not found at $npm_dir"
        DEPLOY_STATUS["npm"]="failed"
        return
    fi
    
    cd "$npm_dir"
    
    # Check if logged in to npm
    if ! npm whoami >/dev/null 2>&1; then
        log "WARN" "Not logged in to npm, attempting login..."
        npm login
    fi
    
    # Publish package
    if npm publish --access public; then
        log "SUCCESS" "npm deployment successful"
        DEPLOY_STATUS["npm"]="success"
        echo -e "${GREEN}✅ npm deployment successful${NC}"
    else
        log "ERROR" "npm deployment failed"
        DEPLOY_STATUS["npm"]="failed"
        echo -e "${RED}❌ npm deployment failed${NC}"
    fi
}

# Function to deploy to PyPI
deploy_pypi() {
    echo -e "${BLUE}🐍 Deploying to PyPI...${NC}"
    
    if ! command -v pip >/dev/null 2>&1; then
        log "WARN" "pip not available, skipping PyPI deployment"
        DEPLOY_STATUS["pypi"]="skipped"
        return
    fi
    
    local python_dir="$BUILD_DIR/python"
    if [[ ! -d "$python_dir" ]]; then
        log "ERROR" "Python package not found at $python_dir"
        DEPLOY_STATUS["pypi"]="failed"
        return
    fi
    
    cd "$python_dir"
    
    # Check if twine is available
    if ! command -v twine >/dev/null 2>&1; then
        log "WARN" "twine not found, installing..."
        pip install twine
    fi
    
    # Build distribution
    if python3 setup.py sdist bdist_wheel; then
        # Upload to PyPI
        if twine upload dist/*; then
            log "SUCCESS" "PyPI deployment successful"
            DEPLOY_STATUS["pypi"]="success"
            echo -e "${GREEN}✅ PyPI deployment successful${NC}"
        else
            log "ERROR" "PyPI deployment failed"
            DEPLOY_STATUS["pypi"]="failed"
            echo -e "${RED}❌ PyPI deployment failed${NC}"
        fi
    else
        log "ERROR" "Python package build failed"
        DEPLOY_STATUS["pypi"]="failed"
        echo -e "${RED}❌ Python package build failed${NC}"
    fi
}

# Function to deploy to Cargo
deploy_cargo() {
    echo -e "${BLUE}🦀 Deploying to Cargo...${NC}"
    
    if ! command -v cargo >/dev/null 2>&1; then
        log "WARN" "cargo not available, skipping Cargo deployment"
        DEPLOY_STATUS["cargo"]="skipped"
        return
    fi
    
    local rust_dir="$BUILD_DIR/rust"
    if [[ ! -d "$rust_dir" ]]; then
        log "ERROR" "Rust package not found at $rust_dir"
        DEPLOY_STATUS["cargo"]="failed"
        return
    fi
    
    cd "$rust_dir"
    
    # Check if logged in to Cargo
    if ! cargo whoami >/dev/null 2>&1; then
        log "WARN" "Not logged in to Cargo, attempting login..."
        cargo login
    fi
    
    # Publish package
    if cargo publish; then
        log "SUCCESS" "Cargo deployment successful"
        DEPLOY_STATUS["cargo"]="success"
        echo -e "${GREEN}✅ Cargo deployment successful${NC}"
    else
        log "ERROR" "Cargo deployment failed"
        DEPLOY_STATUS["cargo"]="failed"
        echo -e "${RED}❌ Cargo deployment failed${NC}"
    fi
}

# Function to deploy to Packagist
deploy_packagist() {
    echo -e "${BLUE}🐘 Deploying to Packagist...${NC}"
    
    if ! command -v composer >/dev/null 2>&1; then
        log "WARN" "composer not available, skipping Packagist deployment"
        DEPLOY_STATUS["packagist"]="skipped"
        return
    fi
    
    local composer_dir="$BUILD_DIR/composer"
    if [[ ! -d "$composer_dir" ]]; then
        log "ERROR" "Composer package not found at $composer_dir"
        DEPLOY_STATUS["packagist"]="failed"
        return
    fi
    
    cd "$composer_dir"
    
    # Create git repository for Packagist
    if [[ ! -d ".git" ]]; then
        git init -b main
        git add .
        git commit -m "Release v$VERSION"
    fi
    
    # Add remote repository
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin https://github.com/cyber-boost/pak.git
    fi
    
    # Tag the release
    git tag -a "v$VERSION" -m "Release v$VERSION"
    
    # Push to GitHub
    if git push origin main --tags; then
        log "SUCCESS" "Packagist deployment successful (via GitHub)"
        DEPLOY_STATUS["packagist"]="success"
        echo -e "${GREEN}✅ Packagist deployment successful${NC}"
    else
        log "ERROR" "Packagist deployment failed"
        DEPLOY_STATUS["packagist"]="failed"
        echo -e "${RED}❌ Packagist deployment failed${NC}"
    fi
}

# Function to deploy to RubyGems
deploy_rubygems() {
    echo -e "${BLUE}💎 Deploying to RubyGems...${NC}"
    
    if ! command -v gem >/dev/null 2>&1; then
        log "WARN" "gem not available, skipping RubyGems deployment"
        DEPLOY_STATUS["rubygems"]="skipped"
        return
    fi
    
    local rubygems_dir="$BUILD_DIR/rubygems"
    if [[ ! -d "$rubygems_dir" ]]; then
        log "ERROR" "RubyGems package not found at $rubygems_dir"
        DEPLOY_STATUS["rubygems"]="failed"
        return
    fi
    
    cd "$rubygems_dir"
    
    # Build the gem
    if gem build pak-sh.gemspec; then
        # Push to RubyGems
        if gem push pak-sh-*.gem; then
            log "SUCCESS" "RubyGems deployment successful"
            DEPLOY_STATUS["rubygems"]="success"
            echo -e "${GREEN}✅ RubyGems deployment successful${NC}"
        else
            log "ERROR" "RubyGems deployment failed"
            DEPLOY_STATUS["rubygems"]="failed"
            echo -e "${RED}❌ RubyGems deployment failed${NC}"
        fi
    else
        log "ERROR" "RubyGems package build failed"
        DEPLOY_STATUS["rubygems"]="failed"
        echo -e "${RED}❌ RubyGems package build failed${NC}"
    fi
}

# Function to deploy to Go modules
deploy_go() {
    echo -e "${BLUE}🐹 Deploying to Go modules...${NC}"
    
    if ! command -v go >/dev/null 2>&1; then
        log "WARN" "go not available, skipping Go deployment"
        DEPLOY_STATUS["go"]="skipped"
        return
    fi
    
    local go_dir="$BUILD_DIR/go"
    if [[ ! -d "$go_dir" ]]; then
        log "ERROR" "Go package not found at $go_dir"
        DEPLOY_STATUS["go"]="failed"
        return
    fi
    
    cd "$go_dir"
    
    # Create git repository for Go modules
    if [[ ! -d ".git" ]]; then
        git init -b main
        git add .
        git commit -m "Release v$VERSION"
    fi
    
    # Add remote repository
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin https://github.com/cyber-boost/pak.git
    fi
    
    # Tag the release
    git tag -a "v$VERSION" -m "Release v$VERSION"
    
    # Push to GitHub (handle branch conflicts)
    if git push origin main --tags --force; then
        log "SUCCESS" "Go modules deployment successful (via GitHub)"
        DEPLOY_STATUS["go"]="success"
        echo -e "${GREEN}✅ Go modules deployment successful${NC}"
    else
        log "ERROR" "Go modules deployment failed"
        DEPLOY_STATUS["go"]="failed"
        echo -e "${RED}❌ Go modules deployment failed${NC}"
    fi
}

# Function to deploy to Homebrew
deploy_homebrew() {
    echo -e "${BLUE}🍺 Deploying to Homebrew...${NC}"
    
    local homebrew_dir="$BUILD_DIR/homebrew"
    if [[ ! -d "$homebrew_dir" ]]; then
        log "ERROR" "Homebrew formula not found at $homebrew_dir"
        DEPLOY_STATUS["homebrew"]="failed"
        return
    fi
    
    # Homebrew deployment requires manual PR to homebrew-core
    log "INFO" "Homebrew deployment requires manual PR to homebrew-core"
    echo -e "${YELLOW}⚠️  Homebrew deployment requires manual PR to homebrew-core${NC}"
    echo -e "${CYAN}📋 Steps:${NC}"
    echo -e "  1. Fork homebrew-core repository"
    echo -e "  2. Add formula to Formula/pak-sh.rb"
    echo -e "  3. Submit pull request"
    echo -e "  4. Wait for review and merge"
    
    DEPLOY_STATUS["homebrew"]="manual"
}

# Function to deploy to Chocolatey
deploy_chocolatey() {
    echo -e "${BLUE}🍫 Deploying to Chocolatey...${NC}"
    
    if ! command -v choco >/dev/null 2>&1; then
        log "WARN" "choco not available, skipping Chocolatey deployment"
        DEPLOY_STATUS["chocolatey"]="skipped"
        return
    fi
    
    local chocolatey_dir="$BUILD_DIR/chocolatey"
    if [[ ! -d "$chocolatey_dir" ]]; then
        log "ERROR" "Chocolatey package not found at $chocolatey_dir"
        DEPLOY_STATUS["chocolatey"]="failed"
        return
    fi
    
    cd "$chocolatey_dir"
    
    # Create nupkg file
    if choco pack; then
        # Push to Chocolatey
        if choco push pak-sh.$VERSION.nupkg; then
            log "SUCCESS" "Chocolatey deployment successful"
            DEPLOY_STATUS["chocolatey"]="success"
            echo -e "${GREEN}✅ Chocolatey deployment successful${NC}"
        else
            log "ERROR" "Chocolatey deployment failed"
            DEPLOY_STATUS["chocolatey"]="failed"
            echo -e "${RED}❌ Chocolatey deployment failed${NC}"
        fi
    else
        log "ERROR" "Chocolatey package creation failed"
        DEPLOY_STATUS["chocolatey"]="failed"
        echo -e "${RED}❌ Chocolatey package creation failed${NC}"
    fi
}

# Function to deploy to Scoop
deploy_scoop() {
    echo -e "${BLUE}🥄 Deploying to Scoop...${NC}"
    
    local scoop_dir="$BUILD_DIR/scoop"
    if [[ ! -d "$scoop_dir" ]]; then
        log "ERROR" "Scoop manifest not found at $scoop_dir"
        DEPLOY_STATUS["scoop"]="failed"
        return
    fi
    
    # Scoop deployment requires manual PR to scoop bucket
    log "INFO" "Scoop deployment requires manual PR to scoop bucket"
    echo -e "${YELLOW}⚠️  Scoop deployment requires manual PR to scoop bucket${NC}"
    echo -e "${CYAN}📋 Steps:${NC}"
    echo -e "  1. Fork main scoop bucket"
    echo -e "  2. Add manifest to bucket/pak-sh.json"
    echo -e "  3. Submit pull request"
    echo -e "  4. Wait for review and merge"
    
    DEPLOY_STATUS["scoop"]="manual"
}

# Function to generate deployment report
generate_report() {
    echo -e "${BLUE}📊 Generating deployment report...${NC}"
    
    local report_file="$SCRIPT_DIR/deploy-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# PAK.sh Wrapper Deployment Report

**Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")  
**Version:** $VERSION  
**Package:** $PACKAGE_NAME  

## Deployment Summary

| Platform | Status | Notes |
|----------|--------|-------|
EOF
    
    for platform in npm pypi cargo packagist go homebrew chocolatey scoop; do
        local status="${DEPLOY_STATUS[$platform]:-unknown}"
        local status_emoji=""
        local notes=""
        
        case "$status" in
            "success")
                status_emoji="✅"
                notes="Deployed successfully"
                ;;
            "failed")
                status_emoji="❌"
                notes="Deployment failed - check logs"
                ;;
            "skipped")
                status_emoji="⏭️"
                notes="Skipped - tool not available"
                ;;
            "manual")
                status_emoji="📝"
                notes="Requires manual PR"
                ;;
            *)
                status_emoji="❓"
                notes="Unknown status"
                ;;
        esac
        
        echo "| $platform | $status_emoji $status | $notes |" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Installation Commands

After successful deployment, users can install via:

\`\`\`bash
# npm
npm install -g pak-sh

# pip
pip install pak-sh

# cargo
cargo install pak-sh

# composer
composer global require pak/pak-sh

# go
go install github.com/cyber-boost/pak@latest

# rubygems
gem install pak-sh

# homebrew (after PR merge)
brew install pak-sh

# chocolatey
choco install pak-sh

# scoop (after PR merge)
scoop install pak-sh
\`\`\`

## Next Steps

1. **Monitor deployments** - Check package manager dashboards
2. **Update documentation** - Update installation instructions
3. **Test installations** - Verify packages work correctly
4. **Announce release** - Notify users of new version

## Logs

Full deployment logs available at: \`$DEPLOY_LOG\`
EOF
    
    echo -e "${GREEN}✅ Deployment report generated: $report_file${NC}"
}

# Function to show deployment summary
show_summary() {
    echo
    echo -e "${BLUE}📋 Deployment Summary:${NC}"
    echo -e "${BLUE}=====================${NC}"
    
    local success_count=0
    local failed_count=0
    local skipped_count=0
    local manual_count=0
    
    for platform in npm pypi cargo packagist go homebrew chocolatey scoop; do
        local status="${DEPLOY_STATUS[$platform]:-unknown}"
        local status_emoji=""
        
        case "$status" in
            "success")
                status_emoji="✅"
                ((success_count++))
                ;;
            "failed")
                status_emoji="❌"
                ((failed_count++))
                ;;
            "skipped")
                status_emoji="⏭️"
                ((skipped_count++))
                ;;
            "manual")
                status_emoji="📝"
                ((manual_count++))
                ;;
            *)
                status_emoji="❓"
                ;;
        esac
        
        echo -e "  $status_emoji $platform: $status"
    done
    
    echo
    echo -e "${GREEN}✅ Successful: $success_count${NC}"
    echo -e "${RED}❌ Failed: $failed_count${NC}"
    echo -e "${YELLOW}⏭️ Skipped: $skipped_count${NC}"
    echo -e "${CYAN}📝 Manual: $manual_count${NC}"
    
    if [[ $failed_count -gt 0 ]]; then
        echo -e "${RED}⚠️  Some deployments failed. Check logs for details.${NC}"
        exit 1
    fi
}

# Function to parse command line arguments
parse_args() {
    SKIP_NPM=false
    SKIP_PYPI=false
    SKIP_CARGO=false
    SKIP_PACKAGIST=false
    SKIP_GO=false
    SKIP_RUBYGEMS=false
    SKIP_HOMEBREW=false
    SKIP_CHOCOLATEY=false
    SKIP_SCOOP=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-npm)
                SKIP_NPM=true
                shift
                ;;
            --skip-pypi)
                SKIP_PYPI=true
                shift
                ;;
            --skip-cargo)
                SKIP_CARGO=true
                shift
                ;;
            --skip-packagist)
                SKIP_PACKAGIST=true
                shift
                ;;
            --skip-go)
                SKIP_GO=true
                shift
                ;;
            --skip-rubygems)
                SKIP_RUBYGEMS=true
                shift
                ;;
            --skip-homebrew)
                SKIP_HOMEBREW=true
                shift
                ;;
            --skip-chocolatey)
                SKIP_CHOCOLATEY=true
                shift
                ;;
            --skip-scoop)
                SKIP_SCOOP=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --skip-npm         Skip npm deployment"
                echo "  --skip-pypi        Skip PyPI deployment"
                echo "  --skip-cargo       Skip Cargo deployment"
                echo "  --skip-packagist   Skip Packagist deployment"
                echo "  --skip-go          Skip Go modules deployment"
                echo "  --skip-rubygems    Skip RubyGems deployment"
                echo "  --skip-homebrew    Skip Homebrew deployment"
                echo "  --skip-chocolatey  Skip Chocolatey deployment"
                echo "  --skip-scoop       Skip Scoop deployment"
                echo "  --help, -h         Show this help message"
                echo
                echo "Examples:"
                echo "  $0                    # Deploy to all platforms"
                echo "  $0 --skip-npm --skip-cargo  # Skip npm and cargo"
                echo "  $0 --skip-pypi        # Skip only PyPI"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main deployment process
main() {
    echo -e "${BLUE}🚀 PAK.sh Wrapper Deployment Script${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo
    
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize log file
    echo "PAK.sh Wrapper Deployment Log - $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$DEPLOY_LOG"
    
    # Check prerequisites
    check_prerequisites
    
    # Build packages
    build_packages
    
    # Deploy to all platforms
    echo -e "${BLUE}🚀 Starting deployments...${NC}"
    
    if [[ "$SKIP_NPM" == "false" ]]; then
        deploy_npm
    else
        echo -e "${YELLOW}⏭️ Skipping npm deployment${NC}"
        DEPLOY_STATUS["npm"]="skipped"
    fi
    
    if [[ "$SKIP_PYPI" == "false" ]]; then
        deploy_pypi
    else
        echo -e "${YELLOW}⏭️ Skipping PyPI deployment${NC}"
        DEPLOY_STATUS["pypi"]="skipped"
    fi
    
    if [[ "$SKIP_CARGO" == "false" ]]; then
        deploy_cargo
    else
        echo -e "${YELLOW}⏭️ Skipping Cargo deployment${NC}"
        DEPLOY_STATUS["cargo"]="skipped"
    fi
    
    if [[ "$SKIP_PACKAGIST" == "false" ]]; then
        deploy_packagist
    else
        echo -e "${YELLOW}⏭️ Skipping Packagist deployment${NC}"
        DEPLOY_STATUS["packagist"]="skipped"
    fi
    
    if [[ "$SKIP_GO" == "false" ]]; then
        deploy_go
    else
        echo -e "${YELLOW}⏭️ Skipping Go modules deployment${NC}"
        DEPLOY_STATUS["go"]="skipped"
    fi
    
    if [[ "$SKIP_RUBYGEMS" == "false" ]]; then
        deploy_rubygems
    else
        echo -e "${YELLOW}⏭️ Skipping RubyGems deployment${NC}"
        DEPLOY_STATUS["rubygems"]="skipped"
    fi
    
    if [[ "$SKIP_HOMEBREW" == "false" ]]; then
        deploy_homebrew
    else
        echo -e "${YELLOW}⏭️ Skipping Homebrew deployment${NC}"
        DEPLOY_STATUS["homebrew"]="skipped"
    fi
    
    if [[ "$SKIP_CHOCOLATEY" == "false" ]]; then
        deploy_chocolatey
    else
        echo -e "${YELLOW}⏭️ Skipping Chocolatey deployment${NC}"
        DEPLOY_STATUS["chocolatey"]="skipped"
    fi
    
    if [[ "$SKIP_SCOOP" == "false" ]]; then
        deploy_scoop
    else
        echo -e "${YELLOW}⏭️ Skipping Scoop deployment${NC}"
        DEPLOY_STATUS["scoop"]="skipped"
    fi
    
    # Generate report and show summary
    generate_report
    show_summary
    
    echo
    echo -e "${GREEN}🎉 Deployment process completed!${NC}"
    echo -e "${CYAN}📁 Logs: $DEPLOY_LOG${NC}"
}

# Run main function
main "$@" 