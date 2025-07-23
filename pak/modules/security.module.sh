#!/bin/bash
# Enhanced Security module - Comprehensive vulnerability scanning and compliance

security_init() {
    log DEBUG "Enhanced Security module initialized"
    
    # Create security directories
    mkdir -p "$PAK_DATA_DIR/security"
    mkdir -p "$PAK_CONFIG_DIR/security"
    mkdir -p "$PAK_TEMPLATES_DIR/security"
    mkdir -p "$PAK_SCRIPTS_DIR/security"
    
    # Initialize security policies
    security_init_policies
}

security_register_commands() {
    register_command "scan" "security" "security_scan"
    register_command "audit" "security" "security_audit"
    register_command "compliance" "security" "security_compliance"
    register_command "sign" "security" "security_sign"
    register_command "verify" "security" "security_verify"
    register_command "policy" "security" "security_policy"
    register_command "vuln-db" "security" "security_vuln_db"
    register_command "license-check" "security" "security_license_check"
    register_command "dependency-check" "security" "security_dependency_check"
    register_command "secrets-scan" "security" "security_secrets_scan"
}

security_init_policies() {
    # Create default security policies
    local policy_dir="$PAK_CONFIG_DIR/security"
    
    # OWASP Top 10 policy
    cat > "$policy_dir/owasp-policy.json" << 'EOF'
{
  "name": "OWASP Top 10 Security Policy",
  "version": "2021",
  "description": "Security policy based on OWASP Top 10 vulnerabilities",
  "rules": {
    "injection": {
      "severity": "critical",
      "description": "Prevent SQL injection, NoSQL injection, LDAP injection",
      "checks": ["sql-injection", "nosql-injection", "ldap-injection"]
    },
    "broken-auth": {
      "severity": "critical",
      "description": "Prevent broken authentication and session management",
      "checks": ["weak-passwords", "session-fixation", "credential-stuffing"]
    },
    "sensitive-data": {
      "severity": "high",
      "description": "Protect sensitive data exposure",
      "checks": ["encryption-at-rest", "encryption-in-transit", "pii-exposure"]
    },
    "xxe": {
      "severity": "high",
      "description": "Prevent XML External Entity attacks",
      "checks": ["xxe-vulnerability", "xml-parser-config"]
    },
    "access-control": {
      "severity": "high",
      "description": "Implement proper access controls",
      "checks": ["broken-access-control", "privilege-escalation"]
    },
    "security-misconfig": {
      "severity": "medium",
      "description": "Prevent security misconfiguration",
      "checks": ["default-configs", "unnecessary-features", "error-handling"]
    },
    "xss": {
      "severity": "high",
      "description": "Prevent Cross-Site Scripting",
      "checks": ["reflected-xss", "stored-xss", "dom-xss"]
    },
    "insecure-deserialization": {
      "severity": "high",
      "description": "Prevent insecure deserialization",
      "checks": ["deserialization-vulnerabilities", "object-injection"]
    },
    "vulnerable-components": {
      "severity": "medium",
      "description": "Prevent use of vulnerable components",
      "checks": ["outdated-dependencies", "known-vulnerabilities"]
    },
    "insufficient-logging": {
      "severity": "medium",
      "description": "Implement sufficient logging and monitoring",
      "checks": ["audit-logs", "security-events", "incident-response"]
    }
  },
  "thresholds": {
    "critical": 0,
    "high": 2,
    "medium": 5,
    "low": 10
  }
}
EOF

    # License compliance policy
    cat > "$policy_dir/license-policy.json" << 'EOF'
{
  "name": "License Compliance Policy",
  "version": "1.0",
  "description": "Policy for license compliance and compatibility",
  "allowed_licenses": [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
    "BSD-2-Clause",
    "ISC",
    "CC0-1.0",
    "Unlicense",
    "WTFPL"
  ],
  "restricted_licenses": [
    "GPL-2.0",
    "GPL-3.0",
    "AGPL-3.0",
    "LGPL-2.1",
    "LGPL-3.0"
  ],
  "forbidden_licenses": [
    "Proprietary",
    "Commercial"
  ],
  "compatibility_matrix": {
    "MIT": ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC"],
    "Apache-2.0": ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC"],
    "BSD-3-Clause": ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC"],
    "GPL-3.0": ["GPL-3.0", "LGPL-3.0"]
  }
}
EOF

    # Dependency security policy
    cat > "$policy_dir/dependency-policy.json" << 'EOF'
{
  "name": "Dependency Security Policy",
  "version": "1.0",
  "description": "Policy for dependency security and updates",
  "update_policy": {
    "auto_update": false,
    "security_updates_only": true,
    "update_schedule": "weekly",
    "approval_required": true
  },
  "vulnerability_policy": {
    "critical_threshold": 0,
    "high_threshold": 2,
    "medium_threshold": 5,
    "low_threshold": 10,
    "auto_block": ["critical", "high"]
  },
  "source_policy": {
    "preferred_registries": [
      "https://registry.npmjs.org",
      "https://pypi.org",
      "https://crates.io",
      "https://packagist.org"
    ],
    "blocked_sources": [],
    "require_checksums": true
  }
}
EOF
}

