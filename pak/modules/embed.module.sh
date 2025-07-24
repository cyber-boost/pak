#!/bin/bash
# Embed module - Telemetry and analytics for embedded packages

# Module metadata
EMBED_MODULE_VERSION="1.0.0"
EMBED_MODULE_DEPENDENCIES=("core" "database")
EMBED_MODULE_HOOKS=("pre_init" "post_init" "telemetry_event")

# Module state
declare -A EMBED_CONFIG_CACHE
declare -A EMBED_TELEMETRY_DATA

# Configuration
EMBED_VERSION="$EMBED_MODULE_VERSION"
EMBED_CONFIG_FILE=".pak-embed.conf"
EMBED_DATA_DIR="${HOME}/.pak-embed"
EMBED_LOGS_DIR="${EMBED_DATA_DIR}/logs"
EMBED_LOG_FILE="${EMBED_LOGS_DIR}/telemetry.log"
EMBED_SQLITE_DB="${EMBED_DATA_DIR}/telemetry.db"

# Default webhook URL (can be overridden in config)
DEFAULT_WEBHOOK_URL="https://pak.sh/webhook/telemetry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[PAK-EMBED]${NC} $1"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [INFO] $1" >> "$EMBED_LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[PAK-EMBED]${NC} $1"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [SUCCESS] $1" >> "$EMBED_LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[PAK-EMBED]${NC} $1"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [WARNING] $1" >> "$EMBED_LOG_FILE"
}

log_error() {
    echo -e "${RED}[PAK-EMBED]${NC} $1"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [ERROR] $1" >> "$EMBED_LOG_FILE"
}

embed_init() {
    log DEBUG "Initializing embed module v$EMBED_MODULE_VERSION"
    
    # Initialize module state
    EMBED_CONFIG_CACHE=()
    EMBED_TELEMETRY_DATA=()
    
    # Create embed directories
    mkdir -p "$EMBED_DATA_DIR"
    
    # Create SQLite database if it doesn't exist
    if [[ ! -f "$EMBED_SQLITE_DB" ]]; then
        embed_create_database
    fi
    
    # Load configuration
    embed_load_config
    
    # Register hooks
    embed_register_hooks
    
    log DEBUG "Embed module initialized successfully"
}

embed_register_commands() {
    register_command "embed" "embed" "embed_main"
    register_command "telemetry" "embed" "embed_telemetry"
    register_command "analytics" "embed" "embed_analytics"
    register_command "track" "embed" "embed_track"
    register_command "report" "embed" "embed_report"
}

embed_register_hooks() {
    register_hook "pre_init" "embed" "embed_pre_init" 20
    register_hook "post_init" "embed" "embed_post_init" 80
    register_hook "telemetry_event" "embed" "embed_telemetry_event" 50
}

# Hook implementations
embed_pre_init() {
    log DEBUG "Embed pre-init hook executed"
    embed_validate_directories
}

embed_post_init() {
    log DEBUG "Embed post-init hook executed"
    embed_update_health_status "initialization" "completed"
}

embed_telemetry_event() {
    local event_type="$1"
    local data="$2"
    embed_record_event "$event_type" "$data"
}

# Create SQLite database schema
embed_create_database() {
    sqlite3 "$EMBED_SQLITE_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS telemetry_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    package_name TEXT,
    package_version TEXT,
    user_id TEXT,
    session_id TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    data TEXT,
    platform TEXT,
    os_info TEXT,
    success BOOLEAN DEFAULT 1,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS user_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE NOT NULL,
    user_id TEXT,
    package_name TEXT,
    start_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_events INTEGER DEFAULT 0,
    platform TEXT,
    os_info TEXT
);

CREATE TABLE IF NOT EXISTS package_installs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_name TEXT NOT NULL,
    package_version TEXT,
    install_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id TEXT,
    platform TEXT,
    os_info TEXT,
    install_method TEXT,
    success BOOLEAN DEFAULT 1,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS health_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    status_type TEXT NOT NULL,
    status_value TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    module TEXT DEFAULT 'embed'
);

CREATE INDEX IF NOT EXISTS idx_telemetry_events_type ON telemetry_events(event_type);
CREATE INDEX IF NOT EXISTS idx_telemetry_events_package ON telemetry_events(package_name);
CREATE INDEX IF NOT EXISTS idx_telemetry_events_timestamp ON telemetry_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_package_installs_package ON package_installs(package_name);
CREATE INDEX IF NOT EXISTS idx_health_status_type ON health_status(status_type);
EOF
    
    log_info "SQLite database created: $EMBED_SQLITE_DB"
}

