#!/bin/bash
# Enhanced Platform Module - Multi-platform package management with 30+ platforms

platform_init() {
    # Create platform configurations directory
    mkdir -p "$PAK_CONFIG_DIR/platforms"
    
    # Create platform configurations
    platform_create_configs
    
    # Initialize platform health monitoring
    platform_init_health_monitoring
    
    log INFO "Platform module initialized with 30+ platform support"
}

platform_register_commands() {
    register_command "platforms" "platform" "platform_list"
    register_command "platform-info" "platform" "platform_info"
    register_command "platform-add" "platform" "platform_add"
    register_command "platform-health" "platform" "platform_health_check"
    register_command "platform-test" "platform" "platform_test_connection"
    register_command "platform-config" "platform" "platform_show_config"
    register_command "platform-update" "platform" "platform_update_config"
    register_command "platform-validate" "platform" "platform_validate_config"
}

platform_create_configs() {
    # JavaScript/TypeScript Platforms
    platform_create_npm_config
    platform_create_yarn_config
    platform_create_jsr_config
    platform_create_deno_config
    platform_create_unpkg_config
    platform_create_jsdelivr_config
    
    # Python Platforms
    platform_create_pypi_config
    platform_create_conda_config
    platform_create_pip_config
    
    # Rust Platforms
    platform_create_cargo_config
    platform_create_crates_config
    
    # Go Platforms
    platform_create_go_config
    platform_create_goproxy_config
    
    # Java Platforms
    platform_create_maven_config
    platform_create_gradle_config
    platform_create_jcenter_config
    
    # PHP Platforms
    platform_create_composer_config
    platform_create_packagist_config
    
    # Ruby Platforms
    platform_create_rubygems_config
    platform_create_bundler_config
    
    # .NET Platforms
    platform_create_nuget_config
    platform_create_dotnet_config
    
    # Docker Platforms
    platform_create_dockerhub_config
    platform_create_quay_config
    platform_create_ghcr_config
    
    # Container Platforms
    platform_create_helm_config
    platform_create_chartmuseum_config
    
    # Mobile Platforms
    platform_create_cocoapods_config
    platform_create_gradle_android_config
    
    # Cloud Platforms
    platform_create_aws_config
    platform_create_azure_config
    platform_create_gcp_config
    
    # Infrastructure Platforms
    platform_create_terraform_config
    platform_create_ansible_config
    
    # Documentation Platforms
    platform_create_readthedocs_config
    platform_create_docusaurus_config
    
    log INFO "Created configurations for 30+ platforms"
}

# JavaScript/TypeScript Platform Configurations
platform_create_npm_config() {
    cat > "$PAK_CONFIG_DIR/platforms/npm.json" << 'EOF'
{
    "name": "npm",
    "type": "javascript",
    "language": "javascript",
    "registry": "https://registry.npmjs.org",
    "api": "https://api.npmjs.org",
    "health_endpoint": "https://registry.npmjs.org/-/ping",
    "commands": {
        "publish": "npm publish",
        "info": "npm view {package}",
        "versions": "npm view {package} versions",
        "install": "npm install",
        "build": "npm run build",
        "test": "npm test"
    },
    "files": {
        "required": ["package.json"],
        "optional": ["README.md", "LICENSE", ".npmignore", "tsconfig.json"]
    },
    "authentication": {
        "type": "token",
        "env_var": "NPM_TOKEN",
        "config_key": "//registry.npmjs.org/:_authToken"
    },
    "version_management": {
        "file": "package.json",
        "field": "version",
        "update_command": "npm version {version} --no-git-tag-version"
    },
    "deployment": {
        "pre_hooks": ["npm install", "npm test", "npm run build"],
        "publish_flags": ["--access", "public"],
        "rollback_support": true
    },
    "monitoring": {
        "download_stats": "https://api.npmjs.org/downloads/point/last-month/{package}",
        "version_stats": "https://api.npmjs.org/downloads/range/last-week/{package}"
    }
}
EOF
}

