#!/bin/bash
# Historical Data Import Script for PAK.sh
# Imports existing download stats and metadata from platform APIs

# Configuration
HISTORICAL_VERSION="1.0.0"
HISTORICAL_CACHE_DIR="$PAK_DATA_DIR/history/cache"
HISTORICAL_DATA_DIR="$PAK_DATA_DIR/history/data"
HISTORICAL_TEMP_DIR="$PAK_DATA_DIR/history/temp"

# API rate limiting configuration
declare -A API_RATE_LIMITS
API_RATE_LIMITS=(
    ["npm"]="1000:3600"      # 1000 requests per hour
    ["pypi"]="500:3600"      # 500 requests per hour
    ["crates"]="200:3600"    # 200 requests per hour
    ["maven"]="1000:3600"    # 1000 requests per hour
    ["nuget"]="500:3600"     # 500 requests per hour
    ["composer"]="300:3600"  # 300 requests per hour
    ["gem"]="200:3600"       # 200 requests per hour
    ["hex"]="100:3600"       # 100 requests per hour
    ["pub"]="200:3600"       # 200 requests per hour
    ["go"]="1000:3600"       # 1000 requests per hour
)

# API endpoints for historical data
declare -A HISTORICAL_APIS
HISTORICAL_APIS=(
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
)

# Initialize historical data system
init_historical() {
    mkdir -p "$HISTORICAL_CACHE_DIR"
    mkdir -p "$HISTORICAL_DATA_DIR"
    mkdir -p "$HISTORICAL_TEMP_DIR"
    
    log INFO "Historical data system initialized"
}

# Main historical data import function
import_historical_data() {
    local package_name="$1"
    local platform="$2"
    local options="$3"
    
    log INFO "Importing historical data for package: $package_name ($platform)"
    
    # Check rate limits
    if ! check_rate_limit "$platform"; then
        log WARN "Rate limit exceeded for platform: $platform. Waiting..."
        wait_for_rate_limit "$platform"
    fi
    
    # Import based on platform
    case "$platform" in
        npm)
            import_npm_historical_data "$package_name" "$options"
            ;;
        pypi)
            import_pypi_historical_data "$package_name" "$options"
            ;;
        crates)
            import_crates_historical_data "$package_name" "$options"
            ;;
        maven)
            import_maven_historical_data "$package_name" "$options"
            ;;
        nuget)
            import_nuget_historical_data "$package_name" "$options"
            ;;
        composer)
            import_composer_historical_data "$package_name" "$options"
            ;;
        gem)
            import_gem_historical_data "$package_name" "$options"
            ;;
        hex)
            import_hex_historical_data "$package_name" "$options"
            ;;
        pub)
            import_pub_historical_data "$package_name" "$options"
            ;;
        go)
            import_go_historical_data "$package_name" "$options"
            ;;
        *)
            log ERROR "Historical data import not implemented for platform: $platform"
            return 1
            ;;
    esac
}

