#!/bin/bash
# validation.sh - Input validation utilities

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================
is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

is_positive_integer() {
    [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]
}

is_float() {
    [[ "$1" =~ ^-?[0-9]*\.?[0-9]+$ ]]
}

is_email() {
    [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

is_url() {
    [[ "$1" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]
}

is_ip() {
    local ip="$1"
    local IFS=.
    local -a octets=($ip)
    
    [[ ${#octets[@]} -eq 4 ]] || return 1
    
    for octet in "${octets[@]}"; do
        [[ "$octet" =~ ^[0-9]+$ ]] || return 1
        [[ "$octet" -le 255 ]] || return 1
    done
    return 0
}

is_port() {
    is_integer "$1" && [[ "$1" -ge 1 ]] && [[ "$1" -le 65535 ]]
}

is_absolute_path() {
    [[ "$1" = /* ]]
}

is_valid_filename() {
    local filename="$1"
    # No slashes, no null bytes, not empty
    [[ -n "$filename" ]] && [[ ! "$filename" =~ [/] ]] && [[ ! "$filename" =~ $'\0' ]]
}

# ============================================================================
# SANITIZATION
# ============================================================================
sanitize_filename() {
    local filename="$1"
    # Replace unsafe characters with underscore
    echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

sanitize_path() {
    local path="$1"
    # Remove ../ and ./ sequences
    echo "$path" | sed 's/\.\.//g' | sed 's/\.\///g'
}

escape_regex() {
    echo "$1" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

escape_sql() {
    echo "$1" | sed "s/'/\\'/g"
}

# ============================================================================
# REQUIREMENT CHECKS
# ============================================================================
require_value() {
    local value="$1"
    local name="$2"
    
    if [[ -z "$value" ]]; then
        die "Required value missing: $name"
    fi
}

require_integer() {
    local value="$1"
    local name="$2"
    
    require_value "$value" "$name"
    if ! is_integer "$value"; then
        die "Invalid integer value for $name: $value"
    fi
}

require_file() {
    local file="$1"
    local name="${2:-file}"
    
    if [[ ! -f "$file" ]]; then
        die "Required $name not found: $file"
    fi
}

require_command() {
    local cmd="$1"
    
    if ! command_exists "$cmd"; then
        die "Required command not found: $cmd"
    fi
}