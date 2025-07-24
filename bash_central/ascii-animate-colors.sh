#!/bin/bash
# ascii-combo.sh - Create ASCII art combinations and scenes
# Author: Tusk Lang Team
# Date: 2025-07-13

# Source the main ascii.sh for functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/ascii.sh" 2>/dev/null || {
    echo "Error: ascii.sh not found in $SCRIPT_DIR"
    exit 1
}

# ============================================================================
# COMBO DEFINITIONS
# ============================================================================
declare -A COMBOS=(
    [welcome]="tusk:bold-cyan banner:yellow"
    [elephant-party]="unity:green dance:cyan elder:purple"
    [tusk-full]="tusk:bold-blue peanut:yellow ivory:cyan"
    [peaceful]="peace:bold-green unity:cyan"
    [fun]="dance:rainbow pooping:yellow turd-sm:brown"
)

declare -A COMBO_DESC=(
    [welcome]="Welcome screen with TUSK logo and banner"
    [elephant-party]="Multiple elephants in different colors"
    [tusk-full]="Complete TUSK branding display"
    [peaceful]="Peaceful elephant scene"
    [fun]="Fun and humorous display"
)

# ============================================================================
# SCENES
# ============================================================================
show_loading_scene() {
    clear
    echo -e "${BOLD_CYAN}Loading Tusk Language...${NC}\n"
    
    # Show small turd spinning
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local art_file="$ASCII_DIR/${ASCII_FILES[turd-sm]}"
    
    for i in {1..20}; do
        clear
        echo -e "${BOLD_CYAN}Loading Tusk Language ${frames[$((i % ${#frames[@]}))]}${NC}\n"
        display_art "$art_file" "$YELLOW"
        sleep 0.1
    done
    
    clear
    echo -e "${BOLD_GREEN}✓ Loaded!${NC}\n"
    sleep 0.5
}

show_elephant_walk() {
    # Animate elephant walking across screen
    local width=$(get_term_width)
    local art_file="$ASCII_DIR/${ASCII_FILES[dance]}"
    local position=0
    
    # Read art into array
    mapfile -t art_lines < "$art_file"
    
    # Walk across screen
    while [[ $position -lt $((width - 40)) ]]; do
        clear
        echo -e "\n\n"
        
        for line in "${art_lines[@]}"; do
            printf "%${position}s" ""
            echo -e "${CYAN}${line}${NC}"
        done
        
        ((position += 2))
        sleep 0.05
    done
}

show_rainbow_banner() {
    local banner_file="$ASCII_DIR/${ASCII_FILES[banner]}"
    
    if [[ ! -f "$banner_file" ]]; then
        echo "Banner file not found"
        return
    fi
    
    # Cycle through rainbow colors
    local colors=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$PURPLE")
    
    for i in {1..10}; do
        clear
        local color="${colors[$((i % ${#colors[@]}))]}"
        display_art "$banner_file" "$color"
        sleep 0.3
    done
}

# ============================================================================
# COMBO DISPLAY
# ============================================================================
display_combo() {
    local combo_name="$1"
    local combo_string="${COMBOS[$combo_name]}"
    
    if [[ -z "$combo_string" ]]; then
        echo "Error: Unknown combo: $combo_name" >&2
        return 1
    fi
    
    echo -e "${BOLD_CYAN}=== ${combo_name^^} ===${NC}\n"
    
    # Parse combo string
    for item in $combo_string; do
        IFS=':' read -r art color <<< "$item"
        
        if [[ -n "${ASCII_FILES[$art]:-}" ]]; then
            local art_file="$ASCII_DIR/${ASCII_FILES[$art]}"
            local color_code="${COLOR_THEMES[$color]:-$NC}"
            
            echo -e "\n${DIM}--- $art ---${NC}\n"
            display_art "$art_file" "$color_code"
            echo ""
            
            sleep 0.5
        fi
    done
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================
interactive_mode() {
    while true; do
        clear
        echo -e "${BOLD_CYAN}Tusk ASCII Art Gallery${NC}\n"
        echo "Select an option:"
        echo ""
        echo "1) Display single art"
        echo "2) Show art combo"
        echo "3) Loading animation"
        echo "4) Elephant walk"
        echo "5) Rainbow banner"
        echo "6) Exit"
        echo ""
        
        read -p "Choice (1-6): " choice
        
        case $choice in
            1)
                echo ""
                echo "Available art:"
                for name in "${!ASCII_FILES[@]}"; do
                    echo "  - $name"
                done | sort
                echo ""
                read -p "Enter art name: " art_name
                read -p "Enter color (default/red/green/blue/etc): " color
                
                clear
                display_art "$ASCII_DIR/${ASCII_FILES[$art_name]}" "${COLOR_THEMES[$color]:-$NC}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "Available combos:"
                for name in "${!COMBOS[@]}"; do
                    echo "  - $name: ${COMBO_DESC[$name]}"
                done
                echo ""
                read -p "Enter combo name: " combo_name
                
                clear
                display_combo "$combo_name"
                read -p "Press Enter to continue..."
                ;;
            3)
                show_loading_scene
                read -p "Press Enter to continue..."
                ;;
            4)
                show_elephant_walk
                read -p "Press Enter to continue..."
                ;;
            5)
                show_rainbow_banner
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# USAGE
# ============================================================================
combo_usage() {
    cat << EOF
${BOLD_CYAN}ASCII Art Combo Tool${NC}

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS] [COMBO_NAME]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -l, --list              List available combos
    -i, --interactive       Interactive mode
    -s, --scene SCENE       Show predefined scene
                           (loading, walk, rainbow)

${BOLD}AVAILABLE COMBOS:${NC}
EOF
    for name in "${!COMBOS[@]}"; do
        printf "    %-20s - %s\n" "$name" "${COMBO_DESC[$name]}"
    done

    cat << EOF

${BOLD}EXAMPLES:${NC}
    # Show welcome combo
    $(basename "$0") welcome
    
    # Interactive mode
    $(basename "$0") -i
    
    # Show loading scene
    $(basename "$0") -s loading

EOF
}

# ============================================================================
# MAIN
# ============================================================================
case "${1:-}" in
    -h|--help)
        combo_usage
        ;;
    -l|--list)
        echo -e "${BOLD_CYAN}Available Combos:${NC}\n"
        for name in "${!COMBOS[@]}"; do
            printf "%-20s - %s\n" "$name" "${COMBO_DESC[$name]}"
        done
        ;;
    -i|--interactive)
        interactive_mode
        ;;
    -s|--scene)
        case "${2:-}" in
            loading) show_loading_scene ;;
            walk) show_elephant_walk ;;
            rainbow) show_rainbow_banner ;;
            *) echo "Unknown scene: ${2:-}" ;;
        esac
        ;;
    "")
        combo_usage
        ;;
    *)
        display_combo "$1"
        ;;
esac