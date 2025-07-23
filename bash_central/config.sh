#!/bin/bash
# config.sh - Configuration file handler

# ============================================================================
# DEFAULT CONFIGURATION
# ============================================================================
declare -A CONFIG

# Default values
CONFIG[app_name]="TuskLang"
CONFIG[app_version]="1.0.0"
CONFIG[install_dir]="/opt/tusk"
CONFIG[data_dir]="/var/lib/tusk"
CONFIG[log_dir]="/var/log/tusk"
CONFIG[config_dir]="/etc/tusk"
CONFIG[debug]="false"
CONFIG[verbose]="false"
CONFIG[dry_run]="false"

# ============================================================================
# CONFIG FILE FUNCTIONS
# ============================================================================
load_config() {
    local config_file="${1:-$HOME/.tusk/config}"
    
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Remove quotes if present
            value="${value%\"}"
            value="${value#\"}"
            
            CONFIG[$key]="$value"
        done < "$config_file"
    fi
}

save_config() {
    local config_file="${1:-$HOME/.tusk/config}"
    ensure_dir "$(dirname "$config_file")"
    
    {
        echo "# Tusk Configuration File"
        echo "# Generated on $(date)"
        echo ""
        
        for key in "${!CONFIG[@]}"; do
            echo "$key=\"${CONFIG[$key]}\""
        done | sort
    } > "$config_file"
}

get_config() {
    local key="$1"
    local default="${2:-}"
    echo "${CONFIG[$key]:-$default}"
}

set_config() {
    local key="$1"
    local value="$2"
    CONFIG[$key]="$value"
}

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================
setup_environment() {
    # Export important configs as environment variables
    export TUSK_HOME=$(get_config install_dir)
    export TUSK_DATA=$(get_config data_dir)
    export TUSK_LOGS=$(get_config log_dir)
    export TUSK_DEBUG=$(get_config debug)
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$TUSK_HOME/bin:"* ]]; then
        export PATH="$TUSK_HOME/bin:$PATH"
    fi
}

# Load user config on source
load_config