#!/bin/bash
# PAK.sh - Package Automation Kit
# Enhanced multi-platform deployment system with 30+ platform support

# Base configuration
export PAK_VERSION="3.0.0"
PAK_DOMAIN="pak.sh"

# Handle symlinks properly - resolve to actual script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done

# Determine PAK installation directory structure
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
if [[ "$SCRIPT_DIR" =~ \.pak/bin$ ]]; then
    # Installed in user directory (e.g., ~/.pak/bin/)
    export PAK_HOME="$(dirname "$SCRIPT_DIR")"
    export PAK_DIR="$PAK_HOME"
    export PAK_MODULES_DIR="$PAK_HOME/config/modules"
    export PAK_CONFIG_DIR="$PAK_HOME/config"
    export PAK_DATA_DIR="$PAK_HOME/data"
    export PAK_LOGS_DIR="$PAK_HOME/logs"
    export PAK_TEMPLATES_DIR="$PAK_HOME/config/templates"
    export PAK_SCRIPTS_DIR="$PAK_HOME/config/scripts"
else
    # Development or traditional installation
    export PAK_DIR="$SCRIPT_DIR"
    export PAK_MODULES_DIR="$PAK_DIR/modules"
    export PAK_CONFIG_DIR="$PAK_DIR/config"
    export PAK_DATA_DIR="$PAK_DIR/data"
    export PAK_LOGS_DIR="$PAK_DIR/logs"
    export PAK_TEMPLATES_DIR="$PAK_DIR/templates"
    export PAK_SCRIPTS_DIR="$PAK_DIR/scripts"
fi

# Load dynamic ASCII system
if [[ -f "$PAK_DIR/ascii-letters.sh" ]]; then
    source "$PAK_DIR/ascii-letters.sh"
elif [[ -f "$SCRIPT_DIR/ascii-letters.sh" ]]; then
    # For user directory installations, ascii-letters.sh is in the bin directory
    source "$SCRIPT_DIR/ascii-letters.sh"
fi

# Global state
declare -A LOADED_MODULES
declare -A MODULE_HOOKS
declare -A MODULE_COMMANDS
export PAK_QUIET_MODE=false
export PAK_DEBUG_MODE=false
export PAK_DRY_RUN=false
export PAK_DEFAULT_PLATFORMS="npm pypi cargo docker"

# Initialize arrays to prevent unbound variable errors
LOADED_MODULES=()
MODULE_HOOKS=()
MODULE_COMMANDS=()