# Check API rate limits
check_rate_limit() {
    local platform="$1"
    local rate_limit="${API_RATE_LIMITS[$platform]}"
    
    if [[ -z "$rate_limit" ]]; then
        return 0  # No rate limit configured
    fi
    
    local max_requests=$(echo "$rate_limit" | cut -d: -f1)
    local window_seconds=$(echo "$rate_limit" | cut -d: -f2)
    local cache_file="$HISTORICAL_CACHE_DIR/${platform}_rate_limit.json"
    
    # Check if cache file exists and is recent
    if [[ -f "$cache_file" ]]; then
        local last_request=$(jq -r '.last_request' "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_request))
        
        if [[ $time_diff -lt $window_seconds ]]; then
            local request_count=$(jq -r '.request_count' "$cache_file" 2>/dev/null)
            if [[ $request_count -ge $max_requests ]]; then
                return 1  # Rate limit exceeded
            fi
        else
            # Reset counter for new window
            echo "{\"last_request\": $current_time, \"request_count\": 0}" > "$cache_file"
        fi
    else
        # Initialize cache file
        echo "{\"last_request\": $(date +%s), \"request_count\": 0}" > "$cache_file"
    fi
    
    # Increment request count
    local current_count=$(jq -r '.request_count' "$cache_file" 2>/dev/null)
    local new_count=$((current_count + 1))
    jq --arg count "$new_count" '.request_count = ($count | tonumber)' "$cache_file" > "${cache_file}.tmp"
    mv "${cache_file}.tmp" "$cache_file"
    
    return 0
}

# Wait for rate limit reset
wait_for_rate_limit() {
    local platform="$1"
    local rate_limit="${API_RATE_LIMITS[$platform]}"
    local window_seconds=$(echo "$rate_limit" | cut -d: -f2)
    local cache_file="$HISTORICAL_CACHE_DIR/${platform}_rate_limit.json"
    
    if [[ -f "$cache_file" ]]; then
        local last_request=$(jq -r '.last_request' "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_request))
        local wait_time=$((window_seconds - time_diff))
        
        if [[ $wait_time -gt 0 ]]; then
            log INFO "Waiting $wait_time seconds for rate limit reset..."
            sleep $wait_time
        fi
    fi
    
    # Reset counter
    echo "{\"last_request\": $(date +%s), \"request_count\": 0}" > "$cache_file"
}

# Import npm historical data
import_npm_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing npm historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[npm]}/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local downloads=$(echo "$response" | jq -r '.downloads // {}')
        local versions=$(echo "$response" | jq -r '.versions // {}')
        local time=$(echo "$response" | jq -r '.time // {}')
        local maintainers=$(echo "$response" | jq -r '.maintainers // []')
        local description=$(echo "$response" | jq -r '.description // ""')
        local keywords=$(echo "$response" | jq -r '.keywords // []')
        local repository=$(echo "$response" | jq -r '.repository // {}')
        local bugs=$(echo "$response" | jq -r '.bugs // {}')
        local homepage=$(echo "$response" | jq -r '.homepage // ""')
        local license=$(echo "$response" | jq -r '.license // ""')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "npm",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "downloads": $downloads,
    "versions": $versions,
    "time": $time,
    "maintainers": $maintainers,
    "description": "$description",
    "keywords": $keywords,
    "repository": $repository,
    "bugs": $bugs,
    "homepage": "$homepage",
    "license": "$license"
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/npm_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "NPM historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "npm" "$data_file"
        
    else
        log ERROR "Failed to fetch npm historical data for package: $package_name"
        return 1
    fi
}

# Import PyPI historical data
import_pypi_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing PyPI historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[pypi]}/$package_name/json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local info=$(echo "$response" | jq -r '.info // {}')
        local releases=$(echo "$response" | jq -r '.releases // {}')
        local urls=$(echo "$response" | jq -r '.urls // []')
        
        # Get download stats (PyPI doesn't provide this via API)
        local download_stats="{}"
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "pypi",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "info": $info,
    "releases": $releases,
    "urls": $urls,
    "download_stats": $download_stats
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/pypi_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "PyPI historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "pypi" "$data_file"
        
    else
        log ERROR "Failed to fetch PyPI historical data for package: $package_name"
        return 1
    fi
}

# Import crates.io historical data
import_crates_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing crates.io historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[crates]}/crates/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local crate=$(echo "$response" | jq -r '.crate // {}')
        local versions=$(echo "$response" | jq -r '.versions // []')
        
        # Get download stats
        local download_stats="{}"
        if command -v jq &> /dev/null; then
            download_stats=$(echo "$response" | jq -r '.crate.downloads // {}')
        fi
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "crates",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "crate": $crate,
    "versions": $versions,
    "download_stats": $download_stats
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/crates_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Crates.io historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "crates" "$data_file"
        
    else
        log ERROR "Failed to fetch crates.io historical data for package: $package_name"
        return 1
    fi
}

