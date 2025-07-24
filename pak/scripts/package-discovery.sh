#!/bin/bash
# Advanced Package Discovery Script for PAK.sh
# Implements intelligent package discovery across 30+ platforms

# Configuration
DISCOVERY_VERSION="1.0.0"
DISCOVERY_CACHE_DIR="$PAK_DATA_DIR/discovery/cache"
DISCOVERY_RESULTS_DIR="$PAK_DATA_DIR/discovery/results"
DISCOVERY_TEMP_DIR="$PAK_DATA_DIR/discovery/temp"

# Platform-specific discovery patterns
declare -A DISCOVERY_PATTERNS
DISCOVERY_PATTERNS=(
    # Node.js ecosystem
    ["npm"]="package.json|package-lock.json|yarn.lock|pnpm-lock.yaml"
    ["yarn"]="yarn.lock|package.json"
    ["pnpm"]="pnpm-lock.yaml|package.json"
    
    # Python ecosystem
    ["pypi"]="setup.py|pyproject.toml|requirements.txt|Pipfile|poetry.lock"
    ["pipenv"]="Pipfile|Pipfile.lock"
    ["poetry"]="pyproject.toml|poetry.lock"
    ["conda"]="environment.yml|environment.yaml|meta.yaml"
    
    # Rust ecosystem
    ["cargo"]="Cargo.toml|Cargo.lock"
    ["crates"]="Cargo.toml"
    
    # Java ecosystem
    ["maven"]="pom.xml|mvnw|mvnw.cmd"
    ["gradle"]="build.gradle|build.gradle.kts|gradlew|gradlew.bat"
    ["ant"]="build.xml"
    
    # .NET ecosystem
    ["nuget"]="*.csproj|*.vbproj|*.fsproj|packages.config|*.nuspec"
    ["dotnet"]="*.csproj|*.vbproj|*.fsproj"
    
    # PHP ecosystem
    ["composer"]="composer.json|composer.lock"
    
    # Ruby ecosystem
    ["gem"]="Gemfile|Gemfile.lock|*.gemspec"
    ["bundler"]="Gemfile|Gemfile.lock"
    
    # Elixir ecosystem
    ["hex"]="mix.exs|mix.lock"
    
    # Dart ecosystem
    ["pub"]="pubspec.yaml|pubspec.lock"
    
    # Go ecosystem
    ["go"]="go.mod|go.sum"
    
    # Perl ecosystem
    ["cpan"]="Makefile.PL|Build.PL|META.json|META.yml|cpanfile"
    
    # R ecosystem
    ["cran"]="DESCRIPTION|NAMESPACE"
    
    # Haskell ecosystem
    ["hackage"]="*.cabal|stack.yaml"
    ["stack"]="stack.yaml|*.cabal"
    
    # C/C++ ecosystem
    ["vcpkg"]="vcpkg.json|vcpkg-configuration.json"
    ["conan"]="conanfile.py|conanfile.txt"
    ["spack"]="package.py|spack.yaml"
    
    # Package managers
    ["brew"]="Formula/*.rb|Cask/*.rb"
    ["chocolatey"]="*.nuspec"
    ["scoop"]="*.json"
    ["flatpak"]="*.yml|*.yaml"
    ["snap"]="snapcraft.yaml"
    ["appimage"]="AppDir|*.AppImage"
    
    # Container ecosystem
    ["docker"]="Dockerfile|docker-compose.yml|docker-compose.yaml"
    ["helm"]="Chart.yaml|values.yaml"
    
    # Infrastructure as Code
    ["terraform"]="*.tf|*.tfvars"
    ["ansible"]="*.yml|*.yaml|inventory"
    ["puppet"]="Puppetfile|*.pp"
    ["chef"]="Berksfile|*.rb"
)

