#!/bin/bash
# ascii.sh - Display ASCII art with color options
# Author: Tusk Lang Team
# Date: 2025-07-13

# ============================================================================
# SETUP
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source variables if available
if [[ -f "$SCRIPT_DIR/variables.sh" ]]; then
    source "$SCRIPT_DIR/variables.sh"
else
    # Define colors if variables.sh not found
    BLACK='\033[0;30m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    GRAY='\033[0;90m'
    
    BOLD_RED='\033[1;31m'
    BOLD_GREEN='\033[1;32m'
    BOLD_YELLOW='\033[1;33m'
    BOLD_BLUE='\033[1;34m'
    BOLD_PURPLE='\033[1;35m'
    BOLD_CYAN='\033[1;36m'
    BOLD_WHITE='\033[1;37m'
    
    BOLD='\033[1m'
    DIM='\033[2m'
    ITALIC='\033[3m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    
    NC='\033[0m'
    RESET='\033[0m'
fi

# ============================================================================
# CONFIGURATION
# ============================================================================
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0.0"

# ASCII art directory (same as script directory or specify custom path)
ASCII_DIR="${ASCII_DIR:-$SCRIPT_DIR}"

# Available ASCII art files
declare -A ASCII_FILES=(
    [tusk]="tusk-letters.txt"
    [dance]="dance.txt"
    [banner]="banner.txt"
    [turd-lg]="turd-lg.txt"
    [turd-sm]="turd-sm.txt"
    [pooping]="pooping.txt"
    [peanut]="peanu-tsk.txt"
    [peace]="peace.txt"
    [unity]="unity.txt"
    [ivory]="ivory.txt"
    [elder]="elder.txt"
)

# ASCII art descriptions
declare -A ASCII_DESC=(
    [tusk]="TUSK logo"
    [dance]="Dancing elephant"
    [banner]="Tusk banner with info"
    [turd-lg]="Large decorative element"
    [turd-sm]="Small decorative element"
    [pooping]="Humorous figure"
    [peanut]="Peanut-shaped TSK logo"
    [peace]="Peace sign"
    [unity]="Two elephants together"
    [ivory]="Detailed elephant art"
    [elder]="Elder elephant"
)

# Color themes
declare -A COLOR_THEMES=(
    [default]="$NC"
    [red]="$RED"
    [green]="$GREEN"
    [blue]="$BLUE"
    [yellow]="$YELLOW"
    [cyan]="$CYAN"
    [purple]="$PURPLE"
    [gray]="$GRAY"
    [bold-red]="$BOLD_RED"
    [bold-green]="$BOLD_GREEN"
    [bold-blue]="$BOLD_BLUE"
    [bold-yellow]="$BOLD_YELLOW"
    [bold-cyan]="$BOLD_CYAN"
    [bold-purple]="$BOLD_PURPLE"
    [bold-white]="$BOLD_WHITE"
)

# Default values
ART_NAME=""
COLOR_THEME="default"
ANIMATE=false
RAINBOW=false
CENTER=false
DELAY=0.05
LIST_MODE=false
RANDOM_MODE=false

# ============================================================================
# USAGE
# ============================================================================
usage() {
    cat << EOF
${BOLD_CYAN}ASCII Art Display Tool${NC} v${SCRIPT_VERSION}

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [ART_NAME]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -l, --list              List available ASCII art
    -c, --color COLOR       Set color (red, green, blue, yellow, cyan, purple, gray)
    -b, --bold              Use bold colors
    -a, --animate           Animate the display (line by line)
    -r, --rainbow           Rainbow color effect
    -C, --center            Center the ASCII art
    -d, --delay SECONDS     Animation delay (default: 0.05)
    -R, --random            Display random ASCII art

${BOLD}AVAILABLE ART:${NC}
EOF
    for name in "${!ASCII_FILES[@]}"; do
        printf "    %-15s - %s\n" "$name" "${ASCII_DESC[$name]}"
    done | sort

    cat << EOF

${BOLD}COLOR THEMES:${NC}
    default, red, green, blue, yellow, cyan, purple, gray
    bold-red, bold-green, bold-blue, bold-yellow, bold-cyan, bold-purple

${BOLD}EXAMPLES:${NC}
    # Display TUSK logo in blue
    $SCRIPT_NAME -c blue tusk
    
    # Animate elephant dance in bold cyan
    $SCRIPT_NAME -c bold-cyan -a dance
    
    # Rainbow effect on banner
    $SCRIPT_NAME -r banner
    
    # Center the peace sign
    $SCRIPT_NAME -C peace
    
    # Random art with animation
    $SCRIPT_NAME -R -a

EOF
}

# ============================================================================
# FUNCTIONS
# ============================================================================

# Get terminal width
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

# Center text
center_line() {
    local line="$1"
    local width=$(get_term_width)
    # Remove ANSI codes for length calculation
    local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#clean_line}
    local padding=$(( (width - len) / 2 ))
    
    if [[ $padding -gt 0 ]]; then
        printf "%${padding}s%s\n" "" "$line"
    else
        echo "$line"
    fi
}

# Rainbow colors
get_rainbow_color() {
    local index=$1
    local colors=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$PURPLE")
    echo "${colors[$((index % ${#colors[@]}))]}"
}

# Display ASCII art
display_art() {
    local file="$1"
    local color="${2:-$NC}"
    
    if [[ ! -f "$file" ]]; then
        echo "Error: ASCII art file not found: $file" >&2
        return 1
    fi
    
    # Read file into array
    mapfile -t lines < "$file"
    
    # Display based on options
    if [[ "$ANIMATE" == true ]]; then
        # Animated display
        for i in "${!lines[@]}"; do
            if [[ "$RAINBOW" == true ]]; then
                color=$(get_rainbow_color $i)
            fi
            
            if [[ "$CENTER" == true ]]; then
                center_line "${color}${lines[$i]}${NC}"
            else
                echo -e "${color}${lines[$i]}${NC}"
            fi
            
            sleep "$DELAY"
        done
    elif [[ "$RAINBOW" == true ]]; then
        # Rainbow display (no animation)
        for i in "${!lines[@]}"; do
            color=$(get_rainbow_color $i)
            if [[ "$CENTER" == true ]]; then
                center_line "${color}${lines[$i]}${NC}"
            else
                echo -e "${color}${lines[$i]}${NC}"
            fi
        done
    else
        # Normal display
        if [[ "$CENTER" == true ]]; then
            while IFS= read -r line; do
                center_line "${color}${line}${NC}"
            done < "$file"
        else
            echo -e "${color}$(cat "$file")${NC}"
        fi
    fi
}

# List available ASCII art
list_art() {
    echo -e "${BOLD_CYAN}Available ASCII Art:${NC}\n"
    
    printf "%-15s %-30s %s\n" "NAME" "DESCRIPTION" "FILE"
    printf "%-15s %-30s %s\n" "----" "-----------" "----"
    
    for name in "${!ASCII_FILES[@]}"; do
        local file="${ASCII_FILES[$name]}"
        local desc="${ASCII_DESC[$name]}"
        
        if [[ -f "$ASCII_DIR/$file" ]]; then
            printf "%-15s %-30s %s\n" "$name" "$desc" "$file"
        else
            printf "%-15s %-30s %s ${RED}(missing)${NC}\n" "$name" "$desc" "$file"
        fi
    done | sort
}

# Get random art name
get_random_art() {
    local names=("${!ASCII_FILES[@]}")
    local random_index=$((RANDOM % ${#names[@]}))
    echo "${names[$random_index]}"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -l|--list)
                LIST_MODE=true
                shift
                ;;
            -c|--color)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --color requires an argument" >&2
                    exit 1
                fi
                COLOR_THEME="$2"
                shift 2
                ;;
            -b|--bold)
                # Prepend bold to current color theme if not already bold
                if [[ ! "$COLOR_THEME" =~ ^bold- ]]; then
                    COLOR_THEME="bold-${COLOR_THEME}"
                fi
                shift
                ;;
            -a|--animate)
                ANIMATE=true
                shift
                ;;
            -r|--rainbow)
                RAINBOW=true
                shift
                ;;
            -C|--center)
                CENTER=true
                shift
                ;;
            -d|--delay)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --delay requires an argument" >&2
                    exit 1
                fi
                DELAY="$2"
                shift 2
                ;;
            -R|--random)
                RANDOM_MODE=true
                shift
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                ART_NAME="$1"
                shift
                ;;
        esac
    done
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    # List mode
    if [[ "$LIST_MODE" == true ]]; then
        list_art
        exit 0
    fi
    
    # Random mode
    if [[ "$RANDOM_MODE" == true ]]; then
        ART_NAME=$(get_random_art)
        echo -e "${DIM}Displaying random art: ${ITALIC}$ART_NAME${NC}\n"
    fi
    
    # Check if art name provided
    if [[ -z "$ART_NAME" ]]; then
        echo "Error: No ASCII art specified" >&2
        echo "Use -l to list available art or -R for random" >&2
        exit 1
    fi
    
    # Check if art exists
    if [[ -z "${ASCII_FILES[$ART_NAME]:-}" ]]; then
        echo "Error: Unknown ASCII art: $ART_NAME" >&2
        echo "Use -l to list available art" >&2
        exit 1
    fi
    
    # Get file path
    local art_file="$ASCII_DIR/${ASCII_FILES[$ART_NAME]}"
    
    # Get color
    local color="${COLOR_THEMES[$COLOR_THEME]:-$NC}"
    
    # Display the art
    display_art "$art_file" "$color"
}

# ============================================================================
# SPECIAL FUNCTIONS
# ============================================================================

# Easter egg: Matrix effect with Tusk art
matrix_tusk() {
    local art_file="$ASCII_DIR/${ASCII_FILES[tusk]}"
    if [[ ! -f "$art_file" ]]; then
        return
    fi
    
    clear
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done < "$art_file"
    
    # Matrix rain effect
    for i in {1..20}; do
        clear
        for line in "${lines[@]}"; do
            # Random green shades
            local shade=$((RANDOM % 3))
            case $shade in
                0) color="$GREEN" ;;
                1) color="$BOLD_GREEN" ;;
                2) color="$DIM$GREEN" ;;
            esac
            echo -e "${color}${line}${NC}"
        done
        sleep 0.1
    done
}

# Check for easter eggs
if [[ "${1:-}" == "matrix" ]]; then
    matrix_tusk
    exit 0
fi

# ============================================================================
# ENTRY POINT
# ============================================================================
parse_args "$@"
main