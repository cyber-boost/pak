#!/bin/bash

# Universal Package Tracker & Deployer - Enhanced Installation Script
# Installs the complete system with security and developer experience modules

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Installation variables - Default to user home directory
PAK_HOME="${PAK_HOME:-$HOME/.pak}"
INSTALL_DIR="$PAK_HOME/bin"
CONFIG_DIR="$PAK_HOME/config"
DATA_DIR="$PAK_HOME/data"
LOG_DIR="$PAK_HOME/logs"

# Global binary location for symlink
GLOBAL_BIN_DIR="${GLOBAL_BIN_DIR:-/usr/local/bin}"

# Base URL for downloading files (adjust as needed)
BASE_URL="${PAK_BASE_URL:-https://pak.sh}"

# Handle script directory detection for both local and curl-piped execution
detect_script_dirs() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
        # Running from a local file
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PARENT_DIR="$(dirname "$SCRIPT_DIR")"
        IS_LOCAL_INSTALL=true
        echo -e "${CYAN}🔍 Detected: Local installation from file${NC}"
    else
        # Running from curl pipe or stdin
        SCRIPT_DIR=""
        PARENT_DIR=""
        IS_LOCAL_INSTALL=false
        echo -e "${CYAN}🔍 Detected: Remote installation (piped from curl)${NC}"
    fi
}

# Detect environment
detect_environment() {
    local os_type=""
    local env_info=""
    
    # Check for WSL
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        os_type="WSL"
        env_info="Windows Subsystem for Linux"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="Linux"
        env_info="Native Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
        env_info="macOS"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        os_type="Windows"
        env_info="Windows (Git Bash/MSYS2)"
    else
        os_type="Unknown"
        env_info="Unknown environment"
    fi
    
    echo -e "${CYAN}🔍 Detected environment: ${GREEN}$env_info${NC}"
    
    # WSL-specific recommendations
    if [[ "$os_type" == "WSL" ]]; then
        echo -e "${BLUE}💡 WSL detected! You're running PAK.sh in Windows Subsystem for Linux.${NC}"
        echo -e "${BLUE}   This provides full Linux compatibility with excellent performance.${NC}"
    fi
}

# Download file function
download_file() {
    local url="$1"
    local destination="$2"
    local description="${3:-file}"
    
    echo -e "${BLUE}⬇️  Downloading $description...${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$destination" || {
            echo -e "${RED}❌ Failed to download $description from $url${NC}"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$destination" "$url" || {
            echo -e "${RED}❌ Failed to download $description from $url${NC}"
            return 1
        }
    else
        echo -e "${RED}❌ Neither curl nor wget found. Cannot download $description${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Downloaded $description${NC}"
}

# Run detections
detect_script_dirs
detect_environment

echo -e "${BLUE}🚀 Installing Enhanced Universal Package Tracker & Deployer (UPTD)...${NC}"
echo -e "${CYAN}📍 Installing to: ${GREEN}$PAK_HOME${NC}"

# Check if we can create global symlink (optional)
CAN_CREATE_GLOBAL_SYMLINK=false
if [ "$EUID" -eq 0 ]; then
    CAN_CREATE_GLOBAL_SYMLINK=true
    echo -e "${GREEN}✓ Running as root - will create global symlink${NC}"
elif [ -w "$GLOBAL_BIN_DIR" ]; then
    CAN_CREATE_GLOBAL_SYMLINK=true
    echo -e "${GREEN}✓ Can write to $GLOBAL_BIN_DIR - will create global symlink${NC}"
else
    echo -e "${YELLOW}ℹ️  No root privileges - will install to user directory only${NC}"
    echo -e "${CYAN}💡 Run with sudo to create global symlink: ${GREEN}sudo bash < <(curl -sSL get.pak.sh)${NC}"
fi

