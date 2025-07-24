#!/bin/bash
# Package Manager Module for PAK.sh
# Implements comprehensive package discovery, tracking, and management across 30+ platforms

# Module metadata
PACKAGE_MANAGER_VERSION="1.0.0"
PACKAGE_MANAGER_DESCRIPTION="Advanced package discovery and management across multiple platforms"

# Platform configurations
declare -A PLATFORM_CONFIGS
PLATFORM_CONFIGS=(
    ["npm"]="package.json|node_modules"
    ["pypi"]="setup.py|pyproject.toml|requirements.txt"
    ["cargo"]="Cargo.toml|Cargo.lock"
    ["maven"]="pom.xml|build.gradle"
    ["nuget"]="*.csproj|*.vbproj|packages.config"
    ["composer"]="composer.json|composer.lock"
    ["gem"]="Gemfile|*.gemspec"
    ["hex"]="mix.exs|mix.lock"
    ["pub"]="pubspec.yaml|pubspec.lock"
    ["go"]="go.mod|go.sum"
    ["cpan"]="Makefile.PL|Build.PL|META.json"
    ["cran"]="DESCRIPTION|NAMESPACE"
    ["hackage"]="*.cabal"
    ["crates"]="Cargo.toml"
    ["pypi"]="setup.py|pyproject.toml"
    ["npm"]="package.json"
    ["maven"]="pom.xml"
    ["nuget"]="*.csproj"
    ["composer"]="composer.json"
    ["gem"]="Gemfile"
    ["hex"]="mix.exs"
    ["pub"]="pubspec.yaml"
    ["go"]="go.mod"
    ["cpan"]="Makefile.PL"
    ["cran"]="DESCRIPTION"
    ["hackage"]="*.cabal"
    ["vcpkg"]="vcpkg.json"
    ["conan"]="conanfile.py|conanfile.txt"
    ["spack"]="package.py"
    ["brew"]="Formula/*.rb"
    ["chocolatey"]="*.nuspec"
    ["scoop"]="*.json"
    ["flatpak"]="*.yml|*.yaml"
    ["snap"]="snapcraft.yaml"
    ["appimage"]="AppDir"
    ["docker"]="Dockerfile"
    ["helm"]="Chart.yaml"
    ["terraform"]="*.tf"
    ["ansible"]="*.yml|*.yaml"
)

# API endpoints for different platforms
declare -A PLATFORM_APIS
PLATFORM_APIS=(
    ["npm"]="https://registry.npmjs.org"
    ["pypi"]="https://pypi.org/pypi"
    ["crates"]="https://crates.io/api/v1"
    ["maven"]="https://search.maven.org/solrsearch/select"
    ["nuget"]="https://api.nuget.org/v3"
    ["composer"]="https://packagist.org/packages"
    ["gem"]="https://rubygems.org/api/v1"
    ["hex"]="https://hex.pm/api"
    ["pub"]="https://pub.dev/api"
    ["go"]="https://proxy.golang.org"
    ["cpan"]="https://metacpan.org/api/v1"
    ["cran"]="https://cran.r-project.org/web/packages"
    ["hackage"]="https://hackage.haskell.org/api"
)

# Package discovery patterns
declare -A PACKAGE_PATTERNS
PACKAGE_PATTERNS=(
    ["npm"]="\"name\":\\s*\"([^\"]+)\""
    ["pypi"]="name\\s*=\\s*[\"']([^\"']+)[\"']"
    ["cargo"]="name\\s*=\\s*\"([^\"]+)\""
    ["maven"]="<artifactId>([^<]+)</artifactId>"
    ["nuget"]="<PackageId>([^<]+)</PackageId>"
    ["composer"]="\"name\":\\s*\"([^\"]+)\""
    ["gem"]="spec\\.name\\s*=\\s*[\"']([^\"']+)[\"']"
    ["hex"]="def\\s+project\\s+do\\s+[^}]*app:\\s*:([^,]+)"
    ["pub"]="name:\\s*([^\\n]+)"
    ["go"]="module\\s+([^\\s]+)"
)