# Load configuration from file or environment
embed_load_config() {
    # Default configuration
    EMBED_ENABLED="${PAK_EMBED_ENABLED:-true}"
    EMBED_WEBHOOK_URL="${PAK_EMBED_WEBHOOK_URL:-$DEFAULT_WEBHOOK_URL}"
    EMBED_API_KEY="${PAK_EMBED_API_KEY:-}"
    EMBED_USER_ID="${PAK_EMBED_USER_ID:-$(embed_generate_user_id)}"
    EMBED_SESSION_ID="${PAK_EMBED_SESSION_ID:-$(embed_generate_session_id)}"
    EMBED_PACKAGE_NAME="${PAK_EMBED_PACKAGE_NAME:-unknown}"
    EMBED_PACKAGE_VERSION="${PAK_EMBED_PACKAGE_VERSION:-unknown}"
    
    # Load from config file if it exists
    if [[ -f "$EMBED_CONFIG_FILE" ]]; then
        source "$EMBED_CONFIG_FILE"
        log_info "Configuration loaded from $EMBED_CONFIG_FILE"
    fi
    
    # Override with environment variables if set
    [[ -n "$PAK_EMBED_ENABLED" ]] && EMBED_ENABLED="$PAK_EMBED_ENABLED"
    [[ -n "$PAK_EMBED_WEBHOOK_URL" ]] && EMBED_WEBHOOK_URL="$PAK_EMBED_WEBHOOK_URL"
    [[ -n "$PAK_EMBED_API_KEY" ]] && EMBED_API_KEY="$PAK_EMBED_API_KEY"
    [[ -n "$PAK_EMBED_USER_ID" ]] && EMBED_USER_ID="$PAK_EMBED_USER_ID"
    [[ -n "$PAK_EMBED_SESSION_ID" ]] && EMBED_SESSION_ID="$PAK_EMBED_SESSION_ID"
    [[ -n "$PAK_EMBED_PACKAGE_NAME" ]] && EMBED_PACKAGE_NAME="$PAK_EMBED_PACKAGE_NAME"
    [[ -n "$PAK_EMBED_PACKAGE_VERSION" ]] && EMBED_PACKAGE_VERSION="$PAK_EMBED_PACKAGE_VERSION"
}

# Generate unique user ID
embed_generate_user_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        # Fallback: use hostname + timestamp + random
        echo "$(hostname)-$(date +%s)-$RANDOM" | md5sum | cut -d' ' -f1
    fi
}

# Generate session ID
embed_generate_session_id() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        # Fallback: use timestamp + random
        echo "$(date +%s)-$RANDOM" | md5sum | cut -d' ' -f1
    fi
}

# Get system information
embed_get_system_info() {
    local platform="unknown"
    local os_info="unknown"
    
    # Detect platform
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        platform="linux"
        if [[ -f /etc/os-release ]]; then
            os_info=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        else
            os_info="Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        platform="macos"
        os_info="macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        platform="windows"
        os_info="Windows"
    fi
    
    echo "{\"platform\":\"$platform\",\"os_info\":\"$os_info\"}"
}