# Create installation directories
echo -e "${BLUE}📁 Creating installation directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Install main PAK system
echo -e "${BLUE}📦 Installing PAK system...${NC}"
if [[ "$IS_LOCAL_INSTALL" == "true" ]] && [[ -f "$PARENT_DIR/pak/pak.sh" ]]; then
    # Local installation - copy from repository
    cp "$PARENT_DIR/pak/pak.sh" "$INSTALL_DIR/pak"
    echo -e "${GREEN}✅ Copied pak.sh from local repository${NC}"
else
    # Remote installation - download complete system as tar.gz
    TEMP_DIR=$(mktemp -d)
    echo -e "${BLUE}⬇️  Downloading complete PAK system...${NC}"
    
    # Try to download latest.tar.gz
    alt_urls=(
        "https://get.pak.sh/latest.tar.gz"
        "https://pak.sh/latest.tar.gz"
        "https://cdn.pak.sh/latest.tar.gz"
    )
    
    success=false
    for url in "${alt_urls[@]}"; do
        echo -e "${BLUE}🔄 Trying: $url${NC}"
        if download_file "$url" "$TEMP_DIR/latest.tar.gz" "PAK system archive"; then
            success=true
            break
        fi
    done
    
    if [[ "$success" == "false" ]]; then
        echo -e "${RED}❌ Failed to download PAK system from all sources${NC}"
        echo -e "${YELLOW}💡 Please check your internet connection or try a local installation${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Extract the archive
    echo -e "${BLUE}📦 Extracting PAK system...${NC}"
    cd "$TEMP_DIR"
    if tar -xzf latest.tar.gz; then
        # Find the pak.sh file in the extracted directory
        PAK_DIR=$(find . -name "pak.sh" -type f | head -1 | xargs dirname)
        if [[ -n "$PAK_DIR" ]] && [[ -f "$PAK_DIR/pak.sh" ]]; then
            cp "$PAK_DIR/pak.sh" "$INSTALL_DIR/pak"
            echo -e "${GREEN}✅ Extracted and installed pak.sh${NC}"
            
            # Copy additional files if they exist
            if [[ -d "$PAK_DIR/modules" ]]; then
                # Copy all .module.sh files to the modules directory
                mkdir -p "$CONFIG_DIR/modules"
                cp "$PAK_DIR/modules"/*.module.sh "$CONFIG_DIR/modules/" 2>/dev/null || true
                echo -e "${GREEN}✅ Copied module files from archive${NC}"
            fi
            if [[ -d "$PAK_DIR/templates" ]]; then
                mkdir -p "$CONFIG_DIR/templates"
                cp -r "$PAK_DIR/templates"/* "$CONFIG_DIR/templates/" 2>/dev/null || true
                echo -e "${GREEN}✅ Copied templates from archive${NC}"
            fi
            if [[ -f "$PAK_DIR/ascii-letters.sh" ]]; then
                cp "$PAK_DIR/ascii-letters.sh" "$INSTALL_DIR/" 2>/dev/null || true
                echo -e "${GREEN}✅ Copied ASCII functions from archive${NC}"
            fi
        else
            echo -e "${RED}❌ Could not find pak.sh in the downloaded archive${NC}"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to extract the downloaded archive${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
fi

chmod +x "$INSTALL_DIR/pak"

# Create enhanced modules directory and basic modules for local installations
echo -e "${BLUE}🔧 Installing enhanced modules...${NC}"
mkdir -p "$CONFIG_DIR/modules"

if [[ "$IS_LOCAL_INSTALL" == "true" ]] && [[ -d "$PARENT_DIR/pak/modules" ]]; then
    # Local installation - copy modules
    cp "$PARENT_DIR/pak/modules"/*.module.sh "$CONFIG_DIR/modules/" 2>/dev/null || echo -e "${YELLOW}⚠️  No modules directory found in local repository${NC}"
else
    # Remote installation - create basic module structure if modules weren't copied from archive
    if [[ ! -f "$CONFIG_DIR/modules/core.module.sh" ]]; then
        echo -e "${YELLOW}ℹ️  Creating basic module structure (full modules downloaded from archive)${NC}"
        mkdir -p "$CONFIG_DIR/modules/security"
        mkdir -p "$CONFIG_DIR/modules/automation"
        mkdir -p "$CONFIG_DIR/modules/devex"
    fi
fi

# Create templates directory
echo -e "${BLUE}🔨 Creating deployment templates...${NC}"
mkdir -p "$CONFIG_DIR/templates"

if [[ "$IS_LOCAL_INSTALL" == "true" ]] && [[ -f "$SCRIPT_DIR/platform-configs.json" ]]; then
    # Local installation - copy configuration files
    cp "$SCRIPT_DIR/platform-configs.json" "$CONFIG_DIR/"
    if [[ -d "$SCRIPT_DIR/templates" ]]; then
        cp -r "$SCRIPT_DIR/templates"/* "$CONFIG_DIR/templates/" 2>/dev/null || true
    fi
    
    # Run deploy-templates.sh if it exists
    if [[ -f "$SCRIPT_DIR/deploy-templates.sh" ]]; then
        cd "$SCRIPT_DIR"
        ./deploy-templates.sh || echo -e "${YELLOW}⚠️  deploy-templates.sh failed, continuing...${NC}"
    fi
else
    # Remote installation - embed basic platform configuration
    cat > "$CONFIG_DIR/platform-configs.json" << 'EOF'
{
  "platforms": {
    "npm": {
      "name": "npm",
      "language": "javascript",
      "registry": "https://registry.npmjs.org",
      "api_endpoint": "https://api.npmjs.org",
      "deploy_command": "npm publish",
      "tracking_endpoints": [
        "https://api.npmjs.org/downloads/point/last-month/{package}",
        "https://api.npmjs.org/downloads/range/last-week/{package}"
      ],
      "required_files": ["package.json"],
      "optional_files": ["README.md", "LICENSE", ".npmignore"],
      "package_manager": "npm",
      "version_file": "package.json",
      "version_field": "version",
      "build_command": "npm run build",
      "test_command": "npm test",
      "install_command": "npm install",
      "publish_flags": ["--access", "public"],
      "authentication": {
        "type": "token",
        "env_var": "NPM_TOKEN",
        "config_key": "//registry.npmjs.org/:_authToken"
      }
    },
    "pypi": {
      "name": "pypi",
      "language": "python",
      "registry": "https://pypi.org",
      "api_endpoint": "https://pypi.org/pypi",
      "deploy_command": "twine upload dist/*",
      "tracking_endpoints": [
        "https://pypi.org/pypi/{package}/json"
      ],
      "required_files": ["setup.py", "pyproject.toml"],
      "optional_files": ["README.md", "LICENSE", "MANIFEST.in"],
      "package_manager": "pip",
      "version_file": "setup.py",
      "version_field": "version",
      "build_command": "python setup.py sdist bdist_wheel",
      "test_command": "python -m pytest",
      "install_command": "pip install -r requirements.txt",
      "publish_flags": [],
      "authentication": {
        "type": "token",
        "env_var": "TWINE_PASSWORD",
        "config_key": "password"
      }
    },
    "cargo": {
      "name": "cargo",
      "language": "rust",
      "registry": "https://crates.io",
      "api_endpoint": "https://crates.io/api/v1",
      "deploy_command": "cargo publish",
      "tracking_endpoints": [
        "https://crates.io/api/v1/crates/{package}"
      ],
      "required_files": ["Cargo.toml"],
      "optional_files": ["README.md", "LICENSE", "Cargo.lock"],
      "package_manager": "cargo",
      "version_file": "Cargo.toml",
      "version_field": "version",
      "build_command": "cargo build --release",
      "test_command": "cargo test",
      "install_command": "cargo install",
      "publish_flags": [],
      "authentication": {
        "type": "token",
        "env_var": "CARGO_REGISTRY_TOKEN",
        "config_key": "token"
      }
    }
  }
}
EOF
    echo -e "${GREEN}✅ Created basic platform configuration${NC}"
fi

# Create enhanced default configuration
echo -e "${BLUE}📝 Creating enhanced configuration...${NC}"
cat > "$CONFIG_DIR/default.json" << 'EOF'
{
  "package": {
    "name": "",
    "version": "",
    "description": "",
    "author": "",
    "license": "MIT",
    "repository": "",
    "homepage": "",
    "keywords": []
  },
  "deployment": {
    "auto_deploy": false,
    "require_version": true,
    "pre_deploy_tests": true,
    "post_deploy_verification": true,
    "rollback_on_failure": true,
    "parallel_deployments": 3,
    "security_scan_required": true,
    "license_compliance_required": true
  },
  "tracking": {
    "enabled_platforms": ["npm", "pypi", "cargo", "nuget", "packagist", "rubygems"],
    "tracking_interval": "daily",
    "retention_days": 365,
    "alert_thresholds": {
      "download_drop": 50,
      "error_rate": 5
    }
  },
  "security": {
    "enabled": true,
    "scan_on_deploy": true,
    "vulnerability_threshold": {
      "critical": 0,
      "high": 2,
      "medium": 5,
      "low": 10
    },
    "license_policy": "strict",
    "dependency_audit": true,
    "secrets_scan": true
  },
  "automation": {
    "enabled": true,
    "ci_cd": "github",
    "git_hooks": true,
    "auto_testing": true,
    "auto_building": true,
    "release_automation": true
  },
  "devex": {
    "enabled": true,
    "interactive_wizard": true,
    "project_templates": true,
    "auto_setup": true,
    "documentation_generation": true
  },
  "notifications": {
    "email": "",
    "slack_webhook": "",
    "discord_webhook": "",
    "telegram_bot": ""
  },
  "analytics": {
    "enabled": true,
    "export_formats": ["json", "csv", "html"],
    "trend_analysis": true,
    "comparison_reports": true
  }
}
EOF

# Create security configuration
echo -e "${BLUE}🔐 Creating security configuration...${NC}"
mkdir -p "$CONFIG_DIR/security"
cat > "$CONFIG_DIR/security/config.json" << 'EOF'
{
  "scanning": {
    "enabled": true,
    "auto_scan": true,
    "scan_on_commit": true,
    "scan_on_deploy": true
  },
  "compliance": {
    "owasp": true,
    "license": true,
    "dependency": true
  },
  "policies": {
    "vulnerability_threshold": {
      "critical": 0,
      "high": 2,
      "medium": 5,
      "low": 10
    },
    "allowed_licenses": [
      "MIT",
      "Apache-2.0",
      "BSD-3-Clause",
      "ISC"
    ],
    "blocked_licenses": [
      "GPL-2.0",
      "GPL-3.0",
      "AGPL-3.0"
    ]
  }
}
EOF

# Create automation configuration
echo -e "${BLUE}🤖 Creating automation configuration...${NC}"
mkdir -p "$CONFIG_DIR/automation"
cat > "$CONFIG_DIR/automation/config.json" << 'EOF'
{
  "ci_cd": {
    "platform": "github",
    "auto_deploy": false,
    "require_approval": true,
    "parallel_jobs": 3
  },
  "testing": {
    "unit_tests": true,
    "integration_tests": true,
    "e2e_tests": false,
    "coverage_threshold": 80
  },
  "git_hooks": {
    "pre_commit": true,
    "pre_push": true,
    "post_merge": true
  },
  "release": {
    "auto_version": true,
    "create_tags": true,
    "github_release": true
  }
}
EOF

# Create DevEx configuration
echo -e "${BLUE}👨‍💻 Creating DevEx configuration...${NC}"
mkdir -p "$CONFIG_DIR/devex"
cat > "$CONFIG_DIR/devex/config.json" << 'EOF'
{
  "wizard": {
    "enabled": true,
    "interactive": true,
    "default_license": "MIT",
    "default_platform": "npm"
  },
  "templates": {
    "enabled": true,
    "auto_setup": true,
    "include_tests": true,
    "include_docs": true
  },
  "environment": {
    "auto_setup": true,
    "git_hooks": true,
    "linting": true,
    "formatting": true
  },
  "documentation": {
    "auto_generate": true,
    "include_api_docs": true,
    "include_guides": true
  }
}
EOF

# Create data directories
echo -e "${BLUE}📊 Creating data directories...${NC}"
mkdir -p "$DATA_DIR/history"
mkdir -p "$DATA_DIR/cache"
mkdir -p "$DATA_DIR/analytics"
mkdir -p "$DATA_DIR/security"
mkdir -p "$DATA_DIR/deployments"
mkdir -p "$DATA_DIR/monitoring"

# Create log directories
echo -e "${BLUE}📋 Creating log directories...${NC}"
mkdir -p "$LOG_DIR/deploy"
mkdir -p "$LOG_DIR/track"
mkdir -p "$LOG_DIR/security"
mkdir -p "$LOG_DIR/automation"
mkdir -p "$LOG_DIR/devex"
mkdir -p "$LOG_DIR/errors"

# Set permissions
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chmod 755 "$INSTALL_DIR/pak"
chmod 644 "$CONFIG_DIR"/*.json
chmod -R 755 "$CONFIG_DIR/modules"
chmod -R 755 "$CONFIG_DIR/templates"
chmod -R 755 "$DATA_DIR"
chmod -R 755 "$LOG_DIR"

# Ensure all scripts in installed directories are executable
echo -e "${BLUE}🔐 Setting script permissions...${NC}"
find "$CONFIG_DIR" -name "*.sh" -type f -exec chmod +x {} \;
find "$CONFIG_DIR" -name "*.py" -type f -exec chmod +x {} \;
find "$DATA_DIR" -name "*.sh" -type f -exec chmod +x {} \;
find "$DATA_DIR" -name "*.py" -type f -exec chmod +x {} \;
echo -e "${GREEN}✅ All installed scripts made executable${NC}"

# Create global symlink for easy access
if [ "$CAN_CREATE_GLOBAL_SYMLINK" = "true" ]; then
    echo -e "${BLUE}🔗 Creating global symlink...${NC}"
    ln -sf "$INSTALL_DIR/pak" "$GLOBAL_BIN_DIR/pak"
    echo -e "${GREEN}✅ Global symlink created: $GLOBAL_BIN_DIR/pak${NC}"
else
    echo -e "${YELLOW}⚠️  No global symlink created - pak available at: $INSTALL_DIR/pak${NC}"
fi

# Create enhanced uninstall script
echo -e "${BLUE}🗑️  Creating uninstall script...${NC}"
cat > "$CONFIG_DIR/uninstall.sh" << EOF
#!/bin/bash
# Enhanced uninstall script for Universal Package Tracker & Deployer

set -euo pipefail

echo "🗑️  Uninstalling Enhanced Universal Package Tracker & Deployer..."

# Remove global symlink if it exists
if [[ -L "$GLOBAL_BIN_DIR/pak" ]]; then
    echo "🔗 Removing global symlink..."
    rm -f "$GLOBAL_BIN_DIR/pak"
    echo "✅ Global symlink removed"
fi

# Remove PAK home directory (with confirmation)
echo "⚠️  This will remove PAK installation and all configuration/data from:"
echo "   $PAK_HOME"
echo ""
read -p "Do you want to completely remove PAK? (y/N): " -n 1 -r
echo
if [[ \$REPLY =~ ^[Yy]\$ ]]; then
    rm -rf "$PAK_HOME"
    echo "✅ PAK completely removed from $PAK_HOME"
else
    echo "📁 PAK installation preserved at: $PAK_HOME"
    echo "   You can manually remove it later if needed"
fi

echo "✅ Uninstallation complete!"
EOF

chmod +x "$CONFIG_DIR/uninstall.sh"

# Create enhanced configuration template
echo -e "${BLUE}📄 Creating enhanced configuration template...${NC}"
cat > "$CONFIG_DIR/package-config-template.json" << 'EOF'
{
  "package": {
    "name": "your-package-name",
    "version": "1.0.0",
    "description": "Your package description",
    "author": "Your Name <your.email@example.com>",
    "license": "MIT",
    "repository": "https://github.com/username/your-package",
    "homepage": "https://github.com/username/your-package#readme",
    "keywords": ["your", "keywords", "here"]
  },
  "deployment": {
    "auto_deploy": false,
    "require_version": true,
    "pre_deploy_tests": true,
    "post_deploy_verification": true,
    "rollback_on_failure": true,
    "parallel_deployments": 3,
    "security_scan_required": true,
    "license_compliance_required": true,
    "platforms": {
      "npm": {
        "enabled": true,
        "registry": "https://registry.npmjs.org",
        "access": "public"
      },
      "pypi": {
        "enabled": true,
        "repository": "https://pypi.org",
        "username": "your-pypi-username"
      },
      "cargo": {
        "enabled": true,
        "registry": "https://crates.io"
      }
    }
  },
  "tracking": {
    "enabled_platforms": ["npm", "pypi", "cargo", "nuget", "packagist", "rubygems"],
    "tracking_interval": "daily",
    "retention_days": 365,
    "alert_thresholds": {
      "download_drop": 50,
      "error_rate": 5
    }
  },
  "security": {
    "enabled": true,
    "scan_on_deploy": true,
    "vulnerability_threshold": {
      "critical": 0,
      "high": 2,
      "medium": 5,
      "low": 10
    },
    "license_policy": "strict",
    "dependency_audit": true,
    "secrets_scan": true
  },
  "automation": {
    "enabled": true,
    "ci_cd": "github",
    "git_hooks": true,
    "auto_testing": true,
    "auto_building": true,
    "release_automation": true
  },
  "devex": {
    "enabled": true,
    "interactive_wizard": true,
    "project_templates": true,
    "auto_setup": true,
    "documentation_generation": true
  },
  "notifications": {
    "email": "your.email@example.com",
    "slack_webhook": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
    "discord_webhook": "https://discord.com/api/webhooks/YOUR/WEBHOOK/URL",
    "telegram_bot": "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage"
  },
  "analytics": {
    "enabled": true,
    "export_formats": ["json", "csv", "html"],
    "trend_analysis": true,
    "comparison_reports": true,
    "custom_metrics": []
  }
}
EOF

# Create enhanced README for installation
echo -e "${BLUE}📖 Creating enhanced installation README...${NC}"
cat > "$CONFIG_DIR/README.md" << 'EOF'
# Enhanced Universal Package Tracker & Deployer - Installation

## Quick Start

After installation, you can use the `pak` command from anywhere:

```bash
# Initialize system
pak --init

# Create new package with wizard
pak devex wizard

# Track package statistics
pak --package your-package --track-only

# Security scan
pak scan your-package

# Deploy to all platforms
pak --package your-package --version 1.2.3 --deploy

# List supported platforms
pak --list-platforms

# Get help
pak --help
```

## Enhanced Features

### 🔐 Security Module
- **Vulnerability Scanning**: `pak scan [package]`
- **License Compliance**: `pak license-check [package]`
- **Dependency Audit**: `pak dependency-check [package]`
- **Secrets Detection**: `pak secrets-scan [package]`
- **OWASP Compliance**: `pak compliance owasp [package]`

### 🤖 Automation Module
- **CI/CD Pipelines**: `pak pipeline create [name] [platform]`
- **Git Hooks**: `pak hooks install`
- **Release Automation**: `pak release [package] [version]`
- **Testing**: `pak test [package] [type]`
- **Build**: `pak build [package] [version]`

### 👨‍💻 DevEx Module
- **Interactive Wizard**: `pak devex wizard`
- **Project Templates**: `pak devex template create [type]`
- **Environment Setup**: `pak devex setup`
- **Documentation**: `pak devex docs generate`
- **Code Quality**: `pak devex lint` and `pak devex format`

## Configuration

- **Default Config**: `$CONFIG_DIR/default.json`
- **Template**: `$CONFIG_DIR/package-config-template.json`
- **Platform Configs**: `$CONFIG_DIR/platform-configs.json`
- **Security Config**: `$CONFIG_DIR/security/config.json`
- **Automation Config**: `$CONFIG_DIR/automation/config.json`
- **DevEx Config**: `$CONFIG_DIR/devex/config.json`

## Data Storage

- **History**: `$DATA_DIR/history/`
- **Cache**: `$DATA_DIR/cache/`
- **Analytics**: `$DATA_DIR/analytics/`
- **Security**: `$DATA_DIR/security/`
- **Deployments**: `$DATA_DIR/deployments/`
- **Monitoring**: `$DATA_DIR/monitoring/`

## Logs

- **Deploy Logs**: `$LOG_DIR/deploy/`
- **Track Logs**: `$LOG_DIR/track/`
- **Security Logs**: `$LOG_DIR/security/`
- **Automation Logs**: `$LOG_DIR/automation/`
- **DevEx Logs**: `$LOG_DIR/devex/`
- **Error Logs**: `$LOG_DIR/errors/`

## Security Features

- **OWASP Top 10 Compliance**
- **License Policy Management**
- **Dependency Vulnerability Scanning**
- **Secrets Detection**
- **Package Signing and Verification**

## Automation Features

- **Multi-Platform CI/CD Templates**
- **Git Hook Integration**
- **Automated Testing and Deployment**
- **Release Management**
- **Rollback Capabilities**

## Developer Experience

- **Interactive Package Creation**
- **Multi-Language Templates**
- **Automated Environment Setup**
- **Documentation Generation**
- **Code Quality Tools**

## Uninstall

To uninstall the system:

```bash
$CONFIG_DIR/uninstall.sh
```

## Custom Installation

To install to a custom location:

```bash
INSTALL_DIR=./bin CONFIG_DIR=./config DATA_DIR=./data LOG_DIR=./logs ./install.sh
```
EOF

# Update the README with actual paths
sed -i "s|\$CONFIG_DIR|$CONFIG_DIR|g" "$CONFIG_DIR/README.md"
sed -i "s|\$DATA_DIR|$DATA_DIR|g" "$CONFIG_DIR/README.md"
sed -i "s|\$LOG_DIR|$LOG_DIR|g" "$CONFIG_DIR/README.md"

# Create version file
echo -e "${BLUE}📋 Creating version file...${NC}"
cat > "$CONFIG_DIR/version" << 'EOF'
Enhanced Universal Package Tracker & Deployer (UPTD)
Version: 2.0.0
Installed: 2025-07-23
Supports: 30+ platforms across 25+ languages
Features: Security, Automation, DevEx
EOF

# Test installation
echo -e "${BLUE}🧪 Testing installation...${NC}"
if [[ -x "$INSTALL_DIR/pak" ]]; then
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo -e "${CYAN}📋 Installation Summary:${NC}"
    echo -e "  🏠 PAK Home: $PAK_HOME"
    echo -e "  📦 Main Script: $INSTALL_DIR/pak"
    echo -e "  ⚙️  Config: $CONFIG_DIR"
    echo -e "  📊 Data: $DATA_DIR"
    echo -e "  📋 Logs: $LOG_DIR"
    if [[ "$CAN_CREATE_GLOBAL_SYMLINK" == "true" ]]; then
        echo -e "  🔗 Global Link: $GLOBAL_BIN_DIR/pak"
    fi
    echo -e "  🌐 Installation Type: $([ "$IS_LOCAL_INSTALL" == "true" ] && echo "Local" || echo "Remote")"
    echo -e ""
    echo -e "${GREEN}🎉 Enhanced Universal Package Tracker & Deployer is ready!${NC}"
    echo -e ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    if [[ "$CAN_CREATE_GLOBAL_SYMLINK" == "true" ]]; then
        echo -e "  1. Initialize: ${GREEN}pak --init${NC}"
        echo -e "  2. Get help: ${GREEN}pak --help${NC}"
        echo -e "  3. Deploy package: ${GREEN}pak deploy [package] --version [version]${NC}"
    else
        echo -e "  1. Add to PATH: ${GREEN}export PATH=\$PATH:$INSTALL_DIR${NC}"
        echo -e "  2. Initialize: ${GREEN}pak --init${NC}"
        echo -e "  3. Get help: ${GREEN}pak --help${NC}"
        echo -e "  4. Deploy package: ${GREEN}pak deploy [package] --version [version]${NC}"
    fi
    echo -e ""
    echo -e "${BLUE}🔐 Security Features:${NC}"
    echo -e "  • Vulnerability scan: ${GREEN}pak scan${NC}"
    echo -e "  • License check: ${GREEN}pak license-check${NC}"
    echo -e "  • Dependency audit: ${GREEN}pak dependency-check${NC}"
    echo -e ""
    echo -e "${BLUE}🤖 Automation Features:${NC}"
    echo -e "  • CI/CD pipeline: ${GREEN}pak pipeline create${NC}"
    echo -e "  • Git hooks: ${GREEN}pak hooks install${NC}"
    echo -e "  • Release automation: ${GREEN}pak release${NC}"
    echo -e ""
    echo -e "${BLUE}👨‍💻 DevEx Features:${NC}"
    echo -e "  • Interactive wizard: ${GREEN}pak devex wizard${NC}"
    echo -e "  • Project templates: ${GREEN}pak devex template${NC}"
    echo -e "  • Environment setup: ${GREEN}pak devex setup${NC}"
    echo -e ""
    echo -e "${BLUE}📖 Documentation: $CONFIG_DIR/README.md${NC}"
    echo -e "${BLUE}🗑️  Uninstall: $CONFIG_DIR/uninstall.sh${NC}"
    
    # Add PATH suggestion if no global symlink
    if [[ "$CAN_CREATE_GLOBAL_SYMLINK" != "true" ]]; then
        echo -e ""
        echo -e "${YELLOW}💡 Add to your shell profile for permanent access:${NC}"
        echo -e "   ${GREEN}echo 'export PATH=\$PATH:$INSTALL_DIR' >> ~/.bashrc${NC}"
        echo -e "   ${GREEN}source ~/.bashrc${NC}"
        echo -e ""
        echo -e "${YELLOW}💡 Or run with sudo for global installation:${NC}"
        echo -e "   ${GREEN}sudo bash < <(curl -sSL get.pak.sh)${NC}"
    fi
else
    echo -e "${RED}❌ Installation failed!${NC}"
    echo -e "${YELLOW}💡 The pak script was not installed properly at $INSTALL_DIR/pak${NC}"
    if [[ "$IS_LOCAL_INSTALL" == "false" ]]; then
        echo -e "${YELLOW}💡 This might be due to network issues. Try:${NC}"
        echo -e "   1. Check your internet connection"
        echo -e "   2. Verify that $BASE_URL/latest.tar.gz is accessible"
        echo -e "   3. Try a local installation if you have the repository"
    fi
    exit 1
fi 