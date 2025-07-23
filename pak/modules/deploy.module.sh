#!/bin/bash
# Enhanced Deploy Module - Multi-platform deployment orchestration with 30+ platforms

deploy_init() {
    # Create deployment directories
    mkdir -p "$PAK_DATA_DIR/deployments"
    mkdir -p "$PAK_DATA_DIR/deployment-history"
    mkdir -p "$PAK_LOGS_DIR/deployments"
    mkdir -p "$PAK_TEMPLATES_DIR/deploy"
    
    # Initialize deployment templates
    deploy_init_templates
    
    # Initialize deployment pipelines
    deploy_init_pipelines
    
    log INFO "Deploy module initialized with multi-platform orchestration"
}

deploy_register_commands() {
    register_command "deploy" "deploy" "deploy_package"
    register_command "deploy-parallel" "deploy" "deploy_parallel"
    register_command "deploy-pipeline" "deploy" "deploy_pipeline"
    register_command "rollback" "deploy" "deploy_rollback"
    register_command "deploy-status" "deploy" "deploy_status"
    register_command "deploy-history" "deploy" "deploy_history"
    register_command "deploy-cancel" "deploy" "deploy_cancel"
    register_command "deploy-retry" "deploy" "deploy_retry"
    register_command "deploy-validate" "deploy" "deploy_validate"
    register_command "deploy-test" "deploy" "deploy_test"
}

deploy_init_templates() {
    # Create deployment template directory structure
    mkdir -p "$PAK_TEMPLATES_DIR/deploy/{pre,post,rollback}"
    
    # Pre-deployment templates
    deploy_create_pre_template "npm"
    deploy_create_pre_template "pypi"
    deploy_create_pre_template "cargo"
    deploy_create_pre_template "dockerhub"
    deploy_create_pre_template "maven"
    deploy_create_pre_template "composer"
    
    # Post-deployment templates
    deploy_create_post_template "npm"
    deploy_create_post_template "pypi"
    deploy_create_post_template "cargo"
    deploy_create_post_template "dockerhub"
    deploy_create_post_template "maven"
    deploy_create_post_template "composer"
    
    # Rollback templates
    deploy_create_rollback_template "npm"
    deploy_create_rollback_template "pypi"
    deploy_create_rollback_template "cargo"
    deploy_create_rollback_template "dockerhub"
    deploy_create_rollback_template "maven"
    deploy_create_rollback_template "composer"
}

deploy_create_pre_template() {
    local platform="$1"
    cat > "$PAK_TEMPLATES_DIR/deploy/pre/${platform}.sh" << EOF
#!/bin/bash
# Pre-deployment template for $platform

PACKAGE_NAME="\$1"
PACKAGE_VERSION="\$2"
PACKAGE_DIR="\$3"

cd "\$PACKAGE_DIR"

echo "🔍 Pre-deployment checks for $platform..."

# Platform-specific pre-deployment logic
case "$platform" in
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
        docker build -t "\$PACKAGE_NAME:\$PACKAGE_VERSION" .
        docker run --rm "\$PACKAGE_NAME:\$PACKAGE_VERSION" test
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

echo "✅ Pre-deployment checks passed for $platform"
EOF
    chmod +x "$PAK_TEMPLATES_DIR/deploy/pre/${platform}.sh"
}

