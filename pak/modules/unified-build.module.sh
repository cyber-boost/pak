#!/bin/bash
# PAK.sh Unified Build System - Multi-platform package generation from single source
# Automatically detects project types and generates packages for all platforms

unified_build_init() {
    # Create build system directories
    mkdir -p "$PAK_DATA_DIR/build"
    mkdir -p "$PAK_DATA_DIR/build/templates"
    mkdir -p "$PAK_DATA_DIR/build/cache"
    mkdir -p "$PAK_DATA_DIR/build/artifacts"
    mkdir -p "$PAK_DATA_DIR/build/matrix"
    mkdir -p "$PAK_LOGS_DIR/build"
    
    # Initialize build system components
    unified_build_init_templates
    unified_build_init_detectors
    unified_build_init_matrix
    
    log INFO "Unified build system initialized with multi-platform support"
}

unified_build_register_commands() {
    register_command "build" "build" "unified_build_main"
    register_command "build-detect" "build" "unified_build_detect"
    register_command "build-matrix" "build" "unified_build_matrix"
    register_command "build-cache" "build" "unified_build_cache"
    register_command "build-artifacts" "build" "unified_build_artifacts"
    register_command "build-clean" "build" "unified_build_clean"
    register_command "build-validate" "build" "unified_build_validate"
}

unified_build_init_templates() {
    # Create build templates for different project types
    mkdir -p "$PAK_DATA_DIR/build/templates"
    
    # JavaScript/TypeScript templates
    unified_build_create_js_template
    unified_build_create_ts_template
    
    # Python templates
    unified_build_create_python_template
    
    # Rust templates
    unified_build_create_rust_template
    
    # Go templates
    unified_build_create_go_template
    
    # Java templates
    unified_build_create_java_template
    
    # .NET templates
    unified_build_create_dotnet_template
    
    # Container templates
    unified_build_create_container_template
}

unified_build_create_js_template() {
    cat > "$PAK_DATA_DIR/build/templates/javascript.json" << 'EOF'
{
    "name": "javascript",
    "detectors": [
        "package.json",
        "node_modules",
        "*.js"
    ],
    "platforms": [
        "npm",
        "yarn",
        "pnpm",
        "jspm"
    ],
    "build_steps": [
        {
            "name": "install",
            "command": "npm install",
            "platforms": ["npm", "yarn", "pnpm"]
        },
        {
            "name": "test",
            "command": "npm test",
            "platforms": ["npm", "yarn", "pnpm"],
            "optional": true
        },
        {
            "name": "build",
            "command": "npm run build",
            "platforms": ["npm", "yarn", "pnpm"],
            "optional": true
        },
        {
            "name": "publish",
            "command": "npm publish --access public",
            "platforms": ["npm"]
        },
        {
            "name": "yarn_publish",
            "command": "yarn publish --access public",
            "platforms": ["yarn"]
        }
    ],
    "artifacts": [
        "package.json",
        "node_modules",
        "dist",
        "build"
    ],
    "metadata": {
        "version_field": "package.json.version",
        "name_field": "package.json.name",
        "description_field": "package.json.description"
    }
}
EOF
}

unified_build_create_python_template() {
    cat > "$PAK_DATA_DIR/build/templates/python.json" << 'EOF'
{
    "name": "python",
    "detectors": [
        "setup.py",
        "pyproject.toml",
        "requirements.txt",
        "*.py"
    ],
    "platforms": [
        "pypi",
        "conda",
        "poetry"
    ],
    "build_steps": [
        {
            "name": "install",
            "command": "pip install -e .",
            "platforms": ["pypi", "conda"]
        },
        {
            "name": "test",
            "command": "python -m pytest",
            "platforms": ["pypi", "conda"],
            "optional": true
        },
        {
            "name": "build",
            "command": "python -m build",
            "platforms": ["pypi"]
        },
        {
            "name": "upload",
            "command": "twine upload dist/*",
            "platforms": ["pypi"]
        }
    ],
    "artifacts": [
        "dist",
        "build",
        "*.egg-info"
    ],
    "metadata": {
        "version_field": "setup.py.version",
        "name_field": "setup.py.name",
        "description_field": "setup.py.description"
    }
}
EOF
}