# Track an event
embed_track_event() {
    local event_type="$1"
    local data="${2:-{}}"
    
    if [[ "$EMBED_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local system_info=$(embed_get_system_info)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Prepare event data
    local event_data=$(cat << EOF
{
    "event_type": "$event_type",
    "package_name": "$EMBED_PACKAGE_NAME",
    "package_version": "$EMBED_PACKAGE_VERSION",
    "user_id": "$EMBED_USER_ID",
    "session_id": "$EMBED_SESSION_ID",
    "timestamp": "$timestamp",
    "data": $data,
    "system_info": $system_info,
    "embed_version": "$EMBED_VERSION"
}
EOF
)
    
    # Store in SQLite
    embed_store_event_sqlite "$event_type" "$data" "$system_info"
    
    # Send webhook (async)
    embed_send_webhook "$event_data" &
    
    log_info "Event tracked: $event_type"
}

# Store event in SQLite
embed_store_event_sqlite() {
    local event_type="$1"
    local data="$2"
    local system_info="$3"
    
    local platform=$(echo "$system_info" | jq -r '.platform')
    local os_info=$(echo "$system_info" | jq -r '.os_info')
    
    sqlite3 "$EMBED_SQLITE_DB" << EOF
INSERT INTO telemetry_events (
    event_type, package_name, package_version, user_id, session_id, 
    data, platform, os_info, timestamp
) VALUES (
    '$event_type', '$EMBED_PACKAGE_NAME', '$EMBED_PACKAGE_VERSION', 
    '$EMBED_USER_ID', '$EMBED_SESSION_ID', '$data', '$platform', 
    '$os_info', datetime('now')
);
EOF
}

# Send webhook
embed_send_webhook() {
    local event_data="$1"
    
    if [[ -z "$EMBED_WEBHOOK_URL" ]] || [[ "$EMBED_WEBHOOK_URL" == "none" ]]; then
        return 0
    fi
    
    # Send webhook with timeout and API key authentication
    if command -v curl >/dev/null 2>&1; then
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "User-Agent: PAK-Embed/$EMBED_VERSION" \
            -H "X-API-Key: $EMBED_API_KEY" \
            -d "$event_data" \
            --max-time 10 \
            "$EMBED_WEBHOOK_URL" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        echo "$event_data" | wget --quiet \
            --header="Content-Type: application/json" \
            --header="User-Agent: PAK-Embed/$EMBED_VERSION" \
            --header="X-API-Key: $EMBED_API_KEY" \
            --post-data=- \
            --timeout=10 \
            -O /dev/null \
            "$EMBED_WEBHOOK_URL" 2>/dev/null
    fi
}

# Track package install
embed_track_install() {
    local install_method="${1:-unknown}"
    local success="${2:-true}"
    local error_message="${3:-}"
    
    embed_track_event "install" "{\"method\":\"$install_method\",\"success\":$success,\"error\":\"$error_message\"}"
    
    # Store in installs table
    local system_info=$(embed_get_system_info)
    local platform=$(echo "$system_info" | jq -r '.platform')
    local os_info=$(echo "$system_info" | jq -r '.os_info')
    
    sqlite3 "$EMBED_SQLITE_DB" << EOF
INSERT INTO package_installs (
    package_name, package_version, user_id, platform, os_info, 
    install_method, success, error_message
) VALUES (
    '$EMBED_PACKAGE_NAME', '$EMBED_PACKAGE_VERSION', '$EMBED_USER_ID', 
    '$platform', '$os_info', '$install_method', $success, '$error_message'
);
EOF
    
    log_success "Install tracked for $EMBED_PACKAGE_NAME"
}

# Track command execution
embed_track_command() {
    local command_name="$1"
    local args="${2:-[]}"
    local success="${3:-true}"
    local duration="${4:-0}"
    
    embed_track_event "command" "{\"command\":\"$command_name\",\"args\":$args,\"success\":$success,\"duration\":$duration}"
}

# Track feature usage
embed_track_feature() {
    local feature_name="$1"
    local feature_data="${2:-{}}"
    
    embed_track_event "feature" "{\"feature\":\"$feature_name\",\"data\":$feature_data}"
}

# Track error
embed_track_error() {
    local error_type="$1"
    local error_message="$2"
    local error_context="${3:-{}}"
    
    embed_track_event "error" "{\"type\":\"$error_type\",\"message\":\"$error_message\",\"context\":$error_context}"
}

# Track session start
embed_track_session_start() {
    local system_info=$(embed_get_system_info)
    local platform=$(echo "$system_info" | jq -r '.platform')
    local os_info=$(echo "$system_info" | jq -r '.os_info')
    
    sqlite3 "$EMBED_SQLITE_DB" << EOF
INSERT OR REPLACE INTO user_sessions (
    session_id, user_id, package_name, start_time, last_activity, 
    platform, os_info
) VALUES (
    '$EMBED_SESSION_ID', '$EMBED_USER_ID', '$EMBED_PACKAGE_NAME', 
    datetime('now'), datetime('now'), '$platform', '$os_info'
);
EOF
    
    embed_track_event "session_start" "{\"session_id\":\"$EMBED_SESSION_ID\"}"
}

# Track session end
embed_track_session_end() {
    local session_duration="${1:-0}"
    
    sqlite3 "$EMBED_SQLITE_DB" << EOF
UPDATE user_sessions 
SET last_activity = datetime('now') 
WHERE session_id = '$EMBED_SESSION_ID';
EOF
    
    embed_track_event "session_end" "{\"session_id\":\"$EMBED_SESSION_ID\",\"duration\":$session_duration}"
}

# Get telemetry statistics
embed_get_stats() {
    local stats_file="${EMBED_DATA_DIR}/stats.json"
    
    sqlite3 -json "$EMBED_SQLITE_DB" << 'EOF' > "$stats_file"
SELECT 
    (SELECT COUNT(*) FROM telemetry_events) as total_events,
    (SELECT COUNT(*) FROM package_installs) as total_installs,
    (SELECT COUNT(*) FROM user_sessions) as total_sessions,
    (SELECT COUNT(DISTINCT user_id) FROM telemetry_events) as unique_users,
    (SELECT COUNT(DISTINCT package_name) FROM telemetry_events) as unique_packages,
    (SELECT COUNT(*) FROM telemetry_events WHERE event_type = 'error') as total_errors,
    (SELECT COUNT(*) FROM telemetry_events WHERE event_type = 'command') as total_commands,
    (SELECT COUNT(*) FROM telemetry_events WHERE event_type = 'feature') as total_features;
EOF
    
    cat "$stats_file"
}

# Export telemetry data
embed_export_data() {
    local format="${1:-json}"
    local output_file="${2:-${EMBED_DATA_DIR}/export-$(date +%Y%m%d-%H%M%S)}"
    
    case "$format" in
        json)
            sqlite3 -json "$EMBED_SQLITE_DB" "SELECT * FROM telemetry_events;" > "${output_file}.json"
            log_success "Data exported to ${output_file}.json"
            ;;
        csv)
            sqlite3 -csv "$EMBED_SQLITE_DB" "SELECT * FROM telemetry_events;" > "${output_file}.csv"
            log_success "Data exported to ${output_file}.csv"
            ;;
        sql)
            sqlite3 "$EMBED_SQLITE_DB" ".dump" > "${output_file}.sql"
            log_success "Data exported to ${output_file}.sql"
            ;;
        *)
            log_error "Unknown export format: $format"
            return 1
            ;;
    esac
}

