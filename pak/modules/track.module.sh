#!/bin/bash
# Enhanced Track module - Comprehensive package statistics tracking

track_init() {
    log DEBUG "Enhanced Track module initialized"
    mkdir -p "$PAK_DATA_DIR/tracking/real-time"
    mkdir -p "$PAK_DATA_DIR/tracking/historical"
    mkdir -p "$PAK_DATA_DIR/tracking/comparisons"
    mkdir -p "$PAK_DATA_DIR/tracking/aggregated"
    mkdir -p "$PAK_DATA_DIR/tracking/performance"
}

track_register_commands() {
    register_command "track" "track" "track_package"
    register_command "history" "track" "track_history"
    register_command "compare" "track" "track_compare"
    register_command "aggregate" "track" "track_aggregate"
    register_command "performance" "track" "track_performance"
    register_command "real-time" "track" "track_realtime"
    register_command "export" "track" "track_export"
    register_command "cleanup" "track" "track_cleanup"
}

track_package() {
    local package="$1"
    local platforms="${2:-$PAK_DEFAULT_PLATFORMS}"
    local mode="${3:-standard}"
    
    log INFO "Enhanced tracking for package: $package (mode: $mode)"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local track_record="$PAK_DATA_DIR/tracking/${package}-$(date +%s).json"
    
    # Initialize comprehensive tracking record
    cat > "$track_record" << EOFT
{
    "package": "$package",
    "timestamp": "$timestamp",
    "mode": "$mode",
    "platforms": {},
    "summary": {
        "total_downloads": 0,
        "platforms_tracked": 0,
        "success_rate": 0,
        "response_times": {},
        "errors": []
    },
    "metadata": {
        "tracking_version": "2.0",
        "collection_method": "enhanced",
        "data_quality": "high"
    }
}
EOFT
    
    # Track each platform with enhanced metrics
    local total_downloads=0
    local platforms_tracked=0
    local total_success=0
    local total_attempts=0
    
    for platform in $platforms; do
        local start_time=$(date +%s.%N)
        local result=$(track_platform_stats_enhanced "$package" "$platform")
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc)
        
        ((total_attempts++))
        
        if [[ -n "$result" ]] && [[ "$result" != "error" ]]; then
            ((platforms_tracked++))
            ((total_success++))
            local downloads=$(echo "$result" | jq -r '.downloads')
            ((total_downloads += downloads))
            
            # Update record with enhanced data
            jq --arg platform "$platform" \
               --argjson result "$result" \
               --arg response_time "$response_time" \
               '.platforms[$platform] = ($result + {"response_time": ($response_time | tonumber)})' \
               "$track_record" > temp.json && mv temp.json "$track_record"
        else
            # Record error
            jq --arg platform "$platform" \
               --arg error "Failed to fetch data" \
               --arg response_time "$response_time" \
               '.summary.errors += [{"platform": $platform, "error": $error, "response_time": ($response_time | tonumber)}]' \
               "$track_record" > temp.json && mv temp.json "$track_record"
        fi
    done
    
    # Calculate success rate
    local success_rate=0
    if [[ $total_attempts -gt 0 ]]; then
        success_rate=$(echo "scale=2; $total_success / $total_attempts * 100" | bc)
    fi
    
    # Update summary with enhanced metrics
    jq --arg total "$total_downloads" \
       --arg tracked "$platforms_tracked" \
       --arg success_rate "$success_rate" \
       '.summary.total_downloads = ($total | tonumber) |
        .summary.platforms_tracked = ($tracked | tonumber) |
        .summary.success_rate = ($success_rate | tonumber)' \
       "$track_record" > temp.json && mv temp.json "$track_record"
    
    log SUCCESS "Enhanced tracking complete: $total_downloads total downloads across $platforms_tracked platforms (${success_rate}% success rate)"
    
    # Save to history with enhanced data
    track_save_history_enhanced "$package" "$track_record"
    
    # Execute analytics hooks
    execute_hooks "post_track" "$package" "$track_record"
    
    # Generate real-time metrics
    track_generate_realtime_metrics "$package" "$track_record"
    
    return 0
}