# Package name extraction patterns
declare -A NAME_EXTRACTION_PATTERNS
NAME_EXTRACTION_PATTERNS=(
    ["npm"]="\"name\":\\s*\"([^\"]+)\""
    ["pypi"]="name\\s*=\\s*[\"']([^\"']+)[\"']|name\\s*=\\s*\"([^\"]+)\""
    ["cargo"]="name\\s*=\\s*\"([^\"]+)\""
    ["maven"]="<artifactId>([^<]+)</artifactId>"
    ["gradle"]="group\\s*=\\s*[\"']([^\"']+)[\"']|name\\s*=\\s*[\"']([^\"']+)[\"']"
    ["nuget"]="<PackageId>([^<]+)</PackageId>|<PackageReference\\s+Include=\"([^\"]+)\""
    ["composer"]="\"name\":\\s*\"([^\"]+)\""
    ["gem"]="spec\\.name\\s*=\\s*[\"']([^\"']+)[\"']|gem\\s+[\"']([^\"']+)[\"']"
    ["hex"]="def\\s+project\\s+do\\s+[^}]*app:\\s*:([^,]+)"
    ["pub"]="name:\\s*([^\\n]+)"
    ["go"]="module\\s+([^\\s]+)"
    ["cpan"]="name\\s*=>\\s*[\"']([^\"']+)[\"']"
    ["cran"]="Package:\\s*([^\\n]+)"
    ["hackage"]="name:\\s*([^\\n]+)"
    ["vcpkg"]="\"name\":\\s*\"([^\"]+)\""
    ["conan"]="name\\s*=\\s*[\"']([^\"']+)[\"']"
    ["spack"]="class\\s+([^(]+)"
    ["brew"]="class\\s+([^<]+)"
    ["chocolatey"]="<id>([^<]+)</id>"
    ["scoop"]="\"name\":\\s*\"([^\"]+)\""
    ["flatpak"]="id:\\s*([^\\n]+)"
    ["snap"]="name:\\s*([^\\n]+)"
    ["docker"]="#\\s*([^\\s]+)"
    ["helm"]="name:\\s*([^\\n]+)"
    ["terraform"]="module\\s+\"([^\"]+)\""
    ["ansible"]="name:\\s*([^\\n]+)"
)

# Initialize discovery system
init_discovery() {
    mkdir -p "$DISCOVERY_CACHE_DIR"
    mkdir -p "$DISCOVERY_RESULTS_DIR"
    mkdir -p "$DISCOVERY_TEMP_DIR"
    
    log INFO "Package discovery system initialized"
}

# Main discovery function
discover_packages() {
    local source="$1"
    local options="$2"
    
    case "$source" in
        github)
            discover_github_packages "$options"
            ;;
        local)
            discover_local_packages "$options"
            ;;
        platform)
            discover_platform_packages "$options"
            ;;
        api)
            discover_api_packages "$options"
            ;;
        *)
            log ERROR "Invalid discovery source: $source"
            return 1
            ;;
    esac
}

