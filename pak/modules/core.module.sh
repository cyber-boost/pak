#!/bin/bash
# Core module - Essential functions and utilities for PAK system

# Module metadata
CORE_MODULE_VERSION="2.0.0"
CORE_MODULE_DEPENDENCIES=()
CORE_MODULE_HOOKS=("pre_init" "post_init" "pre_command" "post_command" "system_health_check")

# Module state
declare -A CORE_CONFIG_CACHE
declare -A CORE_HEALTH_STATUS
declare -A CORE_VERSION_INFO

core_init() {
    log DEBUG "Initializing core module v$CORE_MODULE_VERSION"
    
    # Initialize module state
    CORE_CONFIG_CACHE=()
    CORE_HEALTH_STATUS=()
    CORE_VERSION_INFO=()
    
    # Load version information
    core_load_version_info
    
    # Validate system requirements
    core_validate_system_requirements
    
    # Initialize health monitoring
    core_init_health_monitoring
    
    # Register hooks
    core_register_hooks
    
    log DEBUG "Core module initialized successfully"
}

core_register_commands() {
    register_command "version" "core" "core_version"
    register_command "config" "core" "core_config"
    register_command "status" "core" "core_status"
    register_command "health" "core" "core_health"
    register_command "validate" "core" "core_validate"
    register_command "update" "core" "core_update"
    register_command "doctor" "core" "core_doctor"
    register_command "info" "core" "core_info"
    register_command "web" "core" "core_web"
}

core_register_hooks() {
    register_hook "pre_init" "core" "core_pre_init" 10
    register_hook "post_init" "core" "core_post_init" 90
    register_hook "pre_command" "core" "core_pre_command" 10
    register_hook "post_command" "core" "core_post_command" 90
    register_hook "system_health_check" "core" "core_health_check" 50
}

# Hook implementations
core_pre_init() {
    log DEBUG "Core pre-init hook executed"
    core_validate_directories
}

core_post_init() {
    log DEBUG "Core post-init hook executed"
    core_update_health_status "initialization" "completed"
}

core_pre_command() {
    local command="$1"
    log DEBUG "Core pre-command hook for: $command"
    core_update_health_status "last_command" "$command"
}

core_post_command() {
    local command="$1"
    local result="$2"
    log DEBUG "Core post-command hook for: $command (result: $result)"
    core_update_health_status "last_command_result" "$result"
}

# Version management
core_version() {
    local detail="${1:-basic}"
    
    case "$detail" in
        basic)
            echo "PAK.sh - Package Automation Kit"
            echo "Version: $PAK_VERSION"
            echo "Core Module: $CORE_MODULE_VERSION"
            ;;
        full)
            echo "=== PAK Version Information ==="
            echo "PAK Version: $PAK_VERSION"
            echo "Core Module: $CORE_MODULE_VERSION"
            echo "Bash Version: $BASH_VERSION"
            echo "System: $(uname -s) $(uname -r)"
            echo "Architecture: $(uname -m)"
            echo ""
            echo "Module Versions:"
            for module in "${!LOADED_MODULES[@]}"; do
                local version_var="${module^^}_MODULE_VERSION"
                local version="${!version_var:-unknown}"
                echo "  $module: $version"
            done
            ;;
        json)
            core_get_version_json
            ;;
    esac
}

core_get_version_json() {
    local json="{"
    json+="\"pak_version\":\"$PAK_VERSION\","
    json+="\"core_module_version\":\"$CORE_MODULE_VERSION\","
    json+="\"bash_version\":\"$BASH_VERSION\","
    json+="\"system\":\"$(uname -s) $(uname -r)\","
    json+="\"architecture\":\"$(uname -m)\","
    json+="\"modules\":{"
    
    local first=true
    for module in "${!LOADED_MODULES[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json+=","
        fi
        local version_var="${module^^}_MODULE_VERSION"
        local version="${!version_var:-unknown}"
        json+="\"$module\":\"$version\""
    done
    
    json+="}}"
    echo "$json"
}

