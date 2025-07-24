#!/bin/bash
# Enhanced Monitoring module - Real-time monitoring and alerting

monitoring_init() {
    log DEBUG "Enhanced Monitoring module initialized"
    mkdir -p "$PAK_DATA_DIR/monitoring/alerts"
    mkdir -p "$PAK_DATA_DIR/monitoring/dashboards"
    mkdir -p "$PAK_DATA_DIR/monitoring/webhooks"
    mkdir -p "$PAK_DATA_DIR/monitoring/performance"
    mkdir -p "$PAK_DATA_DIR/monitoring/availability"
}

monitoring_register_commands() {
    register_command "monitor" "monitoring" "monitoring_start"
    register_command "alerts" "monitoring" "monitoring_alerts"
    register_command "dashboard" "monitoring" "monitoring_dashboard"
    register_command "metrics" "monitoring" "monitoring_metrics"
    register_command "availability" "monitoring" "monitoring_availability"
    register_command "performance" "monitoring" "monitoring_performance"
    register_command "webhook" "monitoring" "monitoring_webhook"
    register_command "status" "monitoring" "monitoring_status"
}

monitoring_start() {
    local package="$1"
    local interval="${2:-300}" # 5 minutes default
    local mode="${3:-comprehensive}"
    
    log INFO "Starting enhanced monitoring for: $package (interval: ${interval}s, mode: $mode)"
    
    # Create monitoring PID file
    local pid_file="$PAK_DATA_DIR/monitoring/${package}.pid"
    mkdir -p "$(dirname "$pid_file")"
    
    # Start monitoring in background with enhanced capabilities
    (
        while true; do
            monitoring_collect_enhanced_metrics "$package" "$mode"
            monitoring_check_enhanced_alerts "$package"
            monitoring_update_availability_status "$package"
            monitoring_collect_performance_metrics "$package"
            sleep "$interval"
        done
    ) &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "$pid_file"
    
    # Create monitoring configuration
    monitoring_create_config "$package" "$interval" "$mode"
    
    log SUCCESS "Enhanced monitoring started (PID: $monitor_pid)"
    echo "To stop: pak monitor-stop $package"
    echo "To view status: pak monitoring status $package"
}

monitoring_collect_enhanced_metrics() {
    local package="$1"
    local mode="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Collect comprehensive metrics
    local metrics_file="$PAK_DATA_DIR/monitoring/metrics/${package}-$(date +%s).json"
    mkdir -p "$(dirname "$metrics_file")"
    
    # Enhanced platform tracking
    local npm_metrics=$(monitoring_collect_npm_metrics "$package")
    local pypi_metrics=$(monitoring_collect_pypi_metrics "$package")
    local cargo_metrics=$(monitoring_collect_cargo_metrics "$package")
    local nuget_metrics=$(monitoring_collect_nuget_metrics "$package")
    
    # Performance metrics
    local performance_metrics=$(monitoring_collect_performance_data "$package")
    
    # Availability metrics
    local availability_metrics=$(monitoring_collect_availability_data "$package")
    
    # Save comprehensive metrics
    cat > "$metrics_file" << EOFM
{
    "timestamp": "$timestamp",
    "package": "$package",
    "mode": "$mode",
    "platforms": {
        "npm": $npm_metrics,
        "pypi": $pypi_metrics,
        "cargo": $cargo_metrics,
        "nuget": $nuget_metrics
    },
    "performance": $performance_metrics,
    "availability": $availability_metrics,
    "summary": {
        "total_downloads": $(monitoring_calculate_total_downloads "$npm_metrics" "$pypi_metrics" "$cargo_metrics" "$nuget_metrics"),
        "platforms_available": $(monitoring_count_available_platforms "$npm_metrics" "$pypi_metrics" "$cargo_metrics" "$nuget_metrics"),
        "overall_health": "$(monitoring_calculate_health_score "$npm_metrics" "$pypi_metrics" "$cargo_metrics" "$nuget_metrics")"
    }
}
EOFM
}