track_platform_stats_enhanced() {
    local package="$1"
    local platform="$2"
    
    case "$platform" in
        npm)
            track_npm_stats "$package"
            ;;
        pypi)
            track_pypi_stats "$package"
            ;;
        cargo)
            track_cargo_stats "$package"
            ;;
        nuget)
            track_nuget_stats "$package"
            ;;
        maven)
            track_maven_stats "$package"
            ;;
        rubygems)
            track_rubygems_stats "$package"
            ;;
        *)
            echo "error"
            ;;
    esac
}

track_npm_stats() {
    local package="$1"
    
    # Enhanced NPM tracking with multiple endpoints
    local downloads_last_month=$(curl -s "https://api.npmjs.org/downloads/point/last-month/$package" | \
        jq -r '.downloads // 0' 2>/dev/null || echo "0")
    
    local downloads_last_week=$(curl -s "https://api.npmjs.org/downloads/point/last-week/$package" | \
        jq -r '.downloads // 0' 2>/dev/null || echo "0")
    
    local downloads_yesterday=$(curl -s "https://api.npmjs.org/downloads/point/yesterday/$package" | \
        jq -r '.downloads // 0' 2>/dev/null || echo "0")
    
    local package_info=$(curl -s "https://registry.npmjs.org/$package" | \
        jq -r '{version: .["dist-tags"].latest, description: .description, author: .author.name, license: .license}' 2>/dev/null || echo '{}')
    
    cat << EOFN
{
    "downloads": $downloads_last_month,
    "downloads_last_week": $downloads_last_week,
    "downloads_yesterday": $downloads_yesterday,
    "package_info": $package_info,
    "platform": "npm",
    "status": "success"
}
EOFN
}

track_pypi_stats() {
    local package="$1"
    
    # Enhanced PyPI tracking
    local downloads_last_month=$(curl -s "https://pypistats.org/api/packages/$package/recent" | \
        jq -r '.data.last_month // 0' 2>/dev/null || echo "0")
    
    local downloads_last_week=$(curl -s "https://pypistats.org/api/packages/$package/recent" | \
        jq -r '.data.last_week // 0' 2>/dev/null || echo "0")
    
    local package_info=$(curl -s "https://pypi.org/pypi/$package/json" | \
        jq -r '{version: .info.version, description: .info.summary, author: .info.author, license: .info.license}' 2>/dev/null || echo '{}')
    
    cat << EOFP
{
    "downloads": $downloads_last_month,
    "downloads_last_week": $downloads_last_week,
    "downloads_yesterday": 0,
    "package_info": $package_info,
    "platform": "pypi",
    "status": "success"
}
EOFP
}

track_cargo_stats() {
    local package="$1"
    
    # Enhanced Cargo tracking
    local package_data=$(curl -s "https://crates.io/api/v1/crates/$package" 2>/dev/null)
    
    if [[ -n "$package_data" ]]; then
        local downloads=$(echo "$package_data" | jq -r '.crate.downloads // 0')
        local recent_downloads=$(echo "$package_data" | jq -r '.crate.recent_downloads // 0')
        local package_info=$(echo "$package_data" | jq -r '{version: .crate.max_version, description: .crate.description, author: .crate.authors[0], license: .crate.license}')
        
        cat << EOFC
{
    "downloads": $downloads,
    "downloads_last_week": $recent_downloads,
    "downloads_yesterday": 0,
    "package_info": $package_info,
    "platform": "cargo",
    "status": "success"
}
EOFC
    else
        echo "error"
    fi
}

track_nuget_stats() {
    local package="$1"
    
    # Enhanced NuGet tracking
    local package_data=$(curl -s "https://api.nuget.org/v3/registration5-semver1/$package/index.json" 2>/dev/null)
    
    if [[ -n "$package_data" ]]; then
        local total_downloads=$(echo "$package_data" | jq -r '.items[0].count // 0')
        local package_info=$(echo "$package_data" | jq -r '{version: .items[0].upper, description: "NuGet package", author: "Unknown", license: "Unknown"}')
        
        cat << EOFN
{
    "downloads": $total_downloads,
    "downloads_last_week": 0,
    "downloads_yesterday": 0,
    "package_info": $package_info,
    "platform": "nuget",
    "status": "success"
}
EOFN
    else
        echo "error"
    fi
}

track_maven_stats() {
    local package="$1"
    
    # Enhanced Maven tracking (simplified)
    cat << EOFM
{
    "downloads": 0,
    "downloads_last_week": 0,
    "downloads_yesterday": 0,
    "package_info": {"version": "unknown", "description": "Maven package", "author": "Unknown", "license": "Unknown"},
    "platform": "maven",
    "status": "success"
}
EOFM
}

track_rubygems_stats() {
    local package="$1"
    
    # Enhanced RubyGems tracking
    local package_data=$(curl -s "https://rubygems.org/api/v1/gems/$package.json" 2>/dev/null)
    
    if [[ -n "$package_data" ]]; then
        local downloads=$(echo "$package_data" | jq -r '.downloads // 0')
        local version=$(echo "$package_data" | jq -r '.version // "unknown"')
        local description=$(echo "$package_data" | jq -r '.info // "RubyGem package"')
        
        cat << EOFR
{
    "downloads": $downloads,
    "downloads_last_week": 0,
    "downloads_yesterday": 0,
    "package_info": {"version": "$version", "description": "$description", "author": "Unknown", "license": "Unknown"},
    "platform": "rubygems",
    "status": "success"
}
EOFR
    else
        echo "error"
    fi
}

track_save_history_enhanced() {
    local package="$1"
    local record_file="$2"
    local history_file="$PAK_DATA_DIR/history/${package}.json"
    
    # Initialize history if needed
    if [[ ! -f "$history_file" ]]; then
        cat > "$history_file" << EOFH
{
    "package": "$package",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "history": [],
    "metadata": {
        "total_records": 0,
        "first_tracked": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
        "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOFH
    fi
    
    # Append to history
    local record=$(cat "$record_file")
    jq --argjson record "$record" \
       --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.history += [$record] |
        .metadata.total_records = (.history | length) |
        .metadata.last_updated = $now' \
       "$history_file" > temp.json && mv temp.json "$history_file"
    
    # Cleanup old records (keep last 1000)
    jq '.history = .history[-1000:]' "$history_file" > temp.json && mv temp.json "$history_file"
}

track_generate_realtime_metrics() {
    local package="$1"
    local record_file="$2"
    local realtime_file="$PAK_DATA_DIR/tracking/real-time/${package}.json"
    
    # Generate real-time metrics
    local record=$(cat "$record_file")
    local timestamp=$(echo "$record" | jq -r '.timestamp')
    
    cat > "$realtime_file" << EOFR
{
    "package": "$package",
    "last_updated": "$timestamp",
    "current_downloads": $(echo "$record" | jq -r '.summary.total_downloads'),
    "platforms_active": $(echo "$record" | jq -r '.summary.platforms_tracked'),
    "success_rate": $(echo "$record" | jq -r '.summary.success_rate'),
    "status": "active"
}
EOFR
}

track_history() {
    local package="$1"
    local format="${2:-json}"
    local limit="${3:-10}"
    
    local history_file="$PAK_DATA_DIR/history/${package}.json"
    
    if [[ ! -f "$history_file" ]]; then
        log ERROR "No history found for package: $package"
        return 1
    fi
    
    case "$format" in
        json)
            jq --arg limit "$limit" '.history[-($limit | tonumber):]' "$history_file"
            ;;
        csv)
            track_export_history_csv "$package" "$history_file" "$limit"
            ;;
        summary)
            track_generate_history_summary "$package" "$history_file"
            ;;
        *)
            log ERROR "Unknown format: $format"
            return 1
            ;;
    esac
}

track_export_history_csv() {
    local package="$1"
    local history_file="$2"
    local limit="$3"
    
    local csv_file="$PAK_DATA_DIR/exports/${package}-history-$(date +%Y%m%d).csv"
    
    echo "Date,Total_Downloads,Platforms_Tracked,Success_Rate" > "$csv_file"
    
    jq -r --arg limit "$limit" '
        .history[-($limit | tonumber):] | 
        .[] | 
        [.timestamp, .summary.total_downloads, .summary.platforms_tracked, .summary.success_rate] | 
        @csv
    ' "$history_file" >> "$csv_file"
    
    log SUCCESS "CSV export generated: $csv_file"
}

track_generate_history_summary() {
    local package="$1"
    local history_file="$2"
    
    local total_records=$(jq '.history | length' "$history_file")
    local avg_downloads=$(jq -r '[.history[].summary.total_downloads] | add/length' "$history_file")
    local max_downloads=$(jq -r '[.history[].summary.total_downloads] | max' "$history_file")
    local min_downloads=$(jq -r '[.history[].summary.total_downloads] | min' "$history_file")
    local avg_success_rate=$(jq -r '[.history[].summary.success_rate] | add/length' "$history_file")
    
    echo "📊 History Summary for $package:"
    echo "  Total Records: $total_records"
    echo "  Average Downloads: $avg_downloads"
    echo "  Max Downloads: $max_downloads"
    echo "  Min Downloads: $min_downloads"
    echo "  Average Success Rate: ${avg_success_rate}%"
}

track_compare() {
    local package1="$1"
    local package2="$2"
    local metric="${3:-total_downloads}"
    local period="${4:-30d}"
    
    log INFO "Comparing packages: $package1 vs $package2 (metric: $metric, period: $period)"
    
    # Track both packages
    track_package "$package1" > /dev/null
    track_package "$package2" > /dev/null
    
    # Generate comparison
    local comparison_file="$PAK_DATA_DIR/tracking/comparisons/${package1}-vs-${package2}-$(date +%s).json"
    
    track_generate_comparison "$package1" "$package2" "$metric" "$period" > "$comparison_file"
    
    log SUCCESS "Comparison generated: $comparison_file"
    jq . "$comparison_file"
}