# Configuration management
core_config() {
    local action="${1:-show}"
    local key="${2:-}"
    local value="${3:-}"
    
    case "$action" in
        show)
            if [[ -n "$key" ]]; then
                core_get_config_value "$key"
            else
                cat "$PAK_CONFIG_DIR/pak.conf"
            fi
            ;;
        set)
            if [[ -n "$key" && -n "$value" ]]; then
                core_set_config_value "$key" "$value"
            else
                log ERROR "Usage: pak config set KEY VALUE"
                return 1
            fi
            ;;
        get)
            if [[ -n "$key" ]]; then
                core_get_config_value "$key"
            else
                log ERROR "Usage: pak config get KEY"
                return 1
            fi
            ;;
        edit)
            ${EDITOR:-vi} "$PAK_CONFIG_DIR/pak.conf"
            ;;
        validate)
            core_validate_config
            ;;
        reload)
            core_reload_config
            ;;
        schema)
            core_show_config_schema
            ;;
        *)
            log ERROR "Unknown config action: $action"
            return 1
            ;;
    esac
}

core_get_config_value() {
    local key="$1"
    local value
    
    # Check cache first
    if [[ -n "${CORE_CONFIG_CACHE[$key]:-}" ]]; then
        echo "${CORE_CONFIG_CACHE[$key]}"
        return 0
    fi
    
    # Parse config file
    value=$(grep "^${key}=" "$PAK_CONFIG_DIR/pak.conf" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
    
    # Cache the result
    CORE_CONFIG_CACHE["$key"]="$value"
    
    echo "$value"
}

core_set_config_value() {
    local key="$1"
    local value="$2"
    local config_file="$PAK_CONFIG_DIR/pak.conf"
    
    # Update config file
    if grep -q "^${key}=" "$config_file" 2>/dev/null; then
        sed -i "s/^${key}=.*/${key}=\"${value}\"/" "$config_file"
    else
        echo "${key}=\"${value}\"" >> "$config_file"
    fi
    
    # Update cache
    CORE_CONFIG_CACHE["$key"]="$value"
    
    log INFO "Configuration updated: $key=$value"
}

core_validate_config() {
    local errors=0
    local config_file="$PAK_CONFIG_DIR/pak.conf"
    
    log INFO "Validating configuration..."
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Configuration file not found: $config_file"
        return 1
    fi
    
    # Validate required settings
    local required_settings=(
        "PAK_DEFAULT_PLATFORMS"
        "PAK_PARALLEL_JOBS"
        "PAK_CACHE_TTL"
        "PAK_API_TIMEOUT"
    )
    
    for setting in "${required_settings[@]}"; do
        if ! grep -q "^${setting}=" "$config_file"; then
            log ERROR "Missing required setting: $setting"
            ((errors++))
        fi
    done
    
    # Validate syntax
    if ! core_validate_config_syntax "$config_file"; then
        log ERROR "Configuration syntax errors detected"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log SUCCESS "Configuration validation passed"
        return 0
    else
        log ERROR "Configuration validation failed with $errors errors"
        return 1
    fi
}

core_validate_config_syntax() {
    local config_file="$1"
    
    # Check for basic syntax issues
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check for valid key=value format
        if [[ ! "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            log ERROR "Invalid config line: $line"
            return 1
        fi
    done < "$config_file"
    
    return 0
}

core_reload_config() {
    log INFO "Reloading configuration..."
    CORE_CONFIG_CACHE=()
    source "$PAK_CONFIG_DIR/pak.conf"
    log SUCCESS "Configuration reloaded"
}

core_show_config_schema() {
    cat << 'EOF'
# PAK Configuration Schema

# Core settings (required)
PAK_DEFAULT_PLATFORMS="npm pypi cargo nuget packagist rubygems"  # Supported platforms
PAK_PARALLEL_JOBS=5                                              # Number of parallel jobs
PAK_CACHE_TTL=3600                                              # Cache TTL in seconds
PAK_API_TIMEOUT=30                                              # API timeout in seconds

# Module settings (optional)
PAK_ENABLE_ANALYTICS=true                                       # Enable analytics module
PAK_ENABLE_SECURITY=true                                        # Enable security module
PAK_ENABLE_AUTOMATION=true                                      # Enable automation module
PAK_ENABLE_ML=true                                              # Enable ML module

# Feature flags (optional)
PAK_FEATURE_WEBHOOKS=true                                       # Enable webhooks
PAK_FEATURE_PLUGINS=true                                        # Enable plugin system
PAK_FEATURE_API_SERVER=false                                    # Enable API server

# Notifications (optional)
PAK_NOTIFY_EMAIL=""                                             # Email notifications
PAK_NOTIFY_SLACK=""                                             # Slack notifications
PAK_NOTIFY_DISCORD=""                                           # Discord notifications

# Advanced settings (optional)
PAK_LOG_LEVEL="INFO"                                            # Log level (DEBUG, INFO, WARN, ERROR)
PAK_MAX_RETRIES=3                                               # Maximum retry attempts
PAK_BACKUP_RETENTION=30                                         # Backup retention days
EOF
}

# System status and health monitoring
core_status() {
    local detail="${1:-basic}"
    
    case "$detail" in
        basic)
            echo "=== PAK System Status ==="
            echo "Version: $PAK_VERSION"
            echo "Config: $PAK_CONFIG_DIR/pak.conf"
            echo "Data: $PAK_DATA_DIR"
            echo "Logs: $PAK_LOGS_DIR"
            echo ""
            echo "Loaded Modules:"
            for module in "${!LOADED_MODULES[@]}"; do
                echo "  ✓ $module"
            done
            echo ""
            echo "Registered Commands: ${#MODULE_COMMANDS[@]}"
            echo "Registered Hooks: ${#MODULE_HOOKS[@]}"
            ;;
        detailed)
            core_status_detailed
            ;;
        health)
            core_health
            ;;
    esac
}