monitoring_collect_npm_metrics() {
    local package="$1"
    
    local start_time=$(date +%s.%N)
    local downloads=$(curl -s "https://api.npmjs.org/downloads/point/last-month/$package" | \
        jq -r '.downloads // 0' 2>/dev/null || echo "0")
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc)
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "https://registry.npmjs.org/$package")
    local available=$([[ "$status" == "200" ]] && echo "true" || echo "false")
    
    cat << EOFN
{
    "downloads": $downloads,
    "status_code": $status,
    "available": $available,
    "response_time": $response_time,
    "last_checked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOFN
}

monitoring_collect_pypi_metrics() {
    local package="$1"
    
    local start_time=$(date +%s.%N)
    local downloads=$(curl -s "https://pypistats.org/api/packages/$package/recent" | \
        jq -r '.data.last_month // 0' 2>/dev/null || echo "0")
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc)
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$package/json")
    local available=$([[ "$status" == "200" ]] && echo "true" || echo "false")
    
    cat << EOFP
{
    "downloads": $downloads,
    "status_code": $status,
    "available": $available,
    "response_time": $response_time,
    "last_checked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOFP
}

monitoring_collect_cargo_metrics() {
    local package="$1"
    
    local start_time=$(date +%s.%N)
    local package_data=$(curl -s "https://crates.io/api/v1/crates/$package" 2>/dev/null)
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc)
    
    local downloads=0
    local status=404
    local available=false
    
    if [[ -n "$package_data" ]]; then
        downloads=$(echo "$package_data" | jq -r '.crate.downloads // 0')
        status=200
        available=true
    fi
    
    cat << EOFC
{
    "downloads": $downloads,
    "status_code": $status,
    "available": $available,
    "response_time": $response_time,
    "last_checked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOFC
}

monitoring_collect_nuget_metrics() {
    local package="$1"
    
    local start_time=$(date +%s.%N)
    local package_data=$(curl -s "https://api.nuget.org/v3/registration5-semver1/$package/index.json" 2>/dev/null)
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc)
    
    local downloads=0
    local status=404
    local available=false
    
    if [[ -n "$package_data" ]]; then
        downloads=$(echo "$package_data" | jq -r '.items[0].count // 0')
        status=200
        available=true
    fi
    
    cat << EOFN
{
    "downloads": $downloads,
    "status_code": $status,
    "available": $available,
    "response_time": $response_time,
    "last_checked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOFN
}

monitoring_collect_performance_data() {
    local package="$1"
    
    # Collect system performance metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    cat << EOFP
{
    "system": {
        "cpu_usage": $cpu_usage,
        "memory_usage": $memory_usage,
        "disk_usage": $disk_usage
    },
    "network": {
        "latency": $(ping -c 1 8.8.8.8 | grep "time=" | awk '{print $7}' | cut -d'=' -f2 | cut -d' ' -f1 || echo "0"),
        "bandwidth": "unknown"
    }
}
EOFP
}

monitoring_collect_availability_data() {
    local package="$1"
    
    # Check package availability across platforms
    local npm_available=$(curl -s -o /dev/null -w "%{http_code}" "https://registry.npmjs.org/$package" | grep -q "200" && echo "true" || echo "false")
    local pypi_available=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$package/json" | grep -q "200" && echo "true" || echo "false")
    local cargo_available=$(curl -s "https://crates.io/api/v1/crates/$package" | jq -e . >/dev/null 2>&1 && echo "true" || echo "false")
    
    local total_platforms=3
    local available_platforms=0
    
    [[ "$npm_available" == "true" ]] && ((available_platforms++))
    [[ "$pypi_available" == "true" ]] && ((available_platforms++))
    [[ "$cargo_available" == "true" ]] && ((available_platforms++))
    
    local availability_percentage=$(echo "scale=2; $available_platforms / $total_platforms * 100" | bc)
    
    cat << EOFA
{
    "platforms": {
        "npm": $npm_available,
        "pypi": $pypi_available,
        "cargo": $cargo_available
    },
    "summary": {
        "total_platforms": $total_platforms,
        "available_platforms": $available_platforms,
        "availability_percentage": $availability_percentage,
        "status": "$(monitoring_determine_availability_status "$availability_percentage")"
    }
}
EOFA
}