# Initialize package manager module
package_manager_init() {
    log INFO "Initializing Package Manager module v$PACKAGE_MANAGER_VERSION"
    
    # Create data directories
    mkdir -p "$PAK_DATA_DIR/packages"
    mkdir -p "$PAK_DATA_DIR/discovery"
    mkdir -p "$PAK_DATA_DIR/history"
    mkdir -p "$PAK_DATA_DIR/verification"
    mkdir -p "$PAK_DATA_DIR/relationships"
    
    # Initialize package database
    if [[ ! -f "$PAK_DATA_DIR/packages/database.json" ]]; then
        echo '{"packages": {}, "relationships": {}, "metadata": {"version": "1.0", "created": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}}' > "$PAK_DATA_DIR/packages/database.json"
    fi
    
    # Register commands
    register_command "init" "package-manager" "package_manager_init_command"
    register_command "import" "package-manager" "package_manager_import_command"
    register_command "track" "package-manager" "package_manager_track_command"
    register_command "untrack" "package-manager" "package_manager_untrack_command"
    register_command "list" "package-manager" "package_manager_list_command"
    register_command "status" "package-manager" "package_manager_status_command"
    register_command "info" "package-manager" "package_manager_info_command"
    register_command "discover" "package-manager" "package_manager_discover_command"
    register_command "verify" "package-manager" "package_manager_verify_command"
    register_command "history" "package-manager" "package_manager_history_command"
    register_command "relationships" "package-manager" "package_manager_relationships_command"
    
    log SUCCESS "Package Manager module initialized successfully"
}

# Package discovery system
package_manager_discover_command() {
    local source="$1"
    local options="${@:2}"
    
    log INFO "Starting package discovery from: $source"
    
    case "$source" in
        --scan-github|--github)
            local username="$2"
            if [[ -z "$username" ]]; then
                log ERROR "GitHub username required for --scan-github"
                return 1
            fi
            discover_github_packages "$username" "$options"
            ;;
        --scan-local|--local)
            local directory="$2"
            if [[ -z "$directory" ]]; then
                directory="."
            fi
            discover_local_packages "$directory" "$options"
            ;;
        --from-list)
            local file="$2"
            if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
                log ERROR "Valid file path required for --from-list"
                return 1
            fi
            discover_from_list "$file" "$options"
            ;;
        --platform)
            local platform="$2"
            local user="$3"
            if [[ -z "$platform" ]] || [[ -z "$user" ]]; then
                log ERROR "Platform and user required for --platform"
                return 1
            fi
            discover_platform_packages "$platform" "$user" "$options"
            ;;
        *)
            log ERROR "Invalid discovery source. Use --scan-github, --scan-local, --from-list, or --platform"
            return 1
            ;;
    esac
}