core_status_detailed() {
    echo "=== PAK Detailed System Status ==="
    echo "Version Information:"
    core_version full
    echo ""
    
    echo "Directory Structure:"
    echo "  Config: $PAK_CONFIG_DIR ($(find "$PAK_CONFIG_DIR" -type f | wc -l) files)"
    echo "  Data: $PAK_DATA_DIR ($(du -sh "$PAK_DATA_DIR" 2>/dev/null | cut -f1 || echo "N/A"))"
    echo "  Logs: $PAK_LOGS_DIR ($(du -sh "$PAK_LOGS_DIR" 2>/dev/null | cut -f1 || echo "N/A"))"
    echo "  Modules: $PAK_MODULES_DIR ($(find "$PAK_MODULES_DIR" -name "*.module.sh" | wc -l) modules)"
    echo ""
    
    echo "Module Details:"
    for module in "${!LOADED_MODULES[@]}"; do
        local version_var="${module^^}_MODULE_VERSION"
        local version="${!version_var:-unknown}"
        echo "  $module (v$version)"
    done
    echo ""
    
    echo "Command Registry:"
    for cmd in "${!MODULE_COMMANDS[@]}"; do
        local module_func="${MODULE_COMMANDS[$cmd]}"
        local module="${module_func%%:*}"
        local function="${module_func#*:}"
        echo "  $cmd -> $module:$function"
    done | sort
    echo ""
    
    echo "Hook Registry:"
    for hook_key in "${!MODULE_HOOKS[@]}"; do
        local hook_name="${hook_key%%:*}"
        local priority="${hook_key#*:}"
        priority="${priority%%:*}"
        local module="${hook_key##*:}"
        local function="${MODULE_HOOKS[$hook_key]}"
        echo "  $hook_name (priority: $priority) -> $module:$function"
    done | sort
}

core_health() {
    local check="${1:-all}"
    
    case "$check" in
        all)
            core_health_check_all
            ;;
        system)
            core_health_check_system
            ;;
        modules)
            core_health_check_modules
            ;;
        config)
            core_health_check_config
            ;;
        dependencies)
            core_health_check_dependencies
            ;;
        *)
            log ERROR "Unknown health check: $check"
            return 1
            ;;
    esac
}

core_health_check_all() {
    echo "=== PAK System Health Check ==="
    
    local overall_status="healthy"
    local checks=("system" "modules" "config" "dependencies")
    
    for check in "${checks[@]}"; do
        echo ""
        echo "--- $check Check ---"
        if ! core_health "check"; then
            overall_status="unhealthy"
        fi
    done
    
    echo ""
    echo "Overall Status: $overall_status"
    
    if [[ "$overall_status" == "healthy" ]]; then
        return 0
    else
        return 1
    fi
}