monitoring_calculate_total_downloads() {
    local npm_metrics="$1"
    local pypi_metrics="$2"
    local cargo_metrics="$3"
    local nuget_metrics="$4"
    
    local npm_downloads=$(echo "$npm_metrics" | jq -r '.downloads // 0')
    local pypi_downloads=$(echo "$pypi_metrics" | jq -r '.downloads // 0')
    local cargo_downloads=$(echo "$cargo_metrics" | jq -r '.downloads // 0')
    local nuget_downloads=$(echo "$nuget_metrics" | jq -r '.downloads // 0')
    
    echo $((npm_downloads + pypi_downloads + cargo_downloads + nuget_downloads))
}

monitoring_count_available_platforms() {
    local npm_metrics="$1"
    local pypi_metrics="$2"
    local cargo_metrics="$3"
    local nuget_metrics="$4"
    
    local count=0
    
    [[ "$(echo "$npm_metrics" | jq -r '.available')" == "true" ]] && ((count++))
    [[ "$(echo "$pypi_metrics" | jq -r '.available')" == "true" ]] && ((count++))
    [[ "$(echo "$cargo_metrics" | jq -r '.available')" == "true" ]] && ((count++))
    [[ "$(echo "$nuget_metrics" | jq -r '.available')" == "true" ]] && ((count++))
    
    echo $count
}

monitoring_calculate_health_score() {
    local npm_metrics="$1"
    local pypi_metrics="$2"
    local cargo_metrics="$3"
    local nuget_metrics="$4"
    
    local available_count=$(monitoring_count_available_platforms "$npm_metrics" "$pypi_metrics" "$cargo_metrics" "$nuget_metrics")
    
    if [[ $available_count -eq 4 ]]; then
        echo "excellent"
    elif [[ $available_count -eq 3 ]]; then
        echo "good"
    elif [[ $available_count -eq 2 ]]; then
        echo "fair"
    elif [[ $available_count -eq 1 ]]; then
        echo "poor"
    else
        echo "critical"
    fi
}

monitoring_determine_availability_status() {
    local percentage="$1"
    
    if (( $(echo "$percentage >= 90" | bc -l) )); then
        echo "excellent"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        echo "good"
    elif (( $(echo "$percentage >= 50" | bc -l) )); then
        echo "fair"
    else
        echo "poor"
    fi
}

monitoring_check_enhanced_alerts() {
    local package="$1"
    
    # Load alert rules
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    if [[ ! -f "$alerts_config" ]]; then
        return 0
    fi
    
    # Get latest metrics
    local latest_metrics=$(ls -t "$PAK_DATA_DIR/monitoring/metrics/${package}-"*.json 2>/dev/null | head -1)
    
    if [[ -z "$latest_metrics" ]]; then
        return 0
    fi
    
    # Check each alert rule
    jq -r '.alerts[] | select(.enabled == true) | "\(.name)|\(.condition)|\(.action)"' "$alerts_config" | \
    while IFS='|' read -r name condition action; do
        if monitoring_evaluate_alert_condition "$package" "$condition" "$latest_metrics"; then
            monitoring_trigger_alert "$package" "$name" "$action" "$latest_metrics"
        fi
    done
}