# Clean up old data
embed_cleanup() {
    local days="${1:-30}"
    
    sqlite3 "$EMBED_SQLITE_DB" << EOF
DELETE FROM telemetry_events 
WHERE timestamp < datetime('now', '-$days days');

DELETE FROM user_sessions 
WHERE last_activity < datetime('now', '-$days days');
EOF
    
    log_info "Cleaned up data older than $days days"
}

# Disable telemetry
embed_disable() {
    echo "EMBED_ENABLED=false" > "$EMBED_CONFIG_FILE"
    log_warning "Telemetry disabled"
}

# Enable telemetry
embed_enable() {
    echo "EMBED_ENABLED=true" > "$EMBED_CONFIG_FILE"
    log_success "Telemetry enabled"
}

# Show status
embed_status() {
    echo "PAK.sh Embed Status:"
    echo "  Version: $EMBED_VERSION"
    echo "  Enabled: $EMBED_ENABLED"
    echo "  User ID: $EMBED_USER_ID"
    echo "  Session ID: $EMBED_SESSION_ID"
    echo "  Package: $EMBED_PACKAGE_NAME v$EMBED_PACKAGE_VERSION"
    echo "  Webhook URL: $EMBED_WEBHOOK_URL"
    echo "  API Key: ${EMBED_API_KEY:0:8}..."  # Show first 8 characters only
    echo "  Data Directory: $EMBED_DATA_DIR"
    echo "  Database: $EMBED_SQLITE_DB"
    
    if [[ -f "$EMBED_SQLITE_DB" ]]; then
        echo "  Database Size: $(du -h "$EMBED_SQLITE_DB" | cut -f1)"
        echo "  Total Events: $(sqlite3 "$EMBED_SQLITE_DB" "SELECT COUNT(*) FROM telemetry_events;")"
    fi
}

# Main command functions
embed_main() {
    local action="${1:-init}"
    
    case "$action" in
        init)
            embed_init
            embed_track_session_start
            log_success "Embed system ready for $EMBED_PACKAGE_NAME"
            ;;
        *)
            embed_show_help
            ;;
    esac
}

embed_telemetry() {
    local event_type="${1:-unknown}"
    local data="${2:-{}}"
    
    embed_init
    embed_track_event "$event_type" "$data"
    log_success "Telemetry event recorded: $event_type"
}

embed_analytics() {
    local analysis_type="${1:-stats}"
    
    case "$analysis_type" in
        stats)
            embed_get_stats
            ;;
        export)
            embed_export_data "${2:-json}" "${3:-}"
            ;;
        cleanup)
            embed_cleanup "${2:-30}"
            ;;
        *)
            echo "Available analytics commands:"
            echo "  pak embed analytics stats"
            echo "  pak embed analytics export [format] [file]"
            echo "  pak embed analytics cleanup [days]"
            ;;
    esac
}

