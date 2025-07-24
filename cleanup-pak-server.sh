#!/bin/bash
# PAK Server Cleanup Script
# Use with caution - this will permanently delete files

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}⚠️  PAK SERVER CLEANUP SCRIPT ⚠️${NC}"
echo -e "${YELLOW}This script will permanently delete PAK files and data${NC}"
echo

# Function to confirm deletion
confirm_deletion() {
    local item="$1"
    echo -e "${YELLOW}Delete $item? (y/N)${NC}"
    read -p "> " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 1. Remove PAK user installations
echo -e "${BLUE}1. Cleaning PAK user installations...${NC}"
if [[ -d "/root/.pak" ]]; then
    if confirm_deletion "/root/.pak (root user PAK installation)"; then
        rm -rf /root/.pak
        echo -e "${GREEN}✅ Removed /root/.pak${NC}"
    fi
fi

# Check for other user PAK installations
for user_home in /home/*; do
    if [[ -d "$user_home/.pak" ]]; then
        if confirm_deletion "$user_home/.pak (user PAK installation)"; then
            rm -rf "$user_home/.pak"
            echo -e "${GREEN}✅ Removed $user_home/.pak${NC}"
        fi
    fi
done

# 2. Remove global symlinks
echo -e "${BLUE}2. Cleaning global symlinks...${NC}"
if [[ -L "/usr/local/bin/pak" ]]; then
    if confirm_deletion "/usr/local/bin/pak (global symlink)"; then
        rm -f /usr/local/bin/pak
        echo -e "${GREEN}✅ Removed global pak symlink${NC}"
    fi
fi

# 3. Remove PAK development/build files
echo -e "${BLUE}3. Cleaning PAK development files...${NC}"
if [[ -d "/opt/stats" ]]; then
    echo -e "${YELLOW}Found PAK development directory: /opt/stats${NC}"
    echo -e "${RED}⚠️  This contains the entire PAK source code and build system${NC}"
    if confirm_deletion "/opt/stats (ENTIRE PAK SOURCE - BE VERY CAREFUL)"; then
        rm -rf /opt/stats
        echo -e "${GREEN}✅ Removed /opt/stats${NC}"
    fi
fi

# 4. Remove PAK web files
echo -e "${BLUE}4. Cleaning web server files...${NC}"
if [[ -f "/etc/nginx/sites-enabled/pak.sh" ]]; then
    if confirm_deletion "nginx config /etc/nginx/sites-enabled/pak.sh"; then
        rm -f /etc/nginx/sites-enabled/pak.sh
        systemctl reload nginx 2>/dev/null || true
        echo -e "${GREEN}✅ Removed nginx config${NC}"
    fi
fi

# 5. Remove SSL certificates
echo -e "${BLUE}5. Cleaning SSL certificates...${NC}"
if [[ -d "/etc/letsencrypt/live/pak.sh" ]]; then
    if confirm_deletion "SSL certificates for pak.sh"; then
        certbot delete --cert-name pak.sh 2>/dev/null || true
        echo -e "${GREEN}✅ Removed SSL certificates${NC}"
    fi
fi

if [[ -d "/etc/letsencrypt/live/get.pak.sh" ]]; then
    if confirm_deletion "SSL certificates for get.pak.sh"; then
        certbot delete --cert-name get.pak.sh 2>/dev/null || true
        echo -e "${GREEN}✅ Removed SSL certificates${NC}"
    fi
fi

# 6. Remove temporary files
echo -e "${BLUE}6. Cleaning temporary files...${NC}"
rm -rf /tmp/pak-* 2>/dev/null || true
rm -rf /tmp/*pak* 2>/dev/null || true
echo -e "${GREEN}✅ Cleaned temporary files${NC}"

# 7. Remove logs
echo -e "${BLUE}7. Cleaning system logs...${NC}"
if confirm_deletion "PAK-related system logs"; then
    rm -f /var/log/*pak* 2>/dev/null || true
    rm -f /var/log/nginx/pak.sh.* 2>/dev/null || true
    echo -e "${GREEN}✅ Cleaned system logs${NC}"
fi

echo
echo -e "${GREEN}🎉 PAK cleanup completed!${NC}"
echo -e "${BLUE}💡 You may also want to:${NC}"
echo -e "  • Check for any remaining PAK processes: ${YELLOW}ps aux | grep pak${NC}"
echo -e "  • Remove any PAK-related cron jobs: ${YELLOW}crontab -l${NC}"
echo -e "  • Check systemd services: ${YELLOW}systemctl list-units | grep pak${NC}" 