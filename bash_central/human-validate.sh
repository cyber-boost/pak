#!/bin/bash
# human-validate.sh - Human-friendly input validation
# Handles typos, misclicks, and natural language variations

# ============================================================================
# YES/NO VALIDATION WITH HUMAN UNDERSTANDING
# ============================================================================

# Function to check if input means "yes"
is_yes() {
    local input="${1,,}"  # Convert to lowercase
    
    # Handle various yes variations including typos
    case "$input" in
        # Standard yes
        y|yes|yep|yeah|yup|sure|ok|okay|affirmative|aye|correct|true|1)
            return 0
            ;;
        # Typos and misclicks around 'y' on keyboard
        t|u|g|h|j|6|7)  # Keys around 'y'
            return 0
            ;;
        # Enthusiastic yes
        yess|yesss|yessss|yesssss|yasss|yaaas|yaaaas)
            return 0
            ;;
        # International yes
        si|oui|ja|da|hai|tak|sim)
            return 0
            ;;
        # Fun variations
        "hell yes"|"hell yeah"|"fuck yes"|"fuck yeah")
            return 0
            ;;
        # Abbreviated
        ye|ya|yu|ys)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if input means "no"
is_no() {
    local input="${1,,}"  # Convert to lowercase
    
    # Handle various no variations including typos
    case "$input" in
        # Standard no
        n|no|nope|nah|negative|false|0)
            return 0
            ;;
        # Typos and misclicks around 'n' on keyboard
        b|m|h|j|k)  # Keys around 'n'
            return 0
            ;;
        # Common typos
        "on"|"bm"|"bo"|"np"|"ni"|"mo")  # Common misclicks
            return 0
            ;;
        # Emphatic no
        noo|nooo|noooo|nooooo)
            return 0
            ;;
        # Strong no
        "no!"|"NO!"|"hell no"|"fuck no"|"absolutely not")
            return 0
            ;;
        # International no
        non|nein|nie|nyet|iie)
            return 0
            ;;
        # Abbreviated
        na|nn)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to prompt for yes/no with retry
prompt_yes_no() {
    local prompt="${1:-Continue?}"
    local default="${2}"  # Can be "yes", "no", or empty for no default
    local response
    
    # Build prompt with default indicator
    local full_prompt="$prompt"
    if [[ "$default" == "yes" ]]; then
        full_prompt="$prompt [Y/n]"
    elif [[ "$default" == "no" ]]; then
        full_prompt="$prompt [y/N]"
    else
        full_prompt="$prompt [y/n]"
    fi
    
    while true; do
        read -r -p "$full_prompt " response
        
        # Handle empty response with default
        if [[ -z "$response" ]]; then
            if [[ "$default" == "yes" ]]; then
                return 0
            elif [[ "$default" == "no" ]]; then
                return 1
            else
                echo "Please enter yes or no"
                continue
            fi
        fi
        
        # Check response
        if is_yes "$response"; then
            return 0
        elif is_no "$response"; then
            return 1
        else
            echo "I didn't understand '$response'. Please enter yes or no."
            echo "Hint: You can use y, yes, n, no, or many variations!"
        fi
    done
}

# Function to require explicit confirmation for dangerous operations
require_confirmation() {
    local action="$1"
    local confirm_text="${2:-yes, I understand}"
    
    echo "⚠️  WARNING: You are about to $action"
    echo "This action cannot be undone."
    echo
    echo "To confirm, please type exactly: $confirm_text"
    echo "Or type 'no' to cancel"
    
    local response
    read -r -p "> " response
    
    if [[ "$response" == "$confirm_text" ]]; then
        return 0
    elif is_no "$response"; then
        echo "Action cancelled."
        return 1
    else
        echo "Confirmation text did not match. Action cancelled."
        return 1
    fi
}

# ============================================================================
# VALIDATION WITH SUGGESTIONS
# ============================================================================

# Function to validate with common options
validate_choice() {
    local input="$1"
    shift
    local -a options=("$@")
    
    # Direct match
    for option in "${options[@]}"; do
        if [[ "${input,,}" == "${option,,}" ]]; then
            echo "$option"
            return 0
        fi
    done
    
    # Fuzzy match (starts with)
    for option in "${options[@]}"; do
        if [[ "${option,,}" == "${input,,}"* ]]; then
            echo "$option"
            return 0
        fi
    done
    
    return 1
}

# Function to prompt with multiple choice
prompt_choice() {
    local prompt="$1"
    shift
    local -a options=("$@")
    
    echo "$prompt"
    echo
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo
    
    local response
    while true; do
        read -r -p "Enter your choice (number or text): " response
        
        # Check if number
        if is_positive_integer "$response" && [[ "$response" -le "${#options[@]}" ]]; then
            echo "${options[$((response-1))]}"
            return 0
        fi
        
        # Check if text match
        if result=$(validate_choice "$response" "${options[@]}"); then
            echo "$result"
            return 0
        fi
        
        echo "Invalid choice. Please try again."
    done
}

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

# Example usage:
# if prompt_yes_no "Do you want to install TuskLang?" "yes"; then
#     echo "Installing..."
# else
#     echo "Installation cancelled"
# fi

# For dangerous operations:
# if require_confirmation "delete all data"; then
#     echo "Deleting..."
# fi

# For multiple choice:
# language=$(prompt_choice "Select your language:" "PHP" "JavaScript" "Python" "Go")
# echo "You selected: $language"