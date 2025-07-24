#!/bin/bash
# Ownership Verification Script for PAK.sh
# Verifies users own packages before allowing import/management

# Configuration
VERIFICATION_VERSION="1.0.0"
VERIFICATION_CACHE_DIR="$PAK_DATA_DIR/verification/cache"
VERIFICATION_DATA_DIR="$PAK_DATA_DIR/verification/data"
VERIFICATION_TEMP_DIR="$PAK_DATA_DIR/verification/temp"

# Platform-specific verification methods
declare -A VERIFICATION_METHODS
VERIFICATION_METHODS=(
    ["npm"]="api_auth|metadata_match|email_verify"
    ["pypi"]="api_auth|metadata_match|email_verify"
    ["crates"]="api_auth|metadata_match|email_verify"
    ["maven"]="metadata_match|email_verify"
    ["nuget"]="api_auth|metadata_match|email_verify"
    ["composer"]="api_auth|metadata_match|email_verify"
    ["gem"]="api_auth|metadata_match|email_verify"
    ["hex"]="api_auth|metadata_match|email_verify"
    ["pub"]="api_auth|metadata_match|email_verify"
    ["go"]="metadata_match|email_verify"
)

# API endpoints for verification
declare -A VERIFICATION_APIS
VERIFICATION_APIS=(
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

# Initialize verification system
init_verification() {
    mkdir -p "$VERIFICATION_CACHE_DIR"
    mkdir -p "$VERIFICATION_DATA_DIR"
    mkdir -p "$VERIFICATION_TEMP_DIR"
    
    log INFO "Ownership verification system initialized"
}

# Main verification function
verify_package_ownership() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    local options="$4"
    
    log INFO "Verifying ownership for package: $package_name ($platform) by user: $username"
    
    # Check cache first
    if check_verification_cache "$package_name" "$platform" "$username"; then
        log INFO "Using cached verification result for: $package_name"
        return 0
    fi
    
    # Get verification methods for platform
    local methods="${VERIFICATION_METHODS[$platform]}"
    if [[ -z "$methods" ]]; then
        log WARN "No verification methods configured for platform: $platform"
        return 0  # Allow if no methods configured
    fi
    
    # Try each verification method
    local verified=false
    IFS='|' read -ra method_array <<< "$methods"
    
    for method in "${method_array[@]}"; do
        log INFO "Trying verification method: $method"
        
        case "$method" in
            api_auth)
                if verify_api_authentication "$package_name" "$platform" "$username"; then
                    verified=true
                    break
                fi
                ;;
            metadata_match)
                if verify_metadata_match "$package_name" "$platform" "$username"; then
                    verified=true
                    break
                fi
                ;;
            email_verify)
                if verify_email_match "$package_name" "$platform" "$username"; then
                    verified=true
                    break
                fi
                ;;
            *)
                log WARN "Unknown verification method: $method"
                ;;
        esac
    done
    
    # Cache result
    cache_verification_result "$package_name" "$platform" "$username" "$verified"
    
    if [[ "$verified" == "true" ]]; then
        log SUCCESS "Ownership verified for package: $package_name ($platform)"
        return 0
    else
        log ERROR "Ownership verification failed for package: $package_name ($platform)"
        return 1
    fi
}

# Check verification cache
check_verification_cache() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    
    local cache_file="$VERIFICATION_CACHE_DIR/${platform}_${package_name}_${username}.json"
    
    if [[ -f "$cache_file" ]]; then
        local cache_time=$(jq -r '.timestamp' "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        local cache_age=$((current_time - cache_time))
        
        # Cache valid for 24 hours
        if [[ $cache_age -lt 86400 ]]; then
            local verified=$(jq -r '.verified' "$cache_file" 2>/dev/null)
            if [[ "$verified" == "true" ]]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Cache verification result
cache_verification_result() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    local verified="$4"
    
    local cache_file="$VERIFICATION_CACHE_DIR/${platform}_${package_name}_${username}.json"
    
    cat > "$cache_file" <<EOF
{
    "package_name": "$package_name",
    "platform": "$platform",
    "username": "$username",
    "verified": $verified,
    "timestamp": $(date +%s),
    "verified_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    log DEBUG "Cached verification result for: $package_name ($platform)"
}

# Verify API authentication
verify_api_authentication() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    
    case "$platform" in
        npm)
            verify_npm_api_auth "$package_name" "$username"
            ;;
        pypi)
            verify_pypi_api_auth "$package_name" "$username"
            ;;
        crates)
            verify_crates_api_auth "$package_name" "$username"
            ;;
        nuget)
            verify_nuget_api_auth "$package_name" "$username"
            ;;
        composer)
            verify_composer_api_auth "$package_name" "$username"
            ;;
        gem)
            verify_gem_api_auth "$package_name" "$username"
            ;;
        hex)
            verify_hex_api_auth "$package_name" "$username"
            ;;
        pub)
            verify_pub_api_auth "$package_name" "$username"
            ;;
        *)
            log WARN "API authentication not implemented for platform: $platform"
            return 1
            ;;
    esac
}

# Verify npm API authentication
verify_npm_api_auth() {
    local package_name="$1"
    local username="$2"
    
    log INFO "Verifying npm API authentication for package: $package_name"
    
    # Check if user is logged in to npm
    if ! npm whoami &>/dev/null; then
        log ERROR "Not logged in to npm. Run 'npm login' first."
        return 1
    fi
    
    local current_user=$(npm whoami 2>/dev/null)
    if [[ "$current_user" != "$username" ]]; then
        log ERROR "Logged in as different user: $current_user (expected: $username)"
        return 1
    fi
    
    # Check if user owns the package
    local owner_check=$(npm owner ls "$package_name" 2>/dev/null | grep -q "$username")
    if [[ $? -eq 0 ]]; then
        log SUCCESS "NPM API authentication verified for package: $package_name"
        return 0
    else
        log ERROR "User $username does not own npm package: $package_name"
        return 1
    fi
}

# Verify PyPI API authentication
verify_pypi_api_auth() {
    local package_name="$1"
    local username="$2"
    
    log INFO "Verifying PyPI API authentication for package: $package_name"
    
    # Check if user is logged in to pip
    if ! python3 -m pip config list | grep -q "global.username"; then
        log ERROR "Not logged in to PyPI. Run 'python3 -m pip config set global.username $username' first."
        return 1
    fi
    
    # PyPI doesn't have a direct ownership API, so we'll check metadata
    local api_url="${VERIFICATION_APIS[pypi]}/$package_name/json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainers=$(echo "$response" | jq -r '.info.maintainer_email // []' 2>/dev/null)
        local author_email=$(echo "$response" | jq -r '.info.author_email // ""' 2>/dev/null)
        
        # Check if username matches any maintainer or author
        if echo "$maintainers" | grep -q "$username" || [[ "$author_email" == *"$username"* ]]; then
            log SUCCESS "PyPI metadata authentication verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in PyPI package maintainers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch PyPI package metadata: $package_name"
        return 1
    fi
}

# Verify crates.io API authentication
verify_crates_api_auth() {
    local package_name="$1"
    local username="$2"
    
    log INFO "Verifying crates.io API authentication for package: $package_name"
    
    # Check if user is logged in to cargo
    if ! cargo login --check &>/dev/null; then
        log ERROR "Not logged in to crates.io. Run 'cargo login' first."
        return 1
    fi
    
    # Get package owners
    local api_url="${VERIFICATION_APIS[crates]}/crates/$package_name/owners"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local owners=$(echo "$response" | jq -r '.users[].login // []' 2>/dev/null)
        
        if echo "$owners" | grep -q "$username"; then
            log SUCCESS "Crates.io API authentication verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in crates.io package owners: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch crates.io package owners: $package_name"
        return 1
    fi
}

# Verify metadata match
verify_metadata_match() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    
    log INFO "Verifying metadata match for package: $package_name ($platform)"
    
    case "$platform" in
        npm)
            verify_npm_metadata_match "$package_name" "$username"
            ;;
        pypi)
            verify_pypi_metadata_match "$package_name" "$username"
            ;;
        crates)
            verify_crates_metadata_match "$package_name" "$username"
            ;;
        maven)
            verify_maven_metadata_match "$package_name" "$username"
            ;;
        nuget)
            verify_nuget_metadata_match "$package_name" "$username"
            ;;
        composer)
            verify_composer_metadata_match "$package_name" "$username"
            ;;
        gem)
            verify_gem_metadata_match "$package_name" "$username"
            ;;
        hex)
            verify_hex_metadata_match "$package_name" "$username"
            ;;
        pub)
            verify_pub_metadata_match "$package_name" "$username"
            ;;
        go)
            verify_go_metadata_match "$package_name" "$username"
            ;;
        *)
            log WARN "Metadata match verification not implemented for platform: $platform"
            return 1
            ;;
    esac
}

# Verify npm metadata match
verify_npm_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[npm]}/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainers=$(echo "$response" | jq -r '.maintainers[].name // []' 2>/dev/null)
        local author=$(echo "$response" | jq -r '.author.name // ""' 2>/dev/null)
        
        if echo "$maintainers" | grep -q "$username" || [[ "$author" == "$username" ]]; then
            log SUCCESS "NPM metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in NPM package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch NPM package metadata: $package_name"
        return 1
    fi
}

# Verify PyPI metadata match
verify_pypi_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[pypi]}/$package_name/json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainers=$(echo "$response" | jq -r '.info.maintainer // []' 2>/dev/null)
        local author=$(echo "$response" | jq -r '.info.author // ""' 2>/dev/null)
        
        if echo "$maintainers" | grep -q "$username" || [[ "$author" == "$username" ]]; then
            log SUCCESS "PyPI metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in PyPI package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch PyPI package metadata: $package_name"
        return 1
    fi
}

# Verify crates.io metadata match
verify_crates_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[crates]}/crates/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local owners=$(echo "$response" | jq -r '.crate.owners[].login // []' 2>/dev/null)
        
        if echo "$owners" | grep -q "$username"; then
            log SUCCESS "Crates.io metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in crates.io package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch crates.io package metadata: $package_name"
        return 1
    fi
}

# Verify Maven metadata match
verify_maven_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    # Maven Central doesn't have direct ownership info, so we'll check group ID
    local api_url="${VERIFICATION_APIS[maven]}?q=g:$username&rows=20&wt=json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local artifacts=$(echo "$response" | jq -r '.response.docs[].a // []' 2>/dev/null)
        
        if echo "$artifacts" | grep -q "$package_name"; then
            log SUCCESS "Maven metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "Package $package_name not found in Maven artifacts for user: $username"
            return 1
        fi
    else
        log ERROR "Failed to fetch Maven artifacts for user: $username"
        return 1
    fi
}

# Verify NuGet metadata match
verify_nuget_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[nuget]}/registration3-semver2/$package_name/index.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local authors=$(echo "$response" | jq -r '.items[0].catalogEntry.authors // ""' 2>/dev/null)
        local owners=$(echo "$response" | jq -r '.items[0].catalogEntry.owners // ""' 2>/dev/null)
        
        if [[ "$authors" == *"$username"* ]] || [[ "$owners" == *"$username"* ]]; then
            log SUCCESS "NuGet metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in NuGet package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch NuGet package metadata: $package_name"
        return 1
    fi
}

# Verify Composer metadata match
verify_composer_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[composer]}/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainers=$(echo "$response" | jq -r '.package.maintainers[].name // []' 2>/dev/null)
        local authors=$(echo "$response" | jq -r '.package.authors[].name // []' 2>/dev/null)
        
        if echo "$maintainers" | grep -q "$username" || echo "$authors" | grep -q "$username"; then
            log SUCCESS "Composer metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in Composer package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Composer package metadata: $package_name"
        return 1
    fi
}

# Verify RubyGems metadata match
verify_gem_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[gem]}/gems/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local authors=$(echo "$response" | jq -r '.authors // []' 2>/dev/null)
        local maintainers=$(echo "$response" | jq -r '.maintainers // []' 2>/dev/null)
        
        if echo "$authors" | grep -q "$username" || echo "$maintainers" | grep -q "$username"; then
            log SUCCESS "RubyGems metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in RubyGems package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch RubyGems package metadata: $package_name"
        return 1
    fi
}

# Verify Hex metadata match
verify_hex_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[hex]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainers=$(echo "$response" | jq -r '.maintainers[].username // []' 2>/dev/null)
        
        if echo "$maintainers" | grep -q "$username"; then
            log SUCCESS "Hex metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in Hex package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Hex package metadata: $package_name"
        return 1
    fi
}

# Verify Pub metadata match
verify_pub_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    local api_url="${VERIFICATION_APIS[pub]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local publishers=$(echo "$response" | jq -r '.publishers[].name // []' 2>/dev/null)
        
        if echo "$publishers" | grep -q "$username"; then
            log SUCCESS "Pub metadata match verified for package: $package_name"
            return 0
        else
            log ERROR "User $username not found in Pub package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Pub package metadata: $package_name"
        return 1
    fi
}

# Verify Go metadata match
verify_go_metadata_match() {
    local package_name="$1"
    local username="$2"
    
    # Go modules don't have direct ownership, so we'll check the module path
    if [[ "$package_name" == *"$username"* ]]; then
        log SUCCESS "Go metadata match verified for package: $package_name"
        return 0
    else
        log ERROR "Package $package_name doesn't match Go module path for user: $username"
        return 1
    fi
}

# Verify email match
verify_email_match() {
    local package_name="$1"
    local platform="$2"
    local username="$3"
    
    log INFO "Verifying email match for package: $package_name ($platform)"
    
    # Get user's email from git config
    local user_email=$(git config user.email 2>/dev/null)
    if [[ -z "$user_email" ]]; then
        log WARN "No git email configured. Skipping email verification."
        return 1
    fi
    
    case "$platform" in
        npm)
            verify_npm_email_match "$package_name" "$user_email"
            ;;
        pypi)
            verify_pypi_email_match "$package_name" "$user_email"
            ;;
        crates)
            verify_crates_email_match "$package_name" "$user_email"
            ;;
        nuget)
            verify_nuget_email_match "$package_name" "$user_email"
            ;;
        composer)
            verify_composer_email_match "$package_name" "$user_email"
            ;;
        gem)
            verify_gem_email_match "$package_name" "$user_email"
            ;;
        hex)
            verify_hex_email_match "$package_name" "$user_email"
            ;;
        pub)
            verify_pub_email_match "$package_name" "$user_email"
            ;;
        *)
            log WARN "Email verification not implemented for platform: $platform"
            return 1
            ;;
    esac
}

# Verify npm email match
verify_npm_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[npm]}/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainer_emails=$(echo "$response" | jq -r '.maintainers[].email // []' 2>/dev/null)
        local author_email=$(echo "$response" | jq -r '.author.email // ""' 2>/dev/null)
        
        if echo "$maintainer_emails" | grep -q "$user_email" || [[ "$author_email" == "$user_email" ]]; then
            log SUCCESS "NPM email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in NPM package maintainers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch NPM package metadata: $package_name"
        return 1
    fi
}

# Verify PyPI email match
verify_pypi_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[pypi]}/$package_name/json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainer_emails=$(echo "$response" | jq -r '.info.maintainer_email // []' 2>/dev/null)
        local author_email=$(echo "$response" | jq -r '.info.author_email // ""' 2>/dev/null)
        
        if echo "$maintainer_emails" | grep -q "$user_email" || [[ "$author_email" == "$user_email" ]]; then
            log SUCCESS "PyPI email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in PyPI package maintainers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch PyPI package metadata: $package_name"
        return 1
    fi
}

# Verify crates.io email match
verify_crates_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[crates]}/crates/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local owner_emails=$(echo "$response" | jq -r '.crate.owners[].email // []' 2>/dev/null)
        
        if echo "$owner_emails" | grep -q "$user_email"; then
            log SUCCESS "Crates.io email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in crates.io package owners: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch crates.io package metadata: $package_name"
        return 1
    fi
}

# Verify NuGet email match
verify_nuget_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[nuget]}/registration3-semver2/$package_name/index.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local authors=$(echo "$response" | jq -r '.items[0].catalogEntry.authors // ""' 2>/dev/null)
        local owners=$(echo "$response" | jq -r '.items[0].catalogEntry.owners // ""' 2>/dev/null)
        
        # NuGet doesn't expose email addresses publicly, so we'll check author/owner names
        if [[ "$authors" == *"$user_email"* ]] || [[ "$owners" == *"$user_email"* ]]; then
            log SUCCESS "NuGet email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in NuGet package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch NuGet package metadata: $package_name"
        return 1
    fi
}

