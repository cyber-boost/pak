# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PAK.sh (Package Automation Kit) is a universal package deployment system that enables developers to deploy packages to 30+ different platforms with a single command. It's primarily written in Bash with a modular architecture and includes web interfaces in Python (Flask) and PHP.

## Common Development Commands

### Testing
```bash
# Quick functionality test (2-3 minutes)
./tests/quick-test.sh

# Test all 300+ commands (10-15 minutes)
./tests/test-all-commands.sh

# Run complete test suite (30-45 minutes)
./tests/run-all-tests.sh

# Run specific test categories
./tests/advanced-tests.sh    # Edge cases and integration
./tests/stress-tests.sh      # Performance and load testing
./pak/tests/core-tests.sh    # PAK core functionality
./pak/tests/test-register.sh # Registration module tests
```

### Building
```bash
# Build distribution packages
./admin/build.sh

# Build wrapper packages for all package managers
./wrappers/build.sh
```

### Python Development
```bash
# Install development dependencies
pip install -e ".[dev]"

# Run Python linters
flake8    # Linter
black .   # Formatter
mypy      # Type checker

# Run Python tests
pip install -e ".[test]"
pytest
pytest --cov  # With coverage
```

### Running PAK.sh
```bash
# Show help
./pak/pak.sh --help

# Deploy to multiple platforms
./pak/pak.sh deploy my-package --version 1.2.3

# Track package statistics
./pak/pak.sh track my-package

# Register with package platforms
./pak/pak.sh register
```

## High-Level Architecture

### Modular System
PAK.sh uses a plugin-based architecture where functionality is organized into modules:

1. **Core Module Loading**: The main `pak.sh` script loads modules from `/pak/modules/` in a specific order
2. **Command Registration**: Each module registers its commands using `register_command "cmd" "module" "function"`
3. **Hook System**: Modules can register lifecycle hooks (pre_init, post_init, pre_command, post_command)
4. **Command Dispatch**: Commands are dispatched through a central router that finds the appropriate module function

### Module Structure
Each module follows this pattern:
```bash
# Module metadata
MODULE_VERSION="1.0.0"
MODULE_DEPENDENCIES=("core" "other_module")

# Initialization
module_init() {
    # Setup directories, load configs
}

# Command registration
module_register_commands() {
    register_command "command" "module" "module_function"
}

# Command implementations
module_function() {
    # Command logic
}
```

### Key Modules
- **core**: Essential functionality, configuration, utilities
- **platform**: Platform-specific deployment logic
- **deploy**: Cross-platform deployment orchestration
- **track**: Analytics and statistics tracking
- **security**: Vulnerability scanning, license compliance
- **register**: Platform registration wizard
- **automation**: CI/CD pipeline generation

### Directory Structure
```
/opt/stats/
├── pak/
│   ├── pak.sh              # Main entry point
│   ├── modules/            # Plugin modules
│   ├── config/             # Platform configs, policies
│   │   ├── platforms/      # JSON configs for each platform
│   │   └── security/       # Security policies
│   ├── data/               # Runtime data storage
│   └── templates/          # Deployment templates
├── bash_central/           # Shared Bash utilities
├── tests/                  # Test suite
├── web_py/                 # Flask web application
└── wrappers/              # Multi-language package wrappers
```

### Platform Support
Platforms are configured via JSON files in `/pak/config/platforms/`. Each platform config defines:
- Registry URL and authentication
- Package format and metadata requirements
- Deployment commands and API endpoints
- Platform-specific validation rules

### Data Flow
1. User invokes PAK command
2. Main script loads all modules and initializes
3. Command is dispatched to appropriate module
4. Module performs action (deploy, track, scan, etc.)
5. Results are logged to `/pak/logs/` and data stored in `/pak/data/`
6. Analytics are tracked in SQLite database

### Web Interface
- Flask app in `/web_py/` provides dashboard and API
- Uses SQLAlchemy ORM with SQLite database
- Tracks deployment history, analytics, and monitoring data
- Accessible at http://localhost:9123 when running

### Security Considerations
- Credentials stored in `~/.pak/credentials/` (encrypted)
- Security scanning via `pak scan` command
- License compliance checking
- Vulnerability database updates

### ASCII Art System
PAK.sh includes a sophisticated dynamic ASCII art system in `/bash_central/`:
- `ascii.sh`: Main ASCII rendering engine
- `ascii-animate-colors.sh`: Animation and color effects
- Used for visual feedback during operations