#!/bin/bash
# PAK.sh Error Handling Framework
# Comprehensive error handling with stack traces, recovery, and reporting

set -euo pipefail

# Error handling configuration
ERROR_LOG_FILE="${PAK_LOGS_DIR:-/tmp}/pak-errors.log"
ERROR_RECOVERY_ENABLED="${PAK_ERROR_RECOVERY_ENABLED:-true}"
ERROR_STACK_TRACE_ENABLED="${PAK_ERROR_STACK_TRACE_ENABLED:-true}"
ERROR_REPORTING_ENABLED="${PAK_ERROR_REPORTING_ENABLED:-true}"

# Error codes
declare -A ERROR_CODES=(
    [SYNTAX_ERROR]=1
    [CONFIG_ERROR]=2
    [MODULE_ERROR]=3
    [DEPLOYMENT_ERROR]=4
    [NETWORK_ERROR]=5
    [PERMISSION_ERROR]=6
    [VALIDATION_ERROR]=7
    [TIMEOUT_ERROR]=8
    [DEPENDENCY_ERROR]=9
    [RESOURCE_ERROR]=10
)

# Error severity levels
declare -A ERROR_SEVERITY=(
    [CRITICAL]=1
    [HIGH]=2
    [MEDIUM]=3
    [LOW]=4
    [INFO]=5
)

# Global error state
PAK_ERROR_STATE=()
PAK_ERROR_COUNT=0
PAK_LAST_ERROR=""
PAK_ERROR_CONTEXT=""

# Initialize error handling
init_error_handler() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$ERROR_LOG_FILE")"
    
    # Set up error trap
    trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
    
    # Set up exit trap for cleanup
    trap 'cleanup_on_exit' EXIT
    
    log DEBUG "Error handler initialized"
}

# Main error handler
handle_error() {
    local exit_code="$1"
    local line_number="$2"
    local bash_lineno="$3"
    local command="$4"
    local stack_trace="$5"
    
    # Increment error count
    ((PAK_ERROR_COUNT++))
    
    # Determine error type
    local error_type="UNKNOWN_ERROR"
    local severity="MEDIUM"
    
    case $exit_code in
        1) error_type="SYNTAX_ERROR"; severity="CRITICAL" ;;
        2) error_type="CONFIG_ERROR"; severity="HIGH" ;;
        3) error_type="MODULE_ERROR"; severity="HIGH" ;;
        4) error_type="DEPLOYMENT_ERROR"; severity="HIGH" ;;
        5) error_type="NETWORK_ERROR"; severity="MEDIUM" ;;
        6) error_type="PERMISSION_ERROR"; severity="CRITICAL" ;;
        7) error_type="VALIDATION_ERROR"; severity="MEDIUM" ;;
        8) error_type="TIMEOUT_ERROR"; severity="MEDIUM" ;;
        9) error_type="DEPENDENCY_ERROR"; severity="HIGH" ;;
        10) error_type="RESOURCE_ERROR"; severity="MEDIUM" ;;
        *) error_type="UNKNOWN_ERROR"; severity="MEDIUM" ;;
    esac
    
    # Create error message
    local error_message="[$error_type] Error occurred at line $line_number: $command"
    PAK_LAST_ERROR="$error_message"
    
    # Log error with context
    log_error_with_context "$error_type" "$severity" "$error_message" "$line_number" "$stack_trace"
    
    # Attempt recovery if enabled
    if [[ "$ERROR_RECOVERY_ENABLED" == "true" ]]; then
        attempt_error_recovery "$error_type" "$severity" "$exit_code"
    fi
    
    # Report error if enabled
    if [[ "$ERROR_REPORTING_ENABLED" == "true" ]]; then
        report_error "$error_type" "$severity" "$error_message"
    fi
    
    # Store error state
    PAK_ERROR_STATE+=("$error_type:$severity:$error_message")
    
    # Return original exit code
    return $exit_code
}

# Log error with full context
log_error_with_context() {
    local error_type="$1"
    local severity="$2"
    local message="$3"
    local line_number="$4"
    local stack_trace="$5"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create detailed error log entry
    {
        echo "=== PAK ERROR REPORT ==="
        echo "Timestamp: $timestamp"
        echo "Error Type: $error_type"
        echo "Severity: $severity"
        echo "Message: $message"
        echo "Line Number: $line_number"
        echo "Context: $PAK_ERROR_CONTEXT"
        
        if [[ "$ERROR_STACK_TRACE_ENABLED" == "true" && -n "$stack_trace" ]]; then
            echo "Stack Trace:"
            echo "$stack_trace" | tr ':' '\n' | sed 's/^/  /'
        fi
        
        echo "Environment:"
        echo "  PAK_VERSION: ${PAK_VERSION:-unknown}"
        echo "  BASH_VERSION: $BASH_VERSION"
        echo "  OS: $(uname -s) $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Working Directory: $(pwd)"
        echo "  User: $(whoami)"
        echo "  Process ID: $$"
        echo "========================"
        echo ""
    } >> "$ERROR_LOG_FILE"
    
    # Also log to standard error
    echo "[ERROR] $message" >&2
}

