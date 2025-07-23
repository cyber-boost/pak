#!/bin/bash
# PAK.sh - Package Automation Kit
# Main orchestrator script that loads and manages all modules

# Base configuration
export PAK_VERSION="2.0.0"
PAK_DOMAIN="pak.sh"
export PAK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PAK_MODULES_DIR="$PAK_DIR/modules"
export PAK_CONFIG_DIR="$PAK_DIR/config"
export PAK_DATA_DIR="$PAK_DIR/data"
export PAK_LOGS_DIR="$PAK_DIR/logs"
export PAK_TEMPLATES_DIR="$PAK_DIR/templates"
export PAK_SCRIPTS_DIR="$PAK_DIR/scripts"

# Load dynamic ASCII system
if [[ -f "$PAK_DIR/ascii-letters.sh" ]]; then
    source "$PAK_DIR/ascii-letters.sh"
fi

# Global state
declare -A LOADED_MODULES
declare -A MODULE_HOOKS
declare -A MODULE_COMMANDS
export PAK_QUIET_MODE=false
export PAK_DEBUG_MODE=false
export PAK_DRY_RUN=false

# Initialize arrays to prevent unbound variable errors
LOADED_MODULES=()
MODULE_HOOKS=()
MODULE_COMMANDS=()

# Logging function
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
    local priority="${4:-50}"
    
    MODULE_HOOKS["${hook_name}:${priority}:${module}"]="$function"
    log DEBUG "Registered hook: $hook_name -> $module:$function (priority: $priority)"
}

# Module loading function
load_module() {
    local module_name="$1"
    local module_file="$PAK_MODULES_DIR/${module_name}.module.sh"
    
    if [[ -f "$module_file" ]]; then
        source "$module_file"
        LOADED_MODULES["$module_name"]="loaded"
        
        # Initialize module if init function exists
        if declare -F "${module_name}_init" > /dev/null; then
            "${module_name}_init"
        fi
        
        # Register commands if function exists
        if declare -F "${module_name}_register_commands" > /dev/null; then
            "${module_name}_register_commands"
        fi
        
        log INFO "Loaded module: $module_name"
    else
        log ERROR "Module not found: $module_file"
        return 1
    fi
}

# Function to show contextual ASCII art based on command
show_contextual_ascii() {
    local command="$1"
    local platform="$2"
    local subcommand="$3"
    
    # Don't show ASCII in quiet mode
    if [[ "$PAK_QUIET_MODE" == "true" ]]; then
        return
    fi
    
    case "$command" in
        init)
            show_dynamic_ascii "init"
            ;;
        deploy)
            show_dynamic_ascii "deploy" "$platform"
            ;;
        track)
            show_dynamic_ascii "track"
            ;;
        status)
            show_dynamic_ascii "status"
            ;;
        register)
            build_ascii_word "REGISTER"
            echo "🔐 Platform Registration Wizard"
            ;;
        embed)
            build_ascii_word "EMBED"
            echo "📊 Telemetry & Analytics"
            ;;
        security|scan)
            build_ascii_word "SECURITY"
            echo "🔐 Security Scanning & Compliance"
            ;;
        devex)
            build_ascii_word "DEVEX"
            echo "👨‍💻 Developer Experience"
            ;;
        analytics|stats)
            build_ascii_word "ANALYTICS"
            echo "📈 Data Analytics & Insights"
            ;;
        monitoring|monitor)
            build_ascii_word "MONITOR"
            echo "📊 Real-time Monitoring"
            ;;
        automation|pipeline)
            build_ascii_word "AUTOMATE"
            echo "🤖 CI/CD & Automation"
            ;;
        web|flask)
            build_ascii_word "WEB"
            echo "🌐 Web Interface & Dashboard"
            ;;
        enterprise)
            build_ascii_word "ENTERPRISE"
            echo "🏢 Enterprise Features"
            ;;
        version)
            build_ascii_word "PAK"
            echo "Version: $PAK_VERSION"
            ;;
        help)
            build_ascii_word "HELP"
            echo "📚 PAK.sh - Package Automation Kit"
            echo "Universal package management for 30+ platforms"
            ;;
        *)
            # Show PAK logo for unknown commands
            build_ascii_word "PAK"
            ;;
    esac
}