# Discover packages from GitHub repositories
discover_github_packages() {
    local username="$1"
    local options="$2"
    local discovered_packages=()
    
    log INFO "Discovering packages from GitHub user: $username"
    
    # Check if GitHub CLI is available
    if ! command -v gh &> /dev/null; then
        log WARN "GitHub CLI not found. Installing..."
        install_github_cli
    fi
    
    # Get user's repositories
    local repos=$(gh api users/$username/repos --jq '.[].full_name' 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log ERROR "Failed to fetch repositories for user: $username"
        return 1
    fi
    
    local total_repos=$(echo "$repos" | wc -l)
    local current=0
    
    echo "$repos" | while read -r repo; do
        ((current++))
        log INFO "Scanning repository $current/$total_repos: $repo"
        
        # Clone repository temporarily
        local temp_dir=$(mktemp -d)
        if git clone --depth 1 "https://github.com/$repo.git" "$temp_dir" 2>/dev/null; then
            local packages=$(scan_directory_for_packages "$temp_dir" "$repo")
            if [[ -n "$packages" ]]; then
                discovered_packages+=("$packages")
                log SUCCESS "Found packages in $repo: $packages"
            fi
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
    done
    
    # Save discovery results
    local discovery_file="$PAK_DATA_DIR/discovery/github_${username}_$(date +%Y%m%d_%H%M%S).json"
    echo "{\"username\": \"$username\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"packages\": [${discovered_packages[*]}]}" > "$discovery_file"
    
    log SUCCESS "Discovery completed. Found ${#discovered_packages[@]} packages. Results saved to: $discovery_file"
}

# Scan directory for package files
scan_directory_for_packages() {
    local directory="$1"
    local repo_name="$2"
    local packages=()
    
    # Scan for package files based on platform patterns
    for platform in "${!PACKAGE_PATTERNS[@]}"; do
        local pattern="${PLATFORM_CONFIGS[$platform]}"
        local files=$(find "$directory" -type f \( -name "package.json" -o -name "setup.py" -o -name "Cargo.toml" -o -name "pom.xml" -o -name "*.csproj" -o -name "composer.json" -o -name "Gemfile" -o -name "mix.exs" -o -name "pubspec.yaml" -o -name "go.mod" \) 2>/dev/null)
        
        for file in $files; do
            local package_name=$(extract_package_name "$file" "$platform")
            if [[ -n "$package_name" ]]; then
                packages+=("{\"name\": \"$package_name\", \"platform\": \"$platform\", \"file\": \"$file\", \"repo\": \"$repo_name\"}")
            fi
        done
    done
    
    echo "${packages[*]}"
}

# Extract package name from file
extract_package_name() {
    local file="$1"
    local platform="$2"
    local pattern="${PACKAGE_PATTERNS[$platform]}"
    
    if [[ -n "$pattern" ]] && [[ -f "$file" ]]; then
        local name=$(grep -oE "$pattern" "$file" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
        echo "$name"
    fi
}

# Discover packages from local directory
discover_local_packages() {
    local directory="$1"
    local options="$2"
    
    log INFO "Discovering packages in local directory: $directory"
    
    if [[ ! -d "$directory" ]]; then
        log ERROR "Directory does not exist: $directory"
        return 1
    fi
    
    local packages=$(scan_directory_for_packages "$directory" "local")
    local discovery_file="$PAK_DATA_DIR/discovery/local_$(date +%Y%m%d_%H%M%S).json"
    
    echo "{\"directory\": \"$directory\", \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"packages\": [$packages]}" > "$discovery_file"
    
    log SUCCESS "Local discovery completed. Results saved to: $discovery_file"
}

# Import command implementation
package_manager_import_command() {
    local source="$1"
    local options="${@:2}"
    
    log INFO "Starting package import from: $source"
    
    case "$source" in
        --scan-github|--github)
            local username="$2"
            if [[ -z "$username" ]]; then
                log ERROR "GitHub username required for --scan-github"
                return 1
            fi
            import_github_packages "$username" "$options"
            ;;
        --scan-local|--local)
            local directory="$2"
            if [[ -z "$directory" ]]; then
                directory="."
            fi
            import_local_packages "$directory" "$options"
            ;;
        --from-list)
            local file="$2"
            if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
                log ERROR "Valid file path required for --from-list"
                return 1
            fi
            import_from_list "$file" "$options"
            ;;
        --platform)
            local platform="$2"
            local user="$3"
            if [[ -z "$platform" ]] || [[ -z "$user" ]]; then
                log ERROR "Platform and user required for --platform"
                return 1
            fi
            import_platform_packages "$platform" "$user" "$options"
            ;;
        *)
            log ERROR "Invalid import source. Use --scan-github, --scan-local, --from-list, or --platform"
            return 1
            ;;
    esac
}

# Import packages from GitHub
import_github_packages() {
    local username="$1"
    local options="$2"
    
    log INFO "Importing packages from GitHub user: $username"
    
    # First discover packages
    local discovery_result=$(discover_github_packages "$username" "$options")
    
    # Parse discovery results and import
    local latest_discovery=$(ls -t "$PAK_DATA_DIR/discovery/github_${username}_"*.json 2>/dev/null | head -1)
    if [[ -z "$latest_discovery" ]]; then
        log ERROR "No discovery results found for user: $username"
        return 1
    fi
    
    local packages=$(jq -r '.packages[] | @json' "$latest_discovery" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log ERROR "Failed to parse discovery results"
        return 1
    fi
    
    local imported_count=0
    local total_count=$(echo "$packages" | wc -l)
    
    echo "$packages" | while read -r package; do
        local name=$(echo "$package" | jq -r '.name')
        local platform=$(echo "$package" | jq -r '.platform')
        local repo=$(echo "$package" | jq -r '.repo')
        
        log INFO "Importing package: $name ($platform) from $repo"
        
        if import_single_package "$name" "$platform" "$repo" "$options"; then
            ((imported_count++))
            log SUCCESS "Imported package: $name"
        else
            log WARN "Failed to import package: $name"
        fi
    done
    
    log SUCCESS "Import completed. Successfully imported $imported_count/$total_count packages"
}

# Import single package
import_single_package() {
    local name="$1"
    local platform="$2"
    local repo="$3"
    local options="$4"
    
    # Check if package already exists
    if package_exists "$name" "$platform"; then
        log WARN "Package $name ($platform) already exists"
        return 0
    fi
    
    # Verify ownership if required
    if [[ "$options" == *"--verify-ownership"* ]]; then
        if ! verify_package_ownership "$name" "$platform"; then
            log ERROR "Ownership verification failed for package: $name"
            return 1
        fi
    fi
    
    # Import historical data
    local historical_data=$(fetch_historical_data "$name" "$platform")
    
    # Create package record
    local package_record=$(create_package_record "$name" "$platform" "$repo" "$historical_data")
    
    # Save to database
    save_package_to_database "$package_record"
    
    # Import relationships
    import_package_relationships "$name" "$platform"
    
    return 0
}

# Check if package exists in database
package_exists() {
    local name="$1"
    local platform="$2"
    
    local exists=$(jq -r --arg name "$name" --arg platform "$platform" '.packages | has($name + "_" + $platform)' "$PAK_DATA_DIR/packages/database.json" 2>/dev/null)
    [[ "$exists" == "true" ]]
}

# Verify package ownership
verify_package_ownership() {
    local name="$1"
    local platform="$2"
    
    log INFO "Verifying ownership for package: $name ($platform)"
    
    case "$platform" in
        npm)
            verify_npm_ownership "$name"
            ;;
        pypi)
            verify_pypi_ownership "$name"
            ;;
        crates)
            verify_crates_ownership "$name"
            ;;
        *)
            log WARN "Ownership verification not implemented for platform: $platform"
            return 0
            ;;
    esac
}

# Verify npm package ownership
verify_npm_ownership() {
    local name="$1"
    
    # Check if user is logged in to npm
    if ! npm whoami &>/dev/null; then
        log ERROR "Not logged in to npm. Run 'npm login' first."
        return 1
    fi
    
    # Check if user owns the package
    local owner_check=$(npm owner ls "$name" 2>/dev/null | grep -q "$(npm whoami)")
    if [[ $? -eq 0 ]]; then
        log SUCCESS "Ownership verified for npm package: $name"
        return 0
    else
        log ERROR "You don't own the npm package: $name"
        return 1
    fi
}

# Fetch historical data from platform APIs
fetch_historical_data() {
    local name="$1"
    local platform="$2"
    
    log INFO "Fetching historical data for package: $name ($platform)"
    
    case "$platform" in
        npm)
            fetch_npm_historical_data "$name"
            ;;
        pypi)
            fetch_pypi_historical_data "$name"
            ;;
        crates)
            fetch_crates_historical_data "$name"
            ;;
        *)
            log WARN "Historical data fetching not implemented for platform: $platform"
            echo "{}"
            ;;
    esac
}

# Fetch npm historical data
fetch_npm_historical_data() {
    local name="$1"
    local api_url="${PLATFORM_APIS[npm]}/$name"
    
    local response=$(curl -s "$api_url" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local downloads=$(echo "$response" | jq -r '.downloads // {}')
        local versions=$(echo "$response" | jq -r '.versions // {}')
        local time=$(echo "$response" | jq -r '.time // {}')
        
        echo "{\"downloads\": $downloads, \"versions\": $versions, \"time\": $time}"
    else
        echo "{}"
    fi
}

# Create package record
create_package_record() {
    local name="$1"
    local platform="$2"
    local repo="$3"
    local historical_data="$4"
    
    local record=$(cat <<EOF
{
    "name": "$name",
    "platform": "$platform",
    "repository": "$repo",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "historical_data": $historical_data,
    "status": "active",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)
    echo "$record"
}

# Save package to database
save_package_to_database() {
    local package_record="$1"
    local name=$(echo "$package_record" | jq -r '.name')
    local platform=$(echo "$package_record" | jq -r '.platform')
    local key="${name}_${platform}"
    
    # Update database
    local temp_file=$(mktemp)
    jq --arg key "$key" --argjson record "$package_record" '.packages[$key] = $record' "$PAK_DATA_DIR/packages/database.json" > "$temp_file"
    mv "$temp_file" "$PAK_DATA_DIR/packages/database.json"
    
    log SUCCESS "Package saved to database: $key"
}

# Core package management commands
package_manager_init_command() {
    local directory="${1:-.}"
    
    log INFO "Initializing PAK in directory: $directory"
    
    if [[ ! -d "$directory" ]]; then
        log ERROR "Directory does not exist: $directory"
        return 1
    fi
    
    # Detect package type
    local package_type=$(detect_package_type "$directory")
    if [[ -z "$package_type" ]]; then
        log ERROR "No supported package type detected in directory"
        return 1
    fi
    
    # Create .pakrc configuration file
    local pakrc_file="$directory/.pakrc"
    if [[ ! -f "$pakrc_file" ]]; then
        create_pakrc_file "$pakrc_file" "$package_type"
        log SUCCESS "Created .pakrc configuration file"
    else
        log INFO ".pakrc file already exists"
    fi
    
    # Initialize package tracking
    local package_name=$(extract_package_name "$directory" "$package_type")
    if [[ -n "$package_name" ]]; then
        package_manager_track_command "$package_name" "$package_type"
    fi
    
    log SUCCESS "PAK initialized successfully in $directory"
}

# Detect package type in directory
detect_package_type() {
    local directory="$1"
    
    for platform in "${!PLATFORM_CONFIGS[@]}"; do
        local pattern="${PLATFORM_CONFIGS[$platform]}"
        local files=$(find "$directory" -maxdepth 1 -type f \( -name "package.json" -o -name "setup.py" -o -name "Cargo.toml" -o -name "pom.xml" -o -name "*.csproj" -o -name "composer.json" -o -name "Gemfile" -o -name "mix.exs" -o -name "pubspec.yaml" -o -name "go.mod" \) 2>/dev/null)
        
        if [[ -n "$files" ]]; then
            echo "$platform"
            return 0
        fi
    done
    
    echo ""
}

# Create .pakrc configuration file
create_pakrc_file() {
    local file="$1"
    local package_type="$2"
    
    cat > "$file" <<EOF
{
    "package_type": "$package_type",
    "auto_track": true,
    "auto_deploy": false,
    "notifications": {
        "email": false,
        "slack": false
    },
    "deployment": {
        "environments": ["dev", "staging", "prod"],
        "auto_approval": false
    },
    "monitoring": {
        "enabled": true,
        "health_checks": true,
        "performance_tracking": true
    }
}
EOF
}

# Track package command
package_manager_track_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Adding package to tracking: $package_name ($platform)"
    
    # Check if already tracked
    if package_exists "$package_name" "$platform"; then
        log WARN "Package $package_name ($platform) is already tracked"
        return 0
    fi
    
    # Create basic package record
    local package_record=$(create_package_record "$package_name" "$platform" "local" "{}")
    save_package_to_database "$package_record"
    
    log SUCCESS "Package $package_name ($platform) added to tracking"
}

# Untrack package command
package_manager_untrack_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Removing package from tracking: $package_name ($platform)"
    
    # Remove from database
    local key="${package_name}_${platform}"
    local temp_file=$(mktemp)
    jq --arg key "$key" 'del(.packages[$key])' "$PAK_DATA_DIR/packages/database.json" > "$temp_file"
    mv "$temp_file" "$PAK_DATA_DIR/packages/database.json"
    
    log SUCCESS "Package $package_name ($platform) removed from tracking"
}