unified_build_create_rust_template() {
    cat > "$PAK_DATA_DIR/build/templates/rust.json" << 'EOF'
{
    "name": "rust",
    "detectors": [
        "Cargo.toml",
        "Cargo.lock",
        "src"
    ],
    "platforms": [
        "cargo"
    ],
    "build_steps": [
        {
            "name": "build",
            "command": "cargo build --release",
            "platforms": ["cargo"]
        },
        {
            "name": "test",
            "command": "cargo test",
            "platforms": ["cargo"]
        },
        {
            "name": "publish",
            "command": "cargo publish",
            "platforms": ["cargo"]
        }
    ],
    "artifacts": [
        "target",
        "Cargo.lock"
    ],
    "metadata": {
        "version_field": "Cargo.toml.package.version",
        "name_field": "Cargo.toml.package.name",
        "description_field": "Cargo.toml.package.description"
    }
}
EOF
}

unified_build_create_go_template() {
    cat > "$PAK_DATA_DIR/build/templates/go.json" << 'EOF'
{
    "name": "go",
    "detectors": [
        "go.mod",
        "go.sum",
        "*.go"
    ],
    "platforms": [
        "go"
    ],
    "build_steps": [
        {
            "name": "download",
            "command": "go mod download",
            "platforms": ["go"]
        },
        {
            "name": "test",
            "command": "go test ./...",
            "platforms": ["go"]
        },
        {
            "name": "build",
            "command": "go build -o bin/app .",
            "platforms": ["go"]
        },
        {
            "name": "tag",
            "command": "git tag v{version} && git push origin v{version}",
            "platforms": ["go"]
        }
    ],
    "artifacts": [
        "bin",
        "go.sum"
    ],
    "metadata": {
        "version_field": "go.mod.module",
        "name_field": "go.mod.module",
        "description_field": "README.md"
    }
}
EOF
}

unified_build_create_java_template() {
    cat > "$PAK_DATA_DIR/build/templates/java.json" << 'EOF'
{
    "name": "java",
    "detectors": [
        "pom.xml",
        "build.gradle",
        "src"
    ],
    "platforms": [
        "maven",
        "gradle"
    ],
    "build_steps": [
        {
            "name": "compile",
            "command": "mvn clean compile",
            "platforms": ["maven"]
        },
        {
            "name": "test",
            "command": "mvn test",
            "platforms": ["maven"]
        },
        {
            "name": "package",
            "command": "mvn clean package",
            "platforms": ["maven"]
        },
        {
            "name": "deploy",
            "command": "mvn deploy",
            "platforms": ["maven"]
        }
    ],
    "artifacts": [
        "target",
        "build"
    ],
    "metadata": {
        "version_field": "pom.xml.version",
        "name_field": "pom.xml.artifactId",
        "description_field": "pom.xml.description"
    }
}
EOF
}

unified_build_create_dotnet_template() {
    cat > "$PAK_DATA_DIR/build/templates/dotnet.json" << 'EOF'
{
    "name": "dotnet",
    "detectors": [
        "*.csproj",
        "*.vbproj",
        "*.fsproj"
    ],
    "platforms": [
        "nuget"
    ],
    "build_steps": [
        {
            "name": "restore",
            "command": "dotnet restore",
            "platforms": ["nuget"]
        },
        {
            "name": "build",
            "command": "dotnet build --configuration Release",
            "platforms": ["nuget"]
        },
        {
            "name": "test",
            "command": "dotnet test",
            "platforms": ["nuget"]
        },
        {
            "name": "pack",
            "command": "dotnet pack --configuration Release --output nupkgs",
            "platforms": ["nuget"]
        },
        {
            "name": "push",
            "command": "dotnet nuget push nupkgs/*.nupkg --api-key {NUGET_API_KEY} --source https://api.nuget.org/v3/index.json",
            "platforms": ["nuget"]
        }
    ],
    "artifacts": [
        "bin",
        "obj",
        "nupkgs"
    ],
    "metadata": {
        "version_field": "*.csproj.Version",
        "name_field": "*.csproj.AssemblyName",
        "description_field": "*.csproj.Description"
    }
}
EOF
}

unified_build_create_container_template() {
    cat > "$PAK_DATA_DIR/build/templates/container.json" << 'EOF'
{
    "name": "container",
    "detectors": [
        "Dockerfile",
        "docker-compose.yml",
        ".dockerignore"
    ],
    "platforms": [
        "docker",
        "helm"
    ],
    "build_steps": [
        {
            "name": "build",
            "command": "docker build -t {name}:{version} .",
            "platforms": ["docker"]
        },
        {
            "name": "test",
            "command": "docker run --rm {name}:{version} test",
            "platforms": ["docker"],
            "optional": true
        },
        {
            "name": "push",
            "command": "docker push {name}:{version}",
            "platforms": ["docker"]
        }
    ],
    "artifacts": [
        "*.tar",
        "*.tar.gz"
    ],
    "metadata": {
        "version_field": "Dockerfile.LABEL.version",
        "name_field": "Dockerfile.LABEL.name",
        "description_field": "Dockerfile.LABEL.description"
    }
}
EOF
}

unified_build_init_detectors() {
    # Create project type detection scripts
    cat > "$PAK_DATA_DIR/build/detect.sh" << 'EOF'
#!/bin/bash
# Project type detection script

detect_project_type() {
    local project_dir="$1"
    
    cd "$project_dir"
    
    # JavaScript/TypeScript detection
    if [[ -f "package.json" ]]; then
        if [[ -f "tsconfig.json" ]] || grep -q "typescript" package.json; then
            echo "typescript"
        else
            echo "javascript"
        fi
        return 0
    fi
    
    # Python detection
    if [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
        return 0
    fi
    
    # Rust detection
    if [[ -f "Cargo.toml" ]]; then
        echo "rust"
        return 0
    fi
    
    # Go detection
    if [[ -f "go.mod" ]]; then
        echo "go"
        return 0
    fi
    
    # Java detection
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
        return 0
    fi
    
    # .NET detection
    if ls *.csproj *.vbproj *.fsproj >/dev/null 2>&1; then
        echo "dotnet"
        return 0
    fi
    
    # Container detection
    if [[ -f "Dockerfile" ]]; then
        echo "container"
        return 0
    fi
    
    echo "unknown"
    return 1
}

detect_platforms() {
    local project_type="$1"
    local template_file="$PAK_DATA_DIR/build/templates/${project_type}.json"
    
    if [[ -f "$template_file" ]]; then
        jq -r '.platforms[]' "$template_file"
    else
        echo ""
    fi
}

detect_metadata() {
    local project_dir="$1"
    local project_type="$2"
    local template_file="$PAK_DATA_DIR/build/templates/${project_type}.json"
    
    if [[ ! -f "$template_file" ]]; then
        return 1
    fi
    
    local metadata=$(jq -r '.metadata' "$template_file")
    local name_field=$(echo "$metadata" | jq -r '.name_field')
    local version_field=$(echo "$metadata" | jq -r '.version_field')
    local description_field=$(echo "$metadata" | jq -r '.description_field')
    
    cd "$project_dir"
    
    # Extract name
    local name=""
    case "$name_field" in
        package.json.name)
            name=$(jq -r '.name' package.json 2>/dev/null)
            ;;
        setup.py.name)
            name=$(grep -o "name=['\"][^'\"]*['\"]" setup.py | head -1 | cut -d"'" -f2)
            ;;
        Cargo.toml.package.name)
            name=$(grep -A 10 "\[package\]" Cargo.toml | grep "name = " | head -1 | cut -d'"' -f2)
            ;;
        go.mod.module)
            name=$(grep "^module " go.mod | cut -d' ' -f2)
            ;;
        pom.xml.artifactId)
            name=$(grep -o "<artifactId>[^<]*</artifactId>" pom.xml | head -1 | sed 's/<artifactId>\(.*\)<\/artifactId>/\1/')
            ;;
    esac
    
    # Extract version
    local version=""
    case "$version_field" in
        package.json.version)
            version=$(jq -r '.version' package.json 2>/dev/null)
            ;;
        setup.py.version)
            version=$(grep -o "version=['\"][^'\"]*['\"]" setup.py | head -1 | cut -d"'" -f2)
            ;;
        Cargo.toml.package.version)
            version=$(grep -A 10 "\[package\]" Cargo.toml | grep "version = " | head -1 | cut -d'"' -f2)
            ;;
        go.mod.module)
            version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
            ;;
        pom.xml.version)
            version=$(grep -o "<version>[^<]*</version>" pom.xml | head -1 | sed 's/<version>\(.*\)<\/version>/\1/')
            ;;
    esac
    
    # Extract description
    local description=""
    case "$description_field" in
        package.json.description)
            description=$(jq -r '.description' package.json 2>/dev/null)
            ;;
        setup.py.description)
            description=$(grep -o "description=['\"][^'\"]*['\"]" setup.py | head -1 | cut -d"'" -f2)
            ;;
        Cargo.toml.package.description)
            description=$(grep -A 10 "\[package\]" Cargo.toml | grep "description = " | head -1 | cut -d'"' -f2)
            ;;
        README.md)
            description=$(head -1 README.md 2>/dev/null || echo "")
            ;;
    esac
    
    # Output JSON
    jq --null-input \
       --arg name "$name" \
       --arg version "$version" \
       --arg description "$description" \
       '{
           "name": $name,
           "version": $version,
           "description": $description
       }'
}

# Export functions
export -f detect_project_type detect_platforms detect_metadata
EOF
    chmod +x "$PAK_DATA_DIR/build/detect.sh"
}

unified_build_init_matrix() {
    # Create build matrix configuration
    cat > "$PAK_DATA_DIR/build/matrix/config.json" << 'EOF'
{
    "matrix": {
        "javascript": {
            "versions": ["16", "18", "20"],
            "platforms": ["npm", "yarn", "pnpm"],
            "os": ["linux", "macos", "windows"]
        },
        "python": {
            "versions": ["3.8", "3.9", "3.10", "3.11", "3.12"],
            "platforms": ["pypi", "conda"],
            "os": ["linux", "macos", "windows"]
        },
        "rust": {
            "versions": ["stable", "nightly"],
            "platforms": ["cargo"],
            "os": ["linux", "macos", "windows"]
        },
        "go": {
            "versions": ["1.19", "1.20", "1.21"],
            "platforms": ["go"],
            "os": ["linux", "macos", "windows"]
        },
        "java": {
            "versions": ["8", "11", "17", "21"],
            "platforms": ["maven", "gradle"],
            "os": ["linux", "macos", "windows"]
        },
        "dotnet": {
            "versions": ["6.0", "7.0", "8.0"],
            "platforms": ["nuget"],
            "os": ["linux", "macos", "windows"]
        }
    }
}
EOF
}

unified_build_main() {
    local action="$1"
    local project_dir="$2"
    local version="${3:-}"
    local platforms="${4:-all}"
    
    case "$action" in
        detect)
            unified_build_detect_project "$project_dir"
            ;;
        build)
            unified_build_project "$project_dir" "$version" "$platforms"
            ;;
        matrix)
            unified_build_matrix "$project_dir" "$version"
            ;;
        cache)
            unified_build_cache_manage "$project_dir"
            ;;
        artifacts)
            unified_build_artifacts_list "$project_dir"
            ;;
        clean)
            unified_build_clean "$project_dir"
            ;;
        validate)
            unified_build_validate "$project_dir"
            ;;
        *)
            unified_build_usage
            ;;
    esac
}

unified_build_detect_project() {
    local project_dir="$1"
    
    if [[ ! -d "$project_dir" ]]; then
        log ERROR "Project directory not found: $project_dir"
        return 1
    fi
    
    log INFO "Detecting project type: $project_dir"
    
    # Source detection script
    source "$PAK_DATA_DIR/build/detect.sh"
    
    # Detect project type
    local project_type=$(detect_project_type "$project_dir")
    if [[ "$project_type" == "unknown" ]]; then
        log ERROR "Unknown project type"
        return 1
    fi
    
    # Detect platforms
    local platforms=$(detect_platforms "$project_type")
    
    # Detect metadata
    local metadata=$(detect_metadata "$project_dir" "$project_type")
    
    # Output results
    echo "Project Detection Results:"
    echo "========================="
    echo "Type: $project_type"
    echo "Platforms: $platforms"
    echo "Metadata:"
    echo "$metadata" | jq .
    
    # Save detection results
    local detection_file="$PAK_DATA_DIR/build/detection_$(basename "$project_dir").json"
    jq --null-input \
       --arg type "$project_type" \
       --arg platforms "$platforms" \
       --argjson metadata "$metadata" \
       '{
           "project_type": $type,
           "platforms": ($platforms | split(" ") | map(select(length > 0))),
           "metadata": $metadata,
           "detected_at": (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
       }' > "$detection_file"
    
    log SUCCESS "Project detection completed: $detection_file"
}

unified_build_project() {
    local project_dir="$1"
    local version="$2"
    local platforms="$3"
    
    log INFO "Building project: $project_dir"
    log INFO "Version: $version"
    log INFO "Platforms: $platforms"
    
    # Detect project type
    source "$PAK_DATA_DIR/build/detect.sh"
    local project_type=$(detect_project_type "$project_dir")
    if [[ "$project_type" == "unknown" ]]; then
        log ERROR "Unknown project type"
        return 1
    fi
    
    # Get template
    local template_file="$PAK_DATA_DIR/build/templates/${project_type}.json"
    if [[ ! -f "$template_file" ]]; then
        log ERROR "Template not found: $template_file"
        return 1
    fi
    
    # Get available platforms
    local available_platforms=$(detect_platforms "$project_type")
    
    # Determine target platforms
    local target_platforms=""
    if [[ "$platforms" == "all" ]]; then
        target_platforms="$available_platforms"
    else
        # Validate requested platforms
        for platform in $platforms; do
            if echo "$available_platforms" | grep -q "$platform"; then
                target_platforms="$target_platforms $platform"
            else
                log WARN "Platform not supported: $platform"
            fi
        done
    fi
    
    # Create build session
    local build_id=$(date +%s)
    local build_file="$PAK_DATA_DIR/build/session_${build_id}.json"
    
    # Initialize build session
    unified_build_create_session "$build_id" "$project_dir" "$project_type" "$version" "$target_platforms" "$build_file"
    
    # Execute build for each platform
    for platform in $target_platforms; do
        unified_build_platform "$project_dir" "$project_type" "$platform" "$version" "$build_id" "$template_file"
    done
    
    # Finalize build session
    unified_build_finalize_session "$build_id" "$build_file"
    
    log SUCCESS "Build completed: $build_id"
}

unified_build_create_session() {
    local build_id="$1"
    local project_dir="$2"
    local project_type="$3"
    local version="$4"
    local platforms="$5"
    local build_file="$6"
    
    jq --null-input \
       --arg id "$build_id" \
       --arg project_dir "$project_dir" \
       --arg project_type "$project_type" \
       --arg version "$version" \
       --arg platforms "$platforms" \
       --arg started_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '{
           "build_id": $id,
           "project_dir": $project_dir,
           "project_type": $project_type,
           "version": $version,
           "platforms": ($platforms | split(" ") | map(select(length > 0))),
           "started_at": $started_at,
           "status": "in_progress",
           "platform_results": {},
           "artifacts": [],
           "logs": [],
           "errors": []
       }' > "$build_file"
}

