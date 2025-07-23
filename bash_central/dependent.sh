#!/bin/bash
# dependencies.sh - Dependency checking and installation

# ============================================================================
# DEPENDENCY DEFINITIONS
# ============================================================================
declare -A DEPENDENCIES=(
    [curl]="curl command for downloading files"
    [git]="git version control system"
    [jq]="jq JSON processor"
    [wget]="wget download utility"
    [nc]="netcat networking utility"
    [python3]="Python 3 interpreter"
    [node]="Node.js runtime"
    [docker]="Docker container platform"
)

declare -A PACKAGE_NAMES=(
    [curl]="curl"
    [git]="git"
    [jq]="jq"
    [wget]="wget"
    [nc]="netcat|nc|netcat-openbsd"
    [python3]="python3"
    [node]="nodejs"
    [docker]="docker.io|docker"
)

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    # If no specific deps provided, check all
    if [[ ${#deps[@]} -eq 0 ]]; then
        deps=("${!DEPENDENCIES[@]}")
    fi
    
    echo "Checking dependencies..."
    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            print_success "$dep is installed"
        else
            print_error "$dep is not installed"
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        print_warning "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

install_dependencies() {
    local deps=("$@")
    local pm=$(detect_package_manager)
    
    if [[ "$pm" == "unknown" ]]; then
        die "Unable to detect package manager"
    fi
    
    print_info "Using package manager: $pm"
    
    for dep in "${deps[@]}"; do
        local packages="${PACKAGE_NAMES[$dep]}"
        local installed=false
        
        # Try each possible package name
        IFS='|' read -ra pkg_options <<< "$packages"
        for pkg in "${pkg_options[@]}"; do
            if install_package "$pkg"; then
                installed=true
                break
            fi
        done
        
        if ! $installed; then
            print_error "Failed to install $dep"
        fi
    done
}

ensure_dependencies() {
    local deps=("$@")
    
    if ! check_dependencies "${deps[@]}"; then
        if confirm "Would you like to install missing dependencies?" "y"; then
            install_dependencies "${deps[@]}"
        else
            die "Required dependencies are missing"
        fi
    fi
}