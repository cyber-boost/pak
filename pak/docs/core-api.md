# PAK Core API Documentation

## Overview

The PAK (Package Automation Kit) Core API provides a comprehensive set of functions and utilities for building modular, extensible package management systems. This document describes the core API functions, modules, and integration patterns.

## Table of Contents

1. [Core Functions](#core-functions)
2. [Module System](#module-system)
3. [Hook System](#hook-system)
4. [Plugin Architecture](#plugin-architecture)
5. [Configuration Management](#configuration-management)
6. [Health Monitoring](#health-monitoring)
7. [Utility Functions](#utility-functions)
8. [Error Handling](#error-handling)
9. [Performance Monitoring](#performance-monitoring)
10. [Security Functions](#security-functions)
11. [File Operations](#file-operations)
12. [Network Utilities](#network-utilities)
13. [Lifecycle Management](#lifecycle-management)

## Core Functions

### Module Loading

#### `load_module(module_name)`

Loads a module into the PAK system with dependency resolution and error handling.

**Parameters:**
- `module_name` (string): Name of the module to load

**Returns:**
- `0` on success, `1` on failure

**Example:**
```bash
load_module "core"
load_module "analytics"
```

#### `unload_module(module_name)`

Unloads a module from the PAK system, cleaning up commands and hooks.

**Parameters:**
- `module_name` (string): Name of the module to unload

**Example:**
```bash
unload_module "test_module"
```

#### `reload_module(module_name)`

Reloads a module by unloading and then loading it again.

**Parameters:**
- `module_name` (string): Name of the module to reload

**Example:**
```bash
reload_module "core"
```

### Command Registration

#### `register_command(command, module, function)`

Registers a command that can be executed by the PAK system.

**Parameters:**
- `command` (string): Command name
- `module` (string): Module name
- `function` (string): Function name to execute

**Example:**
```bash
register_command "version" "core" "core_version"
register_command "status" "core" "core_status"
```

### Hook System

#### `register_hook(hook_name, module, function, priority)`

Registers a hook function that will be executed at specific points in the system lifecycle.

**Parameters:**
- `hook_name` (string): Name of the hook point
- `module` (string): Module name
- `function` (string): Function name to execute
- `priority` (integer, optional): Priority (0-100, default: 50)

**Example:**
```bash
register_hook "pre_init" "core" "core_pre_init" 10
register_hook "post_command" "core" "core_post_command" 90
```

#### `execute_hooks(hook_name, ...args)`

Executes all registered hooks for a given hook point.

**Parameters:**
- `hook_name` (string): Name of the hook point
- `...args` (any): Arguments to pass to hook functions

**Example:**
```bash
execute_hooks "pre_command" "track" "package-name"
```

## Module System

### Module Structure

Each module should follow this structure:

```bash
#!/bin/bash
# Module metadata
MODULE_VERSION="1.0.0"
MODULE_DEPENDENCIES=("core" "other_module")
MODULE_HOOKS=("pre_init" "post_init")

# Module initialization
module_name_init() {
    # Initialize module
}

# Command registration
module_name_register_commands() {
    register_command "command" "module_name" "module_name_command"
}

# Hook registration
module_name_register_hooks() {
    register_hook "hook_name" "module_name" "module_name_hook" 50
}

# Module functions
module_name_command() {
    # Command implementation
}

module_name_hook() {
    # Hook implementation
}
```

### Dependency Resolution

The module system automatically resolves dependencies:

```bash
# Module A depends on Module B
MODULE_DEPENDENCIES=("module_b")

# When loading Module A, Module B will be loaded first
load_module "module_a"
```

### Circular Dependency Detection

The system detects and prevents circular dependencies:

```bash
# This will fail with circular dependency error
# Module A -> Module B -> Module A
load_module "module_a"  # Error: Circular dependency detected
```

## Plugin Architecture

### Plugin Types

PAK supports three types of plugins:

1. **Module Plugins**: Full modules with commands and hooks
2. **Hook Plugins**: Provide additional hook functions
3. **Utility Plugins**: Provide utility functions

### Plugin Registration

#### `register_plugin(plugin_name, plugin_file, plugin_type)`

Registers a plugin with the PAK system.

**Parameters:**
- `plugin_name` (string): Name of the plugin
- `plugin_file` (string): Path to plugin file
- `plugin_type` (string): Type of plugin (module, hook, utility)

**Example:**
```bash
register_plugin "my_plugin" "/path/to/plugin.sh" "module"
```

#### `load_plugin(plugin_name)`

Loads a registered plugin.

**Parameters:**
- `plugin_name` (string): Name of the plugin to load

**Example:**
```bash
load_plugin "my_plugin"
```

#### `unload_plugin(plugin_name)`

Unloads a plugin from the system.

**Parameters:**
- `plugin_name` (string): Name of the plugin to unload

**Example:**
```bash
unload_plugin "my_plugin"
```

#### `list_plugins()`

Lists all registered plugins.

**Example:**
```bash
list_plugins
```

### Plugin Structure

#### Module Plugin Example

```bash
#!/bin/bash
PLUGIN_NAME="example_plugin"
PLUGIN_VERSION="1.0.0"

example_plugin_init() {
    echo "Example plugin initialized"
}

example_plugin_register_commands() {
    register_command "example" "example_plugin" "example_plugin_command"
}

example_plugin_command() {
    echo "Example plugin command executed"
}
```

## Configuration Management

### Configuration Functions

#### `core_get_config_value(key)`

Gets a configuration value with caching.

**Parameters:**
- `key` (string): Configuration key

**Returns:**
- Configuration value

**Example:**
```bash
value=$(core_get_config_value "PAK_DEFAULT_PLATFORMS")
```

#### `core_set_config_value(key, value)`

Sets a configuration value and updates the cache.

**Parameters:**
- `key` (string): Configuration key
- `value` (string): Configuration value

**Example:**
```bash
core_set_config_value "PAK_API_TIMEOUT" "60"
```

#### `core_validate_config()`

Validates the current configuration.

**Returns:**
- `0` if valid, `1` if invalid

**Example:**
```bash
if core_validate_config; then
    echo "Configuration is valid"
else
    echo "Configuration has errors"
fi
```

#### `core_reload_config()`

Reloads configuration from file and clears cache.

**Example:**
```bash
core_reload_config
```

### Configuration Schema

The configuration system supports schema validation:

```bash
# Validate against schema
validate_config_schema

# Create schema
create_config_schema
```

## Health Monitoring

### Health Check Functions

#### `core_health(check_type)`

Performs health checks on the system.

**Parameters:**
- `check_type` (string): Type of health check (all, system, modules, config, dependencies)

**Example:**
```bash
core_health "all"
core_health "system"
```

#### `core_health_check_system()`

Checks system health (disk space, memory, permissions).

**Returns:**
- `0` if healthy, `1` if unhealthy

#### `core_health_check_modules()`

Checks module health (file existence, syntax, functions).

**Returns:**
- `0` if healthy, `1` if unhealthy

#### `core_health_check_config()`

Checks configuration health (syntax, required settings).

**Returns:**
- `0` if healthy, `1` if unhealthy

#### `core_health_check_dependencies()`

Checks required dependencies.

**Returns:**
- `0` if healthy, `1` if unhealthy

## Utility Functions

### Retry and Backoff

#### `retry_with_backoff(max_attempts, base_delay, max_delay, command)`

Retries a command with exponential backoff.

**Parameters:**
- `max_attempts` (integer): Maximum number of attempts
- `base_delay` (integer): Base delay in seconds
- `max_delay` (integer): Maximum delay in seconds
- `command` (string): Command to retry

**Example:**
```bash
retry_with_backoff 3 2 60 "curl -f https://api.example.com"
```

### JSON Utilities

#### `json_get(json, key)`

Extracts a value from JSON.

**Parameters:**
- `json` (string): JSON string
- `key` (string): Key to extract

**Returns:**
- Extracted value

**Example:**
```bash
value=$(json_get '{"name":"test","value":42}' "name")
```

#### `json_set(json, key, value)`

Sets a value in JSON.

**Parameters:**
- `json` (string): JSON string
- `key` (string): Key to set
- `value` (string): Value to set

**Returns:**
- Updated JSON

**Example:**
```bash
new_json=$(json_set '{"name":"test"}' "value" "42")
```

#### `json_merge(json1, json2)`

Merges two JSON objects.

**Parameters:**
- `json1` (string): First JSON object
- `json2` (string): Second JSON object

**Returns:**
- Merged JSON

**Example:**
```bash
merged=$(json_merge '{"a":1}' '{"b":2}')
```

### Validation Functions

#### `validate_email(email)`

Validates email address format.

**Parameters:**
- `email` (string): Email address to validate

**Returns:**
- `0` if valid, `1` if invalid

**Example:**
```bash
if validate_email "user@example.com"; then
    echo "Valid email"
fi
```

#### `validate_url(url)`

Validates URL format.

**Parameters:**
- `url` (string): URL to validate

**Returns:**
- `0` if valid, `1` if invalid

**Example:**
```bash
if validate_url "https://example.com"; then
    echo "Valid URL"
fi
```

#### `validate_version(version)`

Validates version string format.

**Parameters:**
- `version` (string): Version string to validate

**Returns:**
- `0` if valid, `1` if invalid

**Example:**
```bash
if validate_version "1.2.3"; then
    echo "Valid version"
fi
```

## Error Handling

### Error Handling Functions

#### `log(level, message)`

Logs a message with specified level.

**Parameters:**
- `level` (string): Log level (ERROR, WARN, INFO, DEBUG, SUCCESS)
- `message` (string): Message to log

**Example:**
```bash
log ERROR "Failed to load module"
log INFO "Module loaded successfully"
```

#### `log_with_context(level, context, message)`

Logs a message with context.

**Parameters:**
- `level` (string): Log level
- `context` (string): Context information
- `message` (string): Message to log

**Example:**
```bash
log_with_context ERROR "module_loader" "Failed to load module"
```

## Performance Monitoring

### Performance Functions

#### `log_performance(operation, start_time, end_time)`

Logs performance metrics for an operation.

**Parameters:**
- `operation` (string): Operation name
- `start_time` (float): Start time (seconds since epoch)
- `end_time` (float): End time (seconds since epoch)

**Example:**
```bash
start_time=$(date +%s.%N)
# ... perform operation ...
end_time=$(date +%s.%N)
log_performance "database_query" "$start_time" "$end_time"
```

## Security Functions

### Security Utilities

#### `generate_random_string(length)`

Generates a random string of specified length.

**Parameters:**
- `length` (integer): Length of string to generate

**Returns:**
- Random string

**Example:**
```bash
token=$(generate_random_string 32)
```

#### `hash_string(string)`

Generates SHA256 hash of a string.

**Parameters:**
- `string` (string): String to hash

**Returns:**
- SHA256 hash

**Example:**
```bash
hash=$(hash_string "password123")
```

## File Operations

### File Utilities

#### `file_backup(file, backup_dir)`

Creates a backup of a file.

**Parameters:**
- `file` (string): File to backup
- `backup_dir` (string, optional): Backup directory

**Returns:**
- Path to backup file

**Example:**
```bash
backup_path=$(file_backup "/etc/config.conf")
```

#### `file_restore(backup_file, target_file)`

Restores a file from backup.

**Parameters:**
- `backup_file` (string): Path to backup file
- `target_file` (string): Path to restore to

**Example:**
```bash
file_restore "/backups/config.conf.bak" "/etc/config.conf"
```

## Network Utilities

### Network Functions

#### `check_connectivity(url, timeout)`

Checks network connectivity to a URL.

**Parameters:**
- `url` (string): URL to check (default: https://httpbin.org/get)
- `timeout` (integer): Timeout in seconds (default: 10)

**Returns:**
- `0` if connected, `1` if not connected

**Example:**
```bash
if check_connectivity "https://api.example.com"; then
    echo "Network is accessible"
fi
```

#### `get_external_ip()`

Gets the external IP address.

**Returns:**
- External IP address or empty string

**Example:**
```bash
ip=$(get_external_ip)
echo "External IP: $ip"
```

## Lifecycle Management

### Lifecycle Functions

#### `module_lifecycle_init(module_name)`

Initializes module lifecycle tracking.

**Parameters:**
- `module_name` (string): Name of the module

**Example:**
```bash
module_lifecycle_init "my_module"
```

#### `module_lifecycle_start(module_name)`

Marks module as started.

**Parameters:**
- `module_name` (string): Name of the module

**Example:**
```bash
module_lifecycle_start "my_module"
```

#### `module_lifecycle_stop(module_name)`

Marks module as stopped.

**Parameters:**
- `module_name` (string): Name of the module

**Example:**
```bash
module_lifecycle_stop "my_module"
```

#### `module_lifecycle_error(module_name, error_message)`

Marks module as having an error.

**Parameters:**
- `module_name` (string): Name of the module
- `error_message` (string): Error message

**Example:**
```bash
module_lifecycle_error "my_module" "Failed to initialize"
```

#### `get_module_status(module_name)`

Gets the status of a module.

**Parameters:**
- `module_name` (string): Name of the module

**Returns:**
- Module status information

**Example:**
```bash
status=$(get_module_status "my_module")
echo "$status"
```

## Hot Reloading

### Hot Reload Functions

#### `setup_hot_reload(module_name, module_file)`

Sets up hot reloading for a module.

**Parameters:**
- `module_name` (string): Name of the module
- `module_file` (string): Path to module file

**Example:**
```bash
setup_hot_reload "my_module" "/path/to/module.sh"
```

#### `check_hot_reload()`

Checks for module file changes and reloads if necessary.

**Example:**
```bash
check_hot_reload
```

## Integration Examples

### Creating a Custom Module

```bash
#!/bin/bash
# my_module.module.sh

MODULE_VERSION="1.0.0"
MODULE_DEPENDENCIES=("core")
MODULE_HOOKS=("pre_init" "post_init")

my_module_init() {
    log INFO "My module initialized"
    module_lifecycle_start "my_module"
}

my_module_register_commands() {
    register_command "my-command" "my_module" "my_module_command"
}

my_module_register_hooks() {
    register_hook "pre_init" "my_module" "my_module_pre_init" 10
    register_hook "post_init" "my_module" "my_module_post_init" 90
}

my_module_command() {
    echo "My module command executed"
}

my_module_pre_init() {
    log DEBUG "My module pre-init hook"
}

my_module_post_init() {
    log DEBUG "My module post-init hook"
}
```

### Creating a Plugin

```bash
#!/bin/bash
# my_plugin.sh

PLUGIN_NAME="my_plugin"
PLUGIN_VERSION="1.0.0"

my_plugin_init() {
    log INFO "My plugin initialized"
}

my_plugin_register_commands() {
    register_command "plugin-command" "my_plugin" "my_plugin_command"
}

my_plugin_command() {
    echo "Plugin command executed"
}
```

### Using Configuration

```bash
#!/bin/bash

# Get configuration value
platforms=$(core_get_config_value "PAK_DEFAULT_PLATFORMS")
echo "Platforms: $platforms"

# Set configuration value
core_set_config_value "PAK_CUSTOM_SETTING" "my_value"

# Validate configuration
if core_validate_config; then
    echo "Configuration is valid"
else
    echo "Configuration has errors"
fi
```

### Error Handling and Retry

```bash
#!/bin/bash

# Retry with backoff
retry_with_backoff 3 2 60 "curl -f https://api.example.com/data"

# Log with context
log_with_context ERROR "api_client" "Failed to fetch data"

# Validate inputs
if ! validate_email "$email"; then
    log ERROR "Invalid email address: $email"
    exit 1
fi
```

## Best Practices

1. **Module Design**: Keep modules focused and single-purpose
2. **Error Handling**: Always check return values and handle errors gracefully
3. **Logging**: Use appropriate log levels and provide context
4. **Configuration**: Validate configuration early and often
5. **Performance**: Monitor performance and optimize slow operations
6. **Security**: Validate all inputs and use secure defaults
7. **Testing**: Write comprehensive tests for all functionality
8. **Documentation**: Document all public APIs and functions

## Troubleshooting

### Common Issues

1. **Module not loading**: Check file permissions and syntax
2. **Circular dependencies**: Review module dependency declarations
3. **Configuration errors**: Validate configuration syntax and required fields
4. **Performance issues**: Monitor execution times and optimize slow operations
5. **Permission errors**: Check file and directory permissions

### Debug Mode

Enable debug mode for detailed logging:

```bash
export PAK_DEBUG_MODE=true
pak your-command
```

### Health Checks

Run comprehensive health checks:

```bash
pak health all
pak doctor
```

## Version History

- **2.0.0**: Enhanced core system with advanced features
- **1.0.0**: Initial release with basic functionality

## Support

For support and questions:

1. Check the documentation
2. Run health checks: `pak health`
3. Enable debug mode: `export PAK_DEBUG_MODE=true`
4. Review logs: `tail -f $PAK_LOGS_DIR/pak.log` 