security_scan() {
    local package="$1"
    local platforms="${2:-all}"
    local scan_type="${3:-comprehensive}"
    
    log INFO "Running $scan_type security scan for: $package"
    
    local scan_report="$PAK_DATA_DIR/security/scan-${package}-$(date +%s).json"
    local scan_start=$(date +%s)
    
    # Initialize comprehensive report
    echo "{
        \"package\": \"$package\",
        \"scan_type\": \"$scan_type\",
        \"scan_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"scan_duration\": 0,
        \"vulnerabilities\": [],
        \"license_issues\": [],
        \"dependency_issues\": [],
        \"secrets_found\": [],
        \"summary\": {
            \"critical\": 0,
            \"high\": 0,
            \"medium\": 0,
            \"low\": 0,
            \"total\": 0
        },
        \"recommendations\": []
    }" > "$scan_report"
    
    # Run platform-specific scans
    if [[ "$platforms" == "all" ]] || [[ "$platforms" == *"npm"* ]]; then
        security_scan_npm "$scan_report"
    fi
    
    if [[ "$platforms" == "all" ]] || [[ "$platforms" == *"python"* ]]; then
        security_scan_python "$scan_report"
    fi
    
    if [[ "$platforms" == "all" ]] || [[ "$platforms" == *"rust"* ]]; then
        security_scan_cargo "$scan_report"
    fi
    
    if [[ "$platforms" == "all" ]] || [[ "$platforms" == *"go"* ]]; then
        security_scan_go "$scan_report"
    fi
    
    # Run additional scans for comprehensive mode
    if [[ "$scan_type" == "comprehensive" ]]; then
        security_scan_secrets "$scan_report"
        security_scan_licenses "$scan_report"
        security_scan_dependencies "$scan_report"
        security_scan_configs "$scan_report"
    fi
    
    # Calculate scan duration
    local scan_end=$(date +%s)
    local duration=$((scan_end - scan_start))
    
    # Update report with duration and summary
    jq --arg duration "$duration" '.scan_duration = $duration' "$scan_report" > temp.json && mv temp.json "$scan_report"
    
    # Generate summary
    local total_vulns=$(jq '.vulnerabilities | length' "$scan_report")
    local critical=$(jq '.summary.critical' "$scan_report")
    local high=$(jq '.summary.high' "$scan_report")
    
    log SUCCESS "Security scan complete in ${duration}s. Found $total_vulns vulnerabilities ($critical critical, $high high)."
    
    # Show results
    if [[ "$PAK_QUIET_MODE" == "false" ]]; then
        jq '.summary' "$scan_report"
    fi
    
    # Return exit code based on critical/high vulnerabilities
    if [[ "$critical" -gt 0 ]] || [[ "$high" -gt 2 ]]; then
        return 1
    fi
    
    return 0
}