# Verify Composer email match
verify_composer_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[composer]}/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainer_emails=$(echo "$response" | jq -r '.package.maintainers[].email // []' 2>/dev/null)
        local author_emails=$(echo "$response" | jq -r '.package.authors[].email // []' 2>/dev/null)
        
        if echo "$maintainer_emails" | grep -q "$user_email" || echo "$author_emails" | grep -q "$user_email"; then
            log SUCCESS "Composer email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in Composer package maintainers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Composer package metadata: $package_name"
        return 1
    fi
}

# Verify RubyGems email match
verify_gem_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[gem]}/gems/$package_name.json"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local author_emails=$(echo "$response" | jq -r '.authors // []' 2>/dev/null)
        local maintainer_emails=$(echo "$response" | jq -r '.maintainers // []' 2>/dev/null)
        
        if echo "$author_emails" | grep -q "$user_email" || echo "$maintainer_emails" | grep -q "$user_email"; then
            log SUCCESS "RubyGems email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in RubyGems package metadata: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch RubyGems package metadata: $package_name"
        return 1
    fi
}

# Verify Hex email match
verify_hex_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[hex]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local maintainer_emails=$(echo "$response" | jq -r '.maintainers[].email // []' 2>/dev/null)
        
        if echo "$maintainer_emails" | grep -q "$user_email"; then
            log SUCCESS "Hex email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in Hex package maintainers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Hex package metadata: $package_name"
        return 1
    fi
}

# Verify Pub email match
verify_pub_email_match() {
    local package_name="$1"
    local user_email="$2"
    
    local api_url="${VERIFICATION_APIS[pub]}/packages/$package_name"
    local response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$response" ]]; then
        local publisher_emails=$(echo "$response" | jq -r '.publishers[].email // []' 2>/dev/null)
        
        if echo "$publisher_emails" | grep -q "$user_email"; then
            log SUCCESS "Pub email match verified for package: $package_name"
            return 0
        else
            log ERROR "Email $user_email not found in Pub package publishers: $package_name"
            return 1
        fi
    else
        log ERROR "Failed to fetch Pub package metadata: $package_name"
        return 1
    fi
}

# Bulk verification
bulk_verify_ownership() {
    local packages_file="$1"
    local username="$2"
    local options="$3"
    
    if [[ ! -f "$packages_file" ]]; then
        log ERROR "Packages file not found: $packages_file"
        return 1
    fi
    
    if [[ -z "$username" ]]; then
        log ERROR "Username required for bulk verification"
        return 1
    fi
    
    log INFO "Starting bulk ownership verification for user: $username"
    
    local total_packages=$(jq '.packages | length' "$packages_file" 2>/dev/null)
    local current=0
    local verified_count=0
    local failed_count=0
    
    # Process packages
    jq -r '.packages[] | "\(.name) \(.platform)"' "$packages_file" | while read -r package_name platform; do
        ((current++))
        log INFO "Verifying package $current/$total_packages: $package_name ($platform)"
        
        if verify_package_ownership "$package_name" "$platform" "$username" "$options"; then
            ((verified_count++))
            log SUCCESS "Verified ownership for: $package_name"
        else
            ((failed_count++))
            log ERROR "Failed to verify ownership for: $package_name"
        fi
        
        # Progress indicator
        if [[ $((current % 10)) -eq 0 ]]; then
            log INFO "Progress: $current/$total_packages packages verified"
        fi
    done
    
    log SUCCESS "Bulk verification completed. Verified: $verified_count, Failed: $failed_count"
}

# Clean up verification cache
cleanup_verification_cache() {
    log INFO "Cleaning up verification cache"
    
    # Remove cache files older than 7 days
    find "$VERIFICATION_CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null
    
    # Remove temporary files older than 24 hours
    find "$VERIFICATION_TEMP_DIR" -type f -mtime +1 -delete 2>/dev/null
    
    log SUCCESS "Verification cache cleaned up"
}

# Main function
main() {
    local command="$1"
    local args="${@:2}"
    
    # Initialize verification system
    init_verification
    
    case "$command" in
        verify)
            verify_package_ownership "$args"
            ;;
        bulk)
            bulk_verify_ownership "$args"
            ;;
        cleanup)
            cleanup_verification_cache
            ;;
        *)
            echo "Usage: $0 {verify|bulk|cleanup} [args...]"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 