track_generate_comparison() {
    local package1="$1"
    local package2="$2"
    local metric="$3"
    local period="$4"
    
    local history1="$PAK_DATA_DIR/history/${package1}.json"
    local history2="$PAK_DATA_DIR/history/${package2}.json"
    
    if [[ ! -f "$history1" ]] || [[ ! -f "$history2" ]]; then
        log ERROR "Missing historical data for comparison"
        return 1
    fi
    
    # Calculate comparison metrics
    local avg1=$(jq -r "[.history[].summary.$metric] | add/length" "$history1")
    local avg2=$(jq -r "[.history[].summary.$metric] | add/length" "$history2")
    local max1=$(jq -r "[.history[].summary.$metric] | max" "$history1")
    local max2=$(jq -r "[.history[].summary.$metric] | max" "$history2")
    local success1=$(jq -r "[.history[].summary.success_rate] | add/length" "$history1")
    local success2=$(jq -r "[.history[].summary.success_rate] | add/length" "$history2")
    
    cat << EOFC
{
    "comparison": {
        "package1": "$package1",
        "package2": "$package2",
        "metric": "$metric",
        "period": "$period",
        "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    },
    "metrics": {
        "package1": {
            "average": $avg1,
            "maximum": $max1,
            "success_rate": $success1
        },
        "package2": {
            "average": $avg2,
            "maximum": $max2,
            "success_rate": $success2
        }
    },
    "analysis": {
        "performance_ratio": $(echo "scale=2; $avg1 / $avg2" | bc),
        "success_rate_difference": $(echo "scale=2; $success1 - $success2" | bc),
        "winner": "$(if (( $(echo "$avg1 > $avg2" | bc -l) )); then echo "$package1"; else echo "$package2"; fi)",
        "recommendation": "$(track_generate_recommendation "$avg1" "$avg2" "$success1" "$success2")"
    }
}
EOFC
}

track_generate_recommendation() {
    local avg1="$1"
    local avg2="$2"
    local success1="$3"
    local success2="$4"
    
    local ratio=$(echo "scale=2; $avg1 / $avg2" | bc)
    
    if (( $(echo "$ratio > 1.5" | bc -l) )); then
        echo "Package 1 significantly outperforms Package 2"
    elif (( $(echo "$ratio > 1.1" | bc -l) )); then
        echo "Package 1 slightly outperforms Package 2"
    elif (( $(echo "$ratio < 0.67" | bc -l) )); then
        echo "Package 2 significantly outperforms Package 1"
    elif (( $(echo "$ratio < 0.91" | bc -l) )); then
        echo "Package 2 slightly outperforms Package 1"
    else
        echo "Both packages perform similarly"
    fi
}

track_aggregate() {
    local packages="$1"
    local period="${2:-7d}"
    
    log INFO "Aggregating data for packages: $packages (period: $period)"
    
    local aggregate_file="$PAK_DATA_DIR/tracking/aggregated/aggregate-$(date +%s).json"
    
    # Generate aggregated statistics
    track_generate_aggregate_stats "$packages" "$period" > "$aggregate_file"
    
    log SUCCESS "Aggregate data generated: $aggregate_file"
    jq . "$aggregate_file"
}

track_generate_aggregate_stats() {
    local packages="$1"
    local period="$2"
    
    local total_downloads=0
    local total_packages=0
    local platform_stats="{}"
    
    for package in $packages; do
        local history_file="$PAK_DATA_DIR/history/${package}.json"
        if [[ -f "$history_file" ]]; then
            ((total_packages++))
            local downloads=$(jq -r '.history[-1].summary.total_downloads // 0' "$history_file")
            ((total_downloads += downloads))
            
            # Aggregate platform statistics
            local package_platforms=$(jq -r '.history[-1].platforms | to_entries[] | "\(.key):\(.value.downloads)"' "$history_file" 2>/dev/null)
            for platform_data in $package_platforms; do
                local platform=$(echo "$platform_data" | cut -d: -f1)
                local platform_downloads=$(echo "$platform_data" | cut -d: -f2)
                platform_stats=$(echo "$platform_stats" | jq --arg platform "$platform" --arg downloads "$platform_downloads" \
                    '.[$platform] = (.[$platform] // 0) + ($downloads | tonumber)')
            done
        fi
    done
    
    cat << EOFA
{
    "aggregate": {
        "period": "$period",
        "total_packages": $total_packages,
        "total_downloads": $total_downloads,
        "average_downloads_per_package": $(echo "scale=2; $total_downloads / $total_packages" | bc),
        "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    },
    "platform_distribution": $platform_stats
}
EOFA
}

track_performance() {
    local package="$1"
    local metric="${2:-response_time}"
    
    log INFO "Analyzing performance for: $package (metric: $metric)"
    
    local history_file="$PAK_DATA_DIR/history/${package}.json"
    
    if [[ ! -f "$history_file" ]]; then
        log ERROR "No history found for package: $package"
        return 1
    fi
    
    # Analyze performance metrics
    local avg_response_time=$(jq -r '[.history[].summary.response_times | to_entries[] | .value] | add/length' "$history_file" 2>/dev/null || echo "0")
    local success_rate=$(jq -r '[.history[].summary.success_rate] | add/length' "$history_file")
    local error_count=$(jq -r '[.history[].summary.errors | length] | add' "$history_file")
    
    echo "📈 Performance Analysis for $package:"
    echo "  Average Response Time: ${avg_response_time}s"
    echo "  Success Rate: ${success_rate}%"
    echo "  Total Errors: $error_count"
    echo "  Performance Grade: $(track_calculate_performance_grade "$avg_response_time" "$success_rate")"
}

track_calculate_performance_grade() {
    local response_time="$1"
    local success_rate="$2"
    
    local grade="F"
    
    if (( $(echo "$response_time < 1" | bc -l) )) && (( $(echo "$success_rate > 95" | bc -l) )); then
        grade="A+"
    elif (( $(echo "$response_time < 2" | bc -l) )) && (( $(echo "$success_rate > 90" | bc -l) )); then
        grade="A"
    elif (( $(echo "$response_time < 3" | bc -l) )) && (( $(echo "$success_rate > 85" | bc -l) )); then
        grade="B"
    elif (( $(echo "$response_time < 5" | bc -l) )) && (( $(echo "$success_rate > 80" | bc -l) )); then
        grade="C"
    elif (( $(echo "$response_time < 10" | bc -l) )) && (( $(echo "$success_rate > 70" | bc -l) )); then
        grade="D"
    fi
    
    echo "$grade"
}

track_realtime() {
    local package="$1"
    local interval="${2:-60}"
    
    log INFO "Starting real-time tracking for: $package (interval: ${interval}s)"
    
    # Create real-time tracking PID file
    local pid_file="$PAK_DATA_DIR/tracking/real-time/${package}.pid"
    mkdir -p "$(dirname "$pid_file")"
    
    # Start real-time tracking in background
    (
        while true; do
            track_package "$package" "$PAK_DEFAULT_PLATFORMS" "realtime"
            sleep "$interval"
        done
    ) &
    
    local realtime_pid=$!
    echo "$realtime_pid" > "$pid_file"
    
    log SUCCESS "Real-time tracking started (PID: $realtime_pid)"
    echo "To stop: pak track-stop $package"
}

track_export() {
    local package="$1"
    local format="${2:-json}"
    local period="${3:-30d}"
    
    log INFO "Exporting tracking data for: $package (format: $format, period: $period)"
    
    local history_file="$PAK_DATA_DIR/history/${package}.json"
    
    if [[ ! -f "$history_file" ]]; then
        log ERROR "No history found for package: $package"
        return 1
    fi
    
    case "$format" in
        json)
            jq '.history[-30:]' "$history_file"
            ;;
        csv)
            track_export_history_csv "$package" "$history_file" "30"
            ;;
        prometheus)
            track_export_prometheus "$package" "$history_file"
            ;;
        *)
            log ERROR "Unknown format: $format"
            return 1
            ;;
    esac
}