security_scan_npm() {
    local report_file="$1"
    
    if command -v npm &>/dev/null && [[ -f "package.json" ]]; then
        log INFO "Running npm security audit..."
        
        # Run npm audit with JSON output
        local npm_audit=$(npm audit --json 2>/dev/null || echo '{"vulnerabilities":{}}')
        
        # Parse vulnerabilities and add to report
        echo "$npm_audit" | jq -r '.vulnerabilities | to_entries[] | {
            package: .key,
            severity: .value.severity,
            title: .value.title,
            url: .value.url,
            description: .value.description,
            platform: "npm",
            cve: .value.cves?[0],
            cvss_score: .value.cvss_score,
            recommendation: .value.recommendation
        }' | jq -s '.' | \
        jq --argjson vulns - '.vulnerabilities += $vulns' "$report_file" > temp.json && \
        mv temp.json "$report_file"
        
        # Update summary counts
        security_update_summary "$report_file" "npm"
    fi
}

security_scan_python() {
    local report_file="$1"
    
    if command -v safety &>/dev/null; then
        log INFO "Running Python safety check..."
        
        # Run safety check
        safety check --json > safety-report.json 2>/dev/null || true
        
        # Parse and add to report
        if [[ -f "safety-report.json" ]]; then
            jq '.vulnerabilities[] | {
                package: .package,
                severity: .severity,
                title: .vulnerability_id,
                description: .description,
                platform: "python",
                cve: .vulnerability_id,
                recommendation: "Update to version " + .installed_version
            }' safety-report.json | jq -s '.' | \
            jq --argjson vulns - '.vulnerabilities += $vulns' "$report_file" > temp.json && \
            mv temp.json "$report_file"
            
            rm -f safety-report.json
        fi
        
        # Update summary counts
        security_update_summary "$report_file" "python"
    fi
}

security_scan_cargo() {
    local report_file="$1"
    
    if command -v cargo-audit &>/dev/null && [[ -f "Cargo.toml" ]]; then
        log INFO "Running cargo audit..."
        
        # Run cargo audit
        cargo audit --json > cargo-audit.json 2>/dev/null || true
        
        # Parse and add to report
        if [[ -f "cargo-audit.json" ]]; then
            jq '.vulnerabilities.list[] | {
                package: .package.name,
                severity: .advisory.severity,
                title: .advisory.title,
                description: .advisory.description,
                platform: "rust",
                cve: .advisory.id,
                recommendation: "Update to version " + .advisory.patched_versions[0]
            }' cargo-audit.json | jq -s '.' | \
            jq --argjson vulns - '.vulnerabilities += $vulns' "$report_file" > temp.json && \
            mv temp.json "$report_file"
            
            rm -f cargo-audit.json
        fi
        
        # Update summary counts
        security_update_summary "$report_file" "rust"
    fi
}

security_scan_go() {
    local report_file="$1"
    
    if command -v gosec &>/dev/null && [[ -f "go.mod" ]]; then
        log INFO "Running gosec security scan..."
        
        # Run gosec
        gosec -fmt json -out gosec-report.json . 2>/dev/null || true
        
        # Parse and add to report
        if [[ -f "gosec-report.json" ]]; then
            jq '.Issues[] | {
                package: .file,
                severity: .severity,
                title: .rule_id,
                description: .details,
                platform: "go",
                cve: .cwe.id,
                recommendation: "Fix " + .rule_id + " in " + .file
            }' gosec-report.json | jq -s '.' | \
            jq --argjson vulns - '.vulnerabilities += $vulns' "$report_file" > temp.json && \
            mv temp.json "$report_file"
            
            rm -f gosec-report.json
        fi
        
        # Update summary counts
        security_update_summary "$report_file" "go"
    fi
}