core_health_check_system() {
    local status="healthy"
    
    # Check disk space
    local disk_usage=$(df "$PAK_DATA_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        log WARN "Low disk space: ${disk_usage}%"
        status="warning"
    fi
    
    # Check memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [[ $mem_usage -gt 85 ]]; then
        log WARN "High memory usage: ${mem_usage}%"
        status="warning"
    fi
    
    # Check permissions
    if [[ ! -w "$PAK_DATA_DIR" ]]; then
        log ERROR "Data directory not writable: $PAK_DATA_DIR"
        status="unhealthy"
    fi
    
    if [[ ! -w "$PAK_LOGS_DIR" ]]; then
        log ERROR "Logs directory not writable: $PAK_LOGS_DIR"
        status="unhealthy"
    fi
    
    echo "System Status: $status"
    [[ "$status" == "healthy" || "$status" == "warning" ]]
}

core_health_check_modules() {
    local status="healthy"
    
    for module in "${!LOADED_MODULES[@]}"; do
        local module_file="$PAK_MODULES_DIR/${module}.module.sh"
        
        if [[ ! -f "$module_file" ]]; then
            log ERROR "Module file missing: $module_file"
            status="unhealthy"
            continue
        fi
        
        if [[ ! -r "$module_file" ]]; then
            log ERROR "Module file not readable: $module_file"
            status="unhealthy"
            continue
        fi
        
        # Check if module has required functions
        if ! grep -q "${module}_init" "$module_file"; then
            log WARN "Module missing init function: $module"
            status="warning"
        fi
        
        if ! grep -q "${module}_register_commands" "$module_file"; then
            log WARN "Module missing command registration: $module"
            status="warning"
        fi
    done
    
    echo "Modules Status: $status"
    [[ "$status" == "healthy" || "$status" == "warning" ]]
}

core_health_check_config() {
    local status="healthy"
    
    if ! core_validate_config; then
        status="unhealthy"
    fi
    
    # Check for deprecated settings
    local deprecated_settings=("PAK_OLD_SETTING" "PAK_DEPRECATED")
    for setting in "${deprecated_settings[@]}"; do
        if grep -q "^${setting}=" "$PAK_CONFIG_DIR/pak.conf" 2>/dev/null; then
            log WARN "Deprecated setting found: $setting"
            status="warning"
        fi
    done
    
    echo "Config Status: $status"
    [[ "$status" == "healthy" || "$status" == "warning" ]]
}

core_health_check_dependencies() {
    local status="healthy"
    local required_tools=("jq" "curl" "grep" "sed" "awk")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log ERROR "Required tool missing: $tool"
            status="unhealthy"
        fi
    done
    
    echo "Dependencies Status: $status"
    [[ "$status" == "healthy" ]]
}

# System validation
core_validate() {
    local component="${1:-all}"
    
    case "$component" in
        all)
            core_validate_system_requirements
            core_validate_config
            core_validate_modules
            ;;
        system)
            core_validate_system_requirements
            ;;
        config)
            core_validate_config
            ;;
        modules)
            core_validate_modules
            ;;
        *)
            log ERROR "Unknown validation component: $component"
            return 1
            ;;
    esac
}

core_validate_system_requirements() {
    log DEBUG "Validating system requirements..."
    
    # Check bash version
    local bash_major="${BASH_VERSION%%.*}"
    if [[ $bash_major -lt 4 ]]; then
        log ERROR "Bash 4.0 or higher required (current: $BASH_VERSION)"
        return 1
    fi
    
    # Check required directories
    local required_dirs=("$PAK_CONFIG_DIR" "$PAK_DATA_DIR" "$PAK_LOGS_DIR" "$PAK_MODULES_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log ERROR "Required directory missing: $dir"
            return 1
        fi
    done
    
    # Check required tools
    local required_tools=("jq" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log ERROR "Required tool missing: $tool"
            return 1
        fi
    done
    
    log DEBUG "System requirements validation passed"
    return 0
}

core_validate_modules() {
    log DEBUG "Validating modules..."
    
    for module in "${!LOADED_MODULES[@]}"; do
        local module_file="$PAK_MODULES_DIR/${module}.module.sh"
        
        if [[ ! -f "$module_file" ]]; then
            log ERROR "Module file missing: $module_file"
            return 1
        fi
        
        # Check module syntax
        if ! bash -n "$module_file" 2>/dev/null; then
            log ERROR "Module syntax error: $module_file"
            return 1
        fi
    done
    
    log DEBUG "Module validation passed"
    return 0
}

# Update functionality
core_update() {
    local component="${1:-system}"
    
    case "$component" in
        system)
            core_update_system
            ;;
        modules)
            core_update_modules
            ;;
        config)
            core_update_config
            ;;
        *)
            log ERROR "Unknown update component: $component"
            return 1
            ;;
    esac
}