unified_build_platform() {
    local project_dir="$1"
    local project_type="$2"
    local platform="$3"
    local version="$4"
    local build_id="$5"
    local template_file="$6"
    
    log INFO "Building for platform: $platform"
    
    # Get build steps for platform
    local steps=$(jq -r ".build_steps[] | select(.platforms[] | contains(\"$platform\"))" "$template_file")
    
    cd "$project_dir"
    
    # Execute each build step
    local step_count=0
    while IFS= read -r step; do
        [[ -z "$step" ]] && continue
        
        local step_name=$(echo "$step" | jq -r '.name')
        local step_command=$(echo "$step" | jq -r '.command')
        local step_optional=$(echo "$step" | jq -r '.optional // false')
        
        # Replace placeholders in command
        step_command="${step_command//\{name\}/$(basename "$project_dir")}"
        step_command="${step_command//\{version\}/$version}"
        
        log INFO "Executing step: $step_name"
        
        if eval "$step_command"; then
            log SUCCESS "Step completed: $step_name"
            unified_build_log_step "$build_id" "$platform" "$step_name" "completed"
        else
            if [[ "$step_optional" == "true" ]]; then
                log WARN "Optional step failed: $step_name"
                unified_build_log_step "$build_id" "$platform" "$step_name" "skipped"
            else
                log ERROR "Step failed: $step_name"
                unified_build_log_step "$build_id" "$platform" "$step_name" "failed"
                unified_build_log_error "$build_id" "Build step failed: $platform:$step_name"
                return 1
            fi
        fi
        
        ((step_count++))
    done <<< "$steps"
    
    # Update platform result
    unified_build_update_platform_result "$build_id" "$platform" "completed"
    
    log SUCCESS "Platform build completed: $platform"
}

unified_build_finalize_session() {
    local build_id="$1"
    local build_file="$2"
    
    # Check for failed platforms
    local failed_platforms=$(jq -r '.platform_results | to_entries[] | select(.value.status == "failed") | .key' "$build_file" 2>/dev/null)
    
    if [[ -n "$failed_platforms" ]]; then
        jq --arg status "failed" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.status = $status | .completed_at = $completed_at' \
           "$build_file" > temp.json && mv temp.json "$build_file"
        log ERROR "Build failed for platforms: $failed_platforms"
    else
        jq --arg status "completed" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
           '.status = $status | .completed_at = $completed_at' \
           "$build_file" > temp.json && mv temp.json "$build_file"
        log SUCCESS "Build completed successfully"
    fi
}

unified_build_matrix() {
    local project_dir="$1"
    local version="$2"
    
    log INFO "Building matrix for: $project_dir"
    
    # Detect project type
    source "$PAK_DATA_DIR/build/detect.sh"
    local project_type=$(detect_project_type "$project_dir")
    
    # Get matrix configuration
    local matrix_config="$PAK_DATA_DIR/build/matrix/config.json"
    local matrix=$(jq -r ".matrix.$project_type" "$matrix_config")
    
    if [[ "$matrix" == "null" ]]; then
        log ERROR "No matrix configuration for: $project_type"
        return 1
    fi
    
    # Build for each combination
    local versions=$(echo "$matrix" | jq -r '.versions[]')
    local platforms=$(echo "$matrix" | jq -r '.platforms[]')
    local os_list=$(echo "$matrix" | jq -r '.os[]')
    
    for ver in $versions; do
        for platform in $platforms; do
            for os in $os_list; do
                log INFO "Building matrix: $project_type $ver $platform $os"
                unified_build_project "$project_dir" "$ver" "$platform"
            done
        done
    done
    
    log SUCCESS "Matrix build completed"
}