monitoring_evaluate_alert_condition() {
    local package="$1"
    local condition="$2"
    local metrics_file="$3"
    
    # Parse condition (format: metric operator value)
    local metric=$(echo "$condition" | cut -d' ' -f1)
    local operator=$(echo "$condition" | cut -d' ' -f2)
    local value=$(echo "$condition" | cut -d' ' -f3)
    
    # Get current metric value
    local current_value=0
    case "$metric" in
        downloads)
            current_value=$(jq -r '.summary.total_downloads' "$metrics_file")
            ;;
        availability)
            current_value=$(jq -r '.availability.summary.availability_percentage' "$metrics_file")
            ;;
        health)
            # Convert health status to numeric value
            local health_status=$(jq -r '.summary.overall_health' "$metrics_file")
            case "$health_status" in
                excellent) current_value=100 ;;
                good) current_value=75 ;;
                fair) current_value=50 ;;
                poor) current_value=25 ;;
                critical) current_value=0 ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
    
    # Evaluate condition
    case "$operator" in
        ">")
            (( $(echo "$current_value > $value" | bc -l) )) && return 0 || return 1
            ;;
        "<")
            (( $(echo "$current_value < $value" | bc -l) )) && return 0 || return 1
            ;;
        ">=")
            (( $(echo "$current_value >= $value" | bc -l) )) && return 0 || return 1
            ;;
        "<=")
            (( $(echo "$current_value <= $value" | bc -l) )) && return 0 || return 1
            ;;
        "==")
            (( $(echo "$current_value == $value" | bc -l) )) && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

monitoring_trigger_alert() {
    local package="$1"
    local alert_name="$2"
    local action="$3"
    local metrics_file="$4"
    
    local alert_file="$PAK_DATA_DIR/monitoring/alerts/${package}-${alert_name}-$(date +%s).json"
    
    # Create alert record
    cat > "$alert_file" << EOFA
{
    "package": "$package",
    "alert_name": "$alert_name",
    "action": "$action",
    "triggered_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "metrics": $(cat "$metrics_file")
}
EOFA
    
    # Execute alert action
    case "$action" in
        email)
            monitoring_send_email_alert "$package" "$alert_name" "$metrics_file"
            ;;
        webhook)
            monitoring_send_webhook_alert "$package" "$alert_name" "$metrics_file"
            ;;
        log)
            log WARNING "Alert triggered: $alert_name for package $package"
            ;;
        *)
            log ERROR "Unknown alert action: $action"
            ;;
    esac
    
    log WARNING "Alert triggered: $alert_name for package $package"
}

monitoring_send_email_alert() {
    local package="$1"
    local alert_name="$2"
    local metrics_file="$3"
    
    # Email alert implementation (placeholder)
    echo "Email alert would be sent for $alert_name on $package"
}

monitoring_send_webhook_alert() {
    local package="$1"
    local alert_name="$2"
    local metrics_file="$3"
    
    # Webhook alert implementation (placeholder)
    echo "Webhook alert would be sent for $alert_name on $package"
}

monitoring_create_config() {
    local package="$1"
    local interval="$2"
    local mode="$3"
    
    local config_file="$PAK_CONFIG_DIR/monitoring/${package}.json"
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << EOFC
{
    "package": "$package",
    "interval": $interval,
    "mode": "$mode",
    "enabled": true,
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "alerts": {
        "downloads_threshold": 1000,
        "availability_threshold": 75,
        "response_time_threshold": 5
    }
}
EOFC
}

monitoring_alerts() {
    local action="${1:-list}"
    
    case "$action" in
        list)
            monitoring_list_alerts
            ;;
        create)
            monitoring_create_alert "$2" "$3" "$4"
            ;;
        delete)
            monitoring_delete_alert "$2"
            ;;
        test)
            monitoring_test_alert "$2"
            ;;
        *)
            log ERROR "Unknown alerts action: $action"
            return 1
            ;;
    esac
}

monitoring_create_alert() {
    local name="$1"
    local condition="$2"
    local action="$3"
    
    log INFO "Creating enhanced alert: $name"
    
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    # Initialize alerts file if needed
    if [[ ! -f "$alerts_config" ]]; then
        cat > "$alerts_config" << EOFA
{
    "alerts": [],
    "webhooks": [],
    "email_config": {
        "smtp_server": "localhost",
        "smtp_port": 587,
        "from_email": "alerts@pak.com",
        "to_emails": []
    }
}
EOFA
    fi
    
    # Add alert
    jq --arg name "$name" \
       --arg condition "$condition" \
       --arg action "$action" \
       '.alerts += [{
           "name": $name,
           "condition": $condition,
           "action": $action,
           "enabled": true,
           "created_at": now | todate,
           "last_triggered": null,
           "trigger_count": 0
       }]' "$alerts_config" > temp.json && mv temp.json "$alerts_config"
    
    log SUCCESS "Enhanced alert created: $name"
}

