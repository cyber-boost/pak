#!/bin/bash
# Package Configuration Script for PAK.sh
# Manages per-package configuration for deployment settings

# Configuration
CONFIG_VERSION="1.0.0"
CONFIG_CACHE_DIR="$PAK_DATA_DIR/config/cache"
CONFIG_DATA_DIR="$PAK_DATA_DIR/config/data"
CONFIG_TEMP_DIR="$PAK_DATA_DIR/config/temp"

# Default configuration template
DEFAULT_CONFIG_TEMPLATE='{
    "package": {
        "name": "",
        "platform": "",
        "version": "1.0.0",
        "description": "",
        "author": "",
        "license": "MIT"
    },
    "deployment": {
        "environments": {
            "dev": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true
            },
            "staging": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true
            },
            "prod": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true
            }
        },
        "platforms": {
            "npm": {
                "registry": "https://registry.npmjs.org",
                "access": "public",
                "tag": "latest"
            },
            "pypi": {
                "repository": "https://pypi.org/pypi",
                "username": "",
                "password": ""
            },
            "crates": {
                "registry": "https://crates.io",
                "token": ""
            },
            "maven": {
                "repository": "https://oss.sonatype.org/service/local/staging/deploy/maven2/",
                "groupId": "",
                "artifactId": ""
            },
            "nuget": {
                "source": "https://api.nuget.org/v3/index.json",
                "apiKey": ""
            }
        }
    },
    "monitoring": {
        "enabled": true,
        "health_checks": {
            "enabled": true,
            "interval": 300,
            "timeout": 30,
            "retries": 3
        },
        "performance_tracking": {
            "enabled": true,
            "metrics": ["downloads", "version_updates", "dependencies"]
        },
        "alerts": {
            "enabled": true,
            "channels": ["email", "slack"],
            "thresholds": {
                "download_drop": 50,
                "error_rate": 5,
                "response_time": 1000
            }
        }
    },
    "notifications": {
        "email": {
            "enabled": false,
            "recipients": [],
            "template": "default"
        },
        "slack": {
            "enabled": false,
            "webhook_url": "",
            "channel": "#deployments"
        },
        "discord": {
            "enabled": false,
            "webhook_url": "",
            "channel": "deployments"
        }
    },
    "security": {
        "vulnerability_scanning": {
            "enabled": true,
            "auto_fix": false,
            "block_on_critical": true
        },
        "dependency_audit": {
            "enabled": true,
            "auto_update": false,
            "schedule": "weekly"
        },
        "secrets_scanning": {
            "enabled": true,
            "patterns": ["api_key", "password", "token", "secret"]
        }
    },
    "automation": {
        "auto_version": {
            "enabled": false,
            "strategy": "semver",
            "bump_on": ["commit", "tag", "manual"]
        },
        "auto_deploy": {
            "enabled": false,
            "triggers": ["tag", "branch", "manual"],
            "environments": ["dev", "staging"]
        },
        "auto_test": {
            "enabled": true,
            "frameworks": ["jest", "pytest", "cargo", "maven"],
            "coverage_threshold": 80
        }
    },
    "documentation": {
        "auto_generate": {
            "enabled": true,
            "formats": ["markdown", "html", "pdf"],
            "include_examples": true
        },
        "readme_template": "default",
        "changelog": {
            "enabled": true,
            "format": "keepachangelog",
            "auto_update": true
        }
    },
    "integration": {
        "ci_cd": {
            "github_actions": {
                "enabled": false,
                "workflow_template": "default"
            },
            "gitlab_ci": {
                "enabled": false,
                "pipeline_template": "default"
            },
            "jenkins": {
                "enabled": false,
                "job_template": "default"
            }
        },
        "issue_tracking": {
            "github": {
                "enabled": false,
                "repository": "",
                "labels": ["pak", "deployment"]
            },
            "jira": {
                "enabled": false,
                "project_key": "",
                "issue_type": "Task"
            }
        }
    }
}'

# Initialize configuration system
init_config() {
    mkdir -p "$CONFIG_CACHE_DIR"
    mkdir -p "$CONFIG_DATA_DIR"
    mkdir -p "$CONFIG_TEMP_DIR"
    
    log INFO "Package configuration system initialized"
}

# Create package configuration
create_package_config() {
    local package_name="$1"
    local platform="$2"
    local directory="${3:-.}"
    local template="${4:-default}"
    
    log INFO "Creating package configuration for: $package_name ($platform) in $directory"
    
    # Determine config file path
    local config_file="$directory/.pakrc"
    
    if [[ -f "$config_file" ]]; then
        log WARN "Configuration file already exists: $config_file"
        if [[ "$PAK_DRY_RUN" != "true" ]]; then
            read -p "Overwrite existing configuration? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log INFO "Configuration creation cancelled"
                return 0
            fi
        fi
    fi
    
    # Generate configuration from template
    local config_content=$(generate_config_from_template "$package_name" "$platform" "$template")
    
    # Validate configuration
    if ! validate_config "$config_content"; then
        log ERROR "Generated configuration is invalid"
        return 1
    fi
    
    # Write configuration file
    if [[ "$PAK_DRY_RUN" != "true" ]]; then
        echo "$config_content" > "$config_file"
        log SUCCESS "Package configuration created: $config_file"
    else
        log INFO "DRY RUN: Would create configuration file: $config_file"
        echo "$config_content"
    fi
    
    return 0
}

# Generate configuration from template
generate_config_from_template() {
    local package_name="$1"
    local platform="$2"
    local template="$3"
    
    case "$template" in
        default)
            echo "$DEFAULT_CONFIG_TEMPLATE" | jq --arg name "$package_name" --arg platform "$platform" '.package.name = $name | .package.platform = $platform'
            ;;
        minimal)
            generate_minimal_config "$package_name" "$platform"
            ;;
        enterprise)
            generate_enterprise_config "$package_name" "$platform"
            ;;
        custom)
            generate_custom_config "$package_name" "$platform"
            ;;
        *)
            log WARN "Unknown template: $template. Using default."
            echo "$DEFAULT_CONFIG_TEMPLATE" | jq --arg name "$package_name" --arg platform "$platform" '.package.name = $name | .package.platform = $platform'
            ;;
    esac
}

# Generate minimal configuration
generate_minimal_config() {
    local package_name="$1"
    local platform="$2"
    
    cat <<EOF
{
    "package": {
        "name": "$package_name",
        "platform": "$platform",
        "version": "1.0.0"
    },
    "deployment": {
        "environments": {
            "dev": {
                "enabled": true,
                "auto_deploy": false
            },
            "prod": {
                "enabled": true,
                "auto_deploy": false
            }
        }
    },
    "monitoring": {
        "enabled": true
    }
}
EOF
}

# Generate enterprise configuration
generate_enterprise_config() {
    local package_name="$1"
    local platform="$2"
    
    cat <<EOF
{
    "package": {
        "name": "$package_name",
        "platform": "$platform",
        "version": "1.0.0",
        "description": "",
        "author": "",
        "license": "MIT"
    },
    "deployment": {
        "environments": {
            "dev": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true,
                "approval_required": false
            },
            "staging": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true,
                "approval_required": true
            },
            "prod": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": true,
                "health_checks": true,
                "rollback_enabled": true,
                "approval_required": true
            }
        },
        "platforms": {
            "$platform": {
                "registry": "",
                "access": "restricted",
                "tag": "latest"
            }
        }
    },
    "monitoring": {
        "enabled": true,
        "health_checks": {
            "enabled": true,
            "interval": 300,
            "timeout": 30,
            "retries": 3
        },
        "performance_tracking": {
            "enabled": true,
            "metrics": ["downloads", "version_updates", "dependencies", "security_scan"]
        },
        "alerts": {
            "enabled": true,
            "channels": ["email", "slack", "pagerduty"],
            "thresholds": {
                "download_drop": 50,
                "error_rate": 5,
                "response_time": 1000,
                "security_vulnerabilities": 0
            }
        }
    },
    "notifications": {
        "email": {
            "enabled": true,
            "recipients": ["devops@company.com", "security@company.com"],
            "template": "enterprise"
        },
        "slack": {
            "enabled": true,
            "webhook_url": "",
            "channel": "#deployments"
        },
        "pagerduty": {
            "enabled": true,
            "service_key": "",
            "urgency": "high"
        }
    },
    "security": {
        "vulnerability_scanning": {
            "enabled": true,
            "auto_fix": false,
            "block_on_critical": true,
            "block_on_high": true
        },
        "dependency_audit": {
            "enabled": true,
            "auto_update": false,
            "schedule": "daily",
            "block_on_vulnerabilities": true
        },
        "secrets_scanning": {
            "enabled": true,
            "patterns": ["api_key", "password", "token", "secret", "private_key"],
            "block_on_secrets": true
        },
        "compliance": {
            "enabled": true,
            "standards": ["SOC2", "ISO27001", "GDPR"],
            "auto_report": true
        }
    },
    "automation": {
        "auto_version": {
            "enabled": true,
            "strategy": "semver",
            "bump_on": ["commit", "tag", "manual"],
            "changelog_generation": true
        },
        "auto_deploy": {
            "enabled": true,
            "triggers": ["tag", "branch", "manual"],
            "environments": ["dev"],
            "approval_workflow": true
        },
        "auto_test": {
            "enabled": true,
            "frameworks": ["jest", "pytest", "cargo", "maven", "sonarqube"],
            "coverage_threshold": 90,
            "quality_gate": true
        }
    },
    "documentation": {
        "auto_generate": {
            "enabled": true,
            "formats": ["markdown", "html", "pdf", "confluence"],
            "include_examples": true,
            "include_api_docs": true
        },
        "readme_template": "enterprise",
        "changelog": {
            "enabled": true,
            "format": "keepachangelog",
            "auto_update": true,
            "include_breaking_changes": true
        }
    },
    "integration": {
        "ci_cd": {
            "github_actions": {
                "enabled": true,
                "workflow_template": "enterprise",
                "secrets_management": true
            },
            "gitlab_ci": {
                "enabled": false,
                "pipeline_template": "enterprise"
            },
            "jenkins": {
                "enabled": false,
                "job_template": "enterprise"
            }
        },
        "issue_tracking": {
            "github": {
                "enabled": true,
                "repository": "",
                "labels": ["pak", "deployment", "security", "compliance"]
            },
            "jira": {
                "enabled": true,
                "project_key": "",
                "issue_type": "Task",
                "auto_create_issues": true
            }
        },
        "monitoring": {
            "datadog": {
                "enabled": true,
                "api_key": "",
                "app_key": ""
            },
            "newrelic": {
                "enabled": false,
                "license_key": "",
                "app_name": ""
            },
            "splunk": {
                "enabled": false,
                "hec_url": "",
                "hec_token": ""
            }
        }
    }
}
EOF
}

# Generate custom configuration
generate_custom_config() {
    local package_name="$1"
    local platform="$2"
    
    # Interactive configuration generation
    log INFO "Generating custom configuration for: $package_name ($platform)"
    
    # Get user input
    read -p "Package description: " description
    read -p "Author: " author
    read -p "License (MIT): " license
    license=${license:-MIT}
    
    read -p "Enable auto-deploy to dev? (y/N): " -n 1 -r auto_deploy_dev
    echo
    auto_deploy_dev=${auto_deploy_dev:-false}
    
    read -p "Enable notifications? (Y/n): " -n 1 -r notifications
    echo
    notifications=${notifications:-true}
    
    read -p "Enable security scanning? (Y/n): " -n 1 -r security_scanning
    echo
    security_scanning=${security_scanning:-true}
    
    # Generate configuration
    cat <<EOF
{
    "package": {
        "name": "$package_name",
        "platform": "$platform",
        "version": "1.0.0",
        "description": "$description",
        "author": "$author",
        "license": "$license"
    },
    "deployment": {
        "environments": {
            "dev": {
                "enabled": true,
                "auto_deploy": $auto_deploy_dev,
                "notifications": $notifications,
                "health_checks": true,
                "rollback_enabled": true
            },
            "staging": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": $notifications,
                "health_checks": true,
                "rollback_enabled": true
            },
            "prod": {
                "enabled": true,
                "auto_deploy": false,
                "notifications": $notifications,
                "health_checks": true,
                "rollback_enabled": true
            }
        }
    },
    "monitoring": {
        "enabled": true,
        "health_checks": {
            "enabled": true,
            "interval": 300,
            "timeout": 30,
            "retries": 3
        },
        "performance_tracking": {
            "enabled": true,
            "metrics": ["downloads", "version_updates", "dependencies"]
        },
        "alerts": {
            "enabled": $notifications,
            "channels": ["email"],
            "thresholds": {
                "download_drop": 50,
                "error_rate": 5,
                "response_time": 1000
            }
        }
    },
    "security": {
        "vulnerability_scanning": {
            "enabled": $security_scanning,
            "auto_fix": false,
            "block_on_critical": true
        },
        "dependency_audit": {
            "enabled": $security_scanning,
            "auto_update": false,
            "schedule": "weekly"
        },
        "secrets_scanning": {
            "enabled": $security_scanning,
            "patterns": ["api_key", "password", "token", "secret"]
        }
    },
    "automation": {
        "auto_version": {
            "enabled": true,
            "strategy": "semver",
            "bump_on": ["commit", "tag", "manual"]
        },
        "auto_deploy": {
            "enabled": false,
            "triggers": ["tag", "branch", "manual"],
            "environments": ["dev"]
        },
        "auto_test": {
            "enabled": true,
            "frameworks": ["jest", "pytest", "cargo", "maven"],
            "coverage_threshold": 80
        }
    }
}
EOF
}

# Validate configuration
validate_config() {
    local config_content="$1"
    
    # Check if it's valid JSON
    if ! echo "$config_content" | jq . >/dev/null 2>&1; then
        log ERROR "Configuration is not valid JSON"
        return 1
    fi
    
    # Check required fields
    local package_name=$(echo "$config_content" | jq -r '.package.name // empty')
    local platform=$(echo "$config_content" | jq -r '.package.platform // empty')
    
    if [[ -z "$package_name" ]]; then
        log ERROR "Package name is required"
        return 1
    fi
    
    if [[ -z "$platform" ]]; then
        log ERROR "Platform is required"
        return 1
    fi
    
    # Validate environment configurations
    local environments=$(echo "$config_content" | jq -r '.deployment.environments // {}')
    if [[ "$environments" == "{}" ]]; then
        log WARN "No deployment environments configured"
    fi
    
    # Validate platform-specific configurations
    local platforms=$(echo "$config_content" | jq -r '.deployment.platforms // {}')
    if [[ "$platforms" == "{}" ]]; then
        log WARN "No platform-specific configurations found"
    fi
    
    log INFO "Configuration validation passed"
    return 0
}

# Load package configuration
load_package_config() {
    local directory="${1:-.}"
    local config_file="$directory/.pakrc"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Configuration file not found: $config_file"
        return 1
    fi
    
    # Load and validate configuration
    local config_content=$(cat "$config_file")
    if ! validate_config "$config_content"; then
        log ERROR "Invalid configuration in: $config_file"
        return 1
    fi
    
    echo "$config_content"
}

# Get configuration value
get_config_value() {
    local config_content="$1"
    local path="$2"
    local default="$3"
    
    local value=$(echo "$config_content" | jq -r "$path // empty" 2>/dev/null)
    
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Set configuration value
set_config_value() {
    local config_file="$1"
    local path="$2"
    local value="$3"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Configuration file not found: $config_file"
        return 1
    fi
    
    # Update configuration
    local temp_file=$(mktemp)
    jq --arg path "$path" --arg value "$value" 'setpath($path | split(".") | map(if test("^[0-9]+$") then tonumber else . end); $value)' "$config_file" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$config_file"
        log SUCCESS "Configuration updated: $path = $value"
        return 0
    else
        log ERROR "Failed to update configuration: $path"
        rm -f "$temp_file"
        return 1
    fi
}

# Merge configurations
merge_configs() {
    local base_config="$1"
    local override_config="$2"
    
    # Merge configurations using jq
    echo "$base_config" | jq -s '.[0] * .[1]' <(echo "$base_config") <(echo "$override_config")
}

# Apply environment-specific configuration
apply_environment_config() {
    local config_content="$1"
    local environment="$2"
    
    # Get environment-specific configuration
    local env_config=$(echo "$config_content" | jq -r ".deployment.environments.$environment // {}")
    
    if [[ "$env_config" == "{}" ]]; then
        log WARN "No configuration found for environment: $environment"
        return 1
    fi
    
    # Merge with base configuration
    local merged_config=$(echo "$config_content" | jq --argjson env "$env_config" '.deployment.current_environment = $env')
    
    echo "$merged_config"
}

# Validate deployment configuration
validate_deployment_config() {
    local config_content="$1"
    local environment="$2"
    
    # Check if environment is enabled
    local enabled=$(get_config_value "$config_content" ".deployment.environments.$environment.enabled" "false")
    if [[ "$enabled" != "true" ]]; then
        log ERROR "Environment $environment is not enabled"
        return 1
    fi
    
    # Check platform-specific configuration
    local platform=$(get_config_value "$config_content" ".package.platform" "")
    if [[ -n "$platform" ]]; then
        local platform_config=$(echo "$config_content" | jq -r ".deployment.platforms.$platform // {}")
        if [[ "$platform_config" == "{}" ]]; then
            log WARN "No platform-specific configuration found for: $platform"
        fi
    fi
    
    # Check notification configuration
    local notifications_enabled=$(get_config_value "$config_content" ".deployment.environments.$environment.notifications" "false")
    if [[ "$notifications_enabled" == "true" ]]; then
        local email_enabled=$(get_config_value "$config_content" ".notifications.email.enabled" "false")
        local slack_enabled=$(get_config_value "$config_content" ".notifications.slack.enabled" "false")
        
        if [[ "$email_enabled" != "true" ]] && [[ "$slack_enabled" != "true" ]]; then
            log WARN "Notifications enabled but no notification channels configured"
        fi
    fi
    
    log INFO "Deployment configuration validation passed for environment: $environment"
    return 0
}

# Export configuration
export_config() {
    local config_content="$1"
    local format="${2:-json}"
    local output_file="$3"
    
    case "$format" in
        json)
            if [[ -n "$output_file" ]]; then
                echo "$config_content" > "$output_file"
                log SUCCESS "Configuration exported to: $output_file"
            else
                echo "$config_content"
            fi
            ;;
        yaml)
            local yaml_content=$(echo "$config_content" | jq -r '.' | yq eval -P)
            if [[ -n "$output_file" ]]; then
                echo "$yaml_content" > "$output_file"
                log SUCCESS "Configuration exported to: $output_file"
            else
                echo "$yaml_content"
            fi
            ;;
        env)
            local env_content=$(echo "$config_content" | jq -r 'to_entries[] | "PAK_\(.key | ascii_upcase)=\(.value)"')
            if [[ -n "$output_file" ]]; then
                echo "$env_content" > "$output_file"
                log SUCCESS "Configuration exported to: $output_file"
            else
                echo "$env_content"
            fi
            ;;
        *)
            log ERROR "Unsupported export format: $format"
            return 1
            ;;
    esac
}

# Migrate configuration
migrate_config() {
    local config_file="$1"
    local target_version="$2"
    
    if [[ ! -f "$config_file" ]]; then
        log ERROR "Configuration file not found: $config_file"
        return 1
    fi
    
    local config_content=$(cat "$config_file")
    local current_version=$(get_config_value "$config_content" ".version" "1.0.0")
    
    if [[ "$current_version" == "$target_version" ]]; then
        log INFO "Configuration is already at target version: $target_version"
        return 0
    fi
    
    log INFO "Migrating configuration from $current_version to $target_version"
    
    # Perform migration based on version
    case "$current_version" in
        1.0.0)
            if [[ "$target_version" == "1.1.0" ]]; then
                config_content=$(migrate_1_0_to_1_1 "$config_content")
            fi
            ;;
        1.1.0)
            if [[ "$target_version" == "1.2.0" ]]; then
                config_content=$(migrate_1_1_to_1_2 "$config_content")
            fi
            ;;
        *)
            log ERROR "Migration from version $current_version not supported"
            return 1
            ;;
    esac
    
    # Update version
    config_content=$(echo "$config_content" | jq --arg version "$target_version" '.version = $version')
    
    # Backup original file
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Write migrated configuration
    echo "$config_content" > "$config_file"
    
    log SUCCESS "Configuration migrated to version: $target_version"
    return 0
}

# Migration functions
migrate_1_0_to_1_1() {
    local config_content="$1"
    
    # Add new fields for version 1.1.0
    echo "$config_content" | jq '
        . + {
            "security": {
                "vulnerability_scanning": {
                    "enabled": true,
                    "auto_fix": false,
                    "block_on_critical": true
                },
                "dependency_audit": {
                    "enabled": true,
                    "auto_update": false,
                    "schedule": "weekly"
                },
                "secrets_scanning": {
                    "enabled": true,
                    "patterns": ["api_key", "password", "token", "secret"]
                }
            }
        }
    '
}

migrate_1_1_to_1_2() {
    local config_content="$1"
    
    # Add new fields for version 1.2.0
    echo "$config_content" | jq '
        . + {
            "integration": {
                "ci_cd": {
                    "github_actions": {
                        "enabled": false,
                        "workflow_template": "default"
                    },
                    "gitlab_ci": {
                        "enabled": false,
                        "pipeline_template": "default"
                    },
                    "jenkins": {
                        "enabled": false,
                        "job_template": "default"
                    }
                },
                "issue_tracking": {
                    "github": {
                        "enabled": false,
                        "repository": "",
                        "labels": ["pak", "deployment"]
                    },
                    "jira": {
                        "enabled": false,
                        "project_key": "",
                        "issue_type": "Task"
                    }
                }
            }
        }
    '
}

# Clean up configuration cache
cleanup_config_cache() {
    log INFO "Cleaning up configuration cache"
    
    # Remove cache files older than 30 days
    find "$CONFIG_CACHE_DIR" -type f -mtime +30 -delete 2>/dev/null
    
    # Remove temporary files older than 24 hours
    find "$CONFIG_TEMP_DIR" -type f -mtime +1 -delete 2>/dev/null
    
    log SUCCESS "Configuration cache cleaned up"
}

# Main function
main() {
    local command="$1"
    local args="${@:2}"
    
    # Initialize configuration system
    init_config
    
    case "$command" in
        create)
            create_package_config "$args"
            ;;
        load)
            load_package_config "$args"
            ;;
        get)
            local config_content=$(load_package_config)
            local path="$2"
            local default="$3"
            get_config_value "$config_content" "$path" "$default"
            ;;
        set)
            local config_file="$2"
            local path="$3"
            local value="$4"
            set_config_value "$config_file" "$path" "$value"
            ;;
        validate)
            local config_content=$(load_package_config)
            validate_config "$config_content"
            ;;
        export)
            local config_content=$(load_package_config)
            local format="$2"
            local output_file="$3"
            export_config "$config_content" "$format" "$output_file"
            ;;
        migrate)
            local config_file="$2"
            local target_version="$3"
            migrate_config "$config_file" "$target_version"
            ;;
        cleanup)
            cleanup_config_cache
            ;;
        *)
            echo "Usage: $0 {create|load|get|set|validate|export|migrate|cleanup} [args...]"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 