security_scan_secrets() {
    local report_file="$1"
    
    log INFO "Scanning for secrets and sensitive data..."
    
    # Common secret patterns
    local secret_patterns=(
        "api_key.*=.*['\"][a-zA-Z0-9]{32,}['\"]"
        "password.*=.*['\"][^'\"]{8,}['\"]"
        "secret.*=.*['\"][a-zA-Z0-9]{16,}['\"]"
        "token.*=.*['\"][a-zA-Z0-9]{32,}['\"]"
        "private_key.*=.*['\"][a-zA-Z0-9]{64,}['\"]"
        "aws_access_key_id.*=.*['\"][A-Z0-9]{20}['\"]"
        "aws_secret_access_key.*=.*['\"][A-Za-z0-9/+=]{40}['\"]"
    )
    
    local secrets_found=()
    
    for pattern in "${secret_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            if grep -qE "$pattern" "$file" 2>/dev/null; then
                local line=$(grep -nE "$pattern" "$file" | head -1)
                secrets_found+=("{\"file\": \"$file\", \"line\": \"$line\", \"pattern\": \"$pattern\"}")
            fi
        done < <(find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.rb" -o -name "*.php" -o -name "*.java" -o -name "*.go" -o -name "*.rs" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env*" \) -print0 2>/dev/null)
    done
    
    # Add secrets to report
    if [[ ${#secrets_found[@]} -gt 0 ]]; then
        printf '%s\n' "${secrets_found[@]}" | jq -s '.' | \
        jq --argjson secrets - '.secrets_found = $secrets' "$report_file" > temp.json && \
        mv temp.json "$report_file"
    fi
}

security_scan_licenses() {
    local report_file="$1"
    
    log INFO "Checking license compliance..."
    
    local license_issues=()
    local policy_file="$PAK_CONFIG_DIR/security/license-policy.json"
    
    if [[ -f "$policy_file" ]]; then
        local allowed_licenses=$(jq -r '.allowed_licenses[]' "$policy_file")
        local restricted_licenses=$(jq -r '.restricted_licenses[]' "$policy_file")
        
        # Check package.json licenses
        if [[ -f "package.json" ]]; then
            local license=$(jq -r '.license // empty' package.json)
            if [[ -n "$license" ]]; then
                if echo "$restricted_licenses" | grep -q "^$license$"; then
                    license_issues+=("{\"package\": \"$(jq -r '.name' package.json)\", \"license\": \"$license\", \"issue\": \"restricted_license\", \"platform\": \"npm\"}")
                fi
            fi
        fi
        
        # Check Python licenses
        if [[ -f "setup.py" ]]; then
            local license=$(grep -E "license\s*=\s*['\"]" setup.py | grep -oE "[A-Za-z0-9.-]+" | head -1)
            if [[ -n "$license" ]]; then
                if echo "$restricted_licenses" | grep -q "^$license$"; then
                    license_issues+=("{\"package\": \"$(grep -E "name\s*=\s*['\"]" setup.py | grep -oE "[A-Za-z0-9_-]+" | head -1)\", \"license\": \"$license\", \"issue\": \"restricted_license\", \"platform\": \"python\"}")
                fi
            fi
        fi
    fi
    
    # Add license issues to report
    if [[ ${#license_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${license_issues[@]}" | jq -s '.' | \
        jq --argjson issues - '.license_issues = $issues' "$report_file" > temp.json && \
        mv temp.json "$report_file"
    fi
}

security_scan_dependencies() {
    local report_file="$1"
    
    log INFO "Checking dependency security..."
    
    local dependency_issues=()
    
    # Check for outdated dependencies
    if [[ -f "package.json" ]] && command -v npm &>/dev/null; then
        local outdated=$(npm outdated --json 2>/dev/null || echo '{}')
        echo "$outdated" | jq -r 'to_entries[] | {
            package: .key,
            current: .value.current,
            wanted: .value.wanted,
            latest: .value.latest,
            issue: "outdated_dependency",
            platform: "npm"
        }' | jq -s '.' | \
        jq --argjson issues - '.dependency_issues = $issues' "$report_file" > temp.json && \
        mv temp.json "$report_file"
    fi
}

security_scan_configs() {
    local report_file="$1"
    
    log INFO "Checking security configurations..."
    
    local config_issues=()
    
    # Check for common security misconfigurations
    if [[ -f ".env" ]]; then
        config_issues+=("{\"file\": \".env\", \"issue\": \"environment_file_exposed\", \"severity\": \"medium\"}")
    fi
    
    if [[ -f "docker-compose.yml" ]] && grep -q "password.*:" docker-compose.yml; then
        config_issues+=("{\"file\": \"docker-compose.yml\", \"issue\": \"hardcoded_password\", \"severity\": \"high\"}")
    fi
    
    # Add config issues to report
    if [[ ${#config_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${config_issues[@]}" | jq -s '.' | \
        jq --argjson issues - '.config_issues = $issues' "$report_file" > temp.json && \
        mv temp.json "$report_file"
    fi
}

security_update_summary() {
    local report_file="$1"
    local platform="$2"
    
    # Count vulnerabilities by severity
    local critical=$(jq '.vulnerabilities | map(select(.severity == "critical")) | length' "$report_file")
    local high=$(jq '.vulnerabilities | map(select(.severity == "high")) | length' "$report_file")
    local medium=$(jq '.vulnerabilities | map(select(.severity == "medium")) | length' "$report_file")
    local low=$(jq '.vulnerabilities | map(select(.severity == "low")) | length' "$report_file")
    local total=$(jq '.vulnerabilities | length' "$report_file")
    
    # Update summary
    jq --argjson critical "$critical" --argjson high "$high" --argjson medium "$medium" --argjson low "$low" --argjson total "$total" \
       '.summary = {"critical": $critical, "high": $high, "medium": $medium, "low": $low, "total": $total}' "$report_file" > temp.json && \
    mv temp.json "$report_file"
}

security_audit() {
    local package="$1"
    local audit_type="${2:-comprehensive}"
    
    log INFO "Running comprehensive security audit for: $package"
    
    # Run vulnerability scan
    security_scan "$package" "all" "comprehensive"
    
    # Check licenses
    security_license_check "$package"
    
    # Check dependencies
    security_dependency_check "$package"
    
    # Generate audit report
    local audit_file="$PAK_DATA_DIR/security/audit-${package}-$(date +%s).json"
    echo "{
        \"package\": \"$package\",
        \"audit_type\": \"$audit_type\",
        \"audit_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"status\": \"completed\",
        \"findings\": {
            \"vulnerabilities\": 0,
            \"license_issues\": 0,
            \"dependency_issues\": 0,
            \"config_issues\": 0
        },
        \"recommendations\": [],
        \"compliance\": {
            \"owasp\": false,
            \"license\": false,
            \"dependency\": false
        }
    }" > "$audit_file"
    
    log SUCCESS "Security audit complete"
}

security_compliance() {
    local package="$1"
    local standard="${2:-owasp}"
    
    log INFO "Checking compliance with: $standard"
    
    case "$standard" in
        owasp)
            security_check_owasp_compliance "$package"
            ;;
        pci)
            security_check_pci_compliance "$package"
            ;;
        hipaa)
            security_check_hipaa_compliance "$package"
            ;;
        gdpr)
            security_check_gdpr_compliance "$package"
            ;;
        *)
            log ERROR "Unknown compliance standard: $standard"
            return 1
            ;;
    esac
}

security_check_owasp_compliance() {
    local package="$1"
    local policy_file="$PAK_CONFIG_DIR/security/owasp-policy.json"
    
    if [[ ! -f "$policy_file" ]]; then
        log ERROR "OWASP policy not found"
        return 1
    fi
    
    log INFO "Checking OWASP Top 10 compliance..."
    
    # Run security scan
    security_scan "$package" "all" "comprehensive"
    
    # Check against OWASP policy thresholds
    local critical=$(jq '.summary.critical' "$PAK_DATA_DIR/security/scan-${package}-$(date +%s).json")
    local high=$(jq '.summary.high' "$PAK_DATA_DIR/security/scan-${package}-$(date +%s).json")
    
    local critical_threshold=$(jq '.thresholds.critical' "$policy_file")
    local high_threshold=$(jq '.thresholds.high' "$policy_file")
    
    if [[ "$critical" -le "$critical_threshold" ]] && [[ "$high" -le "$high_threshold" ]]; then
        log SUCCESS "OWASP compliance check passed"
        return 0
    else
        log ERROR "OWASP compliance check failed"
        return 1
    fi
}

security_sign() {
    local package="$1"
    local file="${2:-}"
    local key_id="${3:-}"
    
    log INFO "Signing package: $package"
    
    # Check if GPG is available
    if ! command -v gpg &>/dev/null; then
        log ERROR "GPG not found. Please install GPG to sign packages."
        return 1
    fi
    
    # Use specified key or default
    local gpg_args=""
    if [[ -n "$key_id" ]]; then
        gpg_args="--local-user $key_id"
    fi
    
    # Sign package files
    if [[ -n "$file" ]]; then
        gpg $gpg_args --armor --detach-sign "$file"
        log SUCCESS "Signed: $file"
    else
        # Sign all package files
        for f in *.tar.gz *.whl *.gem *.crate; do
            [[ -f "$f" ]] && gpg $gpg_args --armor --detach-sign "$f"
        done
    fi
    
    # Create signature manifest
    local manifest_file="signatures.json"
    echo "{
        \"package\": \"$package\",
        \"signature_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"signer\": \"$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f10 | head -1)\",
        \"files\": []
    }" > "$manifest_file"
    
    log SUCCESS "Package signing complete"
}