embed_track() {
    local track_type="${1:-event}"
    local name="${2:-unknown}"
    local data="${3:-{}}"
    
    embed_init
    
    case "$track_type" in
        event)
            embed_track_event "$name" "$data"
            ;;
        install)
            embed_track_install "$name" "${4:-true}" "${5:-}"
            ;;
        command)
            embed_track_command "$name" "$data" "${4:-true}" "${5:-0}"
            ;;
        feature)
            embed_track_feature "$name" "$data"
            ;;
        error)
            embed_track_error "$name" "$data" "${4:-{}}"
            ;;
        *)
            echo "Available track commands:"
            echo "  pak embed track event <name> [data]"
            echo "  pak embed track install <method> [success] [error]"
            echo "  pak embed track command <name> [args] [success] [duration]"
            echo "  pak embed track feature <name> [data]"
            echo "  pak embed track error <type> <message> [context]"
            ;;
    esac
}

embed_report() {
    local report_type="${1:-status}"
    
    case "$report_type" in
        status)
            embed_status
            ;;
        stats)
            embed_get_stats
            ;;
        *)
            echo "Available report commands:"
            echo "  pak embed report status"
            echo "  pak embed report stats"
            ;;
    esac
}

embed_show_help() {
    echo "PAK.sh Embed Module Usage:"
    echo "  pak embed init                    - Initialize embed system"
    echo "  pak embed telemetry <type> [data] - Track telemetry event"
    echo "  pak embed analytics [type]        - Analytics operations"
    echo "  pak embed track [type] [name] [data] - Track various events"
    echo "  pak embed report [type]           - Generate reports"
    echo ""
    echo "Examples:"
    echo "  pak embed telemetry install '{\"method\":\"npm\"}'"
    echo "  pak embed track event user_login '{\"user_id\":\"123\"}'"
    echo "  pak embed analytics stats"
    echo "  pak embed report status"
}

# Directory validation for embed module
embed_validate_directories() {
    local required_dirs=("$EMBED_DATA_DIR" "$EMBED_LOGS_DIR" "$(dirname "$EMBED_SQLITE_DB")")
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log WARN "Creating missing embed directory: $dir"
            mkdir -p "$dir"
        fi
    done
}

# Health status update for embed module
embed_update_health_status() {
    local status_type="$1"
    local status_value="$2"
    local timestamp=$(date +%s)
    
    # Update health status in memory
    EMBED_HEALTH_STATUS["$status_type"]="$status_value"
    EMBED_HEALTH_STATUS["${status_type}_timestamp"]="$timestamp"
    
    # Log the status update
    log DEBUG "Embed health status updated: $status_type = $status_value"
    
    # Store in SQLite if available
    if [[ -f "$EMBED_SQLITE_DB" ]]; then
        sqlite3 "$EMBED_SQLITE_DB" << EOF
INSERT OR REPLACE INTO health_status (status_type, status_value, timestamp) 
VALUES ('$status_type', '$status_value', '$timestamp');
EOF
    fi
}

# Main function - initialize and track session start (legacy)
embed_main_legacy() {
    embed_init
    embed_track_session_start
    
    # Set up cleanup on exit
    trap 'embed_track_session_end' EXIT
    
    log_success "Embed system ready for $EMBED_PACKAGE_NAME"
}

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "init")
            embed_main
            ;;
        "track")
            embed_init
            embed_track_event "${2:-unknown}" "${3:-{}}"
            ;;
        "install")
            embed_init
            embed_track_install "${2:-unknown}" "${3:-true}" "${4:-}"
            ;;
        "command")
            embed_init
            embed_track_command "${2:-unknown}" "${3:-[]}" "${4:-true}" "${5:-0}"
            ;;
        "feature")
            embed_init
            embed_track_feature "${2:-unknown}" "${3:-{}}"
            ;;
        "error")
            embed_init
            embed_track_error "${2:-unknown}" "${3:-}" "${4:-{}}"
            ;;
        "stats")
            embed_get_stats
            ;;
        "export")
            embed_export_data "${2:-json}" "${3:-}"
            ;;
        "cleanup")
            embed_cleanup "${2:-30}"
            ;;
        "disable")
            embed_disable
            ;;
        "enable")
            embed_enable
            ;;
        "status")
            embed_status
            ;;
        *)
            echo "PAK.sh Embed Usage:"
            echo "  $0 init                    - Initialize embed system"
            echo "  $0 track <type> [data]     - Track an event"
            echo "  $0 install [method] [success] [error] - Track installation"
            echo "  $0 command <name> [args] [success] [duration] - Track command"
            echo "  $0 feature <name> [data]   - Track feature usage"
            echo "  $0 error <type> <message> [context] - Track error"
            echo "  $0 stats                   - Show statistics"
            echo "  $0 export [format] [file]  - Export data"
            echo "  $0 cleanup [days]          - Clean up old data"
            echo "  $0 disable                 - Disable telemetry"
            echo "  $0 enable                  - Enable telemetry"
            echo "  $0 status                  - Show status"
            ;;
    esac
fi 