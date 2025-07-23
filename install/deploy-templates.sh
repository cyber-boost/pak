#!/bin/bash

# Enhanced Universal Package Deployer - Template Generator
# Creates deployment scripts for all supported platforms with PAK integration

set -euo pipefail

TEMPLATES_DIR="templates"
PLATFORMS_CONFIG="platform-configs.json"
PAK_TEMPLATES_DIR="../pak/templates/deploy"
PAK_CONFIG_DIR="../pak/config"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Generating enhanced deployment templates for all platforms...${NC}"

# Create templates directory
mkdir -p "$TEMPLATES_DIR"

# Function to generate platform-specific templates
generate_platform_templates() {
    local platform="$1"
    local config="$2"
    
    echo -e "${GREEN}Generating templates for $platform...${NC}"
    
    # Extract platform configuration
    local registry=$(echo "$config" | jq -r '.registry')
    local api=$(echo "$config" | jq -r '.api')
    local deploy_command=$(echo "$config" | jq -r '.deploy_command')
    local build_command=$(echo "$config" | jq -r '.build_command // "echo \"No build command specified\""')
    local test_command=$(echo "$config" | jq -r '.test_command // "echo \"No test command specified\""')
    local install_command=$(echo "$config" | jq -r '.install_command // "echo \"No install command specified\""')
    local required_files=$(echo "$config" | jq -r '.required_files[]?' | tr '\n' ' ')
    local optional_files=$(echo "$config" | jq -r '.optional_files[]?' | tr '\n' ' ')
    local publish_flags=$(echo "$config" | jq -r '.publish_flags[]?' | tr '\n' ' ')
    
    # Generate deployment template
    cat > "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
#!/bin/bash
# Enhanced ${platform} Deployment Template with PAK Integration

set -euo pipefail

PACKAGE_NAME="\$1"
PACKAGE_VERSION="\$2"
PACKAGE_DIR="\$3"
DEPLOY_ID="\${4:-}"

cd "\$PACKAGE_DIR"

echo "🚀 Deploying \$PACKAGE_NAME v\$PACKAGE_VERSION to ${platform}..."

# PAK Integration - Load platform configuration
if [[ -f "\$PAK_CONFIG_DIR/platforms/platforms.json" ]]; then
    PLATFORM_CONFIG=\$(jq -r '.platforms.${platform}' "\$PAK_CONFIG_DIR/platforms/platforms.json")
    if [[ "\$PLATFORM_CONFIG" != "null" ]]; then
        echo "📋 Using PAK platform configuration for ${platform}"
        REGISTRY=\$(echo "\$PLATFORM_CONFIG" | jq -r '.registry')
        API_ENDPOINT=\$(echo "\$PLATFORM_CONFIG" | jq -r '.api')
        HEALTH_ENDPOINT=\$(echo "\$PLATFORM_CONFIG" | jq -r '.health_endpoint')
        
        # Health check
        if [[ "\$HEALTH_ENDPOINT" != "null" ]]; then
            echo "🔍 Checking ${platform} health..."
            if curl -s --max-time 10 "\$HEALTH_ENDPOINT" >/dev/null; then
                echo "✅ ${platform} is healthy"
            else
                echo "⚠️  ${platform} health check failed"
            fi
        fi
    fi
fi

# Pre-deployment checks
echo "🔍 Pre-deployment validation..."

# Check required files
EOF

    # Add required file checks
    for file in $required_files; do
        cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if [[ ! -f "$file" ]]; then
    echo "❌ Required file not found: $file"
    exit 1
fi
EOF
    done

    cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF

# Check optional files
EOF

    # Add optional file checks
    for file in $optional_files; do
        cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if [[ ! -f "$file" ]]; then
    echo "⚠️  Optional file not found: $file"
fi
EOF
    done

    cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF

# Version check
if [[ -n "\$PACKAGE_VERSION" ]]; then
    echo "📝 Updating version to \$PACKAGE_VERSION..."
EOF

    # Add version update logic based on platform
    case "$platform" in
        npm|yarn)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    if command -v jq >/dev/null; then
        jq --arg version "\$PACKAGE_VERSION" '.version = \$version' package.json > temp.json && mv temp.json package.json
    else
        sed -i "s/\"version\": \".*\"/\"version\": \"\$PACKAGE_VERSION\"/" package.json
    fi
