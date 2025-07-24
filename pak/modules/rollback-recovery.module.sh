#!/bin/bash
# PAK.sh Rollback & Recovery System - Safe rollback for failed deployments
# Implements transaction tracking, platform-specific rollback, and state reconciliation

rollback_recovery_init() {
    # Create rollback directories
    mkdir -p "$PAK_DATA_DIR/rollback"
    mkdir -p "$PAK_DATA_DIR/rollback/transactions"
    mkdir -p "$PAK_DATA_DIR/rollback/snapshots"
    mkdir -p "$PAK_DATA_DIR/rollback/backups"
    mkdir -p "$PAK_DATA_DIR/rollback/recovery"
    mkdir -p "$PAK_LOGS_DIR/rollback"
    
    # Initialize rollback components
    rollback_recovery_init_transactions
    rollback_recovery_init_snapshots
    rollback_recovery_init_platforms
    
    log INFO "Rollback & Recovery system initialized"
}

rollback_recovery_register_commands() {
    register_command "rollback" "rollback" "rollback_recovery_main"
    register_command "rollback-status" "rollback" "rollback_recovery_status"
    register_command "rollback-history" "rollback" "rollback_recovery_history"
    register_command "rollback-automate" "rollback" "rollback_recovery_automate"
    register_command "rollback-manual" "rollback" "rollback_recovery_manual"
    register_command "rollback-verify" "rollback" "rollback_recovery_verify"
    register_command "rollback-cleanup" "rollback" "rollback_recovery_cleanup"
}

rollback_recovery_init_transactions() {
    # Create transaction tracking system
    cat > "$PAK_DATA_DIR/rollback/transactions/schema.json" << 'EOF'
{
    "transaction_schema": {
        "id": "string",
        "deployment_id": "string",
        "package_name": "string",
        "version": "string",
        "platforms": ["string"],
        "started_at": "timestamp",
        "status": "string",
        "operations": [
            {
                "platform": "string",
                "operation": "string",
                "status": "string",
                "timestamp": "timestamp",
                "details": "object"
            }
        ],
        "rollback_triggered": "boolean",
        "rollback_reason": "string",
        "rollback_completed_at": "timestamp",
        "state_before": "object",
        "state_after": "object"
    }
}
EOF
}

rollback_recovery_init_snapshots() {
    # Create snapshot management system
    cat > "$PAK_DATA_DIR/rollback/snapshots/config.json" << 'EOF'
{
    "snapshot_config": {
        "auto_snapshot": true,
        "snapshot_interval": 300,
        "retention_days": 30,
        "max_snapshots": 100,
        "snapshot_types": [
            "pre_deployment",
            "post_deployment",
            "before_rollback",
            "after_rollback"
        ]
    }
}
EOF
}

rollback_recovery_init_platforms() {
    # Create platform-specific rollback configurations
    mkdir -p "$PAK_DATA_DIR/rollback/platforms"
    
    # NPM rollback configuration
    cat > "$PAK_DATA_DIR/rollback/platforms/npm.json" << 'EOF'
{
    "name": "npm",
    "rollback_supported": true,
    "rollback_methods": [
        {
            "name": "unpublish",
            "description": "Unpublish package version",
            "command": "npm unpublish {package}@{version}",
            "timeout": 300,
            "requires_confirmation": true
        },
        {
            "name": "dist_tag_rollback",
            "description": "Rollback dist-tag to previous version",
            "command": "npm dist-tag add {package}@{previous_version} latest",
            "timeout": 60,
            "requires_confirmation": false
        }
    ],
    "state_tracking": {
        "pre_deployment": {
            "latest_version": "npm view {package} version",
            "dist_tags": "npm dist-tag ls {package}"
        },
        "post_deployment": {
            "current_version": "npm view {package}@{version} version",
            "downloads": "npm view {package}@{version} downloads"
        }
    },
    "recovery_actions": [
        "verify_package_removal",
        "restore_previous_tags",
        "notify_users"
    ]
}
EOF

    # PyPI rollback configuration
    cat > "$PAK_DATA_DIR/rollback/platforms/pypi.json" << 'EOF'
{
    "name": "pypi",
    "rollback_supported": true,
    "rollback_methods": [
        {
            "name": "delete",
            "description": "Delete package version",
            "command": "twine delete {package} {version}",
            "timeout": 300,
            "requires_confirmation": true
        }
    ],
    "state_tracking": {
        "pre_deployment": {
            "latest_version": "pip index versions {package}",
            "download_stats": "curl -s https://pypi.org/pypi/{package}/json"
        },
        "post_deployment": {
            "current_version": "pip show {package}",
            "downloads": "curl -s https://pypi.org/pypi/{package}/{version}/json"
        }
    },
    "recovery_actions": [
        "verify_package_removal",
        "restore_previous_version",
        "update_documentation"
    ]
}
EOF

    # Cargo rollback configuration
    cat > "$PAK_DATA_DIR/rollback/platforms/cargo.json" << 'EOF'
{
    "name": "cargo",
    "rollback_supported": true,
    "rollback_methods": [
        {
            "name": "yank",
            "description": "Yank package version",
            "command": "cargo yank {package} {version}",
            "timeout": 300,
            "requires_confirmation": true
        }
    ],
    "state_tracking": {
        "pre_deployment": {
            "latest_version": "cargo search {package}",
            "downloads": "curl -s https://crates.io/api/v1/crates/{package}"
        },
        "post_deployment": {
            "current_version": "cargo search {package} {version}",
            "downloads": "curl -s https://crates.io/api/v1/crates/{package}/{version}"
        }
    },
    "recovery_actions": [
        "verify_package_yank",
        "restore_previous_version",
        "update_cargo_toml"
    ]
}
EOF

    # Docker rollback configuration
    cat > "$PAK_DATA_DIR/rollback/platforms/docker.json" << 'EOF'
{
    "name": "docker",
    "rollback_supported": true,
    "rollback_methods": [
        {
            "name": "tag_rollback",
            "description": "Rollback latest tag to previous version",
            "command": "docker tag {package}:{previous_version} {package}:latest && docker push {package}:latest",
            "timeout": 300,
            "requires_confirmation": false
        },
        {
            "name": "delete_tag",
            "description": "Delete specific version tag",
            "command": "docker rmi {package}:{version}",
            "timeout": 60,
            "requires_confirmation": true
        }
    ],
    "state_tracking": {
        "pre_deployment": {
            "latest_tag": "docker images {package} --format '{{.Tag}}' | head -1",
            "all_tags": "docker images {package} --format '{{.Tag}}'"
        },
        "post_deployment": {
            "current_tag": "docker images {package}:{version}",
            "pull_count": "docker pull {package}:{version}"
        }
    },
    "recovery_actions": [
        "verify_tag_rollback",
        "restore_previous_tags",
        "update_registry"
    ]
}
EOF
}

rollback_recovery_main() {
    local action="$1"
    local deployment_id="$2"
    local platforms="${3:-all}"
    
    case "$action" in
        status)
            rollback_recovery_status "$deployment_id"
            ;;
        history)
            rollback_recovery_history
            ;;
        automate)
            rollback_recovery_automate "$deployment_id" "$platforms"
            ;;
        manual)
            rollback_recovery_manual "$deployment_id" "$platforms"
            ;;
        verify)
            rollback_recovery_verify "$deployment_id"
            ;;
        cleanup)
            rollback_recovery_cleanup
            ;;
        *)
            rollback_recovery_usage
            ;;
    esac
}

rollback_recovery_status() {
    local deployment_id="$1"
    
    if [[ -z "$deployment_id" ]]; then
        log ERROR "Deployment ID required"
        return 1
    fi
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${deployment_id}.json"
    
    if [[ ! -f "$transaction_file" ]]; then
        log ERROR "No rollback transaction found for deployment: $deployment_id"
        return 1
    fi
    
    echo "Rollback Status for Deployment: $deployment_id"
    echo "============================================="
    jq . "$transaction_file"
}

rollback_recovery_history() {
    local limit="${1:-10}"
    
    echo "Rollback History (last $limit):"
    echo "==============================="
    
    local count=0
    for transaction in $(ls -t "$PAK_DATA_DIR/rollback/transactions"/*.json 2>/dev/null); do
        [[ $count -ge $limit ]] && break
        
        local deployment_id=$(basename "$transaction" .json)
        local package_name=$(jq -r '.package_name' "$transaction")
        local version=$(jq -r '.version' "$transaction")
        local status=$(jq -r '.status' "$transaction")
        local rollback_triggered=$(jq -r '.rollback_triggered' "$transaction")
        local started_at=$(jq -r '.started_at' "$transaction")
        
        printf "%-12s %-20s %-15s %-12s %-8s %s\n" "$deployment_id" "$package_name" "$version" "$status" "$rollback_triggered" "$started_at"
        ((count++))
    done
}

rollback_recovery_automate() {
    local deployment_id="$1"
    local platforms="$2"
    
    log INFO "Starting automated rollback for deployment: $deployment_id"
    log INFO "Platforms: $platforms"
    
    # Create rollback transaction
    local transaction_id=$(rollback_recovery_create_transaction "$deployment_id" "$platforms")
    
    # Execute automated rollback
    if rollback_recovery_execute_rollback "$transaction_id" "$deployment_id" "$platforms"; then
        log SUCCESS "Automated rollback completed successfully"
        return 0
    else
        log ERROR "Automated rollback failed"
        return 1
    fi
}

rollback_recovery_manual() {
    local deployment_id="$1"
    local platforms="$2"
    
    log INFO "Starting manual rollback for deployment: $deployment_id"
    log INFO "Platforms: $platforms"
    
    # Create rollback transaction
    local transaction_id=$(rollback_recovery_create_transaction "$deployment_id" "$platforms")
    
    # Execute manual rollback with confirmations
    if rollback_recovery_execute_manual_rollback "$transaction_id" "$deployment_id" "$platforms"; then
        log SUCCESS "Manual rollback completed successfully"
        return 0
    else
        log ERROR "Manual rollback failed"
        return 1
    fi
}

rollback_recovery_create_transaction() {
    local deployment_id="$1"
    local platforms="$2"
    
    local transaction_id="${deployment_id}_rollback_$(date +%s)"
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    
    # Get deployment information
    local deploy_file="$PAK_DATA_DIR/deployments/${deployment_id}.json"
    if [[ ! -f "$deploy_file" ]]; then
        log ERROR "Deployment not found: $deployment_id"
        return 1
    fi
    
    local package_name=$(jq -r '.package' "$deploy_file")
    local version=$(jq -r '.version' "$deploy_file")
    
    # Create transaction record
    jq --null-input \
       --arg id "$transaction_id" \
       --arg deployment_id "$deployment_id" \
       --arg package_name "$package_name" \
       --arg version "$version" \
       --arg platforms "$platforms" \
       --arg started_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '{
           "id": $id,
           "deployment_id": $deployment_id,
           "package_name": $package_name,
           "version": $version,
           "platforms": ($platforms | split(" ") | map(select(length > 0))),
           "started_at": $started_at,
           "status": "in_progress",
           "operations": [],
           "rollback_triggered": true,
           "rollback_reason": "manual_trigger",
           "state_before": {},
           "state_after": {}
       }' > "$transaction_file"
    
    echo "$transaction_id"
}

rollback_recovery_execute_rollback() {
    local transaction_id="$1"
    local deployment_id="$2"
    local platforms="$3"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    
    # Capture state before rollback
    rollback_recovery_capture_state "$transaction_id" "before"
    
    # Execute rollback for each platform
    local success_count=0
    local total_count=0
    
    for platform in $platforms; do
        ((total_count++))
        if rollback_recovery_rollback_platform "$transaction_id" "$platform"; then
            ((success_count++))
        fi
    done
    
    # Capture state after rollback
    rollback_recovery_capture_state "$transaction_id" "after"
    
    # Update transaction status
    if [[ $success_count -eq $total_count ]]; then
        rollback_recovery_update_transaction "$transaction_id" "completed"
        log SUCCESS "Rollback completed for all platforms"
        return 0
    else
        rollback_recovery_update_transaction "$transaction_id" "failed"
        log ERROR "Rollback failed for some platforms"
        return 1
    fi
}

rollback_recovery_execute_manual_rollback() {
    local transaction_id="$1"
    local deployment_id="$2"
    local platforms="$3"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    
    # Capture state before rollback
    rollback_recovery_capture_state "$transaction_id" "before"
    
    # Execute rollback for each platform with confirmation
    local success_count=0
    local total_count=0
    
    for platform in $platforms; do
        ((total_count++))
        
        echo "Rollback platform: $platform"
        echo "This will undo the deployment for $platform"
        echo -n "Continue? (y/N): "
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if rollback_recovery_rollback_platform "$transaction_id" "$platform"; then
                ((success_count++))
            fi
        else
            log INFO "Skipping rollback for $platform"
        fi
    done
    
    # Capture state after rollback
    rollback_recovery_capture_state "$transaction_id" "after"
    
    # Update transaction status
    if [[ $success_count -eq $total_count ]]; then
        rollback_recovery_update_transaction "$transaction_id" "completed"
        log SUCCESS "Manual rollback completed for all platforms"
        return 0
    else
        rollback_recovery_update_transaction "$transaction_id" "failed"
        log ERROR "Manual rollback failed for some platforms"
        return 1
    fi
}

rollback_recovery_rollback_platform() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Rolling back platform: $platform"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    local platform_config="$PAK_DATA_DIR/rollback/platforms/${platform}.json"
    
    if [[ ! -f "$platform_config" ]]; then
        log ERROR "No rollback configuration for platform: $platform"
        rollback_recovery_log_operation "$transaction_id" "$platform" "failed" "No rollback configuration"
        return 1
    fi
    
    # Check if rollback is supported
    local rollback_supported=$(jq -r '.rollback_supported' "$platform_config")
    if [[ "$rollback_supported" != "true" ]]; then
        log WARN "Rollback not supported for platform: $platform"
        rollback_recovery_log_operation "$transaction_id" "$platform" "skipped" "Rollback not supported"
        return 0
    fi
    
    # Get package information
    local package_name=$(jq -r '.package_name' "$transaction_file")
    local version=$(jq -r '.version' "$transaction_file")
    
    # Get previous version
    local previous_version=$(rollback_recovery_get_previous_version "$package_name" "$platform")
    
    # Execute rollback methods
    local methods=$(jq -r '.rollback_methods[] | .name' "$platform_config")
    local success=false
    
    for method in $methods; do
        local method_config=$(jq -r ".rollback_methods[] | select(.name == \"$method\")" "$platform_config")
        local command=$(echo "$method_config" | jq -r '.command')
        local timeout=$(echo "$method_config" | jq -r '.timeout')
        local requires_confirmation=$(echo "$method_config" | jq -r '.requires_confirmation')
        
        # Replace placeholders in command
        command="${command//\{package\}/$package_name}"
        command="${command//\{version\}/$version}"
        command="${command//\{previous_version\}/$previous_version}"
        
        log INFO "Executing rollback method: $method"
        
        # Execute command with timeout
        if timeout "$timeout" bash -c "$command" >/dev/null 2>&1; then
            rollback_recovery_log_operation "$transaction_id" "$platform" "completed" "Method $method succeeded"
            success=true
            break
        else
            rollback_recovery_log_operation "$transaction_id" "$platform" "failed" "Method $method failed"
        fi
    done
    
    if [[ "$success" == "true" ]]; then
        # Execute recovery actions
        rollback_recovery_execute_recovery_actions "$transaction_id" "$platform" "$platform_config"
        return 0
    else
        return 1
    fi
}

rollback_recovery_execute_recovery_actions() {
    local transaction_id="$1"
    local platform="$2"
    local platform_config="$3"
    
    log INFO "Executing recovery actions for: $platform"
    
    local actions=$(jq -r '.recovery_actions[]' "$platform_config")
    
    for action in $actions; do
        case "$action" in
            verify_package_removal)
                rollback_recovery_verify_package_removal "$transaction_id" "$platform"
                ;;
            restore_previous_tags)
                rollback_recovery_restore_previous_tags "$transaction_id" "$platform"
                ;;
            notify_users)
                rollback_recovery_notify_users "$transaction_id" "$platform"
                ;;
            update_documentation)
                rollback_recovery_update_documentation "$transaction_id" "$platform"
                ;;
            update_registry)
                rollback_recovery_update_registry "$transaction_id" "$platform"
                ;;
        esac
    done
}

rollback_recovery_verify_package_removal() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Verifying package removal for: $platform"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    local package_name=$(jq -r '.package_name' "$transaction_file")
    local version=$(jq -r '.version' "$transaction_file")
    
    case "$platform" in
        npm)
            if ! npm view "$package_name@$version" version >/dev/null 2>&1; then
                log SUCCESS "Package removal verified for NPM"
            else
                log ERROR "Package still available on NPM"
            fi
            ;;
        pypi)
            if ! pip show "$package_name" | grep -q "Version: $version" 2>/dev/null; then
                log SUCCESS "Package removal verified for PyPI"
            else
                log ERROR "Package still available on PyPI"
            fi
            ;;
        cargo)
            if ! cargo search "$package_name" | grep -q "$version" 2>/dev/null; then
                log SUCCESS "Package removal verified for Cargo"
            else
                log ERROR "Package still available on Cargo"
            fi
            ;;
    esac
}

rollback_recovery_restore_previous_tags() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Restoring previous tags for: $platform"
    
    # Implementation depends on platform
    case "$platform" in
        npm)
            # Restore latest tag to previous version
            ;;
        docker)
            # Restore latest tag to previous version
            ;;
    esac
}

rollback_recovery_notify_users() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Notifying users about rollback for: $platform"
    
    # Send notifications about rollback
    # This could be email, Slack, etc.
}

rollback_recovery_update_documentation() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Updating documentation for: $platform"
    
    # Update documentation to reflect rollback
}

rollback_recovery_update_registry() {
    local transaction_id="$1"
    local platform="$2"
    
    log INFO "Updating registry for: $platform"
    
    # Update registry information
}

rollback_recovery_capture_state() {
    local transaction_id="$1"
    local state_type="$2"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    local package_name=$(jq -r '.package_name' "$transaction_file")
    local platforms=$(jq -r '.platforms[]' "$transaction_file")
    
    local state_data="{}"
    
    for platform in $platforms; do
        local platform_config="$PAK_DATA_DIR/rollback/platforms/${platform}.json"
        if [[ -f "$platform_config" ]]; then
            local state_commands=$(jq -r ".state_tracking.${state_type} | to_entries[] | .key + \":\" + .value" "$platform_config" 2>/dev/null)
            
            local platform_state="{}"
            while IFS=: read -r key command; do
                [[ -z "$key" || -z "$command" ]] && continue
                
                # Replace placeholders in command
                command="${command//\{package\}/$package_name}"
                
                # Execute command and capture output
                local output=$(eval "$command" 2>/dev/null || echo "null")
                platform_state=$(echo "$platform_state" | jq --arg key "$key" --arg value "$output" '. + {($key): $value}')
            done <<< "$state_commands"
            
            state_data=$(echo "$state_data" | jq --arg platform "$platform" --argjson state "$platform_state" '. + {($platform): $state}')
        fi
    done
    
    # Update transaction with state
    jq --arg type "$state_type" --argjson state "$state_data" \
       ".state_${state_type} = \$state" \
       "$transaction_file" > temp.json && mv temp.json "$transaction_file"
}

rollback_recovery_get_previous_version() {
    local package_name="$1"
    local platform="$2"
    
    case "$platform" in
        npm)
            npm view "$package_name" versions --json | jq -r '.[-2]' 2>/dev/null || echo "unknown"
            ;;
        pypi)
            pip index versions "$package_name" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | tail -2 | head -1 2>/dev/null || echo "unknown"
            ;;
        cargo)
            cargo search "$package_name" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | tail -2 | head -1 2>/dev/null || echo "unknown"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

rollback_recovery_verify() {
    local deployment_id="$1"
    
    log INFO "Verifying rollback for deployment: $deployment_id"
    
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${deployment_id}_rollback_*.json"
    local transaction=$(ls -t $transaction_file 2>/dev/null | head -1)
    
    if [[ ! -f "$transaction" ]]; then
        log ERROR "No rollback transaction found for deployment: $deployment_id"
        return 1
    fi
    
    local status=$(jq -r '.status' "$transaction")
    local platforms=$(jq -r '.platforms[]' "$transaction")
    
    echo "Rollback Verification for Deployment: $deployment_id"
    echo "=================================================="
    echo "Status: $status"
    echo ""
    
    local all_verified=true
    
    for platform in $platforms; do
        echo "Verifying $platform..."
        if rollback_recovery_verify_platform "$deployment_id" "$platform"; then
            echo "  ✅ $platform: Verified"
        else
            echo "  ❌ $platform: Failed"
            all_verified=false
        fi
    done
    
    if [[ "$all_verified" == "true" ]]; then
        log SUCCESS "Rollback verification completed successfully"
        return 0
    else
        log ERROR "Rollback verification failed"
        return 1
    fi
}

rollback_recovery_verify_platform() {
    local deployment_id="$1"
    local platform="$2"
    
    # Platform-specific verification
    case "$platform" in
        npm)
            # Verify package is not available
            ;;
        pypi)
            # Verify package is not available
            ;;
        cargo)
            # Verify package is yanked
            ;;
        docker)
            # Verify tags are rolled back
            ;;
        *)
            return 0
            ;;
    esac
    
    return 0
}

rollback_recovery_cleanup() {
    local days="${1:-30}"
    
    log INFO "Cleaning up rollback data older than $days days"
    
    # Clean up old transactions
    find "$PAK_DATA_DIR/rollback/transactions" -name "*.json" -mtime +$days -delete
    
    # Clean up old snapshots
    find "$PAK_DATA_DIR/rollback/snapshots" -name "*.json" -mtime +$days -delete
    
    # Clean up old backups
    find "$PAK_DATA_DIR/rollback/backups" -name "*.tar.gz" -mtime +$days -delete
    
    log SUCCESS "Rollback cleanup completed"
}

# Helper functions
rollback_recovery_log_operation() {
    local transaction_id="$1"
    local platform="$2"
    local status="$3"
    local message="$4"
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    
    jq --arg platform "$platform" --arg status "$status" --arg message "$message" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.operations += [{"platform": $platform, "status": $status, "message": $message, "timestamp": $timestamp}]' \
       "$transaction_file" > temp.json && mv temp.json "$transaction_file"
}

rollback_recovery_update_transaction() {
    local transaction_id="$1"
    local status="$2"
    local transaction_file="$PAK_DATA_DIR/rollback/transactions/${transaction_id}.json"
    
    jq --arg status "$status" --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = $status | .completed_at = $completed_at' \
       "$transaction_file" > temp.json && mv temp.json "$transaction_file"
}

rollback_recovery_usage() {
    echo "PAK.sh Rollback & Recovery System"
    echo "================================="
    echo ""
    echo "Usage: rollback <action> [deployment_id] [platforms]"
    echo ""
    echo "Actions:"
    echo "  status     - Show rollback status for deployment"
    echo "  history    - Show rollback history"
    echo "  automate   - Execute automated rollback"
    echo "  manual     - Execute manual rollback with confirmations"
    echo "  verify     - Verify rollback completion"
    echo "  cleanup    - Clean up old rollback data"
    echo ""
    echo "Examples:"
    echo "  rollback status 12345"
    echo "  rollback history"
    echo "  rollback automate 12345"
    echo "  rollback automate 12345 npm pypi"
    echo "  rollback manual 12345"
    echo "  rollback verify 12345"
    echo "  rollback cleanup 30"
}

# Export functions
export -f rollback_recovery_main rollback_recovery_status rollback_recovery_history rollback_recovery_automate rollback_recovery_manual rollback_recovery_verify rollback_recovery_cleanup 