# Attempt error recovery
attempt_error_recovery() {
    local error_type="$1"
    local severity="$2"
    local exit_code="$3"
    
    log DEBUG "Attempting error recovery for $error_type (severity: $severity)"
    
    case "$error_type" in
        "CONFIG_ERROR")
            recover_config_error
            ;;
        "MODULE_ERROR")
            recover_module_error
            ;;
        "NETWORK_ERROR")
            recover_network_error
            ;;
        "DEPLOYMENT_ERROR")
            recover_deployment_error
            ;;
        "RESOURCE_ERROR")
            recover_resource_error
            ;;
        *)
            log WARN "No recovery strategy for error type: $error_type"
            ;;
    esac
}

# Recovery strategies
recover_config_error() {
    log INFO "Attempting config error recovery"
    
    # Try to reload configuration
    if [[ -f "$PAK_CONFIG_DIR/pak.conf" ]]; then
        source "$PAK_CONFIG_DIR/pak.conf"
        log INFO "Configuration reloaded"
    fi
}

recover_module_error() {
    log INFO "Attempting module error recovery"
    
    # Try to reinitialize modules
    if declare -f init_modules >/dev/null; then
        init_modules
        log INFO "Modules reinitialized"
    fi
}

recover_network_error() {
    log INFO "Attempting network error recovery"
    
    # Wait and retry
    sleep 2
    log INFO "Network retry completed"
}

recover_deployment_error() {
    log INFO "Attempting deployment error recovery"
    
    # Clean up any partial deployments
    if declare -f cleanup_deployment >/dev/null; then
        cleanup_deployment
        log INFO "Deployment cleanup completed"
    fi
}

recover_resource_error() {
    log INFO "Attempting resource error recovery"
    
    # Clear caches and temporary files
    rm -rf /tmp/pak-* 2>/dev/null || true
    log INFO "Resource cleanup completed"
}

# Report error to external systems
report_error() {
    local error_type="$1"
    local severity="$2"
    local message="$3"
    
    # Only report high severity errors
    if [[ "${ERROR_SEVERITY[$severity]}" -le "${ERROR_SEVERITY[HIGH]}" ]]; then
        log INFO "Reporting error: $error_type - $message"
        
        # Send to webhook if configured
        if [[ -n "${PAK_ERROR_WEBHOOK_URL:-}" ]]; then
            send_error_webhook "$error_type" "$severity" "$message"
        fi
        
        # Send to monitoring system if configured
        if [[ -n "${PAK_MONITORING_ENDPOINT:-}" ]]; then
            send_error_monitoring "$error_type" "$severity" "$message"
        fi
    fi
}

# Send error to webhook
send_error_webhook() {
    local error_type="$1"
    local severity="$2"
    local message="$3"
    
    local payload=$(cat << EOF
{
    "error_type": "$error_type",
    "severity": "$severity",
    "message": "$message",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "${PAK_VERSION:-unknown}",
    "environment": "$(uname -s)"
}
EOF
)
    
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$PAK_ERROR_WEBHOOK_URL" >/dev/null 2>&1 || true
}

# Send error to monitoring system
send_error_monitoring() {
    local error_type="$1"
    local severity="$2"
    local message="$3"
    
    # Implementation depends on monitoring system
    log DEBUG "Sending error to monitoring: $error_type"
}

# Set error context
set_error_context() {
    PAK_ERROR_CONTEXT="$1"
    log DEBUG "Error context set: $PAK_ERROR_CONTEXT"
}

# Clear error context
clear_error_context() {
    PAK_ERROR_CONTEXT=""
}

# Get error statistics
get_error_stats() {
    echo "Error Statistics:"
    echo "  Total Errors: $PAK_ERROR_COUNT"
    echo "  Last Error: $PAK_LAST_ERROR"
    echo "  Error Log: $ERROR_LOG_FILE"
    
    if [[ -f "$ERROR_LOG_FILE" ]]; then
        echo "  Recent Errors:"
        tail -5 "$ERROR_LOG_FILE" | grep "Error Type:" | tail -3
    fi
}

# Cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log WARN "PAK exiting with error code: $exit_code"
        get_error_stats
    fi
    
    # Clear error context
    clear_error_context
}

# Error validation functions
validate_error_code() {
    local code="$1"
    
    if [[ -n "${ERROR_CODES[$code]:-}" ]]; then
        return 0
    else
        return 1
    fi
}

validate_severity() {
    local severity="$1"
    
    if [[ -n "${ERROR_SEVERITY[$severity]:-}" ]]; then
        return 0
    else
        return 1
    fi
}

# Error utility functions
create_error() {
    local error_type="$1"
    local message="$2"
    local severity="${3:-MEDIUM}"
    
    if ! validate_error_code "$error_type"; then
        log ERROR "Invalid error type: $error_type"
        return 1
    fi
    
    if ! validate_severity "$severity"; then
        log ERROR "Invalid severity: $severity"
        return 1
    fi
    
    local exit_code="${ERROR_CODES[$error_type]}"
    log_error_with_context "$error_type" "$severity" "$message" "$LINENO" ""
    
    return $exit_code
}

# Export functions for use in modules
export -f init_error_handler
export -f handle_error
export -f set_error_context
export -f clear_error_context
export -f get_error_stats
export -f create_error
export -f validate_error_code
export -f validate_severity

# Initialize error handler if script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_error_handler
fi 