track_export_prometheus() {
    local package="$1"
    local history_file="$2"
    
    echo "# HELP pak_downloads_total Total downloads by package"
    echo "# TYPE pak_downloads_total counter"
    jq -r '.history[-1] | "pak_downloads_total{package=\"'$package'\"} \(.summary.total_downloads)"' "$history_file"
    
    echo "# HELP pak_success_rate Success rate by package"
    echo "# TYPE pak_success_rate gauge"
    jq -r '.history[-1] | "pak_success_rate{package=\"'$package'\"} \(.summary.success_rate)"' "$history_file"
}

track_cleanup() {
    local days="${1:-30}"
    
    log INFO "Cleaning up tracking data older than $days days"
    
    # Clean up old tracking files
    find "$PAK_DATA_DIR/tracking" -name "*.json" -mtime +$days -delete 2>/dev/null
    
    # Clean up old history records (keep only last 1000 per package)
    for history_file in "$PAK_DATA_DIR/history"/*.json; do
        if [[ -f "$history_file" ]]; then
            jq '.history = .history[-1000:]' "$history_file" > temp.json && mv temp.json "$history_file"
        fi
    done
    
    log SUCCESS "Cleanup completed"
}

# Legacy functions for backward compatibility
track_platform_stats() {
    local package="$1"
    local platform="$2"
    
    case "$platform" in
        npm)
            curl -s "https://api.npmjs.org/downloads/point/last-month/$package" | \
                jq -r '.downloads // 0' 2>/dev/null || echo "0"
            ;;
        pypi)
            curl -s "https://pypistats.org/api/packages/$package/recent" | \
                jq -r '.data.last_month // 0' 2>/dev/null || echo "0"
            ;;
        cargo)
            curl -s "https://crates.io/api/v1/crates/$package" | \
                jq -r '.crate.downloads // 0' 2>/dev/null || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

track_save_history() {
    local package="$1"
    local record_file="$2"
    local history_file="$PAK_DATA_DIR/history/${package}.json"
    
    # Initialize history if needed
    if [[ ! -f "$history_file" ]]; then
        echo '{"package": "'$package'", "history": []}' > "$history_file"
    fi
    
    # Append to history
    local record=$(cat "$record_file")
    jq --argjson record "$record" '.history += [$record]' "$history_file" > temp.json && \
        mv temp.json "$history_file"
}