# Discover packages from GitHub repositories
discover_github_packages() {
    local username="$1"
    local options="$2"
    
    log INFO "Starting GitHub discovery for user: $username"
    
    # Check GitHub CLI availability
    if ! command -v gh &> /dev/null; then
        log ERROR "GitHub CLI (gh) not found. Please install it first."
        return 1
    fi
    
    # Get user repositories
    local repos=$(gh api users/$username/repos --jq '.[].full_name' --paginate 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log ERROR "Failed to fetch repositories for user: $username"
        return 1
    fi
    
    local total_repos=$(echo "$repos" | wc -l)
    local discovered_count=0
    local current=0
    
    log INFO "Found $total_repos repositories to scan"
    
    # Process repositories in parallel batches
    echo "$repos" | xargs -P 5 -I {} bash -c '
        repo="$1"
        current="$2"
        total="$3"
        options="$4"
        
        echo "Scanning repository $current/$total: $repo"
        
        # Clone repository temporarily
        temp_dir=$(mktemp -d)
        if git clone --depth 1 "https://github.com/$repo.git" "$temp_dir" 2>/dev/null; then
            packages=$(scan_repository_for_packages "$temp_dir" "$repo" "$options")
            if [[ -n "$packages" ]]; then
                echo "$packages" >> "$DISCOVERY_TEMP_DIR/github_${username}_packages.json"
                echo "Found packages in $repo"
            fi
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
    ' _ {} $((++current)) $total_repos "$options"
    
    # Combine results
    if [[ -f "$DISCOVERY_TEMP_DIR/github_${username}_packages.json" ]]; then
        local results_file="$DISCOVERY_RESULTS_DIR/github_${username}_$(date +%Y%m%d_%H%M%S).json"
        echo '{"username": "'$username'", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "packages": [' > "$results_file"
        cat "$DISCOVERY_TEMP_DIR/github_${username}_packages.json" | tr '\n' ',' | sed 's/,$//' >> "$results_file"
        echo ']}' >> "$results_file"
        
        local discovered_count=$(jq '.packages | length' "$results_file")
        log SUCCESS "GitHub discovery completed. Found $discovered_count packages in $total_repos repositories"
        log INFO "Results saved to: $results_file"
    else
        log WARN "No packages found in any repositories"
    fi
}

# Scan repository for packages
scan_repository_for_packages() {
    local directory="$1"
    local repo_name="$2"
    local options="$3"
    local packages=()
    
    # Scan for package files
    for platform in "${!DISCOVERY_PATTERNS[@]}"; do
        local pattern="${DISCOVERY_PATTERNS[$platform]}"
        local files=$(find "$directory" -type f \( -name "package.json" -o -name "setup.py" -o -name "Cargo.toml" -o -name "pom.xml" -o -name "*.csproj" -o -name "composer.json" -o -name "Gemfile" -o -name "mix.exs" -o -name "pubspec.yaml" -o -name "go.mod" -o -name "Makefile.PL" -o -name "DESCRIPTION" -o -name "*.cabal" -o -name "vcpkg.json" -o -name "conanfile.py" -o -name "package.py" -o -name "Formula/*.rb" -o -name "*.nuspec" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "Dockerfile" -o -name "Chart.yaml" -o -name "*.tf" \) 2>/dev/null)
        
        for file in $files; do
            local package_name=$(extract_package_name_from_file "$file" "$platform")
            if [[ -n "$package_name" ]]; then
                local package_info=$(create_package_info "$package_name" "$platform" "$file" "$repo_name")
                packages+=("$package_info")
            fi
        done
    done
    
    echo "${packages[*]}"
}

# Extract package name from file
extract_package_name_from_file() {
    local file="$1"
    local platform="$2"
    local pattern="${NAME_EXTRACTION_PATTERNS[$platform]}"
    
    if [[ -n "$pattern" ]] && [[ -f "$file" ]]; then
        local name=$(grep -oE "$pattern" "$file" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -z "$name" ]]; then
            # Try alternative extraction methods
            case "$platform" in
                npm)
                    name=$(jq -r '.name // empty' "$file" 2>/dev/null)
                    ;;
                pypi)
                    name=$(python3 -c "import ast; print(ast.literal_eval(open('$file').read()).get('name', ''))" 2>/dev/null)
                    ;;
                cargo)
                    name=$(grep -o 'name\s*=\s*"[^"]*"' "$file" | head -1 | sed 's/name\s*=\s*"\([^"]*\)"/\1/')
                    ;;
                *)
                    # Generic extraction
                    name=$(grep -i "name\|title\|id" "$file" | head -1 | sed -E 's/.*[nN]ame\s*[=:]\s*["'\'']?([^"'\''\s]+)["'\''\s]?.*/\1/')
                    ;;
            esac
        fi
        
        echo "$name"
    fi
}

# Create package information object
create_package_info() {
    local name="$1"
    local platform="$2"
    local file="$3"
    local repo="$4"
    
    local relative_path=$(realpath --relative-to="$DISCOVERY_TEMP_DIR" "$file")
    
    cat <<EOF
{
    "name": "$name",
    "platform": "$platform",
    "file_path": "$relative_path",
    "repository": "$repo",
    "discovered_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "file_size": "$(stat -c%s "$file" 2>/dev/null || echo "0")",
    "file_hash": "$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "")"
}
EOF
}