platform_create_yarn_config() {
    cat > "$PAK_CONFIG_DIR/platforms/yarn.json" << 'EOF'
{
    "name": "yarn",
    "type": "javascript",
    "language": "javascript",
    "registry": "https://registry.yarnpkg.com",
    "api": "https://api.npmjs.org",
    "health_endpoint": "https://registry.yarnpkg.com/-/ping",
    "commands": {
        "publish": "yarn publish",
        "info": "yarn info {package}",
        "versions": "yarn info {package} versions",
        "install": "yarn install",
        "build": "yarn build",
        "test": "yarn test"
    },
    "files": {
        "required": ["package.json"],
        "optional": ["README.md", "LICENSE", ".yarnignore", "yarn.lock"]
    },
    "authentication": {
        "type": "token",
        "env_var": "NPM_TOKEN",
        "config_key": "//registry.npmjs.org/:_authToken"
    },
    "version_management": {
        "file": "package.json",
        "field": "version",
        "update_command": "yarn version --new-version {version} --no-git-tag"
    },
    "deployment": {
        "pre_hooks": ["yarn install", "yarn test", "yarn build"],
        "publish_flags": ["--access", "public"],
        "rollback_support": true
    }
}
EOF
}

platform_create_jsr_config() {
    cat > "$PAK_CONFIG_DIR/platforms/jsr.json" << 'EOF'
{
    "name": "jsr",
    "type": "javascript",
    "language": "typescript",
    "registry": "https://jsr.io",
    "api": "https://jsr.io/api",
    "health_endpoint": "https://jsr.io/api/health",
    "commands": {
        "publish": "jsr publish",
        "info": "jsr info {package}",
        "versions": "jsr info {package} --versions",
        "install": "jsr install",
        "build": "deno run --allow-all build.ts",
        "test": "deno test"
    },
    "files": {
        "required": ["deno.json", "mod.ts"],
        "optional": ["README.md", "LICENSE", "deps.ts"]
    },
    "authentication": {
        "type": "token",
        "env_var": "JSR_TOKEN",
        "config_key": "jsr_token"
    },
    "version_management": {
        "file": "deno.json",
        "field": "version",
        "update_command": "deno run --allow-all scripts/update-version.ts {version}"
    },
    "deployment": {
        "pre_hooks": ["deno install", "deno test", "deno run --allow-all build.ts"],
        "publish_flags": [],
        "rollback_support": true
    }
}
EOF
}

platform_create_pypi_config() {
    cat > "$PAK_CONFIG_DIR/platforms/pypi.json" << 'EOF'
{
    "name": "pypi",
    "type": "python",
    "language": "python",
    "registry": "https://pypi.org",
    "api": "https://pypi.org/pypi/{package}/json",
    "health_endpoint": "https://pypi.org/health",
    "commands": {
        "publish": "twine upload dist/*",
        "info": "pip show {package}",
        "versions": "pip index versions {package}",
        "install": "pip install -e .",
        "build": "python -m build",
        "test": "python -m pytest"
    },
    "files": {
        "required": ["setup.py", "pyproject.toml"],
        "optional": ["README.md", "LICENSE", "MANIFEST.in", "requirements.txt"]
    },
    "authentication": {
        "type": "token",
        "env_var": "PYPI_TOKEN",
        "config_key": "pypi_token"
    },
    "version_management": {
        "file": "pyproject.toml",
        "field": "version",
        "update_command": "poetry version {version}"
    },
    "deployment": {
        "pre_hooks": ["pip install -e .", "python -m pytest", "python -m build"],
        "publish_flags": [],
        "rollback_support": true
    }
}
EOF
}

platform_create_cargo_config() {
    cat > "$PAK_CONFIG_DIR/platforms/cargo.json" << 'EOF'
{
    "name": "cargo",
    "type": "rust",
    "language": "rust",
    "registry": "https://crates.io",
    "api": "https://crates.io/api/v1/crates/{package}",
    "health_endpoint": "https://crates.io/api/v1/summary",
    "commands": {
        "publish": "cargo publish",
        "info": "cargo search {package}",
        "versions": "cargo search {package} --limit 100",
        "install": "cargo build",
        "build": "cargo build --release",
        "test": "cargo test"
    },
    "files": {
        "required": ["Cargo.toml", "src/lib.rs"],
        "optional": ["README.md", "LICENSE", "Cargo.lock"]
    },
    "authentication": {
        "type": "token",
        "env_var": "CARGO_TOKEN",
        "config_key": "cargo_token"
    },
    "version_management": {
        "file": "Cargo.toml",
        "field": "version",
        "update_command": "cargo set-version {version}"
    },
    "deployment": {
        "pre_hooks": ["cargo build", "cargo test", "cargo build --release"],
        "publish_flags": [],
        "rollback_support": true
    }
}
EOF
}

platform_create_dockerhub_config() {
    cat > "$PAK_CONFIG_DIR/platforms/dockerhub.json" << 'EOF'
{
    "name": "dockerhub",
    "type": "container",
    "language": "docker",
    "registry": "https://hub.docker.com",
    "api": "https://hub.docker.com/v2/repositories/{package}",
    "health_endpoint": "https://hub.docker.com/v2/",
    "commands": {
        "publish": "docker push {package}:{version}",
        "info": "docker inspect {package}",
        "versions": "docker images {package}",
        "install": "docker pull {package}",
        "build": "docker build -t {package}:{version} .",
        "test": "docker run --rm {package}:{version} test"
    },
    "files": {
        "required": ["Dockerfile"],
        "optional": ["README.md", "LICENSE", ".dockerignore", "docker-compose.yml"]
    },
    "authentication": {
        "type": "login",
        "env_var": "DOCKER_USERNAME",
        "password_var": "DOCKER_PASSWORD",
        "login_command": "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
    },
    "version_management": {
        "file": "Dockerfile",
        "field": "LABEL version",
        "update_command": "sed -i 's/LABEL version=\".*\"/LABEL version=\"{version}\"/' Dockerfile"
    },
    "deployment": {
        "pre_hooks": ["docker build -t {package}:{version} .", "docker run --rm {package}:{version} test"],
        "publish_flags": [],
        "rollback_support": true
    }
}
EOF
}

# Add more platform configurations...
platform_create_conda_config() {
    cat > "$PAK_CONFIG_DIR/platforms/conda.json" << 'EOF'
{
    "name": "conda",
    "type": "python",
    "language": "python",
    "registry": "https://anaconda.org",
    "api": "https://api.anaconda.org/package/{package}",
    "health_endpoint": "https://api.anaconda.org/health",
    "commands": {
        "publish": "anaconda upload dist/*",
        "info": "conda search {package}",
        "versions": "conda search {package} --info",
        "install": "conda install {package}",
        "build": "conda build .",
        "test": "conda build --test ."
    },
    "files": {
        "required": ["meta.yaml", "build.sh"],
        "optional": ["README.md", "LICENSE", "recipe/"]
    },
    "authentication": {
        "type": "token",
        "env_var": "ANACONDA_TOKEN",
        "config_key": "anaconda_token"
    }
}
EOF
}

platform_create_maven_config() {
    cat > "$PAK_CONFIG_DIR/platforms/maven.json" << 'EOF'
{
    "name": "maven",
    "type": "java",
    "language": "java",
    "registry": "https://repo1.maven.org/maven2",
    "api": "https://search.maven.org/solrsearch/select?q=g:{group}+AND+a:{artifact}",
    "health_endpoint": "https://repo1.maven.org/maven2/",
    "commands": {
        "publish": "mvn deploy",
        "info": "mvn dependency:get -Dartifact={package}",
        "versions": "mvn versions:display-dependency-updates",
        "install": "mvn install",
        "build": "mvn clean package",
        "test": "mvn test"
    },
    "files": {
        "required": ["pom.xml"],
        "optional": ["README.md", "LICENSE", "src/"]
    },
    "authentication": {
        "type": "settings",
        "env_var": "MAVEN_SETTINGS",
        "config_file": "~/.m2/settings.xml"
    }
}
EOF
}

platform_create_composer_config() {
    cat > "$PAK_CONFIG_DIR/platforms/composer.json" << 'EOF'
{
    "name": "composer",
    "type": "php",
    "language": "php",
    "registry": "https://packagist.org",
    "api": "https://packagist.org/packages/{package}.json",
    "health_endpoint": "https://packagist.org/",
    "commands": {
        "publish": "composer publish",
        "info": "composer show {package}",
        "versions": "composer show {package} --all",
        "install": "composer install",
        "build": "composer build",
        "test": "composer test"
    },
    "files": {
        "required": ["composer.json"],
        "optional": ["README.md", "LICENSE", "src/"]
    },
    "authentication": {
        "type": "token",
        "env_var": "PACKAGIST_TOKEN",
        "config_key": "packagist_token"
    }
}
EOF
}

