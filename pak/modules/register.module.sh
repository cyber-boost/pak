#!/bin/bash
# Registration module - Easy platform registration wizard

register_init() {
    log DEBUG "Registration module initialized"
    
    # Create registration directories
    mkdir -p "$PAK_CONFIG_DIR/credentials"
    mkdir -p "$PAK_SCRIPTS_DIR/register"
    mkdir -p "$PAK_TEMPLATES_DIR/registration"
    
    # Initialize registration templates
    register_init_templates
}

register_register_commands() {
    register_command "register" "register" "register_wizard"
    register_command "register-all" "register" "register_all_platforms"
    register_command "register-platform" "register" "register_single_platform"
    register_command "register-test" "register" "register_test_credentials"
    register_command "register-list" "register" "register_list_platforms"
    register_command "register-export" "register" "register_export_credentials"
    register_command "register-import" "register" "register_import_credentials"
    register_command "register-clear" "register" "register_clear_credentials"
}

register_init_templates() {
    local templates_dir="$PAK_TEMPLATES_DIR/registration"
    
    # Create platform registration guides
    cat > "$templates_dir/npm-guide.md" << 'EOF'
# NPM Registration Guide

## Quick Registration
1. Go to https://www.npmjs.com/signup
2. Create account with email
3. Verify email address
4. Go to https://www.npmjs.com/settings/tokens
5. Create new token with "Automation" type
6. Copy token to clipboard

## Environment Variable
```bash
export NPM_TOKEN="your_npm_token_here"
```

## Test Command
```bash
npm whoami
```
EOF

    cat > "$templates_dir/pypi-guide.md" << 'EOF'
# PyPI Registration Guide

## Quick Registration
1. Go to https://pypi.org/account/register/
2. Create account with email
3. Verify email address
4. Go to https://pypi.org/manage/account/token/
5. Create new token with "Entire account" scope
6. Copy token to clipboard

## Environment Variable
```bash
export PYPI_TOKEN="your_pypi_token_here"
```

## Test Command
```bash
pip install --user --upgrade twine
twine check dist/*
```
EOF

    cat > "$templates_dir/cargo-guide.md" << 'EOF'
# Cargo Registration Guide

## Quick Registration
1. Go to https://crates.io/signup
2. Create account with GitHub
3. Verify GitHub authorization
4. Go to https://crates.io/settings/tokens
5. Create new token
6. Copy token to clipboard

## Environment Variable
```bash
export CARGO_REGISTRY_TOKEN="your_cargo_token_here"
```

## Test Command
```bash
cargo login
```
EOF

    # Create more platform guides...
    register_create_platform_guides
}

register_create_platform_guides() {
    local templates_dir="$PAK_TEMPLATES_DIR/registration"
    
    # Create guides for all major platforms
    local platforms=(
        "nuget:https://www.nuget.org/account/register:NUGET_TOKEN"
        "maven:https://oss.sonatype.org/:MAVEN_USERNAME:MAVEN_PASSWORD"
        "packagist:https://packagist.org/register/:PACKAGIST_TOKEN"
        "rubygems:https://rubygems.org/sign_up:RUBYGEMS_USERNAME:RUBYGEMS_PASSWORD"
        "conda:https://anaconda.org/account/register/:ANACONDA_TOKEN"
        "helm:https://charts.helm.sh/:HELM_TOKEN"
        "terraform:https://registry.terraform.io/signup:TF_TOKEN"
        "dockerhub:https://hub.docker.com/signup:DOCKER_USERNAME:DOCKER_PASSWORD"
        "jsr:https://jsr.io/signup:JSR_TOKEN"
        "deno:https://deno.land/signup:DENO_TOKEN"
    )
    
    for platform_info in "${platforms[@]}"; do
        IFS=':' read -r platform url env_var <<< "$platform_info"
        register_create_platform_guide "$platform" "$url" "$env_var"
    done
}

