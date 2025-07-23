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

# Installation variables
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/pak}"
DATA_DIR="${DATA_DIR:-/var/lib/pak}"
LOG_DIR="${LOG_DIR:-/var/log/pak}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

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

# Run environment detection
detect_environment

echo -e "${BLUE}🚀 Installing Enhanced Universal Package Tracker & Deployer (UPTD)...${NC}"

# Check if running as root for system-wide installation
if [ "$EUID" -ne 0 ] && [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
    echo -e "${YELLOW}⚠️  Installing to system directory requires root privileges${NC}"
    echo -e "${CYAN}💡 Options:${NC}"
    echo -e "  1. Run with sudo: ${GREEN}sudo ./install.sh${NC}"
    echo -e "  2. Install locally: ${GREEN}INSTALL_DIR=./bin ./install.sh${NC}"
    exit 1
fi

# Create installation directories
echo -e "${BLUE}📁 Creating installation directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Copy main PAK system
echo -e "${BLUE}📦 Installing PAK system...${NC}"
cp "$PARENT_DIR/pak/pak.sh" "$INSTALL_DIR/pak"
chmod +x "$INSTALL_DIR/pak"

# Make all shell scripts executable
echo -e "${BLUE}🔐 Setting executable permissions...${NC}"
find "$PARENT_DIR" -name "*.sh" -type f -exec chmod +x {} \;
find "$PARENT_DIR" -name "*.py" -type f -exec chmod +x {} \;
echo -e "${GREEN}✅ All shell scripts and Python files made executable${NC}"

# Copy enhanced modules
echo -e "${BLUE}🔧 Installing enhanced modules...${NC}"
mkdir -p "$CONFIG_DIR/modules"
cp -r "$PARENT_DIR/pak/modules" "$CONFIG_DIR/"

# Copy configuration files
echo -e "${BLUE}⚙️  Installing configuration files...${NC}"
cp "$SCRIPT_DIR/platform-configs.json" "$CONFIG_DIR/"
cp -r "$SCRIPT_DIR/templates" "$CONFIG_DIR/"

# Generate deployment templates
echo -e "${BLUE}🔨 Generating deployment templates...${NC}"
cd "$SCRIPT_DIR"
./deploy-templates.sh

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

# Create symlink for easy access
if [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
    echo -e "${BLUE}🔗 Creating symlinks...${NC}"
    ln -sf "$INSTALL_DIR/pak" /usr/local/bin/pak
fi

# Create enhanced uninstall script
echo -e "${BLUE}🗑️  Creating uninstall script...${NC}"
cat > "$CONFIG_DIR/uninstall.sh" << EOF
#!/bin/bash
# Enhanced uninstall script for Universal Package Tracker & Deployer

set -euo pipefail

echo "🗑️  Uninstalling Enhanced Universal Package Tracker & Deployer..."

# Remove main script
rm -f "$INSTALL_DIR/pak"
rm -f /usr/local/bin/pak

# Remove configuration and data (with confirmation)
echo "⚠️  This will remove all configuration and data."
read -p "Do you want to remove configuration and data? (y/N): " -n 1 -r
echo
if [[ \$REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$CONFIG_DIR"
    rm -rf "$DATA_DIR"
    rm -rf "$LOG_DIR"
    echo "✅ All data removed."
else
    echo "📁 Configuration and data preserved at:"
    echo "   Config: $CONFIG_DIR"
    echo "   Data: $DATA_DIR"
    echo "   Logs: $LOG_DIR"
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
if command -v pak >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo -e "${CYAN}📋 Installation Summary:${NC}"
    echo -e "  📦 Main Script: $INSTALL_DIR/pak"
    echo -e "  ⚙️  Config: $CONFIG_DIR"
    echo -e "  📊 Data: $DATA_DIR"
    echo -e "  📋 Logs: $LOG_DIR"
    echo -e ""
    echo -e "${GREEN}🎉 Enhanced Universal Package Tracker & Deployer is ready!${NC}"
    echo -e ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo -e "  1. Run: ${GREEN}pak --init${NC}"
    echo -e "  2. Create package: ${GREEN}pak devex wizard${NC}"
    echo -e "  3. Security scan: ${GREEN}pak scan [package]${NC}"
    echo -e "  4. Deploy: ${GREEN}pak deploy [package] --version [version]${NC}"
    echo -e ""
    echo -e "${BLUE}🔐 Security Features:${NC}"
    echo -e "  • OWASP compliance: ${GREEN}pak compliance owasp${NC}"
    echo -e "  • Vulnerability scan: ${GREEN}pak scan${NC}"
    echo -e "  • License check: ${GREEN}pak license-check${NC}"
    echo -e ""
    echo -e "${BLUE}🤖 Automation Features:${NC}"
    echo -e "  • CI/CD pipeline: ${GREEN}pak pipeline create${NC}"
    echo -e "  • Git hooks: ${GREEN}pak hooks install${NC}"
    echo -e "  • Release: ${GREEN}pak release${NC}"
    echo -e ""
    echo -e "${BLUE}👨‍💻 DevEx Features:${NC}"
    echo -e "  • Interactive wizard: ${GREEN}pak devex wizard${NC}"
    echo -e "  • Project templates: ${GREEN}pak devex template${NC}"
    echo -e "  • Environment setup: ${GREEN}pak devex setup${NC}"
    echo -e ""
    echo -e "${BLUE}📖 Documentation: $CONFIG_DIR/README.md${NC}"
else
    echo -e "${RED}❌ Installation failed!${NC}"
    echo -e "${YELLOW}💡 Try adding $INSTALL_DIR to your PATH${NC}"
    exit 1
fi 