# Add remaining platform configurations (simplified for brevity)
platform_create_deno_config() { platform_create_generic_config "deno" "javascript" "typescript"; }
platform_create_unpkg_config() { platform_create_generic_config "unpkg" "javascript" "javascript"; }
platform_create_jsdelivr_config() { platform_create_generic_config "jsdelivr" "javascript" "javascript"; }
platform_create_pip_config() { platform_create_generic_config "pip" "python" "python"; }
platform_create_crates_config() { platform_create_generic_config "crates" "rust" "rust"; }
platform_create_go_config() { platform_create_generic_config "go" "go" "go"; }
platform_create_goproxy_config() { platform_create_generic_config "goproxy" "go" "go"; }
platform_create_gradle_config() { platform_create_generic_config "gradle" "java" "java"; }
platform_create_jcenter_config() { platform_create_generic_config "jcenter" "java" "java"; }
platform_create_packagist_config() { platform_create_generic_config "packagist" "php" "php"; }
platform_create_rubygems_config() { platform_create_generic_config "rubygems" "ruby" "ruby"; }
platform_create_bundler_config() { platform_create_generic_config "bundler" "ruby" "ruby"; }
platform_create_nuget_config() { platform_create_generic_config "nuget" "dotnet" "csharp"; }
platform_create_dotnet_config() { platform_create_generic_config "dotnet" "dotnet" "csharp"; }
platform_create_quay_config() { platform_create_generic_config "quay" "container" "docker"; }
platform_create_ghcr_config() { platform_create_generic_config "ghcr" "container" "docker"; }
platform_create_helm_config() { platform_create_generic_config "helm" "kubernetes" "yaml"; }
platform_create_chartmuseum_config() { platform_create_generic_config "chartmuseum" "kubernetes" "yaml"; }
platform_create_cocoapods_config() { platform_create_generic_config "cocoapods" "mobile" "swift"; }
platform_create_gradle_android_config() { platform_create_generic_config "gradle_android" "mobile" "java"; }
platform_create_aws_config() { platform_create_generic_config "aws" "cloud" "terraform"; }
platform_create_azure_config() { platform_create_generic_config "azure" "cloud" "terraform"; }
platform_create_gcp_config() { platform_create_generic_config "gcp" "cloud" "terraform"; }
platform_create_terraform_config() { platform_create_generic_config "terraform" "infrastructure" "hcl"; }
platform_create_ansible_config() { platform_create_generic_config "ansible" "infrastructure" "yaml"; }
platform_create_readthedocs_config() { platform_create_generic_config "readthedocs" "documentation" "markdown"; }
platform_create_docusaurus_config() { platform_create_generic_config "docusaurus" "documentation" "markdown"; }

platform_create_generic_config() {
    local name="$1"
    local type="$2"
    local language="$3"
    
    cat > "$PAK_CONFIG_DIR/platforms/${name}.json" << EOF
{
    "name": "$name",
    "type": "$type",
    "language": "$language",
    "registry": "https://$name.org",
    "api": "https://api.$name.org",
    "health_endpoint": "https://$name.org/health",
    "commands": {
        "publish": "$name publish",
        "info": "$name info {package}",
        "versions": "$name versions {package}",
        "install": "$name install",
        "build": "$name build",
        "test": "$name test"
    },
    "files": {
        "required": ["package.json"],
        "optional": ["README.md", "LICENSE"]
    },
    "authentication": {
        "type": "token",
        "env_var": "${name^^}_TOKEN"
    },
    "deployment": {
        "pre_hooks": ["$name install", "$name test", "$name build"],
        "publish_flags": [],
        "rollback_support": false
    }
}
EOF
}

platform_init_health_monitoring() {
    mkdir -p "$PAK_DATA_DIR/platform-health"
    mkdir -p "$PAK_LOGS_DIR/platform-health"
    
    # Create health check script
    cat > "$PAK_SCRIPTS_DIR/platform-health-check.sh" << 'EOF'
#!/bin/bash
# Platform health monitoring script

PLATFORM="$1"
CONFIG_FILE="$PAK_CONFIG_DIR/platforms/${PLATFORM}.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Platform not found: $PLATFORM"
    exit 1
fi

HEALTH_ENDPOINT=$(jq -r '.health_endpoint' "$CONFIG_FILE")
if [[ "$HEALTH_ENDPOINT" == "null" ]]; then
    echo "No health endpoint configured for $PLATFORM"
    exit 1
fi

# Test health endpoint
if curl -s --max-time 10 "$HEALTH_ENDPOINT" >/dev/null; then
    echo "OK"
    exit 0
else
    echo "FAILED"
    exit 1
fi
EOF
    chmod +x "$PAK_SCRIPTS_DIR/platform-health-check.sh"
}