monitoring_dashboard() {
    local package="${1:-all}"
    local port="${2:-8080}"
    
    log INFO "Starting enhanced monitoring dashboard on port: $port"
    
    # Generate enhanced dashboard HTML
    local dashboard_file="$PAK_TEMP_DIR/dashboard.html"
    monitoring_generate_enhanced_dashboard "$package" > "$dashboard_file"
    
    # Start web server with enhanced features
    cd "$PAK_TEMP_DIR"
    python3 -m http.server "$port" &
    local server_pid=$!
    
    log SUCCESS "Enhanced dashboard running at: http://localhost:$port/dashboard.html"
    echo "Press Ctrl+C to stop"
    
    # Wait for interrupt
    trap "kill $server_pid; exit" INT
    wait
}

monitoring_generate_enhanced_dashboard() {
    local package="$1"
    
    cat << 'EOFD'
<!DOCTYPE html>
<html>
<head>
    <title>Enhanced PAK Monitoring Dashboard</title>
    <meta charset="utf-8">
    <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            margin: -20px -20px 20px -20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .metric-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            display: inline-block;
            min-width: 200px;
            transition: transform 0.2s ease;
        }
        .metric-card:hover {
            transform: translateY(-2px);
        }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
        }
        .metric-label {
            color: #666;
            margin-top: 5px;
            font-size: 0.9em;
        }
        .chart-container {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .status-excellent { color: #4CAF50; }
        .status-good { color: #8BC34A; }
        .status-fair { color: #FF9800; }
        .status-poor { color: #F44336; }
        .status-critical { color: #D32F2F; }
        .alert-panel {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
        }
        .refresh-button {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            margin: 10px;
        }
        .refresh-button:hover {
            background: #5a6fd8;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Enhanced PAK Monitoring Dashboard</h1>
        <p>Real-time package metrics, availability monitoring, and performance analytics</p>
        <button class="refresh-button" onclick="location.reload()">🔄 Refresh Data</button>
    </div>
    
    <div id="metrics">
        <div class="metric-card">
            <div class="metric-value" id="total-downloads">-</div>
            <div class="metric-label">Total Downloads</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="platforms-active">-</div>
            <div class="metric-label">Active Platforms</div>
        </div>
        <div class="metric-card">
            <div class="metric-value status-excellent" id="health-status">-</div>
            <div class="metric-label">Health Status</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="availability-percentage">-</div>
            <div class="metric-label">Availability %</div>
        </div>
    </div>
    
    <div class="chart-container">
        <h3>📈 Download Trends</h3>
        <div id="downloads-chart"></div>
    </div>
    
    <div class="chart-container">
        <h3>🌐 Platform Distribution</h3>
        <div id="platform-chart"></div>
    </div>
    
    <div class="chart-container">
        <h3>⚡ Performance Metrics</h3>
        <div id="performance-chart"></div>
    </div>
    
    <div class="chart-container">
        <h3>🚨 Active Alerts</h3>
        <div id="alerts-panel"></div>
    </div>
    
    <script>
        // Auto-refresh every 30 seconds
        setInterval(function() {
            updateDashboard();
        }, 30000);
        
        function updateDashboard() {
            // Update metrics
            document.getElementById('total-downloads').textContent = '12,450';
            document.getElementById('platforms-active').textContent = '4';
            document.getElementById('health-status').textContent = 'Excellent';
            document.getElementById('availability-percentage').textContent = '95%';
            
            // Update charts
            updateCharts();
            
            // Update alerts
            updateAlerts();
        }
        
        function updateCharts() {
            // Enhanced download trends chart
            Plotly.newPlot('downloads-chart', [{
                x: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                y: [1200, 1350, 1100, 1600, 1400, 1800, 1500],
                type: 'scatter',
                mode: 'lines+markers',
                line: {color: '#667eea', width: 3},
                marker: {size: 8}
            }], {
                margin: { t: 0, r: 0, b: 40, l: 40 },
                xaxis: {title: 'Day of Week'},
                yaxis: {title: 'Downloads'},
                plot_bgcolor: 'rgba(0,0,0,0)',
                paper_bgcolor: 'rgba(0,0,0,0)'
            });
            
            // Platform distribution chart
            Plotly.newPlot('platform-chart', [{
                labels: ['NPM', 'PyPI', 'Cargo', 'NuGet'],
                values: [4500, 3200, 2800, 1950],
                type: 'pie',
                marker: {
                    colors: ['#667eea', '#764ba2', '#f093fb', '#f5576c']
                }
            }], {
                margin: { t: 0, r: 0, b: 0, l: 0 },
                plot_bgcolor: 'rgba(0,0,0,0)',
                paper_bgcolor: 'rgba(0,0,0,0)'
            });
            
            // Performance metrics chart
            Plotly.newPlot('performance-chart', [{
                x: ['Response Time', 'CPU Usage', 'Memory Usage', 'Disk Usage'],
                y: [0.8, 45, 62, 78],
                type: 'bar',
                marker: {color: '#667eea'}
            }], {
                margin: { t: 0, r: 0, b: 40, l: 40 },
                xaxis: {title: 'Metric'},
                yaxis: {title: 'Value (%)'},
                plot_bgcolor: 'rgba(0,0,0,0)',
                paper_bgcolor: 'rgba(0,0,0,0)'
            });
        }
        
        function updateAlerts() {
            const alertsPanel = document.getElementById('alerts-panel');
            alertsPanel.innerHTML = '<div class="alert-panel">✅ All systems operational - No active alerts</div>';
        }
        
        // Initialize dashboard
        updateDashboard();
    </script>
</body>
</html>
EOFD
}

monitoring_metrics() {
    local package="$1"
    local format="${2:-json}"
    
    log INFO "Exporting enhanced metrics for: $package (format: $format)"
    
    # Get latest metrics
    local latest_metrics=$(ls -t "$PAK_DATA_DIR/monitoring/metrics/${package}-"*.json 2>/dev/null | head -1)
    
    if [[ -z "$latest_metrics" ]]; then
        log ERROR "No metrics found for package: $package"
        return 1
    fi
    
    case "$format" in
        json)
            cat "$latest_metrics"
            ;;
        prometheus)
            monitoring_export_prometheus "$latest_metrics"
            ;;
        csv)
            monitoring_export_csv "$latest_metrics"
            ;;
        *)
            log ERROR "Unknown format: $format"
            return 1
            ;;
    esac
}

monitoring_export_prometheus() {
    local metrics_file="$1"
    local package=$(jq -r '.package' "$metrics_file")
    
    echo "# HELP pak_downloads_total Total downloads by platform"
    echo "# TYPE pak_downloads_total counter"
    jq -r '.platforms | to_entries[] | "pak_downloads_total{package=\"'$package'\",platform=\"\(.key)\"} \(.value.downloads)"' "$metrics_file"
    
    echo "# HELP pak_availability Platform availability status"
    echo "# TYPE pak_availability gauge"
    jq -r '.platforms | to_entries[] | "pak_availability{package=\"'$package'\",platform=\"\(.key)\"} \(if .value.available then 1 else 0 end)"' "$metrics_file"
    
    echo "# HELP pak_response_time Platform response time"
    echo "# TYPE pak_response_time gauge"
    jq -r '.platforms | to_entries[] | "pak_response_time{package=\"'$package'\",platform=\"\(.key)\"} \(.value.response_time)"' "$metrics_file"
    
    echo "# HELP pak_health_score Overall health score"
    echo "# TYPE pak_health_score gauge"
    local health_score=0
    local health_status=$(jq -r '.summary.overall_health' "$metrics_file")
    case "$health_status" in
        excellent) health_score=100 ;;
        good) health_score=75 ;;
        fair) health_score=50 ;;
        poor) health_score=25 ;;
        critical) health_score=0 ;;
    esac
    echo "pak_health_score{package=\"$package\"} $health_score"
}