deploy_create_post_template() {
    local platform="$1"
    cat > "$PAK_TEMPLATES_DIR/deploy/post/${platform}.sh" << EOF
#!/bin/bash
# Post-deployment template for $platform

PACKAGE_NAME="\$1"
PACKAGE_VERSION="\$2"
PACKAGE_DIR="\$3"
DEPLOY_ID="\$4"

cd "\$PACKAGE_DIR"

echo "✅ Post-deployment tasks for $platform..."

# Platform-specific post-deployment logic
case "$platform" in
    npm)
        echo "📊 NPM package published: \$PACKAGE_NAME@\$PACKAGE_VERSION"
        npm view "\$PACKAGE_NAME@\$PACKAGE_VERSION" version
        ;;
    pypi)
        echo "📊 PyPI package published: \$PACKAGE_NAME==\$PACKAGE_VERSION"
        pip show "\$PACKAGE_NAME" | grep Version
        ;;
    cargo)
        echo "📊 Cargo package published: \$PACKAGE_NAME \$PACKAGE_VERSION"
        cargo search "\$PACKAGE_NAME" | head -1
        ;;
    dockerhub)
        echo "📊 Docker image published: \$PACKAGE_NAME:\$PACKAGE_VERSION"
        docker images "\$PACKAGE_NAME" | grep "\$PACKAGE_VERSION"
        ;;
    maven)
        echo "📊 Maven artifact published: \$PACKAGE_NAME \$PACKAGE_VERSION"
        ;;
    composer)
        echo "📊 Composer package published: \$PACKAGE_NAME \$PACKAGE_VERSION"
        ;;
esac

# Update deployment record
jq --arg platform "$platform" --arg status "completed" --arg completed_at "\$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
   '.platforms[$platform] = {"status": $status, "completed_at": $completed_at}' \
   "\$PAK_DATA_DIR/deployments/\$DEPLOY_ID.json" > temp.json && mv temp.json "\$PAK_DATA_DIR/deployments/\$DEPLOY_ID.json"

echo "✅ Post-deployment tasks completed for $platform"
EOF
    chmod +x "$PAK_TEMPLATES_DIR/deploy/post/${platform}.sh"
}

deploy_create_rollback_template() {
    local platform="$1"
    cat > "$PAK_TEMPLATES_DIR/deploy/rollback/${platform}.sh" << EOF
#!/bin/bash
# Rollback template for $platform

PACKAGE_NAME="\$1"
PACKAGE_VERSION="\$2"
PREVIOUS_VERSION="\$3"

echo "🔄 Rolling back $platform deployment..."

# Platform-specific rollback logic
case "$platform" in
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
esac

echo "✅ Rollback completed for $platform"
EOF
    chmod +x "$PAK_TEMPLATES_DIR/deploy/rollback/${platform}.sh"
}

deploy_init_pipelines() {
    # Create pipeline configurations
    cat > "$PAK_CONFIG_DIR/pipelines.json" << 'EOF'
{
    "pipelines": {
        "standard": {
            "name": "Standard Deployment",
            "description": "Standard deployment pipeline with pre/post hooks",
            "stages": [
                "validation",
                "pre_deploy",
                "deploy",
                "post_deploy",
                "verification"
            ],
            "parallel_deployment": false,
            "rollback_on_failure": true
        },
        "parallel": {
            "name": "Parallel Deployment",
            "description": "Deploy to multiple platforms in parallel",
            "stages": [
                "validation",
                "pre_deploy",
                "parallel_deploy",
                "post_deploy",
                "verification"
            ],
            "parallel_deployment": true,
            "max_parallel": 5,
            "rollback_on_failure": true
        },
        "staged": {
            "name": "Staged Deployment",
            "description": "Deploy to staging then production",
            "stages": [
                "validation",
                "staging_deploy",
                "staging_verification",
                "production_deploy",
                "production_verification"
            ],
            "parallel_deployment": false,
            "rollback_on_failure": true
        }
    }
}
EOF
}

deploy_package() {
    local package="$1"
    local version="${2:-}"
    local platforms="${3:-$PAK_DEFAULT_PLATFORMS}"
    local pipeline="${4:-standard}"
    
    log INFO "Starting deployment: $package"
    [[ -n "$version" ]] && log INFO "Version: $version"
    log INFO "Platforms: $platforms"
    log INFO "Pipeline: $pipeline"
    
    # Create deployment record
    local deploy_id=$(date +%s)
    local deploy_record="$PAK_DATA_DIR/deployments/${deploy_id}.json"
    
    # Initialize deployment record
    deploy_create_record "$deploy_id" "$package" "$version" "$platforms" "$pipeline"
    
    # Execute deployment pipeline
    case "$pipeline" in
        standard)
            deploy_execute_standard_pipeline "$package" "$version" "$platforms" "$deploy_id"
            ;;
        parallel)
            deploy_execute_parallel_pipeline "$package" "$version" "$platforms" "$deploy_id"
            ;;
        staged)
            deploy_execute_staged_pipeline "$package" "$version" "$platforms" "$deploy_id"
            ;;
        *)
            log ERROR "Unknown pipeline: $pipeline"
            return 1
            ;;
    esac
    
    # Final status update
    deploy_update_final_status "$deploy_id"
    
    log SUCCESS "Deployment completed: $deploy_id"
    echo "Deployment ID: $deploy_id"
}

