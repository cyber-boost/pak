#!/bin/bash
# PAK - Package Automation Kit Installation Script
# Comprehensive installation and setup script

set -euo pipefail

# Script metadata
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="PAK Installer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation variables
INSTALL_DIR="${PAK_INSTALL_DIR:-/opt/pak}"
BIN_DIR="${PAK_BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${PAK_CONFIG_DIR:-/etc/pak}"
DATA_DIR="${PAK_DATA_DIR:-/var/lib/pak}"
LOG_DIR="${PAK_LOG_DIR:-/var/log/pak}"
USER="${PAK_USER:-pak}"
GROUP="${PAK_GROUP:-pak}"

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAK_DIR="$(dirname "$SCRIPT_DIR")"

# Installation state
INSTALL_STEPS=()
CURRENT_STEP=0

# Logging
LOG_FILE="/tmp/pak-install.log"

# Initialize logging
init_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "=== PAK Installation Log ===" | tee -a "$LOG_FILE"
    echo "Started: $(date)" | tee -a "$LOG_FILE"
    echo "Version: $SCRIPT_VERSION" | tee -a "$LOG_FILE"
    echo "Install Directory: $INSTALL_DIR" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Progress tracking
start_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local step_name="$1"
    INSTALL_STEPS+=("$step_name")
    log_info "Step $CURRENT_STEP: $step_name"
}

complete_step() {
    local step_name="${INSTALL_STEPS[-1]}"
    log_success "Completed: $step_name"
}

# System detection
detect_system() {
    log_info "Detecting system information..."
    
    # OS detection
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_ID="$ID"
    else
        OS_NAME=$(uname -s)
        OS_VERSION=$(uname -r)
        OS_ID="unknown"
    fi
    
    # Architecture detection
    ARCH=$(uname -m)
    
    # Package manager detection
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    elif command -v brew &>/dev/null; then
        PKG_MANAGER="brew"
    else
        PKG_MANAGER="unknown"
    fi
    
    log_info "System: $OS_NAME $OS_VERSION ($OS_ID)"
    log_info "Architecture: $ARCH"
    log_info "Package Manager: $PKG_MANAGER"
}

