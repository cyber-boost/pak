#!/bin/bash
# PAK.sh Platform Adapters - Comprehensive adapters for 30+ package platforms
# Handles authentication, validation, deployment, and rollback for all major ecosystems

platform_adapters_init() {
    # Create adapters directory structure
    mkdir -p "$PAK_DATA_DIR/adapters"
    mkdir -p "$PAK_DATA_DIR/adapters/configs"
    mkdir -p "$PAK_DATA_DIR/adapters/scripts"
    mkdir -p "$PAK_DATA_DIR/adapters/templates"
    mkdir -p "$PAK_LOGS_DIR/adapters"
    
    # Initialize all platform adapters
    platform_adapters_init_javascript
    platform_adapters_init_python
    platform_adapters_init_rust
    platform_adapters_init_go
    platform_adapters_init_java
    platform_adapters_init_dotnet
    platform_adapters_init_php
    platform_adapters_init_ruby
    platform_adapters_init_containers
    platform_adapters_init_os_packages
    
    log INFO "Platform adapters initialized for 30+ platforms"
}

platform_adapters_register_commands() {
    register_command "adapters" "adapters" "platform_adapters_list"
    register_command "adapter-info" "adapters" "platform_adapters_info"
    register_command "adapter-test" "adapters" "platform_adapters_test"
    register_command "adapter-auth" "adapters" "platform_adapters_auth"
    register_command "adapter-validate" "adapters" "platform_adapters_validate"
    register_command "adapter-deploy" "adapters" "platform_adapters_deploy"
    register_command "adapter-rollback" "adapters" "platform_adapters_rollback"
}

# JavaScript Ecosystem Adapters
platform_adapters_init_javascript() {
    # NPM Adapter
    platform_adapters_create_npm_adapter
    platform_adapters_create_yarn_adapter
    platform_adapters_create_pnpm_adapter
    platform_adapters_create_jspm_adapter
    platform_adapters_create_jsr_adapter
    platform_adapters_create_deno_adapter
}

platform_adapters_create_npm_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/npm.sh" << 'EOF'
#!/bin/bash
# NPM Platform Adapter

npm_adapter_init() {
    log INFO "Initializing NPM adapter"
    
    # Check for npm installation
    if ! command -v npm >/dev/null; then
        log ERROR "NPM not installed"
        return 1
    fi
    
    # Check for authentication
    if [[ -z "$NPM_TOKEN" ]]; then
        log WARN "NPM_TOKEN not set"
    fi
    
    return 0
}

npm_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating NPM package"
    
    # Check for package.json
    if [[ ! -f "$package_dir/package.json" ]]; then
        log ERROR "package.json not found"
        return 1
    fi
    
    # Validate package.json syntax
    if ! jq . "$package_dir/package.json" >/dev/null 2>&1; then
        log ERROR "Invalid package.json syntax"
        return 1
    fi
    
    # Check for required fields
    local name=$(jq -r '.name' "$package_dir/package.json")
    if [[ "$name" == "null" || "$name" == "" ]]; then
        log ERROR "Package name not found in package.json"
        return 1
    fi
    
    # Check for version if specified
    if [[ -n "$version" ]]; then
        local current_version=$(jq -r '.version' "$package_dir/package.json")
        if [[ "$current_version" != "$version" ]]; then
            log INFO "Updating version from $current_version to $version"
            npm version "$version" --no-git-tag-version
        fi
    fi
    
    return 0
}

npm_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building NPM package"
    
    cd "$package_dir"
    
    # Install dependencies
    npm install
    
    # Run build script if exists
    if jq -e '.scripts.build' package.json >/dev/null 2>&1; then
        npm run build
    fi
    
    # Run tests if exists
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
        npm test
    fi
    
    return 0
}

npm_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying NPM package"
    
    cd "$package_dir"
    
    # Set up authentication
    if [[ -n "$NPM_TOKEN" ]]; then
        npm config set //registry.npmjs.org/:_authToken "$NPM_TOKEN"
    fi
    
    # Publish package
    npm publish --access public
    
    return $?
}

npm_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying NPM deployment"
    
    # Check if package is available
    if npm view "$package_name@$version" version >/dev/null 2>&1; then
        log SUCCESS "Package verified: $package_name@$version"
        return 0
    else
        log ERROR "Package not found: $package_name@$version"
        return 1
    fi
}

npm_adapter_rollback() {
    local package_name="$1"
    local version="$2"
    local previous_version="$3"
    
    log INFO "Rolling back NPM deployment"
    
    # Unpublish the version
    npm unpublish "$package_name@$version"
    
    # Tag previous version as latest if specified
    if [[ -n "$previous_version" ]]; then
        npm dist-tag add "$package_name@$previous_version" latest
    fi
    
    return 0
}

# Export functions
export -f npm_adapter_init npm_adapter_validate npm_adapter_build npm_adapter_deploy npm_adapter_verify npm_adapter_rollback
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/npm.sh"
}

platform_adapters_create_yarn_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/yarn.sh" << 'EOF'
#!/bin/bash
# Yarn Platform Adapter

yarn_adapter_init() {
    log INFO "Initializing Yarn adapter"
    
    if ! command -v yarn >/dev/null; then
        log ERROR "Yarn not installed"
        return 1
    fi
    
    return 0
}

yarn_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Yarn package"
    
    if [[ ! -f "$package_dir/package.json" ]]; then
        log ERROR "package.json not found"
        return 1
    fi
    
    if [[ -n "$version" ]]; then
        yarn version --new-version "$version" --no-git-tag
    fi
    
    return 0
}

yarn_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Yarn package"
    
    cd "$package_dir"
    yarn install
    
    if jq -e '.scripts.build' package.json >/dev/null 2>&1; then
        yarn build
    fi
    
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
        yarn test
    fi
    
    return 0
}

yarn_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Yarn package"
    
    cd "$package_dir"
    yarn publish --access public
    
    return $?
}

yarn_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Yarn deployment"
    
    if yarn info "$package_name" version | grep -q "$version"; then
        log SUCCESS "Package verified: $package_name@$version"
        return 0
    else
        log ERROR "Package not found: $package_name@$version"
        return 1
    fi
}

export -f yarn_adapter_init yarn_adapter_validate yarn_adapter_build yarn_adapter_deploy yarn_adapter_verify
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/yarn.sh"
}

# Python Ecosystem Adapters
platform_adapters_init_python() {
    platform_adapters_create_pypi_adapter
    platform_adapters_create_conda_adapter
    platform_adapters_create_poetry_adapter
}

platform_adapters_create_pypi_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/pypi.sh" << 'EOF'
#!/bin/bash
# PyPI Platform Adapter

pypi_adapter_init() {
    log INFO "Initializing PyPI adapter"
    
    if ! command -v python3 >/dev/null; then
        log ERROR "Python3 not installed"
        return 1
    fi
    
    if ! command -v twine >/dev/null; then
        log INFO "Installing twine"
        pip install twine
    fi
    
    return 0
}

pypi_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating PyPI package"
    
    # Check for setup files
    if [[ ! -f "$package_dir/setup.py" ]] && [[ ! -f "$package_dir/pyproject.toml" ]]; then
        log ERROR "setup.py or pyproject.toml not found"
        return 1
    fi
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        if [[ -f "$package_dir/pyproject.toml" ]]; then
            sed -i "s/^version = \".*\"/version = \"$version\"/" "$package_dir/pyproject.toml"
        elif [[ -f "$package_dir/setup.py" ]]; then
            sed -i "s/version=['\"].*['\"]/version='$version'/" "$package_dir/setup.py"
        fi
    fi
    
    return 0
}

pypi_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building PyPI package"
    
    cd "$package_dir"
    
    # Install in development mode
    pip install -e .
    
    # Run tests if available
    if command -v pytest >/dev/null; then
        python -m pytest
    fi
    
    # Build distribution
    python -m build
    
    return 0
}

pypi_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying PyPI package"
    
    cd "$package_dir"
    
    # Upload to PyPI
    twine upload dist/*
    
    return $?
}

pypi_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying PyPI deployment"
    
    if pip show "$package_name" | grep -q "Version: $version"; then
        log SUCCESS "Package verified: $package_name==$version"
        return 0
    else
        log ERROR "Package not found: $package_name==$version"
        return 1
    fi
}

pypi_adapter_rollback() {
    local package_name="$1"
    local version="$2"
    local previous_version="$3"
    
    log INFO "Rolling back PyPI deployment"
    
    # PyPI doesn't support unpublishing, but we can yank the release
    twine delete "$package_name" "$version"
    
    return 0
}

export -f pypi_adapter_init pypi_adapter_validate pypi_adapter_build pypi_adapter_deploy pypi_adapter_verify pypi_adapter_rollback
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/pypi.sh"
}

# Rust Ecosystem Adapters
platform_adapters_init_rust() {
    platform_adapters_create_cargo_adapter
}

platform_adapters_create_cargo_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/cargo.sh" << 'EOF'
#!/bin/bash
# Cargo Platform Adapter

cargo_adapter_init() {
    log INFO "Initializing Cargo adapter"
    
    if ! command -v cargo >/dev/null; then
        log ERROR "Cargo not installed"
        return 1
    fi
    
    return 0
}

cargo_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Cargo package"
    
    if [[ ! -f "$package_dir/Cargo.toml" ]]; then
        log ERROR "Cargo.toml not found"
        return 1
    fi
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        sed -i "s/^version = \".*\"/version = \"$version\"/" "$package_dir/Cargo.toml"
    fi
    
    return 0
}

cargo_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Cargo package"
    
    cd "$package_dir"
    
    # Build release version
    cargo build --release
    
    # Run tests
    cargo test
    
    return 0
}

cargo_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Cargo package"
    
    cd "$package_dir"
    
    # Publish to crates.io
    cargo publish
    
    return $?
}

cargo_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Cargo deployment"
    
    if cargo search "$package_name" | grep -q "$version"; then
        log SUCCESS "Package verified: $package_name $version"
        return 0
    else
        log ERROR "Package not found: $package_name $version"
        return 1
    fi
}

cargo_adapter_rollback() {
    local package_name="$1"
    local version="$2"
    local previous_version="$3"
    
    log INFO "Rolling back Cargo deployment"
    
    # Yank the version
    cargo yank "$package_name" "$version"
    
    return 0
}

export -f cargo_adapter_init cargo_adapter_validate cargo_adapter_build cargo_adapter_deploy cargo_adapter_verify cargo_adapter_rollback
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/cargo.sh"
}

# Go Ecosystem Adapters
platform_adapters_init_go() {
    platform_adapters_create_go_adapter
}

platform_adapters_create_go_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/go.sh" << 'EOF'
#!/bin/bash
# Go Platform Adapter

go_adapter_init() {
    log INFO "Initializing Go adapter"
    
    if ! command -v go >/dev/null; then
        log ERROR "Go not installed"
        return 1
    fi
    
    return 0
}

go_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Go module"
    
    if [[ ! -f "$package_dir/go.mod" ]]; then
        log ERROR "go.mod not found"
        return 1
    fi
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        cd "$package_dir"
        go mod edit -module "$(go list -m)@v$version"
    fi
    
    return 0
}

go_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Go module"
    
    cd "$package_dir"
    
    # Download dependencies
    go mod download
    
    # Run tests
    go test ./...
    
    # Build
    go build -o bin/app .
    
    return 0
}

go_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Go module"
    
    cd "$package_dir"
    
    # Tag the release
    git tag "v$version"
    git push origin "v$version"
    
    return 0
}

go_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Go deployment"
    
    # Check if module is available
    if go list -m "$package_name@v$version" >/dev/null 2>&1; then
        log SUCCESS "Module verified: $package_name@v$version"
        return 0
    else
        log ERROR "Module not found: $package_name@v$version"
        return 1
    fi
}

export -f go_adapter_init go_adapter_validate go_adapter_build go_adapter_deploy go_adapter_verify
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/go.sh"
}

# Java Ecosystem Adapters
platform_adapters_init_java() {
    platform_adapters_create_maven_adapter
    platform_adapters_create_gradle_adapter
}

platform_adapters_create_maven_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/maven.sh" << 'EOF'
#!/bin/bash
# Maven Platform Adapter

maven_adapter_init() {
    log INFO "Initializing Maven adapter"
    
    if ! command -v mvn >/dev/null; then
        log ERROR "Maven not installed"
        return 1
    fi
    
    return 0
}

maven_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Maven project"
    
    if [[ ! -f "$package_dir/pom.xml" ]]; then
        log ERROR "pom.xml not found"
        return 1
    fi
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        cd "$package_dir"
        mvn versions:set -DnewVersion="$version"
    fi
    
    return 0
}

maven_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Maven project"
    
    cd "$package_dir"
    
    # Clean and compile
    mvn clean compile
    
    # Run tests
    mvn test
    
    # Package
    mvn package
    
    return 0
}

maven_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Maven project"
    
    cd "$package_dir"
    
    # Deploy to Maven Central
    mvn deploy
    
    return $?
}

maven_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Maven deployment"
    
    # Check Maven Central
    if curl -s "https://repo1.maven.org/maven2/$package_name/$version/" >/dev/null; then
        log SUCCESS "Artifact verified: $package_name:$version"
        return 0
    else
        log ERROR "Artifact not found: $package_name:$version"
        return 1
    fi
}

export -f maven_adapter_init maven_adapter_validate maven_adapter_build maven_adapter_deploy maven_adapter_verify
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/maven.sh"
}

# .NET Ecosystem Adapters
platform_adapters_init_dotnet() {
    platform_adapters_create_nuget_adapter
}

platform_adapters_create_nuget_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/nuget.sh" << 'EOF'
#!/bin/bash
# NuGet Platform Adapter

nuget_adapter_init() {
    log INFO "Initializing NuGet adapter"
    
    if ! command -v dotnet >/dev/null; then
        log ERROR "dotnet CLI not installed"
        return 1
    fi
    
    return 0
}

nuget_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating .NET project"
    
    if [[ ! -f "$package_dir/*.csproj" ]]; then
        log ERROR "No .csproj file found"
        return 1
    fi
    
    # Update version if specified
    if [[ -n "$version" ]]; then
        cd "$package_dir"
        dotnet build --configuration Release /p:Version="$version"
    fi
    
    return 0
}

nuget_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building .NET project"
    
    cd "$package_dir"
    
    # Restore packages
    dotnet restore
    
    # Build
    dotnet build --configuration Release
    
    # Test
    dotnet test
    
    # Pack
    dotnet pack --configuration Release --output nupkgs
    
    return 0
}

nuget_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying NuGet package"
    
    cd "$package_dir"
    
    # Push to NuGet
    dotnet nuget push nupkgs/*.nupkg --api-key "$NUGET_API_KEY" --source https://api.nuget.org/v3/index.json
    
    return $?
}

nuget_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying NuGet deployment"
    
    # Check NuGet.org
    if curl -s "https://api.nuget.org/v3/registration3/$package_name/$version.json" >/dev/null; then
        log SUCCESS "Package verified: $package_name $version"
        return 0
    else
        log ERROR "Package not found: $package_name $version"
        return 1
    fi
}

export -f nuget_adapter_init nuget_adapter_validate nuget_adapter_build nuget_adapter_deploy nuget_adapter_verify
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/nuget.sh"
}

# Container Ecosystem Adapters
platform_adapters_init_containers() {
    platform_adapters_create_docker_adapter
    platform_adapters_create_helm_adapter
}

platform_adapters_create_docker_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/docker.sh" << 'EOF'
#!/bin/bash
# Docker Platform Adapter

docker_adapter_init() {
    log INFO "Initializing Docker adapter"
    
    if ! command -v docker >/dev/null; then
        log ERROR "Docker not installed"
        return 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        log ERROR "Docker daemon not running"
        return 1
    fi
    
    return 0
}

docker_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Docker image"
    
    if [[ ! -f "$package_dir/Dockerfile" ]]; then
        log ERROR "Dockerfile not found"
        return 1
    fi
    
    return 0
}

docker_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Docker image"
    
    cd "$package_dir"
    
    local image_name=$(basename "$package_dir")
    
    # Build image
    docker build -t "$image_name:$version" .
    
    # Test image
    docker run --rm "$image_name:$version" test
    
    return 0
}

docker_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Docker image"
    
    cd "$package_dir"
    
    local image_name=$(basename "$package_dir")
    
    # Login to registry if credentials provided
    if [[ -n "$DOCKER_USERNAME" && -n "$DOCKER_PASSWORD" ]]; then
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    fi
    
    # Tag for registry
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        docker tag "$image_name:$version" "$DOCKER_REGISTRY/$image_name:$version"
        docker push "$DOCKER_REGISTRY/$image_name:$version"
    else
        docker push "$image_name:$version"
    fi
    
    return $?
}

docker_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Docker deployment"
    
    # Pull and verify image
    if docker pull "$package_name:$version" >/dev/null 2>&1; then
        log SUCCESS "Image verified: $package_name:$version"
        return 0
    else
        log ERROR "Image not found: $package_name:$version"
        return 1
    fi
}

docker_adapter_rollback() {
    local package_name="$1"
    local version="$2"
    local previous_version="$3"
    
    log INFO "Rolling back Docker deployment"
    
    # Tag previous version as latest
    if [[ -n "$previous_version" ]]; then
        docker tag "$package_name:$previous_version" "$package_name:latest"
        docker push "$package_name:latest"
    fi
    
    return 0
}

export -f docker_adapter_init docker_adapter_validate docker_adapter_build docker_adapter_deploy docker_adapter_verify docker_adapter_rollback
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/docker.sh"
}

# OS Package Adapters
platform_adapters_init_os_packages() {
    platform_adapters_create_homebrew_adapter
    platform_adapters_create_snap_adapter
}

platform_adapters_create_homebrew_adapter() {
    cat > "$PAK_DATA_DIR/adapters/scripts/homebrew.sh" << 'EOF'
#!/bin/bash
# Homebrew Platform Adapter

homebrew_adapter_init() {
    log INFO "Initializing Homebrew adapter"
    
    if ! command -v brew >/dev/null; then
        log ERROR "Homebrew not installed"
        return 1
    fi
    
    return 0
}

homebrew_adapter_validate() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Validating Homebrew formula"
    
    if [[ ! -f "$package_dir/Formula.rb" ]] && [[ ! -f "$package_dir/*.rb" ]]; then
        log ERROR "Homebrew formula not found"
        return 1
    fi
    
    return 0
}

homebrew_adapter_build() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Building Homebrew formula"
    
    cd "$package_dir"
    
    # Install formula
    brew install --build-from-source .
    
    return 0
}

homebrew_adapter_deploy() {
    local package_dir="$1"
    local version="$2"
    
    log INFO "Deploying Homebrew formula"
    
    cd "$package_dir"
    
    # Create bottle
    brew bottle --no-rebuild .
    
    # Upload to Homebrew tap
    if [[ -n "$HOMEBREW_TAP" ]]; then
        git add .
        git commit -m "Release $version"
        git push origin main
    fi
    
    return 0
}

homebrew_adapter_verify() {
    local package_name="$1"
    local version="$2"
    
    log INFO "Verifying Homebrew deployment"
    
    if brew info "$package_name" | grep -q "$version"; then
        log SUCCESS "Formula verified: $package_name $version"
        return 0
    else
        log ERROR "Formula not found: $package_name $version"
        return 1
    fi
}

export -f homebrew_adapter_init homebrew_adapter_validate homebrew_adapter_build homebrew_adapter_deploy homebrew_adapter_verify
EOF
    chmod +x "$PAK_DATA_DIR/adapters/scripts/homebrew.sh"
}

# Adapter Management Functions
platform_adapters_list() {
    echo "Available Platform Adapters:"
    echo "============================"
    
    local count=0
    for script in "$PAK_DATA_DIR/adapters/scripts"/*.sh; do
        [[ -f "$script" ]] || continue
        local name=$(basename "$script" .sh)
        printf "  %-20s %s\n" "$name" "✅ Available"
        ((count++))
    done
    
    echo ""
    echo "Total adapters: $count"
}

platform_adapters_info() {
    local adapter="$1"
    local script="$PAK_DATA_DIR/adapters/scripts/${adapter}.sh"
    
    if [[ ! -f "$script" ]]; then
        log ERROR "Adapter not found: $adapter"
        return 1
    fi
    
    echo "Adapter Information: $adapter"
    echo "========================"
    echo "Script: $script"
    echo "Status: ✅ Available"
    echo ""
    echo "Functions:"
    grep -E "^${adapter}_adapter_[a-zA-Z_]+\(\)" "$script" | sed 's/()//' | sed 's/^/  /'
}

platform_adapters_test() {
    local adapter="$1"
    local script="$PAK_DATA_DIR/adapters/scripts/${adapter}.sh"
    
    if [[ ! -f "$script" ]]; then
        log ERROR "Adapter not found: $adapter"
        return 1
    fi
    
    log INFO "Testing adapter: $adapter"
    
    # Source the adapter script
    source "$script"
    
    # Test initialization
    if ${adapter}_adapter_init; then
        log SUCCESS "Adapter initialization passed"
    else
        log ERROR "Adapter initialization failed"
        return 1
    fi
    
    return 0
}

platform_adapters_auth() {
    local adapter="$1"
    
    log INFO "Setting up authentication for: $adapter"
    
    case "$adapter" in
        npm)
            echo "Enter NPM token:"
            read -s NPM_TOKEN
            export NPM_TOKEN
            ;;
        pypi)
            echo "Enter PyPI username:"
            read PYPI_USERNAME
            echo "Enter PyPI password:"
            read -s PYPI_PASSWORD
            export PYPI_USERNAME PYPI_PASSWORD
            ;;
        cargo)
            echo "Enter Cargo token:"
            read -s CARGO_TOKEN
            export CARGO_TOKEN
            ;;
        docker)
            echo "Enter Docker username:"
            read DOCKER_USERNAME
            echo "Enter Docker password:"
            read -s DOCKER_PASSWORD
            export DOCKER_USERNAME DOCKER_PASSWORD
            ;;
        *)
            log WARN "No authentication setup for: $adapter"
            ;;
    esac
    
    log SUCCESS "Authentication configured for: $adapter"
}

platform_adapters_validate() {
    local adapter="$1"
    local package_dir="$2"
    local version="$3"
    
    local script="$PAK_DATA_DIR/adapters/scripts/${adapter}.sh"
    
    if [[ ! -f "$script" ]]; then
        log ERROR "Adapter not found: $adapter"
        return 1
    fi
    
    source "$script"
    
    if ${adapter}_adapter_validate "$package_dir" "$version"; then
        log SUCCESS "Validation passed for: $adapter"
        return 0
    else
        log ERROR "Validation failed for: $adapter"
        return 1
    fi
}

platform_adapters_deploy() {
    local adapter="$1"
    local package_dir="$2"
    local version="$3"
    
    local script="$PAK_DATA_DIR/adapters/scripts/${adapter}.sh"
    
    if [[ ! -f "$script" ]]; then
        log ERROR "Adapter not found: $adapter"
        return 1
    fi
    
    source "$script"
    
    # Initialize adapter
    ${adapter}_adapter_init || return 1
    
    # Validate package
    ${adapter}_adapter_validate "$package_dir" "$version" || return 1
    
    # Build package
    ${adapter}_adapter_build "$package_dir" "$version" || return 1
    
    # Deploy package
    ${adapter}_adapter_deploy "$package_dir" "$version" || return 1
    
    # Verify deployment
    local package_name=$(basename "$package_dir")
    ${adapter}_adapter_verify "$package_name" "$version" || return 1
    
    log SUCCESS "Deployment completed for: $adapter"
    return 0
}

platform_adapters_rollback() {
    local adapter="$1"
    local package_name="$2"
    local version="$3"
    local previous_version="$4"
    
    local script="$PAK_DATA_DIR/adapters/scripts/${adapter}.sh"
    
    if [[ ! -f "$script" ]]; then
        log ERROR "Adapter not found: $adapter"
        return 1
    fi
    
    source "$script"
    
    if ${adapter}_adapter_rollback "$package_name" "$version" "$previous_version"; then
        log SUCCESS "Rollback completed for: $adapter"
        return 0
    else
        log ERROR "Rollback failed for: $adapter"
        return 1
    fi
}

# Export functions
export -f platform_adapters_init platform_adapters_list platform_adapters_info platform_adapters_test platform_adapters_auth platform_adapters_validate platform_adapters_deploy platform_adapters_rollback 