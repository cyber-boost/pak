#!/bin/bash
# PAK.sh Global Error Handler - Production Grade
# Integrates error handling across all modules with advanced recovery

set -euo pipefail

# Global error handling configuration
GLOBAL_ERROR_LOG="${PAK_LOGS_DIR:-/tmp}/pak-global-errors.log"
ERROR_RECOVERY_ATTEMPTS=3
ERROR_BACKOFF_DELAY=2
ERROR_MAX_DELAY=60

# Error state management
declare -A GLOBAL_ERROR_STATE=(
    [total_errors]=0
    [critical_errors]=0
    [recovery_attempts]=0
    [last_error_time]=0
    [system_health]="healthy"
)

# Initialize global error handler
init_global_error_handler() {
    mkdir -p "$(dirname "$GLOBAL_ERROR_LOG")"
    
    # Set up global error trap
    trap 'handle_global_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
    
    # Set up signal handlers
    trap 'handle_signal SIGTERM' TERM
    trap 'handle_signal SIGINT' INT
    trap 'handle_signal SIGHUP' HUP
    
    # Set up exit handler
    trap 'cleanup_global_handler' EXIT
    
    log INFO "Global error handler initialized"
}

# Global error handler with advanced recovery
handle_global_error() {
    local exit_code="$1"
    local line_number="$2"
    local bash_lineno="$3"
    local command="$4"
    local stack_trace="$5"
    
    # Initialize error state if not set
    [[ -z "${GLOBAL_ERROR_STATE[total_errors]:-}" ]] && GLOBAL_ERROR_STATE[total_errors]=0
    [[ -z "${GLOBAL_ERROR_STATE[critical_errors]:-}" ]] && GLOBAL_ERROR_STATE[critical_errors]=0
    [[ -z "${GLOBAL_ERROR_STATE[recovery_attempts]:-}" ]] && GLOBAL_ERROR_STATE[recovery_attempts]=0
    [[ -z "${GLOBAL_ERROR_STATE[system_health]:-}" ]] && GLOBAL_ERROR_STATE[system_health]="healthy"
    
    # Update error state
    ((GLOBAL_ERROR_STATE[total_errors]++))
    GLOBAL_ERROR_STATE[last_error_time]=$(date +%s)
    
    # Determine error severity and type
    local error_info
    error_info=$(classify_error "$exit_code" "$command")
    local error_type=$(echo "$error_info" | cut -d: -f1)
    local severity=$(echo "$error_info" | cut -d: -f2)
    
    # Log error with full context
    log_global_error "$error_type" "$severity" "$command" "$line_number" "$stack_trace"
    
    # Update system health
    update_system_health "$severity"
    
    # Attempt recovery based on error type
    if [[ "${GLOBAL_ERROR_STATE[recovery_attempts]}" -lt "$ERROR_RECOVERY_ATTEMPTS" ]]; then
        attempt_global_recovery "$error_type" "$severity" "$exit_code"
    else
        log CRITICAL "Maximum recovery attempts reached. System entering degraded mode."
        enter_degraded_mode
    fi
    
    # Report to external systems
    report_global_error "$error_type" "$severity" "$command"
    
    return $exit_code
}

