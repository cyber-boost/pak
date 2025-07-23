#!/bin/bash
# PAK.sh Setup Script
# Helps users configure their pak.sh installation

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PAK_CONFIG_DIR="/opt/pak/config"
PAK_WEB_DIR="/opt/pak/web"
PAK_DATA_DIR="/opt/pak/data"
PAK_LOG_DIR="/opt/pak/logs"

# Function to show header
show_header() {
    echo -e "${GREEN}🚀 PAK.sh Setup Wizard${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}"
        echo -e "${YELLOW}💡 Use: sudo $0${NC}"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check if PAK.sh is installed
    if [[ ! -f "/usr/local/bin/pak" ]] && [[ ! -f "/opt/pak/pak" ]]; then
        echo -e "${RED}❌ PAK.sh is not installed${NC}"
        echo -e "${YELLOW}💡 Install PAK.sh first: curl -sSL https://pak.sh/install | sudo bash${NC}"
        exit 1
    fi
    
    # Check for nginx
    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Nginx not found. Installing...${NC}"
        apt-get update
        apt-get install -y nginx
    fi
    
    # Check for PHP
    if ! command -v php >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ PHP not found. Installing...${NC}"
        apt-get update
        apt-get install -y php-fpm php-sqlite3 php-json php-curl
    fi
    
    # Check for sqlite3
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ SQLite3 not found. Installing...${NC}"
        apt-get update
        apt-get install -y sqlite3
    fi
    
    echo -e "${GREEN}✅ Prerequisites check completed${NC}"
    echo
}

# Function to get domain configuration
get_domain_config() {
    echo -e "${CYAN}🌐 Domain Configuration${NC}"
    echo -e "${BLUE}======================${NC}"
    
    read -p "Enter your domain (e.g., pak.yourdomain.com): " PAK_DOMAIN
    PAK_DOMAIN=${PAK_DOMAIN:-pak.yourdomain.com}
    
    echo -e "${GREEN}✅ Domain set to: $PAK_DOMAIN${NC}"
    echo
}

# Function to configure telemetry
configure_telemetry() {
    echo -e "${CYAN}📊 Telemetry Configuration${NC}"
    echo -e "${BLUE}========================${NC}"
    
    read -p "Enable telemetry tracking? (y/N): " ENABLE_TELEMETRY
    ENABLE_TELEMETRY=${ENABLE_TELEMETRY:-n}
    
    if [[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]]; then
        # Generate API key
        API_KEY=$(openssl rand -hex 32 2>/dev/null || echo "pak_$(date +%s)_$(head -c 16 /dev/urandom | xxd -p)")
        
        # Generate dashboard credentials
        DASHBOARD_USER="admin"
        DASHBOARD_PASS=$(openssl rand -base64 12 2>/dev/null || echo "pak_$(date +%s)")
        
        echo -e "${GREEN}✅ Telemetry enabled!${NC}"
        echo -e "${YELLOW}🔑 API Key: ${GREEN}$API_KEY${NC}"
        echo -e "${YELLOW}👤 Dashboard User: ${GREEN}$DASHBOARD_USER${NC}"
        echo -e "${YELLOW}🔒 Dashboard Password: ${GREEN}$DASHBOARD_PASS${NC}"
        echo -e "${RED}📝 Save these credentials securely!${NC}"
        echo
        
        # Create .htpasswd file
        mkdir -p "$PAK_CONFIG_DIR"
        htpasswd -cb "$PAK_CONFIG_DIR/.htpasswd" "$DASHBOARD_USER" "$DASHBOARD_PASS" 2>/dev/null || \
        echo "$DASHBOARD_USER:$(openssl passwd -apr1 "$DASHBOARD_PASS")" > "$PAK_CONFIG_DIR/.htpasswd"
        
        # Create telemetry configuration
        cat > "$PAK_CONFIG_DIR/telemetry.conf" << EOF
# Telemetry Configuration
[telemetry]
enabled = true
api_key = $API_KEY
webhook_url = https://$PAK_DOMAIN/webhook/telemetry
dashboard_url = https://$PAK_DOMAIN/telemetry
dashboard_user = $DASHBOARD_USER
dashboard_pass = $DASHBOARD_PASS

[security]
rate_limit_webhook = 10
rate_limit_api = 30
max_payload_size = 1048576

[storage]
database = $PAK_DATA_DIR/telemetry.db
log_file = $PAK_LOG_DIR/telemetry.log
retention_days = 90
EOF
        
        echo -e "${GREEN}✅ Telemetry configuration created${NC}"
    else
        API_KEY=""
        DASHBOARD_USER=""
        DASHBOARD_PASS=""
        echo -e "${BLUE}ℹ️ Telemetry disabled${NC}"
    fi
    echo
}