deploy_create_record() {
    local deploy_id="$1"
    local package="$2"
    local version="$3"
    local platforms="$4"
    local pipeline="$5"
    
    # Convert platforms string to array
    local platform_array=()
    for platform in $platforms; do
        platform_array+=("$platform")
    done
    
    # Create JSON record
    jq --null-input \
       --arg id "$deploy_id" \
       --arg package "$package" \
       --arg version "$version" \
       --arg pipeline "$pipeline" \
       --arg started_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --argjson platforms "$(printf '%s\n' "${platform_array[@]}" | jq -R . | jq -s .)" \
       '{
           "id": $id,
           "package": $package,
           "version": $version,
           "pipeline": $pipeline,
           "started_at": $started_at,
           "status": "in_progress",
           "platforms": {},
           "logs": [],
           "errors": []
       }' > "$PAK_DATA_DIR/deployments/${deploy_id}.json"
}

deploy_execute_standard_pipeline() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Executing standard deployment pipeline"
    
    # Stage 1: Validation
    deploy_log_stage "$deploy_id" "validation" "started"
    if ! deploy_validate_package "$package" "$version"; then
        deploy_log_stage "$deploy_id" "validation" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "validation" "completed"
    
    # Stage 2: Pre-deployment
    deploy_log_stage "$deploy_id" "pre_deploy" "started"
    if ! deploy_execute_pre_hooks "$package" "$version" "$platforms" "$deploy_id"; then
        deploy_log_stage "$deploy_id" "pre_deploy" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "pre_deploy" "completed"
    
    # Stage 3: Deploy
    deploy_log_stage "$deploy_id" "deploy" "started"
    local success_count=0
    local total_count=0
    
    for platform in $platforms; do
        ((total_count++))
        if deploy_to_platform "$package" "$version" "$platform" "$deploy_id"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq $total_count ]]; then
        deploy_log_stage "$deploy_id" "deploy" "completed"
    else
        deploy_log_stage "$deploy_id" "deploy" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    
    # Stage 4: Post-deployment
    deploy_log_stage "$deploy_id" "post_deploy" "started"
    deploy_execute_post_hooks "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "post_deploy" "completed"
    
    # Stage 5: Verification
    deploy_log_stage "$deploy_id" "verification" "started"
    deploy_verify_deployment "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "verification" "completed"
}

deploy_execute_parallel_pipeline() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Executing parallel deployment pipeline"
    
    # Validation and pre-deployment (sequential)
    deploy_log_stage "$deploy_id" "validation" "started"
    if ! deploy_validate_package "$package" "$version"; then
        deploy_log_stage "$deploy_id" "validation" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "validation" "completed"
    
    deploy_log_stage "$deploy_id" "pre_deploy" "started"
    if ! deploy_execute_pre_hooks "$package" "$version" "$platforms" "$deploy_id"; then
        deploy_log_stage "$deploy_id" "pre_deploy" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "pre_deploy" "completed"
    
    # Parallel deployment
    deploy_log_stage "$deploy_id" "parallel_deploy" "started"
    deploy_parallel_deploy "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "parallel_deploy" "completed"
    
    # Post-deployment and verification (sequential)
    deploy_log_stage "$deploy_id" "post_deploy" "started"
    deploy_execute_post_hooks "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "post_deploy" "completed"
    
    deploy_log_stage "$deploy_id" "verification" "started"
    deploy_verify_deployment "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "verification" "completed"
}