# Discover packages from local directory
discover_local_packages() {
    local directory="${1:-.}"
    local options="$2"
    
    log INFO "Starting local discovery in directory: $directory"
    
    if [[ ! -d "$directory" ]]; then
        log ERROR "Directory does not exist: $directory"
        return 1
    fi
    
    local results_file="$DISCOVERY_RESULTS_DIR/local_$(date +%Y%m%d_%H%M%S).json"
    local packages=()
    
    # Scan for package files
    for platform in "${!DISCOVERY_PATTERNS[@]}"; do
        local pattern="${DISCOVERY_PATTERNS[$platform]}"
        local files=$(find "$directory" -type f \( -name "package.json" -o -name "setup.py" -o -name "Cargo.toml" -o -name "pom.xml" -o -name "*.csproj" -o -name "composer.json" -o -name "Gemfile" -o -name "mix.exs" -o -name "pubspec.yaml" -o -name "go.mod" -o -name "Makefile.PL" -o -name "DESCRIPTION" -o -name "*.cabal" -o -name "vcpkg.json" -o -name "conanfile.py" -o -name "package.py" -o -name "Formula/*.rb" -o -name "*.nuspec" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "Dockerfile" -o -name "Chart.yaml" -o -name "*.tf" \) 2>/dev/null)
        
        for file in $files; do
            local package_name=$(extract_package_name_from_file "$file" "$platform")
            if [[ -n "$package_name" ]]; then
                local package_info=$(create_package_info "$package_name" "$platform" "$file" "local")
                packages+=("$package_info")
                log INFO "Found package: $package_name ($platform) in $file"
            fi
        done
    done
    
    # Save results
    echo '{"directory": "'$directory'", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "packages": [' > "$results_file"
    if [[ ${#packages[@]} -gt 0 ]]; then
        printf '%s\n' "${packages[@]}" | tr '\n' ',' | sed 's/,$//' >> "$results_file"
    fi
    echo ']}' >> "$results_file"
    
    local discovered_count=${#packages[@]}
    log SUCCESS "Local discovery completed. Found $discovered_count packages"
    log INFO "Results saved to: $results_file"
}

# Discover packages from platform APIs
discover_platform_packages() {
    local platform="$1"
    local username="$2"
    local options="$3"
    
    log INFO "Starting platform discovery for $platform user: $username"
    
    case "$platform" in
        npm)
            discover_npm_packages "$username" "$options"
            ;;
        pypi)
            discover_pypi_packages "$username" "$options"
            ;;
        crates)
            discover_crates_packages "$username" "$options"
            ;;
        maven)
            discover_maven_packages "$username" "$options"
            ;;
        nuget)
            discover_nuget_packages "$username" "$options"
            ;;
        composer)
            discover_composer_packages "$username" "$options"
            ;;
        gem)
            discover_gem_packages "$username" "$options"
            ;;
        *)
            log ERROR "Platform discovery not implemented for: $platform"
            return 1
            ;;
    esac
}

# Discover npm packages
discover_npm_packages() {
    local username="$1"
    local options="$2"
    
    log INFO "Discovering npm packages for user: $username"
    
    # Use npm registry API
    local api_url="https://registry.npmjs.org/-/user/$username/package"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local packages=$(echo "$response" | jq -r '.[] | @json' 2>/dev/null)
        local results_file="$DISCOVERY_RESULTS_DIR/npm_${username}_$(date +%Y%m%d_%H%M%S).json"
        
        echo '{"platform": "npm", "username": "'$username'", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "packages": [' > "$results_file"
        if [[ -n "$packages" ]]; then
            echo "$packages" | tr '\n' ',' | sed 's/,$//' >> "$results_file"
        fi
        echo ']}' >> "$results_file"
        
        local discovered_count=$(echo "$packages" | wc -l)
        log SUCCESS "NPM discovery completed. Found $discovered_count packages"
        log INFO "Results saved to: $results_file"
    else
        log ERROR "Failed to fetch npm packages for user: $username"
        return 1
    fi
}

# Discover PyPI packages
discover_pypi_packages() {
    local username="$1"
    local options="$2"
    
    log INFO "Discovering PyPI packages for user: $username"
    
    # PyPI doesn't have a direct user API, so we'll search by maintainer
    local api_url="https://pypi.org/pypi"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    # This is a simplified approach - PyPI discovery is more complex
    log WARN "PyPI user-based discovery is limited. Consider using local discovery instead."
    
    local results_file="$DISCOVERY_RESULTS_DIR/pypi_${username}_$(date +%Y%m%d_%H%M%S).json"
    echo '{"platform": "pypi", "username": "'$username'", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "packages": []}' > "$results_file"
    
    log INFO "PyPI discovery completed. Results saved to: $results_file"
}