# Import Maven historical data
import_maven_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing Maven historical data for package: $package_name"
    
    # Maven Central API
    local api_url="${HISTORICAL_APIS[maven]}?q=g:$package_name&rows=20&wt=json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local docs=$(echo "$response" | jq -r '.response.docs // []')
        local numFound=$(echo "$response" | jq -r '.response.numFound // 0')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "maven",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "total_found": $numFound,
    "artifacts": $docs
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/maven_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Maven historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "maven" "$data_file"
        
    else
        log ERROR "Failed to fetch Maven historical data for package: $package_name"
        return 1
    fi
}

# Import NuGet historical data
import_nuget_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing NuGet historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[nuget]}/registration3-semver2/$package_name/index.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local items=$(echo "$response" | jq -r '.items // []')
        local count=$(echo "$response" | jq -r '.count // 0')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "nuget",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "total_versions": $count,
    "versions": $items
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/nuget_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "NuGet historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "nuget" "$data_file"
        
    else
        log ERROR "Failed to fetch NuGet historical data for package: $package_name"
        return 1
    fi
}

# Import Composer historical data
import_composer_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing Composer historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[composer]}/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local package=$(echo "$response" | jq -r '.package // {}')
        local versions=$(echo "$response" | jq -r '.package.versions // {}')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "composer",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "package": $package,
    "versions": $versions
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/composer_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Composer historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "composer" "$data_file"
        
    else
        log ERROR "Failed to fetch Composer historical data for package: $package_name"
        return 1
    fi
}

# Import RubyGems historical data
import_gem_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing RubyGems historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[gem]}/gems/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local gem_info=$(echo "$response" | jq -r '. // {}')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "gem",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "gem_info": $gem_info
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/gem_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "RubyGems historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "gem" "$data_file"
        
    else
        log ERROR "Failed to fetch RubyGems historical data for package: $package_name"
        return 1
    fi
}

# Import Hex historical data
import_hex_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing Hex historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[hex]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local package=$(echo "$response" | jq -r '. // {}')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "hex",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "package": $package
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/hex_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Hex historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "hex" "$data_file"
        
    else
        log ERROR "Failed to fetch Hex historical data for package: $package_name"
        return 1
    fi
}

# Import Pub historical data
import_pub_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing Pub historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[pub]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local package=$(echo "$response" | jq -r '. // {}')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "pub",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "package": $package
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/pub_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Pub historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "pub" "$data_file"
        
    else
        log ERROR "Failed to fetch Pub historical data for package: $package_name"
        return 1
    fi
}

# Import Go historical data
import_go_historical_data() {
    local package_name="$1"
    local options="$2"
    
    log INFO "Importing Go historical data for package: $package_name"
    
    local api_url="${HISTORICAL_APIS[go]}/$package_name/@latest"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        # Extract historical data
        local module_info=$(echo "$response" | jq -r '. // {}')
        
        # Create historical data object
        local historical_data=$(cat <<EOF
{
    "platform": "go",
    "package_name": "$package_name",
    "imported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "module_info": $module_info
}
EOF
)
        
        # Save to file
        local data_file="$HISTORICAL_DATA_DIR/go_${package_name}_$(date +%Y%m%d_%H%M%S).json"
        echo "$historical_data" > "$data_file"
        
        log SUCCESS "Go historical data imported for package: $package_name"
        log INFO "Data saved to: $data_file"
        
        # Update package database
        update_package_historical_data "$package_name" "go" "$data_file"
        
    else
        log ERROR "Failed to fetch Go historical data for package: $package_name"
        return 1
    fi
}