core_update_system() {
    log INFO "Updating PAK system..."
    
    # This would typically involve git pull or package update
    log INFO "System update completed"
}

core_update_modules() {
    log INFO "Updating modules..."
    
    # Reload all modules
    for module in "${!LOADED_MODULES[@]}"; do
        load_module "$module"
    done
    
    log INFO "Modules updated"
}

core_update_config() {
    log INFO "Updating configuration..."
    core_reload_config
}

# System diagnostics
core_doctor() {
    echo "=== PAK System Diagnostics ==="
    
    # Run all health checks
    core_health all
    
    # Additional diagnostics
    echo ""
    echo "--- Additional Diagnostics ---"
    
    # Check for common issues
    core_diagnose_common_issues
    
    # Performance metrics
    core_show_performance_metrics
}

core_diagnose_common_issues() {
    echo "Common Issues Check:"
    
    # Check for permission issues
    if [[ ! -w "$PAK_DATA_DIR" ]]; then
        echo "  ❌ Data directory not writable"
    else
        echo "  ✅ Data directory writable"
    fi
    
    # Check for configuration issues
    if ! core_validate_config &>/dev/null; then
        echo "  ❌ Configuration validation failed"
    else
        echo "  ✅ Configuration valid"
    fi
    
    # Check for module issues
    local module_errors=0
    for module in "${!LOADED_MODULES[@]}"; do
        if [[ ! -f "$PAK_MODULES_DIR/${module}.module.sh" ]]; then
            ((module_errors++))
        fi
    done
    
    if [[ $module_errors -gt 0 ]]; then
        echo "  ❌ $module_errors module files missing"
    else
        echo "  ✅ All module files present"
    fi
}

core_show_performance_metrics() {
    echo "Performance Metrics:"
    
    # Module load time
    echo "  Loaded modules: ${#LOADED_MODULES[@]}"
    echo "  Registered commands: ${#MODULE_COMMANDS[@]}"
    echo "  Registered hooks: ${#MODULE_HOOKS[@]}"
    
    # Disk usage
    local data_size=$(du -sh "$PAK_DATA_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    local logs_size=$(du -sh "$PAK_LOGS_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    echo "  Data directory size: $data_size"
    echo "  Logs directory size: $logs_size"
}

# Information display
core_info() {
    local type="${1:-system}"
    
    case "$type" in
        system)
            core_info_system
            ;;
        modules)
            core_info_modules
            ;;
        config)
            core_info_config
            ;;
        *)
            log ERROR "Unknown info type: $type"
            return 1
            ;;
    esac
}

core_info_system() {
    echo "=== PAK System Information ==="
    echo "Installation Directory: $PAK_DIR"
    echo "Configuration Directory: $PAK_CONFIG_DIR"
    echo "Data Directory: $PAK_DATA_DIR"
    echo "Logs Directory: $PAK_LOGS_DIR"
    echo "Modules Directory: $PAK_MODULES_DIR"
    echo "Plugins Directory: $PAK_PLUGINS_DIR"
    echo "Temporary Directory: $PAK_TEMP_DIR"
    echo ""
    echo "Environment:"
    echo "  Bash Version: $BASH_VERSION"
    echo "  System: $(uname -s) $(uname -r)"
    echo "  Architecture: $(uname -m)"
    echo "  User: $(whoami)"
    echo "  Home: $HOME"
}

core_info_modules() {
    echo "=== PAK Module Information ==="
    
    for module in "${!LOADED_MODULES[@]}"; do
        echo ""
        echo "Module: $module"
        echo "  File: $PAK_MODULES_DIR/${module}.module.sh"
        
        local version_var="${module^^}_MODULE_VERSION"
        local version="${!version_var:-unknown}"
        echo "  Version: $version"
        
        # Check for module-specific info function
        if type -t "${module}_info" &>/dev/null; then
            echo "  Info:"
            "${module}_info" | sed 's/^/    /'
        fi
    done
}