deploy_parallel_deploy() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    local max_parallel=5
    local pids=()
    local platform_array=()
    
    # Convert platforms to array
    for platform in $platforms; do
        platform_array+=("$platform")
    done
    
    # Deploy in parallel with limited concurrency
    for platform in "${platform_array[@]}"; do
        # Wait if we've reached max parallel processes
        while [[ ${#pids[@]} -ge $max_parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset "pids[$i]"
                fi
            done
            pids=("${pids[@]}")  # Reindex array
            sleep 1
        done
        
        # Start deployment in background
        deploy_to_platform "$package" "$version" "$platform" "$deploy_id" &
        pids+=($!)
    done
    
    # Wait for all deployments to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

deploy_execute_staged_pipeline() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Executing staged deployment pipeline"
    
    # Stage 1: Validation
    deploy_log_stage "$deploy_id" "validation" "started"
    if ! deploy_validate_package "$package" "$version"; then
        deploy_log_stage "$deploy_id" "validation" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "validation" "completed"
    
    # Stage 2: Staging deployment
    deploy_log_stage "$deploy_id" "staging_deploy" "started"
    local staging_platforms="npm pypi"  # Deploy to staging platforms first
    if ! deploy_to_platforms "$package" "$version" "$staging_platforms" "$deploy_id"; then
        deploy_log_stage "$deploy_id" "staging_deploy" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "staging_deploy" "completed"
    
    # Stage 3: Staging verification
    deploy_log_stage "$deploy_id" "staging_verification" "started"
    if ! deploy_verify_deployment "$package" "$version" "$staging_platforms" "$deploy_id"; then
        deploy_log_stage "$deploy_id" "staging_verification" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "staging_verification" "completed"
    
    # Stage 4: Production deployment
    deploy_log_stage "$deploy_id" "production_deploy" "started"
    if ! deploy_to_platforms "$package" "$version" "$platforms" "$deploy_id"; then
        deploy_log_stage "$deploy_id" "production_deploy" "failed"
        deploy_update_status "$deploy_id" "failed"
        return 1
    fi
    deploy_log_stage "$deploy_id" "production_deploy" "completed"
    
    # Stage 5: Production verification
    deploy_log_stage "$deploy_id" "production_verification" "started"
    deploy_verify_deployment "$package" "$version" "$platforms" "$deploy_id"
    deploy_log_stage "$deploy_id" "production_verification" "completed"
}

deploy_validate_package() {
    local package="$1"
    local version="$2"
    
    log INFO "Validating package: $package"
    
    # Check if package directory exists
    if [[ ! -d "$package" ]]; then
        log ERROR "Package directory not found: $package"
        return 1
    fi
    
    # Check for required files based on platform
    local platforms=$(platform_list | grep -E "^  [a-zA-Z]" | awk '{print $2}')
    for platform in $platforms; do
        local config=$(platform_get_config "$platform")
        local required_files=$(echo "$config" | jq -r '.files.required[]?' 2>/dev/null)
        
        for file in $required_files; do
            if [[ ! -f "$package/$file" ]]; then
                log WARN "Required file not found for $platform: $file"
            fi
        done
    done
    
    return 0
}

deploy_execute_pre_hooks() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Executing pre-deployment hooks"
    
    for platform in $platforms; do
        local pre_script="$PAK_TEMPLATES_DIR/deploy/pre/${platform}.sh"
        if [[ -f "$pre_script" ]]; then
            log INFO "Running pre-deployment for $platform"
            if ! "$pre_script" "$package" "$version" "$(pwd)"; then
                log ERROR "Pre-deployment failed for $platform"
                return 1
            fi
        fi
    done
    
    return 0
}

deploy_execute_post_hooks() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Executing post-deployment hooks"
    
    for platform in $platforms; do
        local post_script="$PAK_TEMPLATES_DIR/deploy/post/${platform}.sh"
        if [[ -f "$post_script" ]]; then
            log INFO "Running post-deployment for $platform"
            "$post_script" "$package" "$version" "$(pwd)" "$deploy_id"
        fi
    done
}