# Prerequisites check
check_prerequisites() {
    start_step "Checking prerequisites"
    
    local missing_deps=()
    
    # Check for required commands
    local required_commands=("bash" "curl" "wget" "tar" "gzip")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for optional but recommended commands
    local recommended_commands=("jq" "git" "docker" "node" "python3")
    for cmd in "${recommended_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_warn "Recommended command not found: $cmd"
        fi
    done
    
    # Check bash version
    local bash_version=$(bash --version | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    local bash_major="${bash_version%%.*}"
    if [[ $bash_major -lt 4 ]]; then
        log_error "Bash 4.0 or higher required (current: $bash_version)"
        missing_deps+=("bash>=4.0")
    fi
    
    # Check for missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and run the installer again"
        return 1
    fi
    
    log_success "All prerequisites satisfied"
    complete_step
}

# User and group creation
create_user_group() {
    start_step "Creating user and group"
    
    # Create group if it doesn't exist
    if ! getent group "$GROUP" &>/dev/null; then
        log_info "Creating group: $GROUP"
        groupadd -r "$GROUP" 2>/dev/null || log_warn "Failed to create group (may already exist)"
    fi
    
    # Create user if it doesn't exist
    if ! getent passwd "$USER" &>/dev/null; then
        log_info "Creating user: $USER"
        useradd -r -g "$GROUP" -d "$DATA_DIR" -s /bin/bash "$USER" 2>/dev/null || log_warn "Failed to create user (may already exist)"
    fi
    
    complete_step
}

# Directory creation
create_directories() {
    start_step "Creating directories"
    
    # Create main installation directory
    log_info "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # Create system directories
    local system_dirs=(
        "$BIN_DIR"
        "$CONFIG_DIR"
        "$DATA_DIR"
        "$LOG_DIR"
    )
    
    for dir in "${system_dirs[@]}"; do
        log_info "Creating directory: $dir"
        mkdir -p "$dir"
    done
    
    # Set ownership
    log_info "Setting ownership to $USER:$GROUP"
    chown -R "$USER:$GROUP" "$INSTALL_DIR" "$DATA_DIR" "$LOG_DIR"
    
    # Set permissions
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$BIN_DIR"
    chmod 750 "$CONFIG_DIR"
    chmod 750 "$DATA_DIR"
    chmod 750 "$LOG_DIR"
    
    complete_step
}

# Copy files
copy_files() {
    start_step "Copying PAK files"
    
    # Copy main PAK directory
    log_info "Copying PAK files to $INSTALL_DIR"
    cp -r "$PAK_DIR"/* "$INSTALL_DIR/"
    
    # Make main script executable
    chmod +x "$INSTALL_DIR/pak.sh"
    
    # Create symlink in bin directory
    log_info "Creating symlink: $BIN_DIR/pak -> $INSTALL_DIR/pak.sh"
    ln -sf "$INSTALL_DIR/pak.sh" "$BIN_DIR/pak"
    
    # Set ownership
    chown -R "$USER:$GROUP" "$INSTALL_DIR"
    
    complete_step
}

# Install dependencies
install_dependencies() {
    start_step "Installing dependencies"
    
    case "$PKG_MANAGER" in
        apt)
            install_dependencies_apt
            ;;
        yum|dnf)
            install_dependencies_yum
            ;;
        pacman)
            install_dependencies_pacman
            ;;
        brew)
            install_dependencies_brew
            ;;
        *)
            log_warn "Unknown package manager: $PKG_MANAGER"
            log_info "Please install dependencies manually"
            ;;
    esac
    
    complete_step
}

install_dependencies_apt() {
    log_info "Installing dependencies via apt..."
    
    # Update package list
    apt-get update
    
    # Install required packages
    apt-get install -y \
        curl \
        wget \
        jq \
        git \
        build-essential \
        python3 \
        python3-pip \
        nodejs \
        npm
}

install_dependencies_yum() {
    log_info "Installing dependencies via yum/dnf..."
    
    # Install required packages
    if command -v dnf &>/dev/null; then
        dnf install -y \
            curl \
            wget \
            jq \
            git \
            gcc \
            python3 \
            python3-pip \
            nodejs \
            npm
    else
        yum install -y \
            curl \
            wget \
            jq \
            git \
            gcc \
            python3 \
            python3-pip \
            nodejs \
            npm
    fi
}

install_dependencies_pacman() {
    log_info "Installing dependencies via pacman..."
    
    pacman -S --noconfirm \
        curl \
        wget \
        jq \
        git \
        base-devel \
        python \
        python-pip \
        nodejs \
        npm
}

install_dependencies_brew() {
    log_info "Installing dependencies via brew..."
    
    brew install \
        curl \
        wget \
        jq \
        git \
        python3 \
        node
}

# Configuration setup
setup_configuration() {
    start_step "Setting up configuration"
    
    # Copy default configuration
    if [[ ! -f "$CONFIG_DIR/pak.conf" ]]; then
        log_info "Creating default configuration: $CONFIG_DIR/pak.conf"
        cp "$INSTALL_DIR/config/pak.conf" "$CONFIG_DIR/pak.conf"
        
        # Update paths in configuration
        sed -i "s|PAK_DATA_DIR=.*|PAK_DATA_DIR=\"$DATA_DIR\"|g" "$CONFIG_DIR/pak.conf"
        sed -i "s|PAK_LOGS_DIR=.*|PAK_LOGS_DIR=\"$LOG_DIR\"|g" "$CONFIG_DIR/pak.conf"
        sed -i "s|PAK_CONFIG_DIR=.*|PAK_CONFIG_DIR=\"$CONFIG_DIR\"|g" "$CONFIG_DIR/pak.conf"
    else
        log_info "Configuration already exists: $CONFIG_DIR/pak.conf"
    fi
    
    # Set ownership
    chown "$USER:$GROUP" "$CONFIG_DIR/pak.conf"
    chmod 640 "$CONFIG_DIR/pak.conf"
    
    complete_step
}

# Service setup
setup_service() {
    start_step "Setting up system service"
    
    # Create systemd service file
    local service_file="/etc/systemd/system/pak.service"
    
    if [[ ! -f "$service_file" ]]; then
        log_info "Creating systemd service: $service_file"
        
        cat > "$service_file" << EOF
[Unit]
Description=PAK - Package Automation Kit
After=network.target

[Service]
Type=simple
User=$USER
Group=$GROUP
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/pak.sh daemon
Restart=always
RestartSec=10
Environment=PAK_CONFIG_DIR=$CONFIG_DIR
Environment=PAK_DATA_DIR=$DATA_DIR
Environment=PAK_LOGS_DIR=$LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
        
        # Reload systemd
        systemctl daemon-reload
        
        # Enable service
        systemctl enable pak.service
        
        log_success "Service created and enabled"
    else
        log_info "Service already exists: $service_file"
    fi
    
    complete_step
}

# Security setup
setup_security() {
    start_step "Setting up security"
    
    # Create SSL certificates directory
    mkdir -p "$CONFIG_DIR/ssl"
    chown "$USER:$GROUP" "$CONFIG_DIR/ssl"
    chmod 750 "$CONFIG_DIR/ssl"
    
    # Set up firewall rules (if firewalld is available)
    if command -v firewall-cmd &>/dev/null; then
        log_info "Configuring firewall rules"
        firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || log_warn "Failed to add firewall rule"
        firewall-cmd --reload 2>/dev/null || log_warn "Failed to reload firewall"
    fi
    
    # Set up SELinux context (if SELinux is enabled)
    if command -v semanage &>/dev/null && sestatus 2>/dev/null | grep -q "enabled"; then
        log_info "Configuring SELinux context"
        semanage fcontext -a -t bin_t "$INSTALL_DIR/pak.sh" 2>/dev/null || log_warn "Failed to set SELinux context"
        restorecon -v "$INSTALL_DIR/pak.sh" 2>/dev/null || log_warn "Failed to restore SELinux context"
    fi
    
    complete_step
}

# Validation
validate_installation() {
    start_step "Validating installation"
    
    local errors=0
    
    # Check if main script exists and is executable
    if [[ ! -f "$INSTALL_DIR/pak.sh" ]]; then
        log_error "Main script not found: $INSTALL_DIR/pak.sh"
        ((errors++))
    elif [[ ! -x "$INSTALL_DIR/pak.sh" ]]; then
        log_error "Main script not executable: $INSTALL_DIR/pak.sh"
        ((errors++))
    fi
    
    # Check if symlink exists
    if [[ ! -L "$BIN_DIR/pak" ]]; then
        log_error "Symlink not found: $BIN_DIR/pak"
        ((errors++))
    fi
    
    # Check if configuration exists
    if [[ ! -f "$CONFIG_DIR/pak.conf" ]]; then
        log_error "Configuration not found: $CONFIG_DIR/pak.conf"
        ((errors++))
    fi
    
    # Test PAK command
    if command -v pak &>/dev/null; then
        log_info "Testing PAK command..."
        if pak version &>/dev/null; then
            log_success "PAK command working correctly"
        else
            log_error "PAK command failed"
            ((errors++))
        fi
    else
        log_error "PAK command not found in PATH"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Installation validation passed"
    else
        log_error "Installation validation failed with $errors errors"
        return 1
    fi
    
    complete_step
}

# Post-installation setup
post_install_setup() {
    start_step "Post-installation setup"
    
    # Initialize PAK
    log_info "Initializing PAK system..."
    if sudo -u "$USER" pak init; then
        log_success "PAK system initialized"
    else
        log_warn "PAK initialization failed (may need manual setup)"
    fi
    
    # Create initial backup
    log_info "Creating initial backup..."
    if sudo -u "$USER" pak backup create; then
        log_success "Initial backup created"
    else
        log_warn "Initial backup failed"
    fi
    
    complete_step
}

# Cleanup
cleanup() {
    start_step "Cleaning up"
    
    # Remove temporary files
    rm -f /tmp/pak-install-*
    
    # Clear package cache (if applicable)
    case "$PKG_MANAGER" in
        apt)
            apt-get clean
            ;;
        yum|dnf)
            yum clean all 2>/dev/null || dnf clean all 2>/dev/null
            ;;
        pacman)
            pacman -Sc --noconfirm
            ;;
    esac
    
    complete_step
}

# Installation summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "PAK Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Installation Details:"
    echo "  Version: $SCRIPT_VERSION"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Configuration: $CONFIG_DIR"
    echo "  Data Directory: $DATA_DIR"
    echo "  Log Directory: $LOG_DIR"
    echo "  User: $USER"
    echo "  Group: $GROUP"
    echo ""
    echo "Next Steps:"
    echo "  1. Configure PAK: pak config edit"
    echo "  2. Check status: pak status"
    echo "  3. Run health check: pak health"
    echo "  4. Start service: sudo systemctl start pak"
    echo "  5. View logs: sudo journalctl -u pak -f"
    echo ""
    echo "Documentation:"
    echo "  - Configuration: $CONFIG_DIR/pak.conf"
    echo "  - Logs: $LOG_DIR"
    echo "  - Data: $DATA_DIR"
    echo ""
    echo "Support:"
    echo "  - Installation log: $LOG_FILE"
    echo "  - Command help: pak --help"
    echo ""
}

# Main installation function
main() {
    echo "=========================================="
    echo "PAK - Package Automation Kit Installer"
    echo "Version: $SCRIPT_VERSION"
    echo "=========================================="
    echo ""
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Initialize logging
    init_logging
    
    # Detect system
    detect_system
    
    # Run installation steps
    check_prerequisites
    create_user_group
    create_directories
    copy_files
    install_dependencies
    setup_configuration
    setup_service
    setup_security
    validate_installation
    post_install_setup
    cleanup
    
    # Show summary
    show_summary
    
    log_success "Installation completed successfully!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "PAK Installer - Usage:"
        echo "  $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version, -v  Show version information"
        echo "  --uninstall    Uninstall PAK"
        echo "  --upgrade      Upgrade existing installation"
        echo ""
        echo "Environment Variables:"
        echo "  PAK_INSTALL_DIR  Installation directory (default: /opt/pak)"
        echo "  PAK_BIN_DIR      Binary directory (default: /usr/local/bin)"
        echo "  PAK_CONFIG_DIR   Configuration directory (default: /etc/pak)"
        echo "  PAK_DATA_DIR     Data directory (default: /var/lib/pak)"
        echo "  PAK_LOG_DIR      Log directory (default: /var/log/pak)"
        echo "  PAK_USER         User name (default: pak)"
        echo "  PAK_GROUP        Group name (default: pak)"
        exit 0
        ;;
    --version|-v)
        echo "PAK Installer version $SCRIPT_VERSION"
        exit 0
        ;;
    --uninstall)
        # TODO: Implement uninstall functionality
        echo "Uninstall functionality not yet implemented"
        exit 1
        ;;
    --upgrade)
        # TODO: Implement upgrade functionality
        echo "Upgrade functionality not yet implemented"
        exit 1
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 