# Function to setup nginx configuration
setup_nginx() {
    echo -e "${CYAN}🌐 Nginx Configuration${NC}"
    echo -e "${BLUE}=====================${NC}"
    
    # Create nginx configuration
    cat > "/etc/nginx/sites-available/pak.sh" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $PAK_DOMAIN www.$PAK_DOMAIN;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Root directory
    root $PAK_WEB_DIR;
    index index.html;

    # Logging
    access_log /var/log/nginx/pak.sh.access.log;
    error_log /var/log/nginx/pak.sh.error.log;

    # Rate limiting for webhook
    limit_req_zone \$binary_remote_addr zone=webhook:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=telemetry:10m rate=30r/s;

    # Handle static files
    location / {
        try_files \$uri \$uri/ =404;
        
        # Cache static files
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Cache JSON and text files for shorter time
        location ~* \.(json|txt|md)\$ {
            expires 1h;
            add_header Cache-Control "public";
        }
    }

    # Handle install script
    location = /install {
        alias $PAK_WEB_DIR/install.sh;
        add_header Content-Type "text/plain";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle install.sh script
    location = /install.sh {
        alias $PAK_WEB_DIR/install.sh;
        add_header Content-Type "text/plain";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle manifest.json
    location = /manifest.json {
        alias $PAK_WEB_DIR/manifest.json;
        add_header Content-Type "application/json";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle latest.tar.gz
    location = /latest.tar.gz {
        alias $PAK_WEB_DIR/latest.tar.gz;
        add_header Content-Type "application/gzip";
        add_header Content-Disposition "attachment; filename=latest.tar.gz";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
EOF

    # Add telemetry endpoints if enabled
    if [[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]]; then
        cat >> "/etc/nginx/sites-available/pak.sh" << EOF

    # Handle telemetry webhook with API key authentication
    location = /webhook/telemetry {
        limit_req zone=webhook burst=20 nodelay;
        
        # API key authentication
        if (\$http_x_api_key != "$API_KEY") {
            return 401;
        }
        
        alias $PAK_WEB_DIR/webhook-telemetry.php;
        add_header Content-Type "application/json";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle telemetry dashboard with basic auth
    location = /telemetry {
        auth_basic "PAK.sh Telemetry Dashboard";
        auth_basic_user_file $PAK_CONFIG_DIR/.htpasswd;
        
        alias $PAK_WEB_DIR/telemetry-dashboard.php;
        add_header Content-Type "text/html";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle telemetry API endpoints
    location ~ ^/api/telemetry/(.*)\$ {
        limit_req zone=telemetry burst=50 nodelay;
        
        # API key authentication
        if (\$http_x_api_key != "$API_KEY") {
            return 401;
        }
        
        alias $PAK_WEB_DIR/api-telemetry.php;
        add_header Content-Type "application/json";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
EOF
    fi

    # Add remaining configuration
    cat >> "/etc/nginx/sites-available/pak.sh" << EOF

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to backup files
    location ~ ~\$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to config files
    location ~ /config/ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/pak.sh /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    if nginx -t; then
        systemctl reload nginx
        echo -e "${GREEN}✅ Nginx configuration created and enabled${NC}"
    else
        echo -e "${RED}❌ Nginx configuration test failed${NC}"
        exit 1
    fi
    echo
}

# Function to setup SSL (optional)
setup_ssl() {
    echo -e "${CYAN}🔒 SSL Configuration (Optional)${NC}"
    echo -e "${BLUE}==============================${NC}"
    
    read -p "Setup SSL with Let's Encrypt? (y/N): " SETUP_SSL
    SETUP_SSL=${SETUP_SSL:-n}
    
    if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
        # Check if certbot is installed
        if ! command -v certbot >/dev/null 2>&1; then
            echo -e "${YELLOW}📦 Installing certbot...${NC}"
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
        fi
        
        # Get SSL certificate
        echo -e "${YELLOW}🔐 Obtaining SSL certificate...${NC}"
        certbot --nginx -d "$PAK_DOMAIN" -d "www.$PAK_DOMAIN" --non-interactive --agree-tos --email admin@$PAK_DOMAIN
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ SSL certificate obtained and configured${NC}"
        else
            echo -e "${YELLOW}⚠️ SSL setup failed. You can configure it manually later.${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️ SSL setup skipped${NC}"
    fi
    echo
}

# Function to create embed configuration
create_embed_config() {
    if [[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}📋 Creating Embed Configuration${NC}"
        echo -e "${BLUE}==============================${NC}"
        
        # Create embed configuration template
        cat > "$PAK_CONFIG_DIR/embed-template.conf" << EOF
# PAK.sh Embed Configuration Template
# Copy this to your package directory as .pak-embed.conf

# Enable/disable telemetry
EMBED_ENABLED=true

# Webhook URL (replace with your domain)
EMBED_WEBHOOK_URL=https://$PAK_DOMAIN/webhook/telemetry

# API Key for authentication
EMBED_API_KEY=$API_KEY

# Package information (set these in your package)
EMBED_PACKAGE_NAME=your-package-name
EMBED_PACKAGE_VERSION=1.0.0

# Optional: Custom user and session IDs
# EMBED_USER_ID=your-user-id
# EMBED_SESSION_ID=your-session-id
EOF
        
        echo -e "${GREEN}✅ Embed configuration template created: $PAK_CONFIG_DIR/embed-template.conf${NC}"
        echo -e "${YELLOW}💡 Copy this template to your packages and customize as needed${NC}"
    fi
    echo
}

# Function to show final instructions
show_final_instructions() {
    echo -e "${GREEN}🎉 PAK.sh Setup Complete!${NC}"
    echo -e "${BLUE}========================${NC}"
    echo
    echo -e "${CYAN}📋 Configuration Summary:${NC}"
    echo -e "  🌐 Domain: ${GREEN}$PAK_DOMAIN${NC}"
    echo -e "  📊 Telemetry: ${GREEN}$([[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]] && echo "Enabled" || echo "Disabled")${NC}"
    echo -e "  🌐 Nginx: ${GREEN}Configured${NC}"
    echo -e "  🔒 SSL: ${GREEN}$([[ "$SETUP_SSL" =~ ^[Yy]$ ]] && echo "Configured" || echo "Not configured")${NC}"
    echo
    echo -e "${YELLOW}🎯 Next Steps:${NC}"
    echo -e "  1. Update your DNS to point $PAK_DOMAIN to this server"
    echo -e "  2. Test your installation: curl https://$PAK_DOMAIN/install"
    if [[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]]; then
        echo -e "  3. Access telemetry dashboard: https://$PAK_DOMAIN/telemetry"
        echo -e "  4. Use embed.sh in your packages with API key: $API_KEY"
    fi
    echo -e "  5. Build and deploy your packages: pak build && pak deploy"
    echo
    echo -e "${PURPLE}📁 Important Files:${NC}"
    echo -e "  • Nginx config: /etc/nginx/sites-available/pak.sh"
    echo -e "  • PAK config: $PAK_CONFIG_DIR/pak.conf"
    if [[ "$ENABLE_TELEMETRY" =~ ^[Yy]$ ]]; then
        echo -e "  • Telemetry config: $PAK_CONFIG_DIR/telemetry.conf"
        echo -e "  • Embed template: $PAK_CONFIG_DIR/embed-template.conf"
    fi
    echo
    echo -e "${GREEN}🚀 Your PAK.sh instance is ready!${NC}"
}

# Main function
main() {
    show_header
    check_root
    check_prerequisites
    get_domain_config
    configure_telemetry
    setup_nginx
    setup_ssl
    create_embed_config
    show_final_instructions
}

# Run main function
main "$@" 