unified_build_cache_manage() {
    local project_dir="$1"
    local action="$2"
    
    case "$action" in
        clean)
            rm -rf "$PAK_DATA_DIR/build/cache"/*
            log SUCCESS "Build cache cleaned"
            ;;
        list)
            echo "Build Cache Contents:"
            echo "===================="
            find "$PAK_DATA_DIR/build/cache" -type f -exec ls -la {} \;
            ;;
        *)
            log ERROR "Unknown cache action: $action"
            ;;
    esac
}

unified_build_artifacts_list() {
    local project_dir="$1"
    
    echo "Build Artifacts:"
    echo "================"
    find "$PAK_DATA_DIR/build/artifacts" -name "*$(basename "$project_dir")*" -type f -exec ls -la {} \;
}

unified_build_clean() {
    local project_dir="$1"
    
    log INFO "Cleaning build artifacts: $project_dir"
    
    # Clean common build directories
    cd "$project_dir"
    
    # JavaScript/TypeScript
    rm -rf node_modules dist build .next .nuxt
    
    # Python
    rm -rf build dist *.egg-info __pycache__ .pytest_cache
    
    # Rust
    rm -rf target
    
    # Go
    rm -rf bin
    
    # Java
    rm -rf target build
    
    # .NET
    rm -rf bin obj nupkgs
    
    # Container
    rm -rf *.tar *.tar.gz
    
    log SUCCESS "Build artifacts cleaned"
}

unified_build_validate() {
    local project_dir="$1"
    
    log INFO "Validating build configuration: $project_dir"
    
    # Detect project type
    source "$PAK_DATA_DIR/build/detect.sh"
    local project_type=$(detect_project_type "$project_dir")
    
    if [[ "$project_type" == "unknown" ]]; then
        log ERROR "Unknown project type"
        return 1
    fi
    
    # Validate template exists
    local template_file="$PAK_DATA_DIR/build/templates/${project_type}.json"
    if [[ ! -f "$template_file" ]]; then
        log ERROR "Template not found: $template_file"
        return 1
    fi
    
    # Validate template syntax
    if ! jq . "$template_file" >/dev/null 2>&1; then
        log ERROR "Invalid template syntax: $template_file"
        return 1
    fi
    
    # Validate required files exist
    local detectors=$(jq -r '.detectors[]' "$template_file")
    local missing_files=()
    
    for detector in $detectors; do
        if [[ ! -f "$project_dir/$detector" ]] && [[ ! -d "$project_dir/$detector" ]]; then
            missing_files+=("$detector")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log WARN "Missing files: ${missing_files[*]}"
    fi
    
    log SUCCESS "Build validation completed"
    return 0
}

# Helper functions
unified_build_log_step() {
    local build_id="$1"
    local platform="$2"
    local step="$3"
    local status="$4"
    local build_file="$PAK_DATA_DIR/build/session_${build_id}.json"
    
    jq --arg platform "$platform" --arg step "$step" --arg status "$status" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.logs += [{"platform": $platform, "step": $step, "status": $status, "timestamp": $timestamp}]' \
       "$build_file" > temp.json && mv temp.json "$build_file"
}

unified_build_log_error() {
    local build_id="$1"
    local error="$2"
    local build_file="$PAK_DATA_DIR/build/session_${build_id}.json"
    
    jq --arg error "$error" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.errors += [{"error": $error, "timestamp": $timestamp}]' \
       "$build_file" > temp.json && mv temp.json "$build_file"
}

unified_build_update_platform_result() {
    local build_id="$1"
    local platform="$2"
    local status="$3"
    local build_file="$PAK_DATA_DIR/build/session_${build_id}.json"
    
    jq --arg platform "$platform" --arg status "$status" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.platform_results[$platform] = {"status": $status, "completed_at": $completed_at}' \
       "$build_file" > temp.json && mv temp.json "$build_file"
}

unified_build_usage() {
    echo "PAK.sh Unified Build System"
    echo "==========================="
    echo ""
    echo "Usage: build <action> <project_dir> [version] [platforms]"
    echo ""
    echo "Actions:"
    echo "  detect     - Detect project type and platforms"
    echo "  build      - Build project for specified platforms"
    echo "  matrix     - Build project matrix"
    echo "  cache      - Manage build cache"
    echo "  artifacts  - List build artifacts"
    echo "  clean      - Clean build artifacts"
    echo "  validate   - Validate build configuration"
    echo ""
    echo "Examples:"
    echo "  build detect ./my-project"
    echo "  build build ./my-project 1.0.0"
    echo "  build build ./my-project 1.0.0 npm pypi"
    echo "  build matrix ./my-project"
    echo "  build cache clean ./my-project"
    echo "  build artifacts ./my-project"
    echo "  build clean ./my-project"
    echo "  build validate ./my-project"
}

# Export functions
export -f unified_build_main unified_build_detect unified_build_matrix unified_build_cache unified_build_artifacts unified_build_clean unified_build_validate 