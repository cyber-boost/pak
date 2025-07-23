#!/bin/bash
# variables.sh - Common variables and utilities for bash scripts
# Source this file: . ./variables.sh or source ./variables.sh

# ============================================================================
# COLORS
# ============================================================================
# Regular Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[0;90m'

# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Special Effects
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'
STRIKETHROUGH='\033[9m'

# Reset
NC='\033[0m'        # No Color / Reset
RESET='\033[0m'     # Alias for NC

# ============================================================================
# UNICODE SYMBOLS
# ============================================================================
# Status symbols
CHECK_MARK="✓"
CROSS_MARK="✗"
WARNING_SIGN="⚠"
INFO_SIGN="ℹ"
QUESTION_MARK="?"
ARROW_RIGHT="→"
ARROW_LEFT="←"
BULLET="•"
STAR="★"
HEART="♥"

# Progress indicators
SPINNER_FRAMES="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_FRAMES2="◐◓◑◒"
SPINNER_FRAMES3="⣾⣽⣻⢿⡿⣟⣯⣷"
PROGRESS_FULL="█"
PROGRESS_EMPTY="░"

# Box drawing
BOX_HORIZONTAL="─"
BOX_VERTICAL="│"
BOX_TOP_LEFT="┌"
BOX_TOP_RIGHT="┐"
BOX_BOTTOM_LEFT="└"
BOX_BOTTOM_RIGHT="┘"
BOX_CROSS="┼"
BOX_T_DOWN="┬"
BOX_T_UP="┴"
BOX_T_RIGHT="├"
BOX_T_LEFT="┤"

# ============================================================================
# SYSTEM DETECTION
# ============================================================================
# Operating System
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    DISTRO=$(lsb_release -si 2>/dev/null || echo "unknown")
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    OS="unknown"
fi

# Architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_SIMPLE="64bit"
elif [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
    ARCH_SIMPLE="32bit"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    ARCH_SIMPLE="arm64"
else
    ARCH_SIMPLE="$ARCH"
fi

# User detection
IS_ROOT=$([[ $EUID -eq 0 ]] && echo "true" || echo "false")
USERNAME=$(whoami)
HOSTNAME=$(hostname)

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================
# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Status messages
print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} $*"
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} $*" >&2
}

print_warning() {
    echo -e "${YELLOW}${WARNING_SIGN}${NC} $*"
}

print_info() {
    echo -e "${BLUE}${INFO_SIGN}${NC} $*"
}

print_debug() {
    [[ "${DEBUG:-false}" == "true" ]] && echo -e "${GRAY}[DEBUG]${NC} $*" >&2
}

# Headers and sections
print_header() {
    local text="$1"
    local width=${2:-60}
    local char=${3:-"="}
    
    echo -e "\n${BOLD_BLUE}$(printf "%${width}s" | tr ' ' "$char")${NC}"
    echo -e "${BOLD_BLUE}${text}${NC}"
    echo -e "${BOLD_BLUE}$(printf "%${width}s" | tr ' ' "$char")${NC}\n"
}

print_section() {
    echo -e "\n${BOLD_CYAN}▶ $*${NC}"
}

# Progress bar
print_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' "$PROGRESS_FULL"
    printf "%$((width - filled))s" | tr ' ' "$PROGRESS_EMPTY"
    printf "] %d%%" "$percentage"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get script directory
get_script_dir() {
    echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

# Prompt for yes/no
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    
    read -r -p "$prompt " response
    response=${response,,} # to lowercase
    
    if [[ -z "$response" ]]; then
        response=$default
    fi
    
    [[ "$response" == "y" ]]
}

# Create a simple spinner
spinner() {
    local pid=$1
    local delay=${2:-0.1}
    local frames=$SPINNER_FRAMES3
    
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#frames}; i++ )); do
            printf "\r${YELLOW}%s${NC} " "${frames:$i:1}"
            sleep "$delay"
        done
    done
    printf "\r   \r" # Clear spinner
}

# ============================================================================
# COMMON PATHS
# ============================================================================
# Temporary directory with cleanup
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Log file with timestamp
LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M%S).log}"

# ============================================================================
# ERROR HANDLING
# ============================================================================
# Exit on error with message
die() {
    print_error "$*"
    exit 1
}

# Run command with error checking
run_command() {
    local cmd="$1"
    local error_msg="${2:-Command failed: $cmd}"
    
    if ! eval "$cmd"; then
        die "$error_msg"
    fi
}

# ============================================================================
# TERMINAL UTILITIES
# ============================================================================
# Get terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)

# Clear line
clear_line() {
    printf "\r\033[K"
}

# Move cursor
move_cursor_up() {
    local lines=${1:-1}
    printf "\033[${lines}A"
}

move_cursor_down() {
    local lines=${1:-1}
    printf "\033[${lines}B"
}

# ============================================================================
# FORMATTING HELPERS
# ============================================================================
# Center text
center_text() {
    local text="$1"
    local width=${2:-$TERM_WIDTH}
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# Create a horizontal line
hr() {
    local char=${1:-"─"}
    local width=${2:-$TERM_WIDTH}
    printf "%${width}s\n" | tr ' ' "$char"
}

# ============================================================================
# VERSION INFO
# ============================================================================
VARIABLES_VERSION="1.0.0"
VARIABLES_LOADED=true

# Show that variables.sh is loaded (optional)
[[ "${QUIET:-false}" != "true" ]] && print_debug "variables.sh v${VARIABLES_VERSION} loaded"