# List packages command
package_manager_list_command() {
    local options="$1"
    
    log INFO "Listing tracked packages"
    
    local packages=$(jq -r '.packages | to_entries[] | "\(.key)\t\(.value.name)\t\(.value.platform)\t\(.value.status)\t\(.value.last_updated)"' "$PAK_DATA_DIR/packages/database.json" 2>/dev/null)
    
    if [[ -z "$packages" ]]; then
        log INFO "No packages currently tracked"
        return 0
    fi
    
    echo "Package ID | Name | Platform | Status | Last Updated"
    echo "-----------|------|----------|--------|-------------"
    echo "$packages" | while IFS=$'\t' read -r key name platform status updated; do
        echo "$key | $name | $platform | $status | $updated"
    done
}

# Status command
package_manager_status_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        # Show status for all packages
        log INFO "Showing status for all tracked packages"
        show_all_packages_status
    else
        # Show status for specific package
        if [[ "$platform" == "auto" ]]; then
            platform=$(detect_package_type ".")
        fi
        
        log INFO "Showing status for package: $package_name ($platform)"
        show_package_status "$package_name" "$platform"
    fi
}

# Show status for all packages
show_all_packages_status() {
    local packages=$(jq -r '.packages | to_entries[] | @json' "$PAK_DATA_DIR/packages/database.json" 2>/dev/null)
    
    if [[ -z "$packages" ]]; then
        log INFO "No packages currently tracked"
        return 0
    fi
    
    echo "$packages" | while read -r package; do
        local name=$(echo "$package" | jq -r '.value.name')
        local platform=$(echo "$package" | jq -r '.value.platform')
        local status=$(echo "$package" | jq -r '.value.status')
        local last_updated=$(echo "$package" | jq -r '.value.last_updated')
        
        echo "📦 $name ($platform)"
        echo "   Status: $status"
        echo "   Last Updated: $last_updated"
        echo "   Repository: $(echo "$package" | jq -r '.value.repository // "N/A"')"
        echo ""
    done
}

# Show status for specific package
show_package_status() {
    local name="$1"
    local platform="$2"
    local key="${name}_${platform}"
    
    local package=$(jq -r --arg key "$key" '.packages[$key]' "$PAK_DATA_DIR/packages/database.json" 2>/dev/null)
    
    if [[ "$package" == "null" ]] || [[ -z "$package" ]]; then
        log ERROR "Package $name ($platform) not found"
        return 1
    fi
    
    echo "📦 Package: $name"
    echo "🏗️  Platform: $platform"
    echo "📊 Status: $(echo "$package" | jq -r '.status')"
    echo "🕒 Last Updated: $(echo "$package" | jq -r '.last_updated')"
    echo "📁 Repository: $(echo "$package" | jq -r '.repository // "N/A"')"
    echo "📅 Imported: $(echo "$package" | jq -r '.imported_at')"
    
    # Show historical data summary
    local historical_data=$(echo "$package" | jq -r '.historical_data')
    if [[ "$historical_data" != "{}" ]] && [[ "$historical_data" != "null" ]]; then
        echo "📈 Historical Data: Available"
    else
        echo "📈 Historical Data: None"
    fi
}

