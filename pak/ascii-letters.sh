#!/bin/bash
# PAK.sh Dynamic ASCII Letter System
# Each letter is defined as 6 rows that can be combined to build any word

# Row 1 (Top)
A_ROW1=" █████╗     "
B_ROW1="██████╗     "
C_ROW1=" ██████╗    "
D_ROW1="██████╗     "
E_ROW1="███████╗    "
F_ROW1="███████╗    "
G_ROW1=" ██████╗    "
H_ROW1="██╗  ██╗    "
I_ROW1="██╗         "
J_ROW1="     ██╗    "
K_ROW1="██╗  ██╗    "
L_ROW1="██╗         "
M_ROW1="███╗   ███╗ "
N_ROW1="███╗   ██╗  "
O_ROW1=" ██████╗    "
P_ROW1="██████╗     "
Q_ROW1=" ██████╗    "
R_ROW1="██████╗     "
S_ROW1=" ██████╗    "
T_ROW1="████████╗   "
U_ROW1="██╗   ██╗   "
V_ROW1="██╗   ██╗   "
W_ROW1="██╗    ██╗  "
X_ROW1="██╗  ██╗    "
Y_ROW1="██╗   ██╗   "
Z_ROW1="███████╗    "

# Row 2
A_ROW2="██╔══██╗    "
B_ROW2="██╔══██╗    "
C_ROW2="██╔════╝    "
D_ROW2="██╔══██╗    "
E_ROW2="██╔════╝    "
F_ROW2="██╔════╝    "
G_ROW2="██╔════╝    "
H_ROW2="██║  ██║    "
I_ROW2="██║         "
J_ROW2="     ██║    "
K_ROW2="██║ ██╔╝    "
L_ROW2="██║         "
M_ROW2="████╗ ████║ "
N_ROW2="████╗  ██║  "
O_ROW2="██╔═══██╗    "
P_ROW2="██╔══██╗    "
Q_ROW2="██╔═══██╗    "
R_ROW2="██╔══██╗    "
S_ROW2="██╔════╝    "
T_ROW2="╚══██╔══╝    "
U_ROW2="██║   ██║   "
V_ROW2="██║   ██║   "
W_ROW2="██║    ██║  "
X_ROW2="╚██╗██╔╝    "
Y_ROW2="╚██╗ ██╔╝   "
Z_ROW2="╚══███╔╝    "

# Row 3
A_ROW3="███████║    "
B_ROW3="██████╔╝    "
C_ROW3="██║         "
D_ROW3="██║  ██║    "
E_ROW3="█████╗      "
F_ROW3="█████╗      "
G_ROW3="██║  ███╗   "
H_ROW3="██████║    "
I_ROW3="██║         "
J_ROW3="     ██║    "
K_ROW3="████╔╝     "
L_ROW3="██║         "
M_ROW3="██╔████╔██║ "
N_ROW3="██╔██╗ ██║  "
O_ROW3="██║   ██║    "
P_ROW3="██████╔╝    "
Q_ROW3="██║   ██║    "
R_ROW3="██████╔╝    "
S_ROW3="███████╗    "
T_ROW3="   ██║      "
U_ROW3="██║   ██║   "
V_ROW3="╚██╗ ██╔╝   "
W_ROW3="██║ █╗ ██║  "
X_ROW3=" ╚███╔╝     "
Y_ROW3=" ╚████╔╝    "
Z_ROW3="  ███╔╝     "

# Row 4
A_ROW4="██╔══██║    "
B_ROW4="██╔══██╗    "
C_ROW4="██║         "
D_ROW4="██║  ██║    "
E_ROW4="██╔══╝      "
F_ROW4="██╔══╝      "
G_ROW4="██║   ██║   "
H_ROW4="██╔══██║    "
I_ROW4="██║         "
J_ROW4="██╗  ██║    "
K_ROW4="██╔═██╗     "
L_ROW4="██║         "
M_ROW4="██║╚██╔╝██║ "
N_ROW4="██║╚██╗██║  "
O_ROW4="██║   ██║    "
P_ROW4="██╔═══╝     "
Q_ROW4="╚██╗██╔╝    "
R_ROW4="██╔══██╗    "
S_ROW4="╚════██║    "
T_ROW4="   ██║      "
U_ROW4="██║   ██║   "
V_ROW4=" ╚██╔╝      "
W_ROW4="██║███╗██║  "
X_ROW4=" ███╔╝      "
Y_ROW4="  ╚██╔╝     "
Z_ROW4=" ██╔═██╗    "

