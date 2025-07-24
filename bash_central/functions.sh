#!/bin/bash
# functions.sh - Reusable utility functions

# ============================================================================
# STRING MANIPULATION
# ============================================================================
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace
    echo -n "$var"
}

to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Check if string contains substring
contains() {
    [[ "$1" =~ $2 ]]
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

ensure_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

safe_copy() {
    local src="$1"
    local dest="$2"
    
    if [[ -f "$dest" ]]; then
        backup_file "$dest"
    fi
    cp "$src" "$dest"
}

# ============================================================================
# NETWORK FUNCTIONS
# ============================================================================
download_file() {
    local url="$1"
    local dest="$2"
    local retry=${3:-3}
    
    for i in $(seq 1 $retry); do
        if curl -fsSL "$url" -o "$dest"; then
            return 0
        fi
        [[ $i -lt $retry ]] && sleep 2
    done
    return 1
}

check_internet() {
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || \
    ping -c 1 -W 2 google.com >/dev/null 2>&1
}

get_public_ip() {
    curl -s https://ipinfo.io/ip || \
    curl -s https://api.ipify.org || \
    echo "unknown"
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================
get_memory_usage() {
    free | grep Mem | awk '{print int($3/$2 * 100)}'
}

get_disk_usage() {
    local path="${1:-/}"
    df "$path" | tail -1 | awk '{print int($5)}'
}

check_port() {
    local port=$1
    local host=${2:-localhost}
    nc -z "$host" "$port" 2>/dev/null
}

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists brew; then
        echo "brew"
    else
        echo "unknown"
    fi
}

install_package() {
    local package="$1"
    local pm=$(detect_package_manager)
    
    case $pm in
        apt)     sudo apt-get install -y "$package" ;;
        yum)     sudo yum install -y "$package" ;;
        dnf)     sudo dnf install -y "$package" ;;
        pacman)  sudo pacman -S --noconfirm "$package" ;;
        brew)    brew install "$package" ;;
        *)       return 1 ;;
    esac
}