core_info_config() {
    echo "=== PAK Configuration Information ==="
    echo "Configuration File: $PAK_CONFIG_DIR/pak.conf"
    echo ""
    echo "Current Settings:"
    
    # Read and display all settings
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        local key="${line%%=*}"
        local value="${line#*=}"
        echo "  $key = $value"
    done < "$PAK_CONFIG_DIR/pak.conf"
}

# Health monitoring
core_init_health_monitoring() {
    CORE_HEALTH_STATUS["start_time"]=$(date +%s)
    CORE_HEALTH_STATUS["initialization"]="completed"
    CORE_HEALTH_STATUS["last_check"]=$(date +%s)
}

core_update_health_status() {
    local key="$1"
    local value="$2"
    CORE_HEALTH_STATUS["$key"]="$value"
    CORE_HEALTH_STATUS["last_update"]=$(date +%s)
}

core_health_check() {
    local check_type="$1"
    
    case "$check_type" in
        system)
            core_health_check_system
            ;;
        modules)
            core_health_check_modules
            ;;
        config)
            core_health_check_config
            ;;
        dependencies)
            core_health_check_dependencies
            ;;
        *)
            log ERROR "Unknown health check type: $check_type"
            return 1
            ;;
    esac
}

# Version information loading
#core_load_version_info() {
##    CORE_VERSION_INFO["core"]="${CORE_MODULE_VERSION:-1.0.0}"
#    CORE_VERSION_INFO["bash"]="$BASH_VERSION"
#    CORE_VERSION_INFO["system"]="$(uname -s) $(uname -r)"
#    CORE_VERSION_INFO["architecture"]="$(uname -m)"
#}
#
## Directory validation
#core_validate_directories() {
    local required_dirs=("$PAK_CONFIG_DIR" "$PAK_DATA_DIR" "$PAK_LOGS_DIR" "$PAK_MODULES_DIR")
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log WARN "Creating missing directory: $dir"
            mkdir -p "$dir"
        fi
    done
}

# Enhanced utility functions
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local base_delay="${2:-2}"
    local max_delay="${3:-60}"
    shift 3
    
    local attempt=1
    local delay=$base_delay
    
    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log WARN "Attempt $attempt failed. Retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))
            if [[ $delay -gt $max_delay ]]; then
                delay=$max_delay
            fi
        fi
        attempt=$((attempt + 1))
    done
    
    return 1
}

safe_json() {
    local json="$1"
    shift
    if echo "$json" | jq -e . >/dev/null 2>&1; then
        echo "$json" | jq "$@"
    else
        echo "{}"
    fi
}

# Enhanced JSON utilities
json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | jq -r ".$key // empty" 2>/dev/null || echo ""
}

json_set() {
    local json="$1"
    local key="$2"
    local value="$3"
    echo "$json" | jq ".$key = $value" 2>/dev/null || echo "{}"
}

json_merge() {
    local json1="$1"
    local json2="$2"
    echo "$json1" | jq -s '.[0] * .[1]' <(echo "$json2") 2>/dev/null || echo "{}"
}

# Enhanced file utilities
file_backup() {
    local file="$1"
    local backup_dir="${2:-$PAK_DATA_DIR/backups}"
    
    if [[ ! -f "$file" ]]; then
        log ERROR "File not found: $file"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
    cp "$file" "$backup_file"
    log INFO "Backup created: $backup_file"
    echo "$backup_file"
}

file_restore() {
    local backup_file="$1"
    local target_file="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi
    
    cp "$backup_file" "$target_file"
    log INFO "File restored: $target_file"
}

# Enhanced logging utilities
log_with_context() {
    local level="$1"
    local context="$2"
    shift 2
    local message="$*"
    
    log "$level" "[$context] $message"
}

log_performance() {
    local operation="$1"
    local start_time="$2"
    local end_time="${3:-$(date +%s.%N)}"
    
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    log DEBUG "Performance: $operation took ${duration}s"
}

# Enhanced validation utilities
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_url() {
    local url="$1"
    [[ "$url" =~ ^https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,} ]]
}

validate_version() {
    local version="$1"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$ ]]
}