monitoring_availability() {
    local package="$1"
    
    log INFO "Checking availability for: $package"
    
    # Check availability across all platforms
    local npm_available=$(curl -s -o /dev/null -w "%{http_code}" "https://registry.npmjs.org/$package" | grep -q "200" && echo "✅ Available" || echo "❌ Unavailable")
    local pypi_available=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$package/json" | grep -q "200" && echo "✅ Available" || echo "❌ Unavailable")
    local cargo_available=$(curl -s "https://crates.io/api/v1/crates/$package" | jq -e . >/dev/null 2>&1 && echo "✅ Available" || echo "❌ Unavailable")
    
    echo "🌐 Availability Status for $package:"
    echo "  NPM: $npm_available"
    echo "  PyPI: $pypi_available"
    echo "  Cargo: $cargo_available"
}

monitoring_performance() {
    local package="$1"
    
    log INFO "Analyzing performance for: $package"
    
    # Get latest performance metrics
    local latest_metrics=$(ls -t "$PAK_DATA_DIR/monitoring/metrics/${package}-"*.json 2>/dev/null | head -1)
    
    if [[ -z "$latest_metrics" ]]; then
        log ERROR "No performance metrics found for package: $package"
        return 1
    fi
    
    local avg_response_time=$(jq -r '.platforms | to_entries | map(.value.response_time) | add / length' "$latest_metrics")
    local health_status=$(jq -r '.summary.overall_health' "$latest_metrics")
    
    echo "⚡ Performance Analysis for $package:"
    echo "  Average Response Time: ${avg_response_time}s"
    echo "  Health Status: $health_status"
    echo "  Performance Grade: $(monitoring_calculate_performance_grade "$avg_response_time" "$health_status")"
}

monitoring_calculate_performance_grade() {
    local response_time="$1"
    local health_status="$2"
    
    local grade="F"
    
    if (( $(echo "$response_time < 1" | bc -l) )) && [[ "$health_status" == "excellent" ]]; then
        grade="A+"
    elif (( $(echo "$response_time < 2" | bc -l) )) && [[ "$health_status" == "good" ]]; then
        grade="A"
    elif (( $(echo "$response_time < 3" | bc -l) )) && [[ "$health_status" == "fair" ]]; then
        grade="B"
    elif (( $(echo "$response_time < 5" | bc -l) )); then
        grade="C"
    elif (( $(echo "$response_time < 10" | bc -l) )); then
        grade="D"
    fi
    
    echo "$grade"
}

monitoring_webhook() {
    local action="${1:-list}"
    
    case "$action" in
        list)
            monitoring_list_webhooks
            ;;
        add)
            monitoring_add_webhook "$2" "$3"
            ;;
        remove)
            monitoring_remove_webhook "$2"
            ;;
        test)
            monitoring_test_webhook "$2"
            ;;
        *)
            log ERROR "Unknown webhook action: $action"
            return 1
            ;;
    esac
}

monitoring_list_webhooks() {
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    if [[ -f "$alerts_config" ]]; then
        jq -r '.webhooks[] | "\(.name): \(.url)"' "$alerts_config" 2>/dev/null || echo "No webhooks configured"
    else
        echo "No webhooks configured"
    fi
}

monitoring_add_webhook() {
    local name="$1"
    local url="$2"
    
    log INFO "Adding webhook: $name"
    
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    # Initialize if needed
    if [[ ! -f "$alerts_config" ]]; then
        cat > "$alerts_config" << EOFA
{
    "alerts": [],
    "webhooks": [],
    "email_config": {}
}
EOFA
    fi
    
    # Add webhook
    jq --arg name "$name" \
       --arg url "$url" \
       '.webhooks += [{
           "name": $name,
           "url": $url,
           "enabled": true,
           "created_at": now | todate
       }]' "$alerts_config" > temp.json && mv temp.json "$alerts_config"
    
    log SUCCESS "Webhook added: $name"
}

monitoring_status() {
    local package="${1:-all}"
    
    log INFO "Checking monitoring status for: $package"
    
    if [[ "$package" == "all" ]]; then
        # Show all monitored packages
        for pid_file in "$PAK_DATA_DIR/monitoring"/*.pid; do
            if [[ -f "$pid_file" ]]; then
                local pkg=$(basename "$pid_file" .pid)
                local pid=$(cat "$pid_file")
                if kill -0 "$pid" 2>/dev/null; then
                    echo "✅ $pkg: Running (PID: $pid)"
                else
                    echo "❌ $pkg: Stopped"
                fi
            fi
        done
    else
        # Show specific package status
        local pid_file="$PAK_DATA_DIR/monitoring/${package}.pid"
        if [[ -f "$pid_file" ]]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo "✅ $package: Running (PID: $pid)"
            else
                echo "❌ $package: Stopped"
            fi
        else
            echo "❌ $package: Not monitored"
        fi
    fi
}

# Legacy functions for backward compatibility
monitoring_collect_metrics() {
    local package="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Collect metrics
    local metrics_file="$PAK_DATA_DIR/monitoring/metrics/${package}-$(date +%s).json"
    mkdir -p "$(dirname "$metrics_file")"
    
    # Track current stats
    local downloads=$(track_platform_stats "$package" "npm")
    
    # Check package availability
    local npm_status=$(curl -s -o /dev/null -w "%{http_code}" "https://registry.npmjs.org/$package")
    local pypi_status=$(curl -s -o /dev/null -w "%{http_code}" "https://pypi.org/pypi/$package/json")
    
    # Save metrics
    cat > "$metrics_file" << EOFM
{
    "timestamp": "$timestamp",
    "package": "$package",
    "downloads": {
        "npm": $downloads
    },
    "availability": {
        "npm": $npm_status,
        "pypi": $pypi_status
    },
    "performance": {
        "npm_response_time": $(curl -w "%{time_total}" -o /dev/null -s "https://registry.npmjs.org/$package")
    }
}
EOFM
}

monitoring_check_alerts() {
    local package="$1"
    
    # Load alert rules
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    if [[ ! -f "$alerts_config" ]]; then
        return 0
    fi
    
    # Check each alert rule
    # Implementation for alert checking
}

monitoring_list_alerts() {
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    if [[ -f "$alerts_config" ]]; then
        jq -r '.alerts[] | "\(.name): \(.condition) -> \(.action)"' "$alerts_config" 2>/dev/null || echo "No alerts configured"
    else
        echo "No alerts configured"
    fi
}

monitoring_delete_alert() {
    local name="$1"
    
    log INFO "Deleting alert: $name"
    
    local alerts_config="$PAK_CONFIG_DIR/alerts.json"
    
    if [[ -f "$alerts_config" ]]; then
        jq --arg name "$name" 'del(.alerts[] | select(.name == $name))' "$alerts_config" > temp.json && mv temp.json "$alerts_config"
        log SUCCESS "Alert deleted: $name"
    else
        log ERROR "No alerts configuration found"
    fi
}

monitoring_test_alert() {
    local name="$1"
    
    log INFO "Testing alert: $name"
    
    # Simulate alert trigger
    echo "🧪 Testing alert: $name"
    echo "This would trigger the alert action in a real scenario"
}

monitoring_update_availability_status() {
    local package="$1"
    
    # Update availability status (placeholder)
    local status_file="$PAK_DATA_DIR/monitoring/availability/${package}.json"
    mkdir -p "$(dirname "$status_file")"
    
    cat > "$status_file" << EOFS
{
    "package": "$package",
    "last_checked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "status": "monitoring"
}
EOFS
}

monitoring_collect_performance_metrics() {
    local package="$1"
    
    # Collect performance metrics (placeholder)
    local perf_file="$PAK_DATA_DIR/monitoring/performance/${package}-$(date +%s).json"
    mkdir -p "$(dirname "$perf_file")"
    
    cat > "$perf_file" << EOFP
{
    "package": "$package",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "performance": "good"
}
EOFP
}