# Row 5
A_ROW5="██║  ██║    "
B_ROW5="██████╔╝    "
C_ROW5="╚██████╗    "
D_ROW5="╚██████╔╝   "
E_ROW5="███████╗    "
F_ROW5="███████╗    "
G_ROW5="╚██████╔╝   "
H_ROW5="██║  ██║    "
I_ROW5="██║         "
J_ROW5="╚█████╔╝    "
K_ROW5="██║  ██╗    "
L_ROW5="╚██████╗    "
M_ROW5="██║ ╚═╝ ██║ "
N_ROW5="██║ ╚████║  "
O_ROW5="╚██████╔╝   "
P_ROW5="██║         "
Q_ROW5=" ╚═╝██╔╝    "
R_ROW5="██║  ██║    "
S_ROW5="██████╔╝    "
T_ROW5="   ██║      "
U_ROW5="╚██████╔╝   "
V_ROW5="   ██║      "
W_ROW5="╚███╔███╔╝  "
X_ROW5="██╔╝ ██╗    "
Y_ROW5="   ██║      "
Z_ROW5="███████╗    "

# Row 6 (Bottom)
A_ROW6="╚═╝  ╚═╝    "
B_ROW6="╚═════╝     "
C_ROW6=" ╚═════╝    "
D_ROW6=" ╚═════╝    "
E_ROW6="╚══════╝    "
F_ROW6="╚══════╝    "
G_ROW6=" ╚═════╝    "
H_ROW6="╚═╝  ╚═╝    "
I_ROW6="╚═╝         "
J_ROW6=" ╚════╝     "
K_ROW6="╚═╝  ╚═╝    "
L_ROW6="╚══════╝    "
M_ROW6="╚═╝     ╚═╝ "
N_ROW6="╚═╝  ╚═══╝  "
O_ROW6=" ╚═════╝    "
P_ROW6="╚═╝         "
Q_ROW6="    ╚═╝     "
R_ROW6="╚═╝  ╚═╝    "
S_ROW6="╚═════╝     "
T_ROW6="   ╚═╝      "
U_ROW6=" ╚═════╝    "
V_ROW6="   ╚═╝      "
W_ROW6=" ╚══╝╚══╝   "
X_ROW6="╚═╝  ╚═╝    "
Y_ROW6="   ╚═╝      "
Z_ROW6="╚══════╝    "

# Function to build any word dynamically
build_ascii_word() {
    local word="$1"
    local rows=("" "" "" "" "" "")
    
    # Convert to uppercase for consistency
    word=$(echo "$word" | tr '[:lower:]' '[:upper:]')
    
    # Build each row by combining letters
    for ((i=0; i<${#word}; i++)); do
        local char="${word:$i:1}"
        
        # Skip non-alphabetic characters
        if [[ ! "$char" =~ [A-Z] ]]; then
            continue
        fi
        
        # Add each row of the letter
        for row in {1..6}; do
            local var_name="${char}_ROW${row}"
            if [[ -n "${!var_name}" ]]; then
                rows[$((row-1))]+="${!var_name}"
            fi
        done
    done
    
    # Print the complete word
    for row in "${rows[@]}"; do
        echo "$row"
    done
}

# Function to build contextual ASCII art
build_contextual_ascii() {
    local command="$1"
    local platform="$2"
    
    case "$command" in
        init)
            echo "# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
            echo "# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
            echo "# ::                                                    ::"
            build_ascii_word "PAK"
            echo "# ::                                                    ::"
            build_ascii_word "SH"
            echo "# ::                                                    ::"
            echo "# ::    🚀 Package Automation Kit v2.0.0               ::"
            echo "# ::    📦 Universal package management for 30+ platforms ::"
            echo "# ::                                                    ::"
            echo "# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
            echo "# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
            ;;
        deploy)
            case "$platform" in
                npm)
                    build_ascii_word "NPM"
                    echo "📦 Deploying to NPM Registry..."
                    ;;
                python)
                    build_ascii_word "PYTHON"
                    echo "🐍 Deploying to PyPI..."
                    ;;
                rust)
                    build_ascii_word "RUST"
                    echo "🦀 Deploying to Cargo..."
                    ;;
                *)
                    build_ascii_word "DEPLOY"
                    echo "🚀 Deploying packages..."
                    ;;
            esac
            ;;
        track)
            build_ascii_word "TRACK"
            echo "📊 Tracking package statistics..."
            ;;
        status)
            build_ascii_word "STATUS"
            echo "📈 System status check..."
            ;;
    esac
}

# Function to show dynamic ASCII art
show_dynamic_ascii() {
    local command="$1"
    local platform="$2"
    local message="$3"
    
    case "$command" in
        init)
            build_contextual_ascii "init"
            ;;
        deploy)
            build_contextual_ascii "deploy" "$platform"
            ;;
        track)
            build_contextual_ascii "track"
            ;;
        status)
            build_contextual_ascii "status"
            ;;
        *)
            build_ascii_word "PAK"
            echo "$message"
            ;;
    esac
} 