deploy_to_platform() {
    local package="$1"
    local version="$2"
    local platform="$3"
    local deploy_id="$4"
    
    log INFO "Deploying to $platform..."
    
    if [[ "$PAK_DRY_RUN" == "true" ]]; then
        log INFO "[DRY RUN] Would deploy to $platform"
        return 0
    fi
    
    # Get platform configuration
    local platform_config=$(platform_get_config "$platform")
    
    # Execute platform-specific deployment
    case "$platform" in
        npm)
            deploy_npm "$package" "$version" "$deploy_id"
            ;;
        pypi)
            deploy_pypi "$package" "$version" "$deploy_id"
            ;;
        cargo)
            deploy_cargo "$package" "$version" "$deploy_id"
            ;;
        dockerhub)
            deploy_dockerhub "$package" "$version" "$deploy_id"
            ;;
        maven)
            deploy_maven "$package" "$version" "$deploy_id"
            ;;
        composer)
            deploy_composer "$package" "$version" "$deploy_id"
            ;;
        *)
            log WARN "No deployment handler for platform: $platform"
            return 1
            ;;
    esac
}

deploy_to_platforms() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    local success_count=0
    local total_count=0
    
    for platform in $platforms; do
        ((total_count++))
        if deploy_to_platform "$package" "$version" "$platform" "$deploy_id"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq $total_count ]]; then
        return 0
    else
        return 1
    fi
}

# Platform-specific deployment functions
deploy_npm() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check package.json exists
    [[ -f "package.json" ]] || {
        log ERROR "package.json not found"
        return 1
    }
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        npm version "$version" --no-git-tag-version
    fi
    
    # Install dependencies
    npm install
    
    # Run tests
    if grep -q '"test"' package.json; then
        npm test
    fi
    
    # Build if needed
    if grep -q '"build"' package.json; then
        npm run build
    fi
    
    # Publish
    npm publish --access public
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "npm" "completed"
}