# Load all modules
load_all_modules() {
    log INFO "Loading PAK.sh modules..."
    
    # Load core modules first (essential functionality)
    load_module "core"
    load_module "platform"
    load_module "deploy"
    load_module "track"
    load_module "security"
    load_module "automation"
    load_module "analytics"
    load_module "monitoring"
    load_module "devex"
    load_module "database"
    
    # Load registration and embed modules
    load_module "register"
    load_module "embed"
    
    # Load enterprise and specialized modules
    load_module "enterprise"
    load_module "integration"
    load_module "lifecycle"
    load_module "ml"
    load_module "collaboration"
    
    # Load any additional modules from subdirectories
    for module_dir in "$PAK_MODULES_DIR"/*/; do
        if [[ -d "$module_dir" ]]; then
            local dir_name=$(basename "$module_dir")
            # Skip if already loaded as main module
            if [[ ! -f "$PAK_MODULES_DIR/${dir_name}.module.sh" ]]; then
                log DEBUG "Loading module from directory: $dir_name"
                # Load any .sh files in subdirectories
                for module_file in "$module_dir"*.sh; do
                    if [[ -f "$module_file" ]]; then
                        source "$module_file"
                        log DEBUG "Loaded module file: $module_file"
                    fi
                done
            fi
        fi
    done
    
    log INFO "All modules loaded successfully"
}

# Execute hooks
execute_hooks() {
    local hook_name="$1"
    local args="${@:2}"
    
    # Sort hooks by priority
    for hook_key in "${!MODULE_HOOKS[@]}"; do
        if [[ "$hook_key" == "$hook_name:"* ]]; then
            local function="${MODULE_HOOKS[$hook_key]}"
            if declare -F "$function" > /dev/null; then
                log DEBUG "Executing hook: $function"
                "$function" "$args"
            fi
        fi
    done
}

# Main command dispatcher
dispatch_command() {
    local command="$1"
    local args="${@:2}"
    
    # Execute pre-command hooks
    execute_hooks "pre_command" "$command" "$args"
    
    # Show ASCII art
    show_contextual_ascii "$command"
    
    # Check if command exists
    if [[ -n "${MODULE_COMMANDS[$command]}" ]]; then
        IFS=':' read -r module function <<< "${MODULE_COMMANDS[$command]}"
        
        if declare -F "$function" > /dev/null; then
            log DEBUG "Executing command: $command -> $function"
            "$function" "$args"
            local result=$?
            
            # Execute post-command hooks
            execute_hooks "post_command" "$command" "$result"
            return $result
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

# Show help
show_help() {
    echo "PAK.sh - Package Automation Kit"
    echo "Version: $PAK_VERSION"
    echo
    echo "Usage: pak <command> [options]"
    echo
    echo "🚀 CORE COMMANDS:"
    echo "  init                    # Initialize PAK in current directory"
    echo "  register               # Interactive platform registration wizard"
    echo "  deploy [package]        # Deploy to all configured platforms"
    echo "  track [package]         # Track package statistics"
    echo "  scan [package]          # Security vulnerability scan"
    echo "  monitor [package]       # Start real-time monitoring"
    echo "  status                  # Show system status"
    echo "  version                 # Show version information"
    echo
    echo "📦 DEPLOYMENT COMMANDS:"
    echo "  deploy list             # List deployment history"
    echo "  deploy rollback         # Rollback deployment"
    echo "  deploy verify           # Verify deployment"
    echo "  deploy clean            # Clean deployment artifacts"
    echo
    echo "📊 TRACKING & ANALYTICS:"
    echo "  stats [package]         # Show package statistics"
    echo "  export [package]        # Export tracking data"
    echo "  analytics [package]     # Generate analytics report"
    echo
    echo "🔐 SECURITY COMMANDS:"
    echo "  security audit          # Full security audit"
    echo "  security fix            # Auto-fix security issues"
    echo "  license check           # Check license compliance"
    echo "  license validate        # Validate licenses"
    echo
    echo "🤖 AUTOMATION COMMANDS:"
    echo "  pipeline create         # Create CI/CD pipeline"
    echo "  pipeline list           # List pipelines"
    echo "  git hooks install       # Install Git hooks"
    echo "  workflow create         # Create workflow"
    echo
    echo "📈 MONITORING COMMANDS:"
    echo "  health [package]        # Health check package"
    echo "  alerts list             # List alerts"
    echo "  alerts create           # Create alert"
    echo
    echo "👨‍💻 DEVELOPER EXPERIENCE:"
    echo "  devex wizard            # Interactive setup wizard"
    echo "  devex init              # Initialize project"
    echo "  devex setup             # Setup development environment"
    echo "  devex template create   # Create template"
    echo
    echo "🌐 WEB INTERFACE & INTEGRATION:"
    echo "  web                     # Start web interface"
    echo "  web start               # Start web server"
    echo "  web stop                # Stop web server"
    echo "  web status              # Check web server status"
    echo "  webhook add             # Add webhook"
    echo "  api start               # Start API server"
    echo "  plugin install          # Install plugin"
    echo
    echo "🏢 ENTERPRISE COMMANDS:"
    echo "  team add                # Add team member"
    echo "  audit start             # Start audit logging"
    echo "  enterprise setup        # Setup enterprise features"
    echo
    echo "🎨 USER INTERFACE:"
    echo "  ascii show              # Show ASCII art"
    echo "  config get/set          # Manage configuration"
    echo "  db status               # Show database status"
    echo "  log show                # Show recent logs"
    echo
    echo "🔄 LIFECYCLE COMMANDS:"
    echo "  version bump            # Bump version"
    echo "  release create          # Create release"
    echo "  deps check              # Check dependencies"
    echo
    echo "🔍 DEBUGGING & PERFORMANCE:"
    echo "  debug enable            # Enable debug mode"
    echo "  troubleshoot            # Troubleshoot issue"
    echo "  optimize cache          # Optimize cache"
    echo "  perf benchmark          # Benchmark package"
    echo
    echo "🌐 NETWORKING & API:"
    echo "  network test            # Test network connectivity"
    echo "  api key                 # Set API key"
    echo "  api test                # Test API connection"
    echo
    echo "📱 MOBILE & I18N:"
    echo "  mobile setup            # Setup mobile support"
    echo "  locale set              # Set locale"
    echo "  timezone set            # Set timezone"
    echo
    echo "🔄 UPDATE & MAINTENANCE:"
    echo "  update check            # Check for updates"
    echo "  maintenance start       # Start maintenance mode"
    echo "  backup create           # Create backup"
    echo
    echo "📊 REPORTING & COMPLIANCE:"
    echo "  report generate         # Generate report"
    echo "  gdpr check              # Check GDPR compliance"
    echo "  policy enforce          # Enforce policies"
    echo
    echo "🎯 SPECIALIZED COMMANDS:"
    echo "  unity deploy            # Deploy Unity asset"
    echo "  docker build            # Build Docker image"
    echo "  aws deploy              # Deploy to AWS"
    echo "  vscode setup            # Setup VS Code integration"
    echo
    echo "🔗 EMBED & TELEMETRY:"
    echo "  embed init              # Initialize embed system"
    echo "  embed telemetry         # Track telemetry events"
    echo "  embed analytics         # Analytics operations"
    echo "  embed track             # Track various events"
    echo "  embed report            # Generate reports"
    echo
    echo "📚 HELP & DOCUMENTATION:"
    echo "  help [command]          # Command-specific help"
    echo "  docs                    # Show documentation"
    echo "  docs search             # Search documentation"
    echo
    echo "Examples:"
    echo "  pak register                    # Start registration wizard"
    echo "  pak deploy my-package --version 1.0.0"
    echo "  pak track my-package"
    echo "  pak security audit my-package"
    echo "  pak devex wizard"
    echo "  pak web                        # Start web interface"
    echo "  pak embed telemetry install"
    echo
    echo "For complete command reference, visit: https://pak.sh/commands"
    echo "For more information, visit: https://pak.sh"
}

# Main function
main() {
    # Parse command line arguments
    local command="$1"
    local args="${@:2}"
    
    # Handle special flags
    case "$command" in
        --quiet|-q)
            PAK_QUIET_MODE=true
            command="$2"
            args="${@:3}"
            ;;
        --debug|-d)
            PAK_DEBUG_MODE=true
            command="$2"
            args="${@:3}"
            ;;
        --dry-run|-n)
            PAK_DRY_RUN=true
            command="$2"
            args="${@:3}"
            ;;
    esac
    
    # Load modules
    load_all_modules
    
    # Execute pre-init hooks
    execute_hooks "pre_init"
    
    # Execute init hooks
    execute_hooks "post_init"
    
    # Handle commands
    case "$command" in
        ""|help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            show_contextual_ascii "version"
            ;;
        *)
            dispatch_command "$command" "$args"
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi