# Universal Package Tracker & Deployer - Installation Guide

🚀 **The ultimate tool for tracking and deploying packages across 30+ languages and package managers**

## Quick Installation

### System-wide Installation (Recommended)
```bash
# Clone or download the repository
git clone <repository-url>
cd <repository-name>

# Install system-wide (requires sudo)
sudo ./install/install.sh
```

### Local Installation
```bash
# Install to local directory
INSTALL_DIR=./bin CONFIG_DIR=./config DATA_DIR=./data LOG_DIR=./logs ./install/install.sh
```

## What Gets Installed

### 📦 Main Components
- **`pak`** - Main command-line tool (installed to `/usr/local/bin/` or custom location)
- **Configuration files** - Platform configs, templates, and defaults
- **Deployment templates** - Platform-specific deployment scripts
- **Data directories** - History, cache, and analytics storage
- **Log directories** - Deployment, tracking, and error logs

### 📁 Directory Structure
```
System-wide installation:
├── /usr/local/bin/pak                    # Main executable
├── /etc/pak/                             # Configuration
│   ├── default.json                      # Default config
│   ├── platform-configs.json             # Platform definitions
│   ├── package-config-template.json      # Config template
│   ├── templates/                        # Deployment templates
│   ├── uninstall.sh                      # Uninstall script
│   └── README.md                         # This file
├── /var/lib/pak/                         # Data storage
│   ├── history/                          # Historical data
│   ├── cache/                            # Cache files
│   └── analytics/                        # Analytics data
└── /var/log/pak/                         # Log files
    ├── deploy/                           # Deployment logs
    ├── track/                            # Tracking logs
    └── errors/                           # Error logs
```

## Usage After Installation

### 🚀 Quick Start
```bash
# Initialize the system
pak.sh --init

# Track package statistics
pak.sh --package your-package --track-only

# Deploy to all platforms
pak.sh --package your-package --version 1.2.3 --deploy

# Deploy to specific platform
pak.sh --package your-package --version 1.2.3 --platform npm --deploy
```

### 📋 Common Commands
```bash
# List all supported platforms
pak.sh --list-platforms

# Create configuration template
pak.sh --create-config

# Get help
pak.sh --help

# Track with custom config
pak.sh --package mylib --config my-config.json --track-only

# Deploy with force flag
pak.sh --package mylib --version 2.1.0 --deploy --force
```

## Configuration

### Default Configuration
The system creates a default configuration at `/etc/pak/default.json` (or custom location):

```json
{
  "package": {
    "name": "",
    "version": "",
    "description": "",
    "author": "",
    "license": "MIT"
  },
  "deployment": {
    "auto_deploy": false,
    "require_version": true,
    "pre_deploy_tests": true,
    "platforms": {
      "npm": {"enabled": true},
      "pypi": {"enabled": true}
    }
  },
  "tracking": {
    "enabled_platforms": ["npm", "pypi", "cargo", "nuget", "packagist", "rubygems"],
    "tracking_interval": "daily",
    "retention_days": 365
  }
}
```

### Custom Configuration
Create your own configuration file:

```bash
# Copy template
cp /etc/pak/package-config-template.json my-package-config.json

# Edit with your details
nano my-package-config.json

# Use with pak command
pak.sh --package mylib --config my-package-config.json --track-only
```

## Supported Platforms

### 🌐 30+ Package Managers Supported

**JavaScript/TypeScript:**
- 📦 npm (npmjs.com)
- 🧶 yarn (yarnpkg.com)
- 🚀 jsr (jsr.io)
- 🦕 deno (deno.land/x)
- 📦 jspm (jspm.org)

**Python:**
- 🐍 PyPI (pypi.org)
- 🐍 conda (anaconda.org)
- 📝 poetry (python-poetry.org)

**Java:**
- ☕ Maven (search.maven.org)
- ☕ JCenter (bintray.com)
- 🔗 JitPack (jitpack.io)
- 🏗️ Gradle (plugins.gradle.org)

**And 20+ more languages...**
- 🦀 Rust (crates.io)
- 🐹 Go (pkg.go.dev)
- 🍎 Swift (swiftpackageindex.com)
- 💎 Ruby (rubygems.org)
- 🐘 PHP (packagist.org)
- 🔷 C#/.NET (nuget.org)
- And many more!

## Examples

### 📊 Tracking Package Statistics
```bash
# Track all enabled platforms
pak.sh --package mylib --track-only

# Track specific platform
pak.sh --package mylib --platform npm --track-only

# Track with custom config
pak.sh --package mylib --config my-config.json --track-only
```

### 🚀 Deploying Packages
```bash
# Deploy to all configured platforms
pak.sh --package mylib --version 1.2.3 --deploy

# Deploy to specific platforms
pak.sh --package mylib --version 1.2.3 --platform npm --platform pypi --deploy

# Force deployment (skip version checks)
pak.sh --package mylib --version 1.2.3 --deploy --force
```

### 🔧 System Management
```bash
# Initialize system
pak.sh --init

# List supported platforms
pak.sh --list-platforms

# Create configuration template
pak.sh --create-config
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Deploy Package
on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to all platforms
        run: |
          pak.sh --package ${{ github.event.repository.name }} --version ${GITHUB_REF#refs/tags/} --deploy --quiet
```

### Automated Tracking
```bash
# Cron job for daily tracking
0 9 * * * pak.sh --package mylib --track-only --quiet
```

## Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
# Fix permissions
sudo chmod +x /usr/local/bin/pak
```

**2. Command Not Found**
```bash
# Add to PATH or reinstall
export PATH="/usr/local/bin:$PATH"
# or
sudo ./install/install.sh
```

**3. Configuration Issues**
```bash
# Check configuration
cat /etc/pak/default.json

# Recreate configuration
pak.sh --create-config
```

**4. Platform-Specific Issues**
```bash
# Check platform configuration
cat /etc/pak/platform-configs.json

# Test specific platform
pak.sh --package test --platform npm --track-only
```

## Uninstallation

### Complete Uninstall
```bash
# Run uninstall script
sudo /etc/pak/uninstall.sh
```

### Preserve Data
```bash
# Manual uninstall (preserves data)
sudo rm -f /usr/local/bin/pak
# Data remains in /var/lib/pak/ and /var/log/pak/
```

## Custom Installation Options

### Environment Variables
```bash
# Custom installation paths
INSTALL_DIR=./bin \
CONFIG_DIR=./config \
DATA_DIR=./data \
LOG_DIR=./logs \
./install/install.sh
```

### Development Installation
```bash
# Install for development
INSTALL_DIR=./bin \
CONFIG_DIR=./config \
DATA_DIR=./data \
LOG_DIR=./logs \
./install/install.sh

# Add to PATH
export PATH="./bin:$PATH"
```

## Support

### 📖 Documentation
- **Installation Guide**: This file
- **User Guide**: `/etc/pak/README.md`
- **Configuration**: `/etc/pak/package-config-template.json`

### 🐛 Issues
- Check logs: `/var/log/pak/`
- Configuration: `/etc/pak/`
- Data: `/var/lib/pak/`

### 🔧 Maintenance
- **Update**: Re-run installation script
- **Backup**: Copy `/var/lib/pak/` and `/etc/pak/`
- **Restore**: Copy back and reinstall main script

---

**Made with ❤️ for the developer community**

*Universal Package Tracker & Deployer - Because managing 30+ package managers shouldn't be a nightmare.* 