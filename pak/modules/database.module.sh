#!/bin/bash
# Database module - SQLite database operations for PAK.sh

database_init() {
    log DEBUG "Database module initialized"
    
    # Load database configuration
    database_load_config
    
    # Create database directories
    mkdir -p "$PAK_DATA_DIR/database"
    mkdir -p "$PAK_DATA_DIR/database/backups"
    mkdir -p "$PAK_DATA_DIR/database/migrations"
}

database_register_commands() {
    register_command "db" "database" "database_command"
    register_command "sqlite" "database" "database_sqlite"
    register_command "backup" "database" "database_backup"
    register_command "restore" "database" "database_restore"
    register_command "migrate" "database" "database_migrate"
    register_command "query" "database" "database_query"
    register_command "stats" "database" "database_stats"
}

database_load_config() {
    # Load database configuration from pak.conf
    if [[ -f "pak.conf" ]]; then
        export DB_TYPE=$(grep "^type = " pak.conf | cut -d'=' -f2 | tr -d ' ')
        export DB_SQLITE_PATH=$(grep "^sqlite_path = " pak.conf | cut -d'=' -f2 | tr -d ' ')
        export DB_ENCRYPTED=$(grep "^encrypted = " pak.conf | cut -d'=' -f2 | tr -d ' ')
        export DB_BACKUP_INTERVAL=$(grep "^backup_interval = " pak.conf | cut -d'=' -f2 | tr -d ' ')
        export DB_RETENTION_DAYS=$(grep "^retention_days = " pak.conf | cut -d'=' -f2 | tr -d ' ')
    else
        # Default configuration
        export DB_TYPE="sqlite"
        export DB_SQLITE_PATH="$PAK_DATA_DIR/pak.db"
        export DB_ENCRYPTED="N"
        export DB_BACKUP_INTERVAL="24"
        export DB_RETENTION_DAYS="90"
    fi
}

database_command() {
    local action="${1:-status}"
    
    case "$action" in
        status)
            database_status
            ;;
        init)
            database_initialize
            ;;
        backup)
            database_backup_db
            ;;
        restore)
            database_restore_db "$2"
            ;;
        migrate)
            database_migrate_db
            ;;
        query)
            database_execute_query "$2"
            ;;
        stats)
            database_show_stats
            ;;
        *)
            log ERROR "Unknown database action: $action"
            return 1
            ;;
    esac
}

database_status() {
    echo "🗄️  Database Status"
    echo "=================="
    echo "Type: $DB_TYPE"
    
    if [[ "$DB_TYPE" == "sqlite" ]] || [[ "$DB_TYPE" == "both" ]]; then
        echo "SQLite Path: $DB_SQLITE_PATH"
        echo "Encrypted: $DB_ENCRYPTED"
        
        if [[ -f "$DB_SQLITE_PATH" ]]; then
            local size=$(du -h "$DB_SQLITE_PATH" | cut -f1)
            local tables=$(sqlite3 "$DB_SQLITE_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
            echo "Size: $size"
            echo "Tables: $tables"
            echo "Status: ✅ Active"
        else
            echo "Status: ❌ Not initialized"
        fi
    fi
    
    echo
}

database_initialize() {
    if [[ "$DB_TYPE" == "sqlite" ]] || [[ "$DB_TYPE" == "both" ]]; then
        database_initialize_sqlite
    fi
}

database_initialize_sqlite() {
    log INFO "Initializing SQLite database: $DB_SQLITE_PATH"
    
    # Create database directory
    mkdir -p "$(dirname "$DB_SQLITE_PATH")"
    
    # Initialize database with schema
    sqlite3 "$DB_SQLITE_PATH" << 'EOF'
-- PAK.sh Database Schema v1.0.0

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    version TEXT NOT NULL,
    description TEXT,
    license TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Packages table
CREATE TABLE IF NOT EXISTS packages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER,
    name TEXT NOT NULL,
    platform TEXT NOT NULL,
    version TEXT NOT NULL,
    path TEXT NOT NULL,
    enabled BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id),
    UNIQUE(name, platform)
);