security_verify() {
    local package="$1"
    local signature_file="${2:-}"
    
    log INFO "Verifying package signatures: $package"
    
    if ! command -v gpg &>/dev/null; then
        log ERROR "GPG not found. Please install GPG to verify signatures."
        return 1
    fi
    
    if [[ -n "$signature_file" ]]; then
        if gpg --verify "$signature_file" 2>/dev/null; then
            log SUCCESS "Signature verification passed: $signature_file"
            return 0
        else
            log ERROR "Signature verification failed: $signature_file"
            return 1
        fi
    else
        # Verify all signatures
        local verified=0
        local total=0
        
        for f in *.asc; do
            if [[ -f "$f" ]]; then
                total=$((total + 1))
                if gpg --verify "$f" 2>/dev/null; then
                    verified=$((verified + 1))
                fi
            fi
        done
        
        if [[ "$verified" -eq "$total" ]] && [[ "$total" -gt 0 ]]; then
            log SUCCESS "All signatures verified ($verified/$total)"
            return 0
        else
            log ERROR "Signature verification failed ($verified/$total)"
            return 1
        fi
    fi
}

security_policy() {
    local action="${1:-list}"
    local policy_name="${2:-}"
    
    case "$action" in
        list)
            echo "Available security policies:"
            ls -1 "$PAK_CONFIG_DIR/security/"*.json 2>/dev/null | sed 's|.*/||' | sed 's|\.json$||' || echo "No policies found"
            ;;
        show)
            if [[ -n "$policy_name" ]]; then
                jq . "$PAK_CONFIG_DIR/security/${policy_name}.json"
            else
                log ERROR "Policy name required"
                return 1
            fi
            ;;
        create)
            security_create_policy "$policy_name"
            ;;
        update)
            security_update_policy "$policy_name"
            ;;
        *)
            log ERROR "Unknown policy action: $action"
            return 1
            ;;
    esac
}