register_create_platform_guide() {
    local platform="$1"
    local url="$2"
    local env_var="$3"
    local templates_dir="$PAK_TEMPLATES_DIR/registration"
    
    cat > "$templates_dir/${platform}-guide.md" << EOF
# ${platform^^} Registration Guide

## Quick Registration
1. Go to $url
2. Create account with email/GitHub
3. Verify account
4. Generate API token/credentials
5. Copy credentials to clipboard

## Environment Variable
\`\`\`bash
export $env_var="your_${platform}_token_here"
\`\`\`

## Test Command
\`\`\`bash
# Test your ${platform} credentials
pak register-test ${platform}
\`\`\`
EOF
}

register_wizard() {
    log INFO "🧙 Starting PAK.sh Platform Registration Wizard"
    
    # Show welcome screen
    register_show_welcome_screen
    
    # Get user preferences
    register_get_user_preferences
    
    # Show platform selection
    register_show_platform_selection
    
    # Process registration for selected platforms
    register_process_registrations
    
    # Test credentials
    register_test_all_credentials
    
    # Show summary
    register_show_summary
}

register_show_welcome_screen() {
    echo
    echo "    ╭─────────────────────────────────────╮"
    echo "    │                                     │"
    echo "    │  ██████╗  █████╗ ██╗  ██╗          │"
    echo "    │  ██╔══██╗██╔══██╗██║ ██╔╝          │"
    echo "    │  ██████╔╝███████║█████╔╝           │"
    echo "    │  ██╔═══╝ ██╔══██║██╔═██╗            │"
    echo "    │  ██║     ██║  ██║██║  ██╗           │"
    echo "    │  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝           │"
    echo "    │                                     │"
    echo "    │    PAK.sh - Registration Wizard     │"
    echo "    │                                     │"
    echo "    │  🔐 Let's set up your credentials!  │"
    echo "    ╰─────────────────────────────────────╯"
    echo
    echo "📋 Platform Registration Wizard"
    echo "==============================="
    echo
    echo "This wizard will help you register with package platforms"
    echo "and configure your credentials for automated deployment."
    echo
}

register_get_user_preferences() {
    echo "👤 USER PREFERENCES"
    echo "------------------"
    echo
    
    read -p "Your name: " user_name
    read -p "Your email: " user_email
    
    echo
    echo "Which platforms do you want to register with?"
    echo "1) All platforms (recommended)"
    echo "2) Popular platforms only (npm, pypi, cargo)"
    echo "3) Custom selection"
    echo
    
    read -p "Choose option [1]: " platform_choice
    platform_choice="${platform_choice:-1}"
    
    case "$platform_choice" in
        1) register_platforms="all" ;;
        2) register_platforms="popular" ;;
        3) register_platforms="custom" ;;
        *) register_platforms="all" ;;
    esac
    
    echo
    echo "How would you like to store credentials?"
    echo "1) Environment variables (recommended)"
    echo "2) Configuration file"
    echo "3) Both"
    echo
    
    read -p "Choose option [1]: " storage_choice
    storage_choice="${storage_choice:-1}"
    
    case "$storage_choice" in
        1) credential_storage="env" ;;
        2) credential_storage="file" ;;
        3) credential_storage="both" ;;
        *) credential_storage="env" ;;
    esac
}

register_show_platform_selection() {
    echo
    echo "🎯 PLATFORM SELECTION"
    echo "-------------------"
    echo
    
    case "$register_platforms" in
        "all")
            echo "Registering with ALL platforms:"
            register_platform_list=("npm" "pypi" "cargo" "nuget" "maven" "packagist" "rubygems" "conda" "helm" "terraform" "dockerhub" "jsr" "deno")
            ;;
        "popular")
            echo "Registering with POPULAR platforms:"
            register_platform_list=("npm" "pypi" "cargo")
            ;;
        "custom")
            echo "Available platforms:"
            echo "1) npm (JavaScript)"
            echo "2) pypi (Python)"
            echo "3) cargo (Rust)"
            echo "4) nuget (.NET)"
            echo "5) maven (Java)"
            echo "6) packagist (PHP)"
            echo "7) rubygems (Ruby)"
            echo "8) conda (Python)"
            echo "9) helm (Kubernetes)"
            echo "10) terraform (Infrastructure)"
            echo "11) dockerhub (Containers)"
            echo "12) jsr (Deno/TypeScript)"
            echo "13) deno (Deno/TypeScript)"
            echo
            
            read -p "Enter platform numbers (comma-separated): " custom_platforms
            IFS=',' read -ra platform_numbers <<< "$custom_platforms"
            
            register_platform_list=()
            for num in "${platform_numbers[@]}"; do
                case "$num" in
                    1) register_platform_list+=("npm") ;;
                    2) register_platform_list+=("pypi") ;;
                    3) register_platform_list+=("cargo") ;;
                    4) register_platform_list+=("nuget") ;;
                    5) register_platform_list+=("maven") ;;
                    6) register_platform_list+=("packagist") ;;
                    7) register_platform_list+=("rubygems") ;;
                    8) register_platform_list+=("conda") ;;
                    9) register_platform_list+=("helm") ;;
                    10) register_platform_list+=("terraform") ;;
                    11) register_platform_list+=("dockerhub") ;;
                    12) register_platform_list+=("jsr") ;;
                    13) register_platform_list+=("deno") ;;
                esac
            done
            ;;
    esac
    
    echo "Selected platforms: ${register_platform_list[*]}"
    echo
}

register_process_registrations() {
    echo "🔐 REGISTRATION PROCESS"
    echo "---------------------"
    echo
    
    local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
    mkdir -p "$(dirname "$credentials_file")"
    
    # Initialize credentials file
    cat > "$credentials_file" << EOF
{
  "user": {
    "name": "$user_name",
    "email": "$user_email",
    "registered_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "platforms": {}
}
EOF
    
    for platform in "${register_platform_list[@]}"; do
        echo "📋 Registering with $platform..."
        register_process_single_platform "$platform"
        echo
    done
}

register_process_single_platform() {
    local platform="$1"
    local templates_dir="$PAK_TEMPLATES_DIR/registration"
    local guide_file="$templates_dir/${platform}-guide.md"
    
    # Show platform guide
    if [[ -f "$guide_file" ]]; then
        echo "📖 Registration guide for $platform:"
        cat "$guide_file"
        echo
    fi
    
    # Get credentials
    case "$platform" in
        "npm")
            read -p "NPM Token: " npm_token
            if [[ -n "$npm_token" ]]; then
                register_save_credential "$platform" "NPM_TOKEN" "$npm_token"
            fi
            ;;
        "pypi")
            read -p "PyPI Token: " pypi_token
            if [[ -n "$pypi_token" ]]; then
                register_save_credential "$platform" "PYPI_TOKEN" "$pypi_token"
            fi
            ;;
        "cargo")
            read -p "Cargo Token: " cargo_token
            if [[ -n "$cargo_token" ]]; then
                register_save_credential "$platform" "CARGO_REGISTRY_TOKEN" "$cargo_token"
            fi
            ;;
        "nuget")
            read -p "NuGet Token: " nuget_token
            if [[ -n "$nuget_token" ]]; then
                register_save_credential "$platform" "NUGET_TOKEN" "$nuget_token"
            fi
            ;;
        "maven")
            read -p "Maven Username: " maven_username
            read -s -p "Maven Password: " maven_password
            echo
            if [[ -n "$maven_username" && -n "$maven_password" ]]; then
                register_save_credential "$platform" "MAVEN_USERNAME" "$maven_username"
                register_save_credential "$platform" "MAVEN_PASSWORD" "$maven_password"
            fi
            ;;
        "packagist")
            read -p "Packagist Token: " packagist_token
            if [[ -n "$packagist_token" ]]; then
                register_save_credential "$platform" "PACKAGIST_TOKEN" "$packagist_token"
            fi
            ;;
        "rubygems")
            read -p "RubyGems Username: " rubygems_username
            read -s -p "RubyGems Password: " rubygems_password
            echo
            if [[ -n "$rubygems_username" && -n "$rubygems_password" ]]; then
                register_save_credential "$platform" "RUBYGEMS_USERNAME" "$rubygems_username"
                register_save_credential "$platform" "RUBYGEMS_PASSWORD" "$rubygems_password"
            fi
            ;;
        "conda")
            read -p "Anaconda Token: " conda_token
            if [[ -n "$conda_token" ]]; then
                register_save_credential "$platform" "ANACONDA_TOKEN" "$conda_token"
            fi
            ;;
        "helm")
            read -p "Helm Token: " helm_token
            if [[ -n "$helm_token" ]]; then
                register_save_credential "$platform" "HELM_TOKEN" "$helm_token"
            fi
            ;;
        "terraform")
            read -p "Terraform Token: " terraform_token
            if [[ -n "$terraform_token" ]]; then
                register_save_credential "$platform" "TF_TOKEN" "$terraform_token"
            fi
            ;;
        "dockerhub")
            read -p "Docker Hub Username: " docker_username
            read -s -p "Docker Hub Password: " docker_password
            echo
            if [[ -n "$docker_username" && -n "$docker_password" ]]; then
                register_save_credential "$platform" "DOCKER_USERNAME" "$docker_username"
                register_save_credential "$platform" "DOCKER_PASSWORD" "$docker_password"
            fi
            ;;
        "jsr")
            read -p "JSR Token: " jsr_token
            if [[ -n "$jsr_token" ]]; then
                register_save_credential "$platform" "JSR_TOKEN" "$jsr_token"
            fi
            ;;
        "deno")
            read -p "Deno Token: " deno_token
            if [[ -n "$deno_token" ]]; then
                register_save_credential "$platform" "DENO_TOKEN" "$deno_token"
            fi
            ;;
        *)
            echo "⚠️  Platform $platform not supported yet"
            ;;
    esac
}

register_save_credential() {
    local platform="$1"
    local env_var="$2"
    local value="$3"
    local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
    
    # Save to JSON file
    jq --arg platform "$platform" \
       --arg env_var "$env_var" \
       --arg value "$value" \
       '.platforms[$platform][$env_var] = $value' \
       "$credentials_file" > temp.json && mv temp.json "$credentials_file"
    
    # Save to environment file if requested
    if [[ "$credential_storage" == "env" || "$credential_storage" == "both" ]]; then
        echo "export $env_var=\"$value\"" >> "$PAK_CONFIG_DIR/credentials/env.sh"
    fi
    
    echo "✅ Saved $env_var for $platform"
}

register_test_all_credentials() {
    echo "🧪 TESTING CREDENTIALS"
    echo "--------------------"
    echo
    
    # Load environment variables
    if [[ -f "$PAK_CONFIG_DIR/credentials/env.sh" ]]; then
        source "$PAK_CONFIG_DIR/credentials/env.sh"
    fi
    
    for platform in "${register_platform_list[@]}"; do
        echo "Testing $platform credentials..."
        register_test_single_platform "$platform"
        echo
    done
}

register_test_single_platform() {
    local platform="$1"
    
    case "$platform" in
        "npm")
            if [[ -n "$NPM_TOKEN" ]]; then
                if npm whoami &>/dev/null; then
                    echo "✅ NPM credentials valid"
                else
                    echo "❌ NPM credentials invalid"
                fi
            else
                echo "⚠️  NPM token not set"
            fi
            ;;
        "pypi")
            if [[ -n "$PYPI_TOKEN" ]]; then
                echo "✅ PyPI token saved (test with: twine check dist/*)"
            else
                echo "⚠️  PyPI token not set"
            fi
            ;;
        "cargo")
            if [[ -n "$CARGO_REGISTRY_TOKEN" ]]; then
                echo "✅ Cargo token saved (test with: cargo login)"
            else
                echo "⚠️  Cargo token not set"
            fi
            ;;
        *)
            echo "✅ $platform credentials saved"
            ;;
    esac
}

register_show_summary() {
    echo "📊 REGISTRATION SUMMARY"
    echo "---------------------"
    echo
    
    echo "✅ Successfully registered with ${#register_platform_list[@]} platforms:"
    for platform in "${register_platform_list[@]}"; do
        echo "  • $platform"
    done
    echo
    
    echo "📁 Credentials saved to:"
    echo "  • $PAK_CONFIG_DIR/credentials/platforms.json"
    if [[ "$credential_storage" == "env" || "$credential_storage" == "both" ]]; then
        echo "  • $PAK_CONFIG_DIR/credentials/env.sh"
    fi
    echo
    
    echo "🚀 Next steps:"
    echo "  1. Source environment variables: source $PAK_CONFIG_DIR/credentials/env.sh"
    echo "  2. Test deployment: pak deploy test-package --version 1.0.0"
    echo "  3. View credentials: pak register-list"
    echo
    
    echo "🔐 Security notes:"
    echo "  • Keep your credentials secure"
    echo "  • Add $PAK_CONFIG_DIR/credentials/ to .gitignore"
    echo "  • Rotate tokens regularly"
    echo
    
    log SUCCESS "Registration wizard completed!"
}

register_all_platforms() {
    log INFO "Registering with all supported platforms"
    
    local all_platforms=("npm" "pypi" "cargo" "nuget" "maven" "packagist" "rubygems" "conda" "helm" "terraform" "dockerhub" "jsr" "deno")
    
    for platform in "${all_platforms[@]}"; do
        register_single_platform "$platform"
    done
}

register_single_platform() {
    local platform="$1"
    
    log INFO "Registering with $platform"
    
    # Show platform guide
    local templates_dir="$PAK_TEMPLATES_DIR/registration"
    local guide_file="$templates_dir/${platform}-guide.md"
    
    if [[ -f "$guide_file" ]]; then
        echo "📖 Registration guide for $platform:"
        cat "$guide_file"
        echo
    else
        echo "⚠️  No registration guide available for $platform"
    fi
}

register_test_credentials() {
    local platform="${1:-all}"
    
    if [[ "$platform" == "all" ]]; then
        log INFO "Testing all platform credentials"
        register_test_all_credentials
    else
        log INFO "Testing $platform credentials"
        register_test_single_platform "$platform"
    fi
}

register_list_platforms() {
    local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
    
    if [[ -f "$credentials_file" ]]; then
        echo "📋 Registered Platforms:"
        echo "======================="
        jq -r '.platforms | keys[]' "$credentials_file" 2>/dev/null || echo "No platforms registered"
    else
        echo "No credentials file found. Run 'pak register' to get started."
    fi
}

register_export_credentials() {
    local output_file="${1:-pak-credentials.json}"
    local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
    
    if [[ -f "$credentials_file" ]]; then
        cp "$credentials_file" "$output_file"
        echo "✅ Credentials exported to: $output_file"
    else
        echo "❌ No credentials to export"
    fi
}

register_import_credentials() {
    local input_file="$1"
    
    if [[ -f "$input_file" ]]; then
        local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
        mkdir -p "$(dirname "$credentials_file")"
        cp "$input_file" "$credentials_file"
        echo "✅ Credentials imported from: $input_file"
    else
        echo "❌ File not found: $input_file"
    fi
}

register_clear_credentials() {
    local credentials_file="$PAK_CONFIG_DIR/credentials/platforms.json"
    local env_file="$PAK_CONFIG_DIR/credentials/env.sh"
    
    if [[ -f "$credentials_file" ]]; then
        rm "$credentials_file"
        echo "✅ Credentials cleared"
    fi
    
    if [[ -f "$env_file" ]]; then
        rm "$env_file"
        echo "✅ Environment file cleared"
    fi
} 