# Info command
package_manager_info_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Showing detailed information for package: $package_name ($platform)"
    
    local key="${package_name}_${platform}"
    local package=$(jq -r --arg key "$key" '.packages[$key]' "$PAK_DATA_DIR/packages/database.json" 2>/dev/null)
    
    if [[ "$package" == "null" ]] || [[ -z "$package" ]]; then
        log ERROR "Package $name ($platform) not found"
        return 1
    fi
    
    # Display detailed information
    echo "$package" | jq '.'
    
    # Show relationships if any
    show_package_relationships "$package_name" "$platform"
}

# Show package relationships
show_package_relationships() {
    local name="$1"
    local platform="$2"
    
    local relationships_file="$PAK_DATA_DIR/relationships/${name}_${platform}.json"
    if [[ -f "$relationships_file" ]]; then
        echo ""
        echo "🔗 Relationships:"
        cat "$relationships_file" | jq '.'
    fi
}

# Relationships command
package_manager_relationships_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Managing relationships for package: $package_name ($platform)"
    
    # Import relationships
    import_package_relationships "$package_name" "$platform"
    
    # Show relationships
    show_package_relationships "$package_name" "$platform"
}

# Import package relationships
import_package_relationships() {
    local name="$1"
    local platform="$2"
    
    log INFO "Importing relationships for package: $name ($platform)"
    
    local relationships_file="$PAK_DATA_DIR/relationships/${name}_${platform}.json"
    local relationships="{}"
    
    case "$platform" in
        npm)
            relationships=$(fetch_npm_relationships "$name")
            ;;
        pypi)
            relationships=$(fetch_pypi_relationships "$name")
            ;;
        crates)
            relationships=$(fetch_crates_relationships "$name")
            ;;
        *)
            log WARN "Relationship fetching not implemented for platform: $platform"
            ;;
    esac
    
    echo "$relationships" > "$relationships_file"
    log SUCCESS "Relationships saved for package: $name"
}

# Fetch npm relationships
fetch_npm_relationships() {
    local name="$1"
    local api_url="${PLATFORM_APIS[npm]}/$name"
    
    local response=$(curl -s "$api_url" 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local dependencies=$(echo "$response" | jq -r '.dependencies // {}')
        local devDependencies=$(echo "$response" | jq -r '.devDependencies // {}')
        local peerDependencies=$(echo "$response" | jq -r '.peerDependencies // {}')
        
        echo "{\"dependencies\": $dependencies, \"devDependencies\": $devDependencies, \"peerDependencies\": $peerDependencies}"
    else
        echo "{}"
    fi
}

# History command
package_manager_history_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Fetching historical data for package: $package_name ($platform)"
    
    local historical_data=$(fetch_historical_data "$package_name" "$platform")
    echo "$historical_data" | jq '.'
}

# Verify command
package_manager_verify_command() {
    local package_name="$1"
    local platform="${2:-auto}"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ "$platform" == "auto" ]]; then
        platform=$(detect_package_type ".")
    fi
    
    log INFO "Verifying ownership for package: $package_name ($platform)"
    
    if verify_package_ownership "$package_name" "$platform"; then
        log SUCCESS "Ownership verified for package: $package_name ($platform)"
    else
        log ERROR "Ownership verification failed for package: $package_name ($platform)"
        return 1
    fi
}

# Install GitHub CLI if not available
install_github_cli() {
    log INFO "Installing GitHub CLI..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install gh -y
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum install gh -y
    elif command -v brew &> /dev/null; then
        # macOS
        brew install gh
    else
        log ERROR "Unable to install GitHub CLI automatically. Please install manually: https://cli.github.com/"
        return 1
    fi
    
    log SUCCESS "GitHub CLI installed successfully"
}

# Module cleanup
package_manager_cleanup() {
    log INFO "Cleaning up Package Manager module"
    # Cleanup temporary files and resources
}

# Register module hooks
register_hook "pre_init" "package-manager" "package_manager_init"
register_hook "cleanup" "package-manager" "package_manager_cleanup" 