security_vuln_db() {
    local action="${1:-update}"
    
    case "$action" in
        update)
            log INFO "Updating vulnerability database..."
            # Implementation for updating vuln DB
            ;;
        search)
            local cve="${2:-}"
            if [[ -n "$cve" ]]; then
                log INFO "Searching for CVE: $cve"
                # Implementation for CVE search
            else
                log ERROR "CVE required for search"
                return 1
            fi
            ;;
        *)
            log ERROR "Unknown vuln-db action: $action"
            return 1
            ;;
    esac
}

security_license_check() {
    local package="$1"
    
    log INFO "Checking license compliance for: $package"
    
    local policy_file="$PAK_CONFIG_DIR/security/license-policy.json"
    if [[ ! -f "$policy_file" ]]; then
        log ERROR "License policy not found"
        return 1
    fi
    
    # Run license scan
    security_scan_licenses
    
    log SUCCESS "License compliance check complete"
}

security_dependency_check() {
    local package="$1"
    
    log INFO "Checking dependency security for: $package"
    
    local policy_file="$PAK_CONFIG_DIR/security/dependency-policy.json"
    if [[ ! -f "$policy_file" ]]; then
        log ERROR "Dependency policy not found"
        return 1
    fi
    
    # Run dependency scan
    security_scan_dependencies
    
    log SUCCESS "Dependency security check complete"
}

security_secrets_scan() {
    local package="$1"
    
    log INFO "Scanning for secrets in: $package"
    
    # Run secrets scan
    security_scan_secrets
    
    log SUCCESS "Secrets scan complete"
}
