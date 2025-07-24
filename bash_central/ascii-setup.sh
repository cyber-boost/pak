#!/bin/bash
# ascii-setup.sh - Setup ASCII art directory structure
# Author: Tusk Lang Team
# Date: 2025-07-13

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Setting up ASCII art directory structure...${NC}\n"

# Create directories
DIRS=(
    "ascii-art"
    "ascii-art/logos"
    "ascii-art/animals"
    "ascii-art/fun"
    "ascii-art/misc"
)

for dir in "${DIRS[@]}"; do
    if mkdir -p "$dir" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Created $dir"
    else
        echo -e "${YELLOW}!${NC} Directory exists: $dir"
    fi
done

# File organization map
declare -A FILE_MAP=(
    ["tusk-letters.txt"]="logos"
    ["peanu-tsk.txt"]="logos"
    ["banner.txt"]="logos"
    ["dance.txt"]="animals"
    ["unity.txt"]="animals"
    ["ivory.txt"]="animals"
    ["elder.txt"]="animals"
    ["turd-lg.txt"]="fun"
    ["turd-sm.txt"]="fun"
    ["pooping.txt"]="fun"
    ["peace.txt"]="misc"
)

echo -e "\n${BLUE}Organizing ASCII art files...${NC}\n"

# Move files to appropriate directories
for file in "${!FILE_MAP[@]}"; do
    category="${FILE_MAP[$file]}"
    
    if [[ -f "$file" ]]; then
        if cp "$file" "ascii-art/$category/" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Copied $file → ascii-art/$category/"
        else
            echo -e "${YELLOW}!${NC} Failed to copy $file"
        fi
    else
        echo -e "${YELLOW}!${NC} File not found: $file"
    fi
done

# Create README
cat > ascii-art/README.md << 'EOF'
# Tusk ASCII Art Collection

## Directory Structure

```
ascii-art/
├── logos/          # Tusk logos and branding
├── animals/        # Elephant ASCII art
├── fun/            # Humorous ASCII art
└── misc/           # Miscellaneous ASCII art
```

## Usage

Use the `ascii.sh` script to display ASCII art:

```bash
# Display specific art
./ascii.sh -c blue tusk

# List all available art
./ascii.sh -l

# Random art with animation
./ascii.sh -R -a

# Rainbow effect
./ascii.sh -r banner
```

## Adding New Art

1. Create your ASCII art in a `.txt` file
2. Place it in the appropriate category directory
3. Update the `ASCII_FILES` array in `ascii.sh`

## ASCII Art Guidelines

- Keep line width under 80 characters for terminal compatibility
- Use standard ASCII characters (avoid extended UTF-8 unless necessary)
- Test your art with different color themes
- Add a description in the `ASCII_DESC` array

EOF

echo -e "\n${GREEN}✓${NC} Created README.md"

# Create sample custom art
cat > ascii-art/misc/custom-template.txt << 'EOF'
     Your ASCII
      Art Here
    ___________
   /           \
  |  Template   |
   \___________/
EOF

echo -e "${GREEN}✓${NC} Created custom template"

# Create index file
echo -e "\n${BLUE}Creating index file...${NC}"

cat > ascii-art/index.txt << EOF
Tusk ASCII Art Index
====================

LOGOS:
- tusk-letters.txt    : Main TUSK logo
- peanu-tsk.txt      : Peanut-shaped TSK logo  
- banner.txt         : Full banner with info

ANIMALS:
- dance.txt          : Dancing elephant
- unity.txt          : Two elephants together
- ivory.txt          : Detailed elephant art
- elder.txt          : Elder elephant

FUN:
- turd-lg.txt        : Large decorative element
- turd-sm.txt        : Small decorative element
- pooping.txt        : Humorous figure

MISC:
- peace.txt          : Peace sign
- custom-template.txt : Template for new art

Total files: $(find ascii-art -name "*.txt" -type f | wc -l)
Generated: $(date)
EOF

echo -e "${GREEN}✓${NC} Created index.txt"

# Update ascii.sh paths if needed
if [[ -f "ascii.sh" ]]; then
    echo -e "\n${BLUE}Updating ascii.sh configuration...${NC}"
    
    # Create a config snippet
    cat > ascii-art-config.sh << 'EOF'
# ASCII art directory configuration
# Add this to your ascii.sh or source it

# Update ASCII_DIR to point to organized structure
ASCII_DIR="${SCRIPT_DIR}/ascii-art"

# Extended file mapping with categories
declare -A ASCII_FILES=(
    [tusk]="logos/tusk-letters.txt"
    [dance]="animals/dance.txt"
    [banner]="logos/banner.txt"
    [turd-lg]="fun/turd-lg.txt"
    [turd-sm]="fun/turd-sm.txt"
    [pooping]="fun/pooping.txt"
    [peanut]="logos/peanu-tsk.txt"
    [peace]="misc/peace.txt"
    [unity]="animals/unity.txt"
    [ivory]="animals/ivory.txt"
    [elder]="animals/elder.txt"
    [custom]="misc/custom-template.txt"
)
EOF
    
    echo -e "${GREEN}✓${NC} Created ascii-art-config.sh"
    echo -e "${YELLOW}!${NC} Update ASCII_DIR in ascii.sh to: \${SCRIPT_DIR}/ascii-art"
fi

# Create quick launcher
cat > show-art << 'EOF'
#!/bin/bash
# Quick ASCII art launcher

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if ascii.sh exists
if [[ ! -f "$SCRIPT_DIR/ascii.sh" ]]; then
    echo "Error: ascii.sh not found"
    echo "Make sure ascii.sh is in the same directory as this script"
    exit 1
fi

# If no arguments, show interactive menu
if [[ $# -eq 0 ]]; then
    "$SCRIPT_DIR/ascii-combo.sh" -i
else
    "$SCRIPT_DIR/ascii.sh" "$@"
fi
EOF

chmod +x show-art
echo -e "${GREEN}✓${NC} Created show-art launcher"

# Summary
echo -e "\n${BLUE}Setup complete!${NC}"
echo -e "\nDirectory structure:"
tree ascii-art 2>/dev/null || find ascii-art -type d | sort

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Update ASCII_DIR in ascii.sh to point to ascii-art/"
echo "2. Run ./show-art to see the interactive menu"
echo "3. Add your own ASCII art to the appropriate directories"
echo ""
echo -e "${BLUE}Enjoy your ASCII art collection!${NC} 🐘"