-- Tracking data table
CREATE TABLE IF NOT EXISTS tracking_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    platform TEXT NOT NULL,
    downloads INTEGER DEFAULT 0,
    version TEXT,
    status_code INTEGER,
    response_time REAL,
    available BOOLEAN DEFAULT 1,
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Monitoring data table
CREATE TABLE IF NOT EXISTS monitoring_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    cpu_usage REAL,
    memory_usage REAL,
    disk_usage REAL,
    network_latency REAL,
    availability_score REAL,
    health_status TEXT,
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    alert_type TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT DEFAULT 'warning',
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Deployments table
CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    version TEXT NOT NULL,
    platform TEXT NOT NULL,
    status TEXT NOT NULL,
    strategy TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Configuration table
CREATE TABLE IF NOT EXISTS configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tracking_data_package_time ON tracking_data(package_id, collected_at);
CREATE INDEX IF NOT EXISTS idx_monitoring_data_package_time ON monitoring_data(package_id, collected_at);
CREATE INDEX IF NOT EXISTS idx_alerts_package_time ON alerts(package_id, triggered_at);
CREATE INDEX IF NOT EXISTS idx_deployments_package_time ON deployments(package_id, started_at);

-- Insert initial configuration
INSERT OR REPLACE INTO configuration (key, value, category) VALUES
('database_version', '1.0.0', 'system'),
('created_at', datetime('now'), 'system'),
('database_type', '$DB_TYPE', 'system');

EOF

    # Set proper permissions
    chmod 644 "$DB_SQLITE_PATH"
    
    log SUCCESS "SQLite database initialized: $DB_SQLITE_PATH"
}

database_backup_db() {
    if [[ ! -f "$DB_SQLITE_PATH" ]]; then
        log ERROR "Database not found: $DB_SQLITE_PATH"
        return 1
    fi
    
    local backup_dir="$PAK_DATA_DIR/database/backups"
    local backup_file="$backup_dir/pak-$(date +%Y%m%d-%H%M%S).db"
    
    mkdir -p "$backup_dir"
    
    # Create backup
    cp "$DB_SQLITE_PATH" "$backup_file"
    
    # Compress backup
    gzip "$backup_file"
    
    log SUCCESS "Database backed up: $backup_file.gz"
    
    # Clean old backups
    database_cleanup_old_backups
}

database_restore_db() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log ERROR "Backup file not specified"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log ERROR "Backup file not found: $backup_file"
        return 1
    fi
    
    # Create backup of current database
    database_backup_db
    
    # Restore from backup
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" > "$DB_SQLITE_PATH"
    else
        cp "$backup_file" "$DB_SQLITE_PATH"
    fi
    
    log SUCCESS "Database restored from: $backup_file"
}