platform_list() {
    echo "Available Platforms (30+):"
    echo "=========================="
    
    local count=0
    for config in "$PAK_CONFIG_DIR/platforms"/*.json; do
        [[ -f "$config" ]] || continue
        local name=$(jq -r '.name' "$config")
        local type=$(jq -r '.type' "$config")
        local language=$(jq -r '.language' "$config")
        printf "  %-20s %-15s (%s)\n" "$name" "$type" "$language"
        ((count++))
    done
    
    echo ""
    echo "Total platforms: $count"
}

platform_info() {
    local platform="$1"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Platform not found: $platform"
        return 1
    fi
    
    echo "Platform Information: $platform"
    echo "================================"
    jq . "$config_file"
}

platform_health_check() {
    local platform="${1:-all}"
    
    if [[ "$platform" == "all" ]]; then
        echo "Checking health for all platforms..."
        for config in "$PAK_CONFIG_DIR/platforms"/*.json; do
            [[ -f "$config" ]] || continue
            local name=$(jq -r '.name' "$config")
            echo -n "Checking $name... "
            if "$PAK_SCRIPTS_DIR/platform-health-check.sh" "$name" >/dev/null 2>&1; then
                echo "✅ OK"
            else
                echo "❌ FAILED"
            fi
        done
    else
        echo -n "Checking $platform... "
        if "$PAK_SCRIPTS_DIR/platform-health-check.sh" "$platform" >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAILED"
        fi
    fi
}

platform_test_connection() {
    local platform="$1"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Platform not found: $platform"
        return 1
    fi
    
    local api_endpoint=$(jq -r '.api' "$config_file")
    local registry=$(jq -r '.registry' "$config_file")
    
    echo "Testing connections for $platform:"
    echo "  API: $api_endpoint"
    echo "  Registry: $registry"
    
    # Test API endpoint
    if curl -s --max-time 10 "$api_endpoint" >/dev/null; then
        echo "  ✅ API: OK"
    else
        echo "  ❌ API: FAILED"
    fi
    
    # Test registry
    if curl -s --max-time 10 "$registry" >/dev/null; then
        echo "  ✅ Registry: OK"
    else
        echo "  ❌ Registry: FAILED"
    fi
}

platform_show_config() {
    local platform="$1"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Platform not found: $platform"
        return 1
    fi
    
    cat "$config_file"
}

platform_update_config() {
    local platform="$1"
    local field="$2"
    local value="$3"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Platform not found: $platform"
        return 1
    fi
    
    jq --arg field "$field" --arg value "$value" ".$field = \$value" "$config_file" > temp.json && mv temp.json "$config_file"
    log INFO "Updated $platform configuration: $field = $value"
}

platform_validate_config() {
    local platform="$1"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Platform not found: $platform"
        return 1
    fi
    
    # Validate JSON syntax
    if jq . "$config_file" >/dev/null 2>&1; then
        echo "✅ JSON syntax: Valid"
    else
        echo "❌ JSON syntax: Invalid"
        return 1
    fi
    
    # Validate required fields
    local required_fields=("name" "type" "language" "registry" "api")
    for field in "${required_fields[@]}"; do
        if jq -e ".$field" "$config_file" >/dev/null 2>&1; then
            echo "✅ Required field '$field': Present"
        else
            echo "❌ Required field '$field': Missing"
            return 1
        fi
    done
    
    echo "✅ Configuration validation passed"
}

platform_add() {
    local name="$1"
    local type="$2"
    local language="$3"
    
    if [[ -z "$name" || -z "$type" || -z "$language" ]]; then
        log ERROR "Usage: platform-add <name> <type> <language>"
        return 1
    fi
    
    platform_create_generic_config "$name" "$type" "$language"
    log INFO "Added platform: $name ($type/$language)"
}

platform_get_config() {
    local platform="$1"
    local config_file="$PAK_CONFIG_DIR/platforms/${platform}.json"
    
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        echo "{}"
    fi
}

# Export functions
export -f platform_get_config platform_health_check platform_test_connection