# Update package database with historical data
update_package_historical_data() {
    local package_name="$1"
    local platform="$2"
    local data_file="$3"
    
    local key="${package_name}_${platform}"
    local database_file="$PAK_DATA_DIR/packages/database.json"
    
    if [[ -f "$database_file" ]]; then
        # Read historical data
        local historical_data=$(cat "$data_file")
        
        # Update database
        local temp_file=$(mktemp)
        jq --arg key "$key" --argjson data "$historical_data" '.packages[$key].historical_data = $data' "$database_file" > "$temp_file"
        mv "$temp_file" "$database_file"
        
        log INFO "Updated package database with historical data for: $key"
    fi
}

# Bulk import historical data
bulk_import_historical_data() {
    local packages_file="$1"
    local options="$2"
    
    if [[ ! -f "$packages_file" ]]; then
        log ERROR "Packages file not found: $packages_file"
        return 1
    fi
    
    log INFO "Starting bulk historical data import from: $packages_file"
    
    local total_packages=$(jq '.packages | length' "$packages_file" 2>/dev/null)
    local current=0
    local success_count=0
    local error_count=0
    
    # Process packages
    jq -r '.packages[] | "\(.name) \(.platform)"' "$packages_file" | while read -r package_name platform; do
        ((current++))
        log INFO "Processing package $current/$total_packages: $package_name ($platform)"
        
        if import_historical_data "$package_name" "$platform" "$options"; then
            ((success_count++))
            log SUCCESS "Imported historical data for: $package_name"
        else
            ((error_count++))
            log ERROR "Failed to import historical data for: $package_name"
        fi
        
        # Progress indicator
        if [[ $((current % 10)) -eq 0 ]]; then
            log INFO "Progress: $current/$total_packages packages processed"
        fi
    done
    
    log SUCCESS "Bulk import completed. Success: $success_count, Errors: $error_count"
}

# Analyze historical data
analyze_historical_data() {
    local package_name="$1"
    local platform="$2"
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name required"
        return 1
    fi
    
    if [[ -z "$platform" ]]; then
        platform="auto"
    fi
    
    log INFO "Analyzing historical data for package: $package_name ($platform)"
    
    # Find historical data file
    local data_file=$(find "$HISTORICAL_DATA_DIR" -name "*_${package_name}_*.json" | head -1)
    
    if [[ -z "$data_file" ]]; then
        log ERROR "No historical data found for package: $package_name"
        return 1
    fi
    
    # Analyze data
    local total_versions=$(jq '.versions | length' "$data_file" 2>/dev/null || echo "0")
    local latest_version=$(jq -r '.versions | keys | last // "unknown"' "$data_file" 2>/dev/null)
    local total_downloads=$(jq -r '.downloads.total // 0' "$data_file" 2>/dev/null)
    local last_updated=$(jq -r '.time | keys | last // "unknown"' "$data_file" 2>/dev/null)
    
    echo "📊 Historical Data Analysis for $package_name ($platform)"
    echo "=================================================="
    echo "Total versions: $total_versions"
    echo "Latest version: $latest_version"
    echo "Total downloads: $total_downloads"
    echo "Last updated: $last_updated"
    echo "Data file: $data_file"
}

# Clean up historical data cache
cleanup_historical_cache() {
    log INFO "Cleaning up historical data cache"
    
    # Remove temporary files older than 24 hours
    find "$HISTORICAL_TEMP_DIR" -type f -mtime +1 -delete 2>/dev/null
    
    # Remove cache files older than 30 days
    find "$HISTORICAL_CACHE_DIR" -type f -mtime +30 -delete 2>/dev/null
    
    log SUCCESS "Historical data cache cleaned up"
}

# Main function
main() {
    local command="$1"
    local args="${@:2}"
    
    # Initialize historical data system
    init_historical
    
    case "$command" in
        import)
            import_historical_data "$args"
            ;;
        bulk)
            bulk_import_historical_data "$args"
            ;;
        analyze)
            analyze_historical_data "$args"
            ;;
        cleanup)
            cleanup_historical_cache
            ;;
        *)
            echo "Usage: $0 {import|bulk|analyze|cleanup} [args...]"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 