# Enhanced logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    case "$level" in
        DEBUG)
            if [[ "$PAK_DEBUG_MODE" == "true" ]]; then
                echo "[$timestamp] [DEBUG] $message" >&2
            fi
            ;;
        INFO)
            echo "[$timestamp] [INFO] $message" >&2
            ;;
        WARN)
            echo "[$timestamp] [WARN] $message" >&2
            ;;
        ERROR)
            echo "[$timestamp] [ERROR] $message" >&2
            ;;
        SUCCESS)
            echo "[$timestamp] [SUCCESS] $message" >&2
            ;;
    esac
    
    # Log to file if logs directory exists
    if [[ -d "$PAK_LOGS_DIR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$PAK_LOGS_DIR/pak.log"
    fi
}

# Command registration function
register_command() {
    local command="$1"
    local module="$2"
    local function="$3"
    
    MODULE_COMMANDS["$command"]="$module:$function"
    log DEBUG "Registered command: $command -> $module:$function"
}

# Hook registration function
register_hook() {
    local hook_name="$1"
    local module="$2"
    local function="$3"
    
    if [[ -z "${MODULE_HOOKS[$hook_name]}" ]]; then
        MODULE_HOOKS["$hook_name"]=""
    fi
    MODULE_HOOKS["$hook_name"]="${MODULE_HOOKS[$hook_name]} $module:$function"
    log DEBUG "Registered hook: $hook_name -> $module:$function"
}

# Module loading function
load_module() {
    local module_name="$1"
    local module_file="$PAK_MODULES_DIR/${module_name}.module.sh"
    
    if [[ -f "$module_file" ]]; then
        if [[ -z "${LOADED_MODULES[$module_name]}" ]]; then
            source "$module_file"
            LOADED_MODULES["$module_name"]="loaded"
            log DEBUG "Loaded module: $module_name"
            
            # Call module init function if it exists
            local init_function="${module_name}_init"
            if declare -F "$init_function" >/dev/null; then
                "$init_function"
            fi
            
            # Register module commands if function exists
            local register_function="${module_name}_register_commands"
            if declare -F "$register_function" >/dev/null; then
                "$register_function"
            fi
        fi
    else
        log ERROR "Module not found: $module_name"
        return 1
    fi
}

# Enhanced module loading with dependencies
load_modules() {
    local modules=("$@")
    
    # Core modules that should be loaded first
    local core_modules=("core" "platform" "deploy")
    
    # Load core modules first
    for module in "${core_modules[@]}"; do
        if [[ " ${modules[*]} " =~ " ${module} " ]]; then
            load_module "$module"
        fi
    done
    
    # Load remaining modules
    for module in "${modules[@]}"; do
        if [[ ! " ${core_modules[*]} " =~ " ${module} " ]]; then
            load_module "$module"
        fi
    done
}

# Initialize PAK system
init_pak() {
    log INFO "Initializing PAK.sh v$PAK_VERSION"
    
    # Create necessary directories
    mkdir -p "$PAK_CONFIG_DIR"
    mkdir -p "$PAK_DATA_DIR"
    mkdir -p "$PAK_LOGS_DIR"
    mkdir -p "$PAK_TEMPLATES_DIR"
    mkdir -p "$PAK_SCRIPTS_DIR"
    
    # Load core modules
    load_modules "core" "platform" "deploy" "platform-adapters" "deploy-orchestrator" "unified-build" "deployment-validation" "rollback-recovery"
    
    log SUCCESS "PAK.sh initialized successfully"
}

# Enhanced command execution
execute_command() {
    local command="$1"
    shift
    local args=("$@")
    
    if [[ -n "${MODULE_COMMANDS[$command]}" ]]; then
        local module_function="${MODULE_COMMANDS[$command]}"
        local module="${module_function%:*}"
        local function="${module_function#*:}"
        
        log DEBUG "Executing command: $command -> $module:$function"
        
        if declare -F "$function" >/dev/null; then
            "$function" "${args[@]}"
            return $?
        else
            log ERROR "Function not found: $function"
            return 1
        fi
    else
        log ERROR "Unknown command: $command"
        show_help
        return 1
    fi
}

# Enhanced help system
show_help() {
    echo "PAK.sh - Package Automation Kit v$PAK_VERSION"
    echo "============================================="
    echo ""
    echo "Multi-platform deployment system with 30+ platform support"
    echo ""
    echo "Usage: pak <command> [options]"
    echo ""
    echo "Core Commands:"
    echo "  pak deploy <package> [version] [platforms] [pipeline]"
    echo "  pak build <package> [version] [platforms]"
    echo "  pak test <package> [platforms]"
    echo "  pak rollback <package> [version] [platforms]"
    echo "  pak release <package> [version] [platforms]"
    echo ""
    echo "Platform Commands:"
    echo "  pak platforms                    - List available platforms"
    echo "  pak platform-info <platform>     - Show platform information"
    echo "  pak platform-health <platform>   - Check platform health"
    echo "  pak platform-test <platform>     - Test platform connection"
    echo ""
    echo "Adapter Commands:"
    echo "  pak adapters                     - List platform adapters"
    echo "  pak adapter-info <adapter>       - Show adapter information"
    echo "  pak adapter-test <adapter>       - Test adapter"
    echo "  pak adapter-auth <adapter>       - Set up authentication"
    echo "  pak adapter-deploy <adapter> <package> [version]"
    echo ""
    echo "Build Commands:"
    echo "  pak build-detect <package>       - Detect project type"
    echo "  pak build-matrix <package>       - Build matrix"
    echo "  pak build-cache <action>         - Manage build cache"
    echo "  pak build-artifacts <package>    - List build artifacts"
    echo "  pak build-clean <package>        - Clean build artifacts"
    echo "  pak build-validate <package>     - Validate build configuration"
    echo ""
    echo "Validation Commands:"
    echo "  pak validate-pre <package> [platforms]  - Pre-deployment validation"
    echo "  pak validate-post <package> [platforms] - Post-deployment validation"
    echo "  pak validate-license <package>   - Validate license compatibility"
    echo "  pak validate-deps <package>      - Validate dependencies"
    echo "  pak validate-conflicts <package> - Check version conflicts"
    echo "  pak validate-integrity <package> - Validate package integrity"
    echo "  pak validate-health <package>    - Check platform health"
    echo ""
    echo "Rollback Commands:"
    echo "  pak rollback-status <deployment> - Show rollback status"
    echo "  pak rollback-history             - Show rollback history"
    echo "  pak rollback-automate <deployment> [platforms] - Automated rollback"
    echo "  pak rollback-manual <deployment> [platforms]  - Manual rollback"
    echo "  pak rollback-verify <deployment> - Verify rollback completion"
    echo "  pak rollback-cleanup [days]      - Clean up old rollback data"
    echo ""
    echo "Deployment Commands:"
    echo "  pak deploy-parallel <package> [version] [platforms] - Parallel deployment"
    echo "  pak deploy-pipeline <package> [version] [platforms] [pipeline] - Pipeline deployment"
    echo "  pak deploy-status <deployment>   - Show deployment status"
    echo "  pak deploy-history [limit]       - Show deployment history"
    echo "  pak deploy-cancel <deployment>   - Cancel deployment"
    echo "  pak deploy-retry <deployment> [platform] - Retry deployment"
    echo "  pak deploy-validate <package> [version] - Validate deployment"
    echo "  pak deploy-test <package> [platforms] - Test deployment (dry run)"
    echo ""
    echo "Examples:"
    echo "  pak deploy my-package 1.0.0"
    echo "  pak deploy my-package 1.0.0 npm pypi cargo"
    echo "  pak deploy my-package 1.0.0 all parallel"
    echo "  pak build my-package"
    echo "  pak test my-package npm pypi"
    echo "  pak rollback my-package 1.0.0"
    echo "  pak validate-pre my-package"
    echo "  pak platforms"
    echo "  pak adapters"
    echo ""
    echo "Options:"
    echo "  --debug                          - Enable debug mode"
    echo "  --dry-run                        - Dry run mode"
    echo "  --quiet                          - Quiet mode"
    echo "  --help, -h                       - Show this help"
    echo "  --version, -v                    - Show version"
    echo ""
    echo "For more information, visit: https://$PAK_DOMAIN"
}

# Enhanced version display
show_version() {
    echo "PAK.sh v$PAK_VERSION"
    echo "Multi-platform deployment system"
    echo "Supports 30+ package platforms"
    echo ""
    echo "Platforms: npm, yarn, pnpm, jspm, pypi, conda, poetry, cargo, go, maven, gradle, nuget, docker, helm, homebrew, snap, and more..."
    echo ""
    echo "Visit: https://$PAK_DOMAIN"
}

# Enhanced argument parsing
parse_args() {
    local args=("$@")
    local command=""
    local command_args=()
    
    for arg in "${args[@]}"; do
        case "$arg" in
            --debug)
                export PAK_DEBUG_MODE=true
                ;;
            --dry-run)
                export PAK_DRY_RUN=true
                ;;
            --quiet)
                export PAK_QUIET_MODE=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            -*)
                log ERROR "Unknown option: $arg"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$arg"
                else
                    command_args+=("$arg")
                fi
                ;;
        esac
    done
    
    if [[ -z "$command" ]]; then
        show_help
        exit 1
    fi
    
    # Execute command
    execute_command "$command" "${command_args[@]}"
    return $?
}

# Enhanced error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    if [[ $exit_code -ne 0 ]]; then
        log ERROR "Error occurred at line $line_number (exit code: $exit_code)"
        
        # Show helpful error information
        case $exit_code in
            1)
                log ERROR "General error - check command syntax and arguments"
                ;;
            2)
                log ERROR "Missing dependency - ensure required tools are installed"
                ;;
            126)
                log ERROR "Permission denied - check file permissions"
                ;;
            127)
                log ERROR "Command not found - ensure required tools are in PATH"
                ;;
            *)
                log ERROR "Unexpected error - check logs for details"
                ;;
        esac
        
        exit $exit_code
    fi
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Main execution
main() {
    local args=("$@")
    
    # Initialize PAK system
    init_pak
    
    # Parse and execute arguments
    parse_args "${args[@]}"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi