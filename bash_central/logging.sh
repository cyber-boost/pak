#!/bin/bash
# logging.sh - Logging utilities

# ============================================================================
# LOG CONFIGURATION
# ============================================================================
LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0" .sh).log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
LOG_TO_STDERR="${LOG_TO_STDERR:-false}"
LOG_TO_FILE="${LOG_TO_FILE:-true}"
LOG_TO_STDOUT="${LOG_TO_STDOUT:-true}"

# Log levels
declare -A LOG_LEVELS=(
    [TRACE]=0
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
    [FATAL]=5
)

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +"$LOG_DATE_FORMAT")
    local caller="${BASH_SOURCE[2]##*/}:${BASH_LINENO[1]}"
    
    # Check if we should log this level
    if [[ ${LOG_LEVELS[$level]} -lt ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        return
    fi
    
    # Format message
    local formatted_msg="[$timestamp] [$level] [$caller] $message"
    
    # Output based on level and settings
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        echo "$formatted_msg" >> "$LOG_FILE"
    fi
    
    if [[ "$LOG_TO_STDOUT" == "true" ]] || [[ "$LOG_TO_STDERR" == "true" ]]; then
        case $level in
            TRACE|DEBUG)
                [[ "$LOG_TO_STDOUT" == "true" ]] && echo -e "${GRAY}$formatted_msg${NC}"
                ;;
            INFO)
                [[ "$LOG_TO_STDOUT" == "true" ]] && echo -e "${BLUE}$formatted_msg${NC}"
                ;;
            WARN)
                [[ "$LOG_TO_STDERR" == "true" ]] && echo -e "${YELLOW}$formatted_msg${NC}" >&2
                ;;
            ERROR|FATAL)
                [[ "$LOG_TO_STDERR" == "true" ]] && echo -e "${RED}$formatted_msg${NC}" >&2
                ;;
        esac
    fi
}

# Convenience functions
log_trace() { log TRACE "$@"; }
log_debug() { log DEBUG "$@"; }
log_info()  { log INFO "$@"; }
log_warn()  { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_fatal() { log FATAL "$@"; exit 1; }

# ============================================================================
# LOG ROTATION
# ============================================================================
rotate_log() {
    local max_size="${1:-10485760}"  # 10MB default
    local max_files="${2:-5}"
    
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt $max_size ]]; then
        for i in $(seq $((max_files-1)) -1 1); do
            [[ -f "$LOG_FILE.$i" ]] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
        done
        mv "$LOG_FILE" "$LOG_FILE.1"
        : > "$LOG_FILE"
        log_info "Log rotated"
    fi
}