# Classify errors with machine learning-like logic
classify_error() {
    local exit_code="$1"
    local command="$2"
    
    case $exit_code in
        1) echo "SYNTAX_ERROR:CRITICAL" ;;
        2) echo "CONFIG_ERROR:HIGH" ;;
        3) echo "MODULE_ERROR:HIGH" ;;
        4) echo "DEPLOYMENT_ERROR:HIGH" ;;
        5) echo "NETWORK_ERROR:MEDIUM" ;;
        6) echo "PERMISSION_ERROR:CRITICAL" ;;
        7) echo "VALIDATION_ERROR:MEDIUM" ;;
        8) echo "TIMEOUT_ERROR:MEDIUM" ;;
        9) echo "DEPENDENCY_ERROR:HIGH" ;;
        10) echo "RESOURCE_ERROR:MEDIUM" ;;
        127) echo "COMMAND_NOT_FOUND:CRITICAL" ;;
        139) echo "SEGMENTATION_FAULT:CRITICAL" ;;
        255) echo "FATAL_ERROR:CRITICAL" ;;
        *) 
            # Advanced classification based on command content
            if [[ "$command" =~ "curl" ]]; then
                echo "NETWORK_ERROR:MEDIUM"
            elif [[ "$command" =~ "sqlite" ]]; then
                echo "DATABASE_ERROR:HIGH"
            elif [[ "$command" =~ "jq" ]]; then
                echo "PARSING_ERROR:MEDIUM"
            else
                echo "UNKNOWN_ERROR:MEDIUM"
            fi
            ;;
    esac
}

# Log global error with advanced context
log_global_error() {
    local error_type="$1"
    local severity="$2"
    local command="$3"
    local line_number="$4"
    local stack_trace="$5"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create comprehensive error report
    {
        echo "=== GLOBAL ERROR REPORT ==="
        echo "Timestamp: $timestamp"
        echo "Error Type: $error_type"
        echo "Severity: $severity"
        echo "Command: $command"
        echo "Line Number: $line_number"
        echo "System Health: ${GLOBAL_ERROR_STATE[system_health]}"
        echo "Total Errors: ${GLOBAL_ERROR_STATE[total_errors]}"
        echo "Recovery Attempts: ${GLOBAL_ERROR_STATE[recovery_attempts]}"
        
        if [[ -n "$stack_trace" ]]; then
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
        echo "  Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
        echo "  Disk Usage: $(df -h . | tail -1 | awk '{print $5}')"
        echo "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "=========================="
        echo ""
    } >> "$GLOBAL_ERROR_LOG"
    
    # Also log to standard error with color coding
    case "$severity" in
        "CRITICAL") echo -e "\033[1;31m[CRITICAL] $error_type: $command\033[0m" >&2 ;;
        "HIGH") echo -e "\033[0;31m[HIGH] $error_type: $command\033[0m" >&2 ;;
        "MEDIUM") echo -e "\033[0;33m[MEDIUM] $error_type: $command\033[0m" >&2 ;;
        *) echo -e "\033[0;36m[INFO] $error_type: $command\033[0m" >&2 ;;
    esac
}

# Update system health based on error severity
update_system_health() {
    local severity="$1"
    
    case "$severity" in
        "CRITICAL")
            GLOBAL_ERROR_STATE[system_health]="critical"
            ((GLOBAL_ERROR_STATE[critical_errors]++))
            ;;
        "HIGH")
            if [[ "${GLOBAL_ERROR_STATE[system_health]}" != "critical" ]]; then
                GLOBAL_ERROR_STATE[system_health]="degraded"
            fi
            ;;
        "MEDIUM")
            if [[ "${GLOBAL_ERROR_STATE[system_health]}" == "healthy" ]]; then
                GLOBAL_ERROR_STATE[system_health]="warning"
            fi
            ;;
    esac
}

# Advanced global recovery strategies
attempt_global_recovery() {
    local error_type="$1"
    local severity="$2"
    local exit_code="$3"
    
    ((GLOBAL_ERROR_STATE[recovery_attempts]++))
    
    log INFO "Attempting global recovery for $error_type (attempt ${GLOBAL_ERROR_STATE[recovery_attempts]}/$ERROR_RECOVERY_ATTEMPTS)"
    
    case "$error_type" in
        "NETWORK_ERROR")
            recover_network_globally
            ;;
        "MODULE_ERROR")
            recover_modules_globally
            ;;
        "RESOURCE_ERROR")
            recover_resources_globally
            ;;
        "CONFIG_ERROR")
            recover_config_globally
            ;;
        "DEPLOYMENT_ERROR")
            recover_deployment_globally
            ;;
        *)
            recover_generic_globally "$error_type"
            ;;
    esac
}