# Enhanced security utilities
generate_random_string() {
    local length="${1:-32}"
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

hash_string() {
    local string="$1"
    echo -n "$string" | sha256sum | cut -d' ' -f1
}

# Enhanced network utilities
check_connectivity() {
    local url="${1:-https://httpbin.org/get}"
    local timeout="${2:-10}"
    
    curl -s --max-time "$timeout" --connect-timeout "$timeout" "$url" >/dev/null 2>&1
}

get_external_ip() {
    curl -s --max-time 10 https://httpbin.org/ip | jq -r '.origin' 2>/dev/null || echo ""
}

# Web interface management
core_web() {
    local action="${1:-start}"
    
    case "$action" in
        start|run)
            core_web_start
            ;;
        stop)
            core_web_stop
            ;;
        status)
            core_web_status
            ;;
        restart)
            core_web_stop
            sleep 2
            core_web_start
            ;;
        *)
            echo "Usage: pak web [start|stop|status|restart]"
            echo
            echo "Commands:"
            echo "  start    Start the web interface"
            echo "  stop     Stop the web interface"
            echo "  status   Check web interface status"
            echo "  restart  Restart the web interface"
            ;;
    esac
}

core_web_start() {
    echo "🌐 Starting PAK.sh web interface..."
    
    # Check if web interface is installed
    local web_dir=""
    if [[ -d "/etc/pak/web/web_py" ]]; then
        web_dir="/etc/pak/web/web_py"
    elif [[ -d "$HOME/.config/pak/web/web_py" ]]; then
        web_dir="$HOME/.config/pak/web/web_py"
    else
        echo "❌ Web interface not found"
        echo "💡 Make sure PAK.sh was installed with web interface support"
        return 1
    fi
    
    # Check if Python is available
    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ Python 3 is required but not installed"
        echo "💡 Install Python 3 and try again"
        return 1
    fi
    
    # Install dependencies if needed
    if [[ -f "$web_dir/requirements.txt" ]]; then
        echo "📦 Installing Python dependencies..."
        pip3 install -r "$web_dir/requirements.txt" --user
    fi
    
    # Start the web interface
    echo "🚀 Launching web interface..."
    echo "🌐 Your PAK.sh web interface will be available at:"
    echo "   http://localhost:5000"
    echo "🔐 Admin interface: http://localhost:5000/admin/users"
    echo "📊 Telemetry dashboard: http://localhost:5000/telemetry"
    echo ""
    echo "Press Ctrl+C to stop the web server"
    echo ""
    cd "$web_dir"
    python3 run.py
}

core_web_stop() {
    echo "🛑 Stopping PAK.sh web interface..."
    
    # Find and kill the web process
    local pids=$(pgrep -f "python3.*run.py" 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        echo "📋 Found web interface processes: $pids"
        kill $pids
        echo "✅ Web interface stopped"
    else
        echo "ℹ️  No web interface processes found"
    fi
}

core_web_status() {
    echo "📊 PAK.sh Web Interface Status"
    echo "=============================="
    
    # Check if web interface is installed
    local web_dir=""
    if [[ -d "/etc/pak/web/web_py" ]]; then
        web_dir="/etc/pak/web/web_py"
        echo "📍 Installation: System-wide"
    elif [[ -d "$HOME/.config/pak/web/web_py" ]]; then
        web_dir="$HOME/.config/pak/web/web_py"
        echo "📍 Installation: User-local"
    else
        echo "❌ Web interface not installed"
        return 1
    fi
    
    echo "📁 Location: $web_dir"
    
    # Check if Python is available
    if command -v python3 >/dev/null 2>&1; then
        echo "🐍 Python: Available ($(python3 --version))"
    else
        echo "🐍 Python: Not available"
    fi
    
    # Check if web interface is running
    local pids=$(pgrep -f "python3.*run.py" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        echo "🟢 Status: Running (PID: $pids)"
        echo "🌐 URL: http://localhost:5000"
    else
        echo "🔴 Status: Not running"
    fi
}

# Export all functions
export -f retry_with_backoff safe_json json_get json_set json_merge
export -f file_backup file_restore log_with_context log_performance
export -f validate_email validate_url validate_version
export -f generate_random_string hash_string check_connectivity get_external_ip