# Discover crates.io packages
discover_crates_packages() {
    local username="$1"
    local options="$2"
    
    log INFO "Discovering crates.io packages for user: $username"
    
    # Use crates.io API
    local api_url="https://crates.io/api/v1/users/$username/crates"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local packages=$(echo "$response" | jq -r '.crates[] | @json' 2>/dev/null)
        local results_file="$DISCOVERY_RESULTS_DIR/crates_${username}_$(date +%Y%m%d_%H%M%S).json"
        
        echo '{"platform": "crates", "username": "'$username'", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'", "packages": [' > "$results_file"
        if [[ -n "$packages" ]]; then
            echo "$packages" | tr '\n' ',' | sed 's/,$//' >> "$results_file"
        fi
        echo ']}' >> "$results_file"
        
        local discovered_count=$(echo "$packages" | wc -l)
        log SUCCESS "Crates.io discovery completed. Found $discovered_count packages"
        log INFO "Results saved to: $results_file"
    else
        log ERROR "Failed to fetch crates.io packages for user: $username"
        return 1
    fi
}

# Discover packages from API endpoints
discover_api_packages() {
    local api_url="$1"
    local options="$2"
    
    log INFO "Starting API discovery from: $api_url"
    
    local response=$(curl -s "$api_url" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local results_file="$DISCOVERY_RESULTS_DIR/api_$(date +%Y%m%d_%H%M%S).json"
        echo "$response" > "$results_file"
        
        log SUCCESS "API discovery completed"
        log INFO "Results saved to: $results_file"
    else
        log ERROR "Failed to fetch data from API: $api_url"
        return 1
    fi
}

# Analyze discovery results
analyze_discovery_results() {
    local results_file="$1"
    
    if [[ ! -f "$results_file" ]]; then
        log ERROR "Results file not found: $results_file"
        return 1
    fi
    
    log INFO "Analyzing discovery results: $results_file"
    
    local total_packages=$(jq '.packages | length' "$results_file" 2>/dev/null)
    local platforms=$(jq -r '.packages[].platform' "$results_file" 2>/dev/null | sort | uniq -c)
    local repositories=$(jq -r '.packages[].repository' "$results_file" 2>/dev/null | sort | uniq -c)
    
    echo "📊 Discovery Analysis"
    echo "===================="
    echo "Total packages found: $total_packages"
    echo ""
    echo "Platforms distribution:"
    echo "$platforms"
    echo ""
    echo "Repositories distribution:"
    echo "$repositories"
}

# Export discovery results
export_discovery_results() {
    local results_file="$1"
    local format="${2:-json}"
    
    if [[ ! -f "$results_file" ]]; then
        log ERROR "Results file not found: $results_file"
        return 1
    fi
    
    case "$format" in
        json)
            # Already in JSON format
            echo "$results_file"
            ;;
        csv)
            local csv_file="${results_file%.json}.csv"
            jq -r '.packages[] | [.name, .platform, .repository, .discovered_at] | @csv' "$results_file" > "$csv_file"
            echo "$csv_file"
            ;;
        yaml)
            local yaml_file="${results_file%.json}.yaml"
            jq -r '.' "$results_file" | yq eval -P > "$yaml_file"
            echo "$yaml_file"
            ;;
        *)
            log ERROR "Unsupported export format: $format"
            return 1
            ;;
    esac
    
    log SUCCESS "Results exported to: $format format"
}

# Clean up discovery cache
cleanup_discovery_cache() {
    log INFO "Cleaning up discovery cache"
    
    # Remove temporary files older than 24 hours
    find "$DISCOVERY_TEMP_DIR" -type f -mtime +1 -delete 2>/dev/null
    
    # Remove cache files older than 7 days
    find "$DISCOVERY_CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null
    
    log SUCCESS "Discovery cache cleaned up"
}

# Main function
main() {
    local command="$1"
    local args="${@:2}"
    
    # Initialize discovery system
    init_discovery
    
    case "$command" in
        github)
            discover_github_packages "$args"
            ;;
        local)
            discover_local_packages "$args"
            ;;
        platform)
            discover_platform_packages "$args"
            ;;
        api)
            discover_api_packages "$args"
            ;;
        analyze)
            analyze_discovery_results "$args"
            ;;
        export)
            export_discovery_results "$args"
            ;;
        cleanup)
            cleanup_discovery_cache
            ;;
        *)
            echo "Usage: $0 {github|local|platform|api|analyze|export|cleanup} [args...]"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 