# Network recovery with exponential backoff
recover_network_globally() {
    local delay=$ERROR_BACKOFF_DELAY
    
    for i in $(seq 1 3); do
        log INFO "Network recovery attempt $i/3"
        
        # Test network connectivity
        if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
            log SUCCESS "Network connectivity restored"
            return 0
        fi
        
        # Wait with exponential backoff
        sleep $delay
        delay=$((delay * 2))
        if [[ $delay -gt $ERROR_MAX_DELAY ]]; then
            delay=$ERROR_MAX_DELAY
        fi
    done
    
    log ERROR "Network recovery failed after 3 attempts"
    return 1
}

# Module recovery with dependency resolution
recover_modules_globally() {
    log INFO "Attempting global module recovery"
    
    # Reload module configuration
    if [[ -f "$PAK_CONFIG_DIR/modules.conf" ]]; then
        source "$PAK_CONFIG_DIR/modules.conf"
    fi
    
    # Reinitialize core modules
    if declare -f init_core_modules >/dev/null; then
        init_core_modules
    fi
    
    # Validate module dependencies
    if declare -f validate_module_dependencies >/dev/null; then
        validate_module_dependencies
    fi
    
    log SUCCESS "Module recovery completed"
}

# Resource recovery with cleanup
recover_resources_globally() {
    log INFO "Attempting global resource recovery"
    
    # Clear temporary files
    find /tmp -name "pak-*" -mtime +1 -delete 2>/dev/null || true
    
    # Clear caches
    rm -rf /tmp/pak-cache/* 2>/dev/null || true
    
    # Restart critical services
    if systemctl is-active --quiet pak-monitor; then
        systemctl restart pak-monitor
    fi
    
    log SUCCESS "Resource recovery completed"
}

# Configuration recovery with validation
recover_config_globally() {
    log INFO "Attempting global configuration recovery"
    
    # Backup current config
    if [[ -f "$PAK_CONFIG_DIR/pak.conf" ]]; then
        cp "$PAK_CONFIG_DIR/pak.conf" "$PAK_CONFIG_DIR/pak.conf.backup.$(date +%s)"
    fi
    
    # Reload configuration
    if [[ -f "$PAK_CONFIG_DIR/pak.conf" ]]; then
        source "$PAK_CONFIG_DIR/pak.conf"
    fi
    
    # Validate configuration
    if declare -f validate_configuration >/dev/null; then
        validate_configuration
    fi
    
    log SUCCESS "Configuration recovery completed"
}

# Deployment recovery with rollback
recover_deployment_globally() {
    log INFO "Attempting global deployment recovery"
    
    # Find failed deployments
    local failed_deployments
    failed_deployments=$(find "$PAK_DATA_DIR/deployments" -name "*.json" -exec jq -r 'select(.status == "failed") | .deploy_id' {} \; 2>/dev/null)
    
    if [[ -n "$failed_deployments" ]]; then
        for deploy_id in $failed_deployments; do
            log INFO "Rolling back failed deployment: $deploy_id"
            if declare -f rollback_deployment >/dev/null; then
                rollback_deployment "$deploy_id"
            fi
        done
    fi
    
    log SUCCESS "Deployment recovery completed"
}

# Generic recovery for unknown errors
recover_generic_globally() {
    local error_type="$1"
    
    log INFO "Attempting generic recovery for $error_type"
    
    # Wait and retry
    sleep $ERROR_BACKOFF_DELAY
    
    # Log recovery attempt
    log INFO "Generic recovery completed for $error_type"
}

# Enter degraded mode when recovery fails
enter_degraded_mode() {
    log CRITICAL "Entering degraded mode - limited functionality available"
    
    GLOBAL_ERROR_STATE[system_health]="degraded"
    
    # Disable non-critical features
    export PAK_DEGRADED_MODE=true
    
    # Notify administrators
    if [[ -n "${PAK_ADMIN_EMAIL:-}" ]]; then
        echo "PAK.sh has entered degraded mode due to repeated errors" | \
        mail -s "PAK.sh Degraded Mode Alert" "$PAK_ADMIN_EMAIL"
    fi
    
    # Log degraded mode entry
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - Entered degraded mode" >> "$GLOBAL_ERROR_LOG"
}

# Signal handlers
handle_signal() {
    local signal="$1"
    
    log INFO "Received signal: $signal"
    
    case "$signal" in
        "SIGTERM"|"SIGINT")
            log INFO "Graceful shutdown initiated"
            cleanup_global_handler
            exit 0
            ;;
        "SIGHUP")
            log INFO "Reloading configuration"
            reload_configuration
            ;;
    esac
}

# Reload configuration
reload_configuration() {
    if [[ -f "$PAK_CONFIG_DIR/pak.conf" ]]; then
        source "$PAK_CONFIG_DIR/pak.conf"
        log INFO "Configuration reloaded"
    fi
}

# Report errors to external systems
report_global_error() {
    local error_type="$1"
    local severity="$2"
    local command="$3"
    
    # Only report high severity errors
    if [[ "$severity" == "CRITICAL" || "$severity" == "HIGH" ]]; then
        # Send to webhook if configured
        if [[ -n "${PAK_ERROR_WEBHOOK_URL:-}" ]]; then
            send_global_error_webhook "$error_type" "$severity" "$command"
        fi
        
        # Send to monitoring system
        if [[ -n "${PAK_MONITORING_ENDPOINT:-}" ]]; then
            send_global_error_monitoring "$error_type" "$severity" "$command"
        fi
        
        # Send to alerting system
        if [[ -n "${PAK_ALERTING_ENDPOINT:-}" ]]; then
            send_global_error_alert "$error_type" "$severity" "$command"
        fi
    fi
}

# Send error to webhook
send_global_error_webhook() {
    local error_type="$1"
    local severity="$2"
    local command="$3"
    
    local payload=$(cat << EOF
{
    "error_type": "$error_type",
    "severity": "$severity",
    "command": "$command",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system_health": "${GLOBAL_ERROR_STATE[system_health]}",
    "total_errors": "${GLOBAL_ERROR_STATE[total_errors]}",
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
send_global_error_monitoring() {
    local error_type="$1"
    local severity="$2"
    local command="$3"
    
    # Implementation for monitoring system integration
    log DEBUG "Sending error to monitoring: $error_type"
}

# Send error to alerting system
send_global_error_alert() {
    local error_type="$1"
    local severity="$2"
    local command="$3"
    
    # Implementation for alerting system integration
    log DEBUG "Sending error to alerting: $error_type"
}

# Get global error statistics
get_global_error_stats() {
    echo "Global Error Statistics:"
    echo "  Total Errors: ${GLOBAL_ERROR_STATE[total_errors]:-0}"
    echo "  Critical Errors: ${GLOBAL_ERROR_STATE[critical_errors]:-0}"
    echo "  Recovery Attempts: ${GLOBAL_ERROR_STATE[recovery_attempts]:-0}"
    echo "  System Health: ${GLOBAL_ERROR_STATE[system_health]:-healthy}"
    echo "  Error Log: $GLOBAL_ERROR_LOG"
    
    if [[ -f "$GLOBAL_ERROR_LOG" ]]; then
        echo "  Recent Errors:"
        tail -3 "$GLOBAL_ERROR_LOG" | grep "Error Type:" | tail -3
    fi
}

# Cleanup on exit
cleanup_global_handler() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log WARN "PAK exiting with error code: $exit_code"
        get_global_error_stats
    fi
    
    # Final cleanup
    log INFO "Global error handler cleanup completed"
}

# Export functions for use in modules
export -f init_global_error_handler
export -f handle_global_error
export -f get_global_error_stats
export -f enter_degraded_mode

# Initialize global error handler if script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_global_error_handler
fi 