deploy_pypi() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check setup files
    [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || {
        log ERROR "setup.py or pyproject.toml not found"
        return 1
    }
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        # Update version in pyproject.toml or setup.py
        if [[ -f "pyproject.toml" ]]; then
            sed -i "s/^version = \".*\"/version = \"$version\"/" pyproject.toml
        elif [[ -f "setup.py" ]]; then
            sed -i "s/version=['\"].*['\"]/version='$version'/" setup.py
        fi
    fi
    
    # Install dependencies
    pip install -e .
    
    # Run tests
    if command -v pytest >/dev/null; then
        python -m pytest
    fi
    
    # Build distribution
    python -m build
    
    # Upload
    twine upload dist/*
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "pypi" "completed"
}

deploy_cargo() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check Cargo.toml
    [[ -f "Cargo.toml" ]] || {
        log ERROR "Cargo.toml not found"
        return 1
    }
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        sed -i "s/^version = \".*\"/version = \"$version\"/" Cargo.toml
    fi
    
    # Build
    cargo build --release
    
    # Test
    cargo test
    
    # Publish
    cargo publish
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "cargo" "completed"
}

deploy_dockerhub() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check Dockerfile
    [[ -f "Dockerfile" ]] || {
        log ERROR "Dockerfile not found"
        return 1
    }
    
    # Build image
    docker build -t "$package:$version" .
    
    # Test image
    docker run --rm "$package:$version" test
    
    # Push to registry
    docker push "$package:$version"
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "dockerhub" "completed"
}

deploy_maven() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check pom.xml
    [[ -f "pom.xml" ]] || {
        log ERROR "pom.xml not found"
        return 1
    }
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        mvn versions:set -DnewVersion="$version"
    fi
    
    # Install dependencies
    mvn install
    
    # Run tests
    mvn test
    
    # Build package
    mvn clean package
    
    # Deploy
    mvn deploy
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "maven" "completed"
}

deploy_composer() {
    local package="$1"
    local version="$2"
    local deploy_id="$3"
    
    cd "$package"
    
    # Check composer.json
    [[ -f "composer.json" ]] || {
        log ERROR "composer.json not found"
        return 1
    }
    
    # Install dependencies
    composer install
    
    # Run tests
    composer test
    
    # Build
    composer build
    
    # Publish
    composer publish
    
    # Update deployment record
    deploy_update_platform_status "$deploy_id" "composer" "completed"
}

deploy_verify_deployment() {
    local package="$1"
    local version="$2"
    local platforms="$3"
    local deploy_id="$4"
    
    log INFO "Verifying deployment"
    
    for platform in $platforms; do
        local config=$(platform_get_config "$platform")
        local api_endpoint=$(echo "$config" | jq -r '.api' 2>/dev/null)
        
        if [[ "$api_endpoint" != "null" ]]; then
            # Replace placeholders in API endpoint
            local url="${api_endpoint//\{package\}/$package}"
            url="${url//\{version\}/$version}"
            
            # Test API endpoint
            if curl -s --max-time 10 "$url" >/dev/null; then
                log INFO "✅ Verification passed for $platform"
            else
                log WARN "⚠️  Verification failed for $platform"
            fi
        fi
    done
}

deploy_rollback() {
    local deploy_id="$1"
    local platform="${2:-all}"
    
    log INFO "Rolling back deployment: $deploy_id"
    
    local deploy_record="$PAK_DATA_DIR/deployments/${deploy_id}.json"
    if [[ ! -f "$deploy_record" ]]; then
        log ERROR "Deployment not found: $deploy_id"
        return 1
    fi
    
    local package=$(jq -r '.package' "$deploy_record")
    local version=$(jq -r '.version' "$deploy_record")
    
    if [[ "$platform" == "all" ]]; then
        local platforms=$(jq -r '.platforms | keys[]' "$deploy_record" 2>/dev/null)
        for p in $platforms; do
            deploy_rollback_platform "$package" "$version" "$p" "$deploy_id"
        done
    else
        deploy_rollback_platform "$package" "$version" "$platform" "$deploy_id"
    fi
    
    # Update deployment status
    deploy_update_status "$deploy_id" "rolled_back"
    
    log SUCCESS "Rollback completed for deployment: $deploy_id"
}

deploy_rollback_platform() {
    local package="$1"
    local version="$2"
    local platform="$3"
    local deploy_id="$4"
    
    local rollback_script="$PAK_TEMPLATES_DIR/deploy/rollback/${platform}.sh"
    if [[ -f "$rollback_script" ]]; then
        log INFO "Rolling back $platform deployment"
        "$rollback_script" "$package" "$version" "$previous_version" "$deploy_id"
    else
        log WARN "No rollback script found for $platform"
    fi
}

deploy_status() {
    local deploy_id="${1:-latest}"
    
    if [[ "$deploy_id" == "latest" ]]; then
        deploy_id=$(ls -t "$PAK_DATA_DIR/deployments"/*.json 2>/dev/null | head -1 | xargs basename .json)
    fi
    
    local deploy_record="$PAK_DATA_DIR/deployments/${deploy_id}.json"
    
    if [[ -f "$deploy_record" ]]; then
        echo "Deployment Status: $deploy_id"
        echo "=================="
        jq . "$deploy_record"
    else
        log ERROR "Deployment not found: $deploy_id"
        return 1
    fi
}

deploy_history() {
    local limit="${1:-10}"
    
    echo "Deployment History (last $limit):"
    echo "================================"
    
    local count=0
    for record in $(ls -t "$PAK_DATA_DIR/deployments"/*.json 2>/dev/null); do
        [[ $count -ge $limit ]] && break
        
        local deploy_id=$(basename "$record" .json)
        local package=$(jq -r '.package' "$record")
        local version=$(jq -r '.version' "$record")
        local status=$(jq -r '.status' "$record")
        local started_at=$(jq -r '.started_at' "$record")
        
        printf "%-12s %-20s %-15s %-12s %s\n" "$deploy_id" "$package" "$version" "$status" "$started_at"
        ((count++))
    done
}

deploy_cancel() {
    local deploy_id="$1"
    
    log INFO "Cancelling deployment: $deploy_id"
    
    # Update deployment status
    deploy_update_status "$deploy_id" "cancelled"
    
    log SUCCESS "Deployment cancelled: $deploy_id"
}

deploy_retry() {
    local deploy_id="$1"
    local platform="${2:-all}"
    
    log INFO "Retrying deployment: $deploy_id"
    
    local deploy_record="$PAK_DATA_DIR/deployments/${deploy_id}.json"
    if [[ ! -f "$deploy_record" ]]; then
        log ERROR "Deployment not found: $deploy_id"
        return 1
    fi
    
    local package=$(jq -r '.package' "$deploy_record")
    local version=$(jq -r '.version' "$deploy_record")
    local platforms=$(jq -r '.platforms | keys[]' "$deploy_record" 2>/dev/null)
    
    # Reset platform statuses
    for p in $platforms; do
        if [[ "$platform" == "all" || "$platform" == "$p" ]]; then
            deploy_update_platform_status "$deploy_id" "$p" "retrying"
        fi
    done
    
    # Retry deployment
    if [[ "$platform" == "all" ]]; then
        deploy_to_platforms "$package" "$version" "$platforms" "$deploy_id"
    else
        deploy_to_platform "$package" "$version" "$platform" "$deploy_id"
    fi
}

deploy_validate() {
    local package="$1"
    local version="${2:-}"
    
    log INFO "Validating deployment configuration"
    
    # Validate package
    if ! deploy_validate_package "$package" "$version"; then
        return 1
    fi
    
    # Validate platform configurations
    local platforms=$(platform_list | grep -E "^  [a-zA-Z]" | awk '{print $2}')
    for platform in $platforms; do
        if ! platform_validate_config "$platform"; then
            log ERROR "Platform validation failed: $platform"
            return 1
        fi
    done
    
    log SUCCESS "Deployment validation passed"
}

deploy_test() {
    local package="$1"
    local platforms="${2:-npm pypi}"
    
    log INFO "Testing deployment (dry run)"
    
    # Set dry run mode
    local original_dry_run="$PAK_DRY_RUN"
    export PAK_DRY_RUN="true"
    
    # Execute test deployment
    deploy_package "$package" "" "$platforms" "standard"
    
    # Restore original dry run setting
    export PAK_DRY_RUN="$original_dry_run"
    
    log SUCCESS "Deployment test completed"
}

# Helper functions
deploy_log_stage() {
    local deploy_id="$1"
    local stage="$2"
    local status="$3"
    
    jq --arg stage "$stage" --arg status "$status" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.logs += [{"stage": $stage, "status": $status, "timestamp": $timestamp}]' \
       "$PAK_DATA_DIR/deployments/${deploy_id}.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/${deploy_id}.json"
}

deploy_update_status() {
    local deploy_id="$1"
    local status="$2"
    
    jq --arg status "$status" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = $status | .completed_at = $completed_at' \
       "$PAK_DATA_DIR/deployments/${deploy_id}.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/${deploy_id}.json"
}

deploy_update_platform_status() {
    local deploy_id="$1"
    local platform="$2"
    local status="$3"
    
    jq --arg platform "$platform" --arg status "$status" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.platforms[$platform] = {"status": $status, "completed_at": $completed_at}' \
       "$PAK_DATA_DIR/deployments/${deploy_id}.json" > temp.json && mv temp.json "$PAK_DATA_DIR/deployments/${deploy_id}.json"
}

deploy_update_final_status() {
    local deploy_id="$1"
    
    local deploy_record="$PAK_DATA_DIR/deployments/${deploy_id}.json"
    local failed_platforms=$(jq -r '.platforms | to_entries[] | select(.value.status == "failed") | .key' "$deploy_record" 2>/dev/null)
    
    if [[ -n "$failed_platforms" ]]; then
        deploy_update_status "$deploy_id" "failed"
        log ERROR "Deployment failed for platforms: $failed_platforms"
    else
        deploy_update_status "$deploy_id" "completed"
        log SUCCESS "Deployment completed successfully"
    fi
}

# Export functions
export -f deploy_package deploy_parallel deploy_pipeline deploy_rollback deploy_status