database_migrate_db() {
    log INFO "Running database migrations..."
    
    local migrations_dir="$PAK_DATA_DIR/database/migrations"
    mkdir -p "$migrations_dir"
    
    # Get current version
    local current_version=$(sqlite3 "$DB_SQLITE_PATH" "SELECT value FROM configuration WHERE key='database_version';" 2>/dev/null || echo "0.0.0")
    
    # Run migrations
    for migration_file in "$migrations_dir"/*.sql; do
        if [[ -f "$migration_file" ]]; then
            local migration_version=$(basename "$migration_file" .sql)
            if [[ "$migration_version" > "$current_version" ]]; then
                log INFO "Running migration: $migration_version"
                sqlite3 "$DB_SQLITE_PATH" < "$migration_file"
            fi
        fi
    done
    
    log SUCCESS "Database migrations completed"
}

database_execute_query() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        log ERROR "Query not specified"
        return 1
    fi
    
    if [[ ! -f "$DB_SQLITE_PATH" ]]; then
        log ERROR "Database not found: $DB_SQLITE_PATH"
        return 1
    fi
    
    sqlite3 "$DB_SQLITE_PATH" "$query"
}

database_show_stats() {
    if [[ ! -f "$DB_SQLITE_PATH" ]]; then
        log ERROR "Database not found: $DB_SQLITE_PATH"
        return 1
    fi
    
    echo "📊 Database Statistics"
    echo "====================="
    
    # Table row counts
    echo "Table Row Counts:"
    sqlite3 "$DB_SQLITE_PATH" << 'EOF'
SELECT 
    'projects' as table_name, COUNT(*) as count FROM projects
UNION ALL
SELECT 'packages', COUNT(*) FROM packages
UNION ALL
SELECT 'tracking_data', COUNT(*) FROM tracking_data
UNION ALL
SELECT 'monitoring_data', COUNT(*) FROM monitoring_data
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts
UNION ALL
SELECT 'deployments', COUNT(*) FROM deployments
UNION ALL
SELECT 'configuration', COUNT(*) FROM configuration;
EOF
    
    echo
    echo "Database Size:"
    du -h "$DB_SQLITE_PATH"
    
    echo
    echo "Recent Activity:"
    sqlite3 "$DB_SQLITE_PATH" "SELECT datetime(created_at) as created, name FROM projects ORDER BY created_at DESC LIMIT 5;"
}

database_cleanup_old_backups() {
    local backup_dir="$PAK_DATA_DIR/database/backups"
    local retention_days="${DB_RETENTION_DAYS:-90}"
    
    # Remove backups older than retention period
    find "$backup_dir" -name "*.db.gz" -mtime +$retention_days -delete 2>/dev/null
    
    log INFO "Cleaned up backups older than $retention_days days"
}

# Database utility functions
database_insert_tracking_data() {
    local package_id="$1"
    local platform="$2"
    local downloads="$3"
    local version="$4"
    local status_code="$5"
    local response_time="$6"
    local available="$7"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT INTO tracking_data (package_id, platform, downloads, version, status_code, response_time, available)
VALUES ($package_id, '$platform', $downloads, '$version', $status_code, $response_time, $available);
EOF
}

database_insert_monitoring_data() {
    local package_id="$1"
    local cpu_usage="$2"
    local memory_usage="$3"
    local disk_usage="$4"
    local network_latency="$5"
    local availability_score="$6"
    local health_status="$7"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT INTO monitoring_data (package_id, cpu_usage, memory_usage, disk_usage, network_latency, availability_score, health_status)
VALUES ($package_id, $cpu_usage, $memory_usage, $disk_usage, $network_latency, $availability_score, '$health_status');
EOF
}

database_insert_alert() {
    local package_id="$1"
    local alert_type="$2"
    local message="$3"
    local severity="${4:-warning}"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT INTO alerts (package_id, alert_type, message, severity)
VALUES ($package_id, '$alert_type', '$message', '$severity');
EOF
}

database_insert_deployment() {
    local package_id="$1"
    local version="$2"
    local platform="$3"
    local status="$4"
    local strategy="$5"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT INTO deployments (package_id, version, platform, status, strategy)
VALUES ($package_id, '$version', '$platform', '$status', '$strategy');
EOF
}

database_get_package_id() {
    local package_name="$1"
    local platform="$2"
    
    sqlite3 "$DB_SQLITE_PATH" "SELECT id FROM packages WHERE name='$package_name' AND platform='$platform';"
}

database_create_package() {
    local project_id="$1"
    local package_name="$2"
    local platform="$3"
    local version="$4"
    local path="$5"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT OR REPLACE INTO packages (project_id, name, platform, version, path)
VALUES ($project_id, '$package_name', '$platform', '$version', '$path');
EOF
}

database_get_project_id() {
    local project_name="$1"
    
    sqlite3 "$DB_SQLITE_PATH" "SELECT id FROM projects WHERE name='$project_name';"
}

database_create_project() {
    local project_name="$1"
    local version="$2"
    local description="$3"
    local license="$4"
    
    sqlite3 "$DB_SQLITE_PATH" << EOF
INSERT OR REPLACE INTO projects (name, version, description, license)
VALUES ('$project_name', '$version', '$description', '$license');
EOF
} 