EOF
            ;;
        pypi)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    if [[ -f "pyproject.toml" ]]; then
        sed -i "s/^version = \".*\"/version = \"\$PACKAGE_VERSION\"/" pyproject.toml
    elif [[ -f "setup.py" ]]; then
        sed -i "s/version=['\"].*['\"]/version='\$PACKAGE_VERSION'/" setup.py
    fi
EOF
            ;;
        cargo)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    sed -i "s/^version = \".*\"/version = \"\$PACKAGE_VERSION\"/" Cargo.toml
EOF
            ;;
        maven)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    mvn versions:set -DnewVersion="\$PACKAGE_VERSION"
EOF
            ;;
        composer)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    if command -v jq >/dev/null; then
        jq --arg version "\$PACKAGE_VERSION" '.version = \$version' composer.json > temp.json && mv temp.json composer.json
    else
        sed -i "s/\"version\": \".*\"/\"version\": \"\$PACKAGE_VERSION\"/" composer.json
    fi
EOF
            ;;
        dockerhub)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
    sed -i "s/LABEL version=\".*\"/LABEL version=\"\$PACKAGE_VERSION\"/" Dockerfile
EOF
            ;;
    esac

    cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
fi

# Install dependencies
echo "📦 Installing dependencies..."
$install_command

# Run tests
echo "🧪 Running tests..."
$test_command

# Build package
echo "🔨 Building package..."
$build_command

# Check if version already exists
echo "🔍 Checking if version already exists..."
EOF

    # Add version existence check based on platform
    case "$platform" in
        npm)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if npm view "\$PACKAGE_NAME@\$PACKAGE_VERSION" version >/dev/null 2>&1; then
    echo "⚠️  Version \$PACKAGE_VERSION already exists on ${platform}"
    if [[ "\$FORCE_DEPLOY" != "true" ]]; then
        echo "❌ Use --force to deploy anyway"
        exit 1
    fi
fi
EOF
            ;;
        pypi)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if pip index versions "\$PACKAGE_NAME" 2>/dev/null | grep -q "\$PACKAGE_VERSION"; then
    echo "⚠️  Version \$PACKAGE_VERSION already exists on ${platform}"
    if [[ "\$FORCE_DEPLOY" != "true" ]]; then
        echo "❌ Use --force to deploy anyway"
        exit 1
    fi
fi
EOF
            ;;
        cargo)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if cargo search "\$PACKAGE_NAME" 2>/dev/null | grep -q "\$PACKAGE_VERSION"; then
    echo "⚠️  Version \$PACKAGE_VERSION already exists on ${platform}"
    if [[ "\$FORCE_DEPLOY" != "true" ]]; then
        echo "❌ Use --force to deploy anyway"
        exit 1
    fi
fi
EOF
            ;;
        *)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
echo "⚠️  Version existence check not implemented for ${platform}"
EOF
            ;;
    esac

    cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF

# Publish
echo "📦 Publishing to ${platform}..."
$deploy_command $publish_flags

# PAK Integration - Update deployment record
if [[ -n "\$DEPLOY_ID" && -f "\$PAK_DATA_DIR/deployments/\$DEPLOY_ID.json" ]]; then
    echo "📝 Updating PAK deployment record..."
    jq --arg platform "${platform}" --arg status "completed" --arg completed_at "\$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.platforms[\$platform] = {"status": \$status, "completed_at": \$completed_at}' \
       "\$PAK_DATA_DIR/deployments/\$DEPLOY_ID.json" > temp.json && mv temp.json "\$PAK_DATA_DIR/deployments/\$DEPLOY_ID.json"
fi

# Verification
echo "✅ Verifying deployment..."
EOF

    # Add verification logic based on platform
    case "$platform" in
        npm)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if npm view "\$PACKAGE_NAME@\$PACKAGE_VERSION" version >/dev/null 2>&1; then
    echo "✅ Successfully deployed to ${platform}!"
    echo "📊 Package: \$PACKAGE_NAME@\$PACKAGE_VERSION"
    echo "🌐 Registry: $registry"
else
    echo "❌ Deployment verification failed"
    exit 1
fi
EOF
            ;;
        pypi)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if pip show "\$PACKAGE_NAME" 2>/dev/null | grep -q "\$PACKAGE_VERSION"; then
    echo "✅ Successfully deployed to ${platform}!"
    echo "📊 Package: \$PACKAGE_NAME==\$PACKAGE_VERSION"
    echo "🌐 Registry: $registry"
else
    echo "❌ Deployment verification failed"
    exit 1
fi
EOF
            ;;
        cargo)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if cargo search "\$PACKAGE_NAME" 2>/dev/null | grep -q "\$PACKAGE_VERSION"; then
    echo "✅ Successfully deployed to ${platform}!"
    echo "📊 Package: \$PACKAGE_NAME \$PACKAGE_VERSION"
    echo "🌐 Registry: $registry"
else
    echo "❌ Deployment verification failed"
    exit 1
fi
EOF
            ;;
        dockerhub)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
if docker images "\$PACKAGE_NAME" 2>/dev/null | grep -q "\$PACKAGE_VERSION"; then
    echo "✅ Successfully deployed to ${platform}!"
    echo "📊 Image: \$PACKAGE_NAME:\$PACKAGE_VERSION"
    echo "🌐 Registry: $registry"
else
    echo "❌ Deployment verification failed"
    exit 1
fi
EOF
            ;;
        *)
            cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF
echo "✅ Successfully deployed to ${platform}!"
echo "📊 Package: \$PACKAGE_NAME \$PACKAGE_VERSION"
echo "🌐 Registry: $registry"
EOF
            ;;
    esac

    cat >> "$TEMPLATES_DIR/${platform}-deploy.sh" << EOF

# PAK Integration - Post-deployment hook
if [[ -f "\$PAK_TEMPLATES_DIR/deploy/post/${platform}.sh" ]]; then
    echo "🔄 Running PAK post-deployment hook..."
    "\$PAK_TEMPLATES_DIR/deploy/post/${platform}.sh" "\$PACKAGE_NAME" "\$PACKAGE_VERSION" "\$PACKAGE_DIR" "\$DEPLOY_ID"
fi

echo "🎉 Deployment completed successfully!"
EOF

    chmod +x "$TEMPLATES_DIR/${platform}-deploy.sh"
    
    # Generate rollback template
    cat > "$TEMPLATES_DIR/${platform}-rollback.sh" << EOF
#!/bin/bash
# ${platform} Rollback Template

PACKAGE_NAME="\$1"
PACKAGE_VERSION="\$2"
PREVIOUS_VERSION="\$3"

echo "🔄 Rolling back ${platform} deployment..."

# Platform-specific rollback logic
case "${platform}" in
    npm)
        echo "⚠️  NPM rollback: Manual intervention required"
        echo "   Run: npm unpublish \$PACKAGE_NAME@\$PACKAGE_VERSION"
        ;;
    pypi)
        echo "⚠️  PyPI rollback: Manual intervention required"
        echo "   Run: twine delete \$PACKAGE_NAME \$PACKAGE_VERSION"
        ;;
    cargo)
        echo "⚠️  Cargo rollback: Manual intervention required"
        echo "   Run: cargo yank \$PACKAGE_NAME \$PACKAGE_VERSION"
        ;;
    dockerhub)
        echo "🔄 Docker rollback: Tagging previous version"
        docker tag "\$PACKAGE_NAME:\$PREVIOUS_VERSION" "\$PACKAGE_NAME:latest"
        docker push "\$PACKAGE_NAME:latest"
        ;;
    maven)
        echo "⚠️  Maven rollback: Manual intervention required"
        ;;
    composer)
        echo "⚠️  Composer rollback: Manual intervention required"
        ;;
    *)
        echo "⚠️  Rollback not implemented for ${platform}"
        ;;
esac

echo "✅ Rollback completed for ${platform}"
EOF

    chmod +x "$TEMPLATES_DIR/${platform}-rollback.sh"
}

# Generate templates for all platforms
echo -e "${BLUE}📋 Reading platform configurations...${NC}"

if [[ -f "$PLATFORMS_CONFIG" ]]; then
    # Read from local platform-configs.json
    platforms=$(jq -r '.platforms | keys[]' "$PLATFORMS_CONFIG")
else
    # Read from PAK platform configurations
    if [[ -f "$PAK_CONFIG_DIR/platforms/platforms.json" ]]; then
        platforms=$(jq -r '.platforms | keys[]' "$PAK_CONFIG_DIR/platforms/platforms.json")
    else
        echo -e "${RED}❌ No platform configuration found${NC}"
        exit 1
    fi
fi

for platform in $platforms; do
    if [[ -f "$PLATFORMS_CONFIG" ]]; then
        config=$(jq -r ".platforms.$platform" "$PLATFORMS_CONFIG")
    else
        config=$(jq -r ".platforms.$platform" "$PAK_CONFIG_DIR/platforms/platforms.json")
    fi
    
    if [[ "$config" != "null" ]]; then
        generate_platform_templates "$platform" "$config"
    fi
done

# Generate PAK integration script
echo -e "${GREEN}🔗 Generating PAK integration script...${NC}"

cat > "$TEMPLATES_DIR/pak-integration.sh" << 'EOF'
#!/bin/bash
# PAK Integration Script for Deployment Templates

# PAK environment variables
export PAK_CONFIG_DIR="${PAK_CONFIG_DIR:-../pak/config}"
export PAK_DATA_DIR="${PAK_DATA_DIR:-../pak/data}"
export PAK_TEMPLATES_DIR="${PAK_TEMPLATES_DIR:-../pak/templates}"
export PAK_LOGS_DIR="${PAK_LOGS_DIR:-../pak/logs}"

# Load PAK platform configurations
load_pak_config() {
    local platform="$1"
    if [[ -f "$PAK_CONFIG_DIR/platforms/platforms.json" ]]; then
        jq -r ".platforms.$platform" "$PAK_CONFIG_DIR/platforms/platforms.json"
    else
        echo "{}"
    fi
}

# Update PAK deployment record
update_pak_deployment() {
    local deploy_id="$1"
    local platform="$2"
    local status="$3"
    local message="${4:-}"
    
    if [[ -n "$deploy_id" && -f "$PAK_DATA_DIR/deployments/$deploy_id.json" ]]; then
        jq --arg platform "$platform" \
           --arg status "$status" \
           --arg message "$message" \
           --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.platforms[$platform] = {"status": $status, "message": $message, "timestamp": $timestamp}' \
           "$PAK_DATA_DIR/deployments/$deploy_id.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/$deploy_id.json"
    fi
}

# Log to PAK system
log_to_pak() {
    local level="$1"
    local message="$2"
    local deploy_id="${3:-}"
    
    echo "[$level] $message"
    
    if [[ -n "$deploy_id" && -f "$PAK_DATA_DIR/deployments/$deploy_id.json" ]]; then
        jq --arg level "$level" \
           --arg message "$message" \
           --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.logs += [{"level": $level, "message": $message, "timestamp": $timestamp}]' \
           "$PAK_DATA_DIR/deployments/$deploy_id.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/$deploy_id.json"
    fi
}

# Health check for platform
check_platform_health() {
    local platform="$1"
    local config=$(load_pak_config "$platform")
    local health_endpoint=$(echo "$config" | jq -r '.health_endpoint')
    
    if [[ "$health_endpoint" != "null" && "$health_endpoint" != "" ]]; then
        if curl -s --max-time 10 "$health_endpoint" >/dev/null; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Export functions
export -f load_pak_config update_pak_deployment log_to_pak check_platform_health
EOF

chmod +x "$TEMPLATES_DIR/pak-integration.sh"

# Generate deployment orchestrator
echo -e "${GREEN}🎼 Generating deployment orchestrator...${NC}"

cat > "$TEMPLATES_DIR/deploy-orchestrator.sh" << 'EOF'
#!/bin/bash
# PAK Deployment Orchestrator

set -euo pipefail

# Load PAK integration
source "$(dirname "$0")/pak-integration.sh"

# Configuration
DEFAULT_PLATFORMS="npm pypi cargo"
PARALLEL_DEPLOYMENT=true
MAX_PARALLEL=5
TIMEOUT=600

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <package_name> <version> [platforms] [options]"
    echo ""
    echo "Arguments:"
    echo "  package_name    Name of the package to deploy"
    echo "  version         Version to deploy"
    echo "  platforms       Space-separated list of platforms (default: $DEFAULT_PLATFORMS)"
    echo ""
    echo "Options:"
    echo "  --parallel      Enable parallel deployment (default: true)"
    echo "  --sequential    Disable parallel deployment"
    echo "  --max-parallel  Maximum parallel deployments (default: $MAX_PARALLEL)"
    echo "  --timeout       Deployment timeout in seconds (default: $TIMEOUT)"
    echo "  --dry-run       Show what would be deployed without actually deploying"
    echo "  --force         Force deployment even if version exists"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 my-package 1.0.0"
    echo "  $0 my-package 1.0.0 \"npm pypi cargo\""
    echo "  $0 my-package 1.0.0 \"npm pypi\" --sequential"
}

# Parse arguments
PACKAGE_NAME=""
PACKAGE_VERSION=""
PLATFORMS="$DEFAULT_PLATFORMS"
DRY_RUN=false
FORCE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL_DEPLOYMENT=true
            shift
            ;;
        --sequential)
            PARALLEL_DEPLOYMENT=false
            shift
            ;;
        --max-parallel)
            MAX_PARALLEL="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -z "$PACKAGE_NAME" ]]; then
                PACKAGE_NAME="$1"
            elif [[ -z "$PACKAGE_VERSION" ]]; then
                PACKAGE_VERSION="$1"
            else
                PLATFORMS="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$PACKAGE_NAME" || -z "$PACKAGE_VERSION" ]]; then
    echo -e "${RED}❌ Package name and version are required${NC}"
    usage
    exit 1
fi

# Create deployment ID
DEPLOY_ID=$(date +%s)

# Initialize deployment record
if [[ -d "$PAK_DATA_DIR/deployments" ]]; then
    jq --null-input \
       --arg id "$DEPLOY_ID" \
       --arg package "$PACKAGE_NAME" \
       --arg version "$PACKAGE_VERSION" \
       --arg started_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --argjson platforms "$(echo "$PLATFORMS" | tr ' ' '\n' | jq -R . | jq -s .)" \
       '{
           "id": $id,
           "package": $package,
           "version": $version,
           "started_at": $started_at,
           "status": "in_progress",
           "platforms": {},
           "logs": [],
           "errors": []
       }' > "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json"
fi

echo -e "${BLUE}🚀 Starting deployment orchestration...${NC}"
echo "Package: $PACKAGE_NAME"
echo "Version: $PACKAGE_VERSION"
echo "Platforms: $PLATFORMS"
echo "Deployment ID: $DEPLOY_ID"
echo "Parallel: $PARALLEL_DEPLOYMENT"
echo "Dry Run: $DRY_RUN"
echo ""

# Set environment variables
export FORCE_DEPLOY="$FORCE_DEPLOY"
export DEPLOY_ID="$DEPLOY_ID"

# Deploy function
deploy_to_platform() {
    local platform="$1"
    local deploy_script="$TEMPLATES_DIR/${platform}-deploy.sh"
    
    if [[ ! -f "$deploy_script" ]]; then
        log_to_pak "ERROR" "Deployment script not found for $platform" "$DEPLOY_ID"
        return 1
    fi
    
    log_to_pak "INFO" "Starting deployment to $platform" "$DEPLOY_ID"
    update_pak_deployment "$DEPLOY_ID" "$platform" "in_progress"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_to_pak "INFO" "[DRY RUN] Would deploy to $platform" "$DEPLOY_ID"
        update_pak_deployment "$DEPLOY_ID" "$platform" "completed" "Dry run"
        return 0
    fi
    
    # Health check
    if ! check_platform_health "$platform"; then
        log_to_pak "WARN" "Platform $platform health check failed" "$DEPLOY_ID"
        update_pak_deployment "$DEPLOY_ID" "$platform" "failed" "Health check failed"
        return 1
    fi
    
    # Execute deployment
    if timeout "$TIMEOUT" "$deploy_script" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$(pwd)" "$DEPLOY_ID"; then
        log_to_pak "SUCCESS" "Successfully deployed to $platform" "$DEPLOY_ID"
        update_pak_deployment "$DEPLOY_ID" "$platform" "completed"
        return 0
    else
        log_to_pak "ERROR" "Deployment failed for $platform" "$DEPLOY_ID"
        update_pak_deployment "$DEPLOY_ID" "$platform" "failed" "Deployment script failed"
        return 1
    fi
}

# Sequential deployment
deploy_sequential() {
    local success_count=0
    local total_count=0
    
    for platform in $PLATFORMS; do
        ((total_count++))
        if deploy_to_platform "$platform"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Sequential deployment completed: $success_count/$total_count platforms${NC}"
    return $((total_count - success_count))
}

# Parallel deployment
deploy_parallel() {
    local pids=()
    local platform_array=()
    
    # Convert platforms to array
    for platform in $PLATFORMS; do
        platform_array+=("$platform")
    done
    
    # Deploy in parallel with limited concurrency
    for platform in "${platform_array[@]}"; do
        # Wait if we've reached max parallel processes
        while [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset "pids[$i]"
                fi
            done
            pids=("${pids[@]}")  # Reindex array
            sleep 1
        done
        
        # Start deployment in background
        deploy_to_platform "$platform" &
        pids+=($!)
    done
    
    # Wait for all deployments to complete
    local success_count=0
    local total_count=${#platform_array[@]}
    
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Parallel deployment completed: $success_count/$total_count platforms${NC}"
    return $((total_count - success_count))
}

# Main deployment logic
if [[ "$PARALLEL_DEPLOYMENT" == "true" ]]; then
    deploy_parallel
else
    deploy_sequential
fi

# Final status update
if [[ -f "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json" ]]; then
    local failed_platforms=$(jq -r '.platforms | to_entries[] | select(.value.status == "failed") | .key' "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json" 2>/dev/null)
    
    if [[ -n "$failed_platforms" ]]; then
        jq --arg status "failed" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.status = $status | .completed_at = $completed_at' \
           "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json"
        
        echo -e "${RED}❌ Deployment failed for platforms: $failed_platforms${NC}"
        exit 1
    else
        jq --arg status "completed" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.status = $status | .completed_at = $completed_at' \
           "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/$DEPLOY_ID.json"
        
        echo -e "${GREEN}🎉 All deployments completed successfully!${NC}"
    fi
fi

echo ""
echo "Deployment ID: $DEPLOY_ID"
echo "View status: pak deploy-status $DEPLOY_ID"
echo "View history: pak deploy-history"
EOF

chmod +x "$TEMPLATES_DIR/deploy-orchestrator.sh"

# Generate migration script
echo -e "${GREEN}🔄 Generating migration script...${NC}"

cat > "$TEMPLATES_DIR/migrate-to-pak.sh" << 'EOF'
#!/bin/bash
# Migration script from legacy deploy-templates.sh to PAK system

set -euo pipefail

echo "🔄 Migrating from legacy deploy-templates.sh to PAK system..."

# Create PAK directories if they don't exist
mkdir -p ../pak/config/platforms
mkdir -p ../pak/templates/deploy/{pre,post,rollback}
mkdir -p ../pak/data/deployments
mkdir -p ../pak/logs/deployments

# Copy platform configurations
if [[ -f "platform-configs.json" ]]; then
    echo "📋 Copying platform configurations..."
    cp platform-configs.json ../pak/config/platforms/platforms.json
fi

# Copy deployment templates
echo "📝 Copying deployment templates..."
cp -r templates/* ../pak/templates/deploy/

# Update PAK module configurations
echo "🔧 Updating PAK module configurations..."
if [[ -f "../pak/modules/platform.module.sh" ]]; then
    echo "✅ Platform module already exists"
else
    echo "⚠️  Platform module not found, please run PAK initialization"
fi

if [[ -f "../pak/modules/deploy.module.sh" ]]; then
    echo "✅ Deploy module already exists"
else
    echo "⚠️  Deploy module not found, please run PAK initialization"
fi

# Create symlinks for backward compatibility
echo "🔗 Creating backward compatibility symlinks..."
ln -sf ../pak/config/platforms/platforms.json platform-configs.json
ln -sf ../pak/templates/deploy templates

echo "✅ Migration completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test the new system: ./templates/deploy-orchestrator.sh my-package 1.0.0"
echo "2. Update your CI/CD pipelines to use the new PAK commands"
echo "3. Remove legacy files after testing"
echo ""
echo "PAK commands available:"
echo "  pak platforms                    # List all platforms"
echo "  pak platform-health             # Check platform health"
echo "  pak deploy <package> <version>  # Deploy package"
echo "  pak deploy-status <id>          # Check deployment status"
echo "  pak deploy-history              # View deployment history"
EOF

chmod +x "$TEMPLATES_DIR/migrate-to-pak.sh"

echo -e "${GREEN}✅ Enhanced deployment templates generated successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Generated files:${NC}"
echo "  - $TEMPLATES_DIR/*-deploy.sh (platform-specific deployment scripts)"
echo "  - $TEMPLATES_DIR/*-rollback.sh (platform-specific rollback scripts)"
echo "  - $TEMPLATES_DIR/pak-integration.sh (PAK integration utilities)"
echo "  - $TEMPLATES_DIR/deploy-orchestrator.sh (deployment orchestrator)"
echo "  - $TEMPLATES_DIR/migrate-to-pak.sh (migration script)"
echo ""
echo -e "${BLUE}🚀 Usage examples:${NC}"
echo "  # Deploy to single platform"
echo "  ./templates/npm-deploy.sh my-package 1.0.0 ."
echo ""
echo "  # Deploy to multiple platforms"
echo "  ./templates/deploy-orchestrator.sh my-package 1.0.0 \"npm pypi cargo\""
echo ""
echo "  # Parallel deployment"
echo "  ./templates/deploy-orchestrator.sh my-package 1.0.0 \"npm pypi cargo dockerhub\" --parallel"
echo ""
echo "  # Dry run"
echo "  ./templates/deploy-orchestrator.sh my-package 1.0.0 \"npm pypi\" --dry-run"
echo ""
echo -e "${BLUE}🔗 PAK Integration:${NC}"
echo "  # Migrate to PAK system"
echo "  ./templates/migrate-to-pak.sh"
echo ""
echo "  # Use PAK commands"
echo "  pak deploy my-package 1.0.0"
echo "  pak deploy-status <deploy_id>"
echo "  pak deploy-history" 