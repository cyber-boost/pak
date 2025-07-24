#!/bin/bash
# PAK.sh Deployment Validation - Comprehensive pre/post deployment validation
# Performs thorough validation and testing for all platforms

deployment_validation_init() {
    # Create validation directories
    mkdir -p "$PAK_DATA_DIR/validation"
    mkdir -p "$PAK_DATA_DIR/validation/checks"
    mkdir -p "$PAK_DATA_DIR/validation/tests"
    mkdir -p "$PAK_DATA_DIR/validation/reports"
    mkdir -p "$PAK_LOGS_DIR/validation"
    
    # Initialize validation components
    deployment_validation_init_checks
    deployment_validation_init_tests
    deployment_validation_init_reports
    
    log INFO "Deployment validation system initialized"
}

deployment_validation_register_commands() {
    register_command "validate" "validation" "deployment_validation_main"
    register_command "validate-pre" "validation" "deployment_validation_pre"
    register_command "validate-post" "validation" "deployment_validation_post"
    register_command "validate-license" "validation" "deployment_validation_license"
    register_command "validate-deps" "validation" "deployment_validation_dependencies"
    register_command "validate-conflicts" "validation" "deployment_validation_conflicts"
    register_command "validate-integrity" "validation" "deployment_validation_integrity"
    register_command "validate-health" "validation" "deployment_validation_health"
}

deployment_validation_init_checks() {
    # Create validation check configurations
    cat > "$PAK_DATA_DIR/validation/checks/license.json" << 'EOF'
{
    "name": "license_compatibility",
    "description": "Check license compatibility across platforms",
    "severity": "high",
    "platforms": ["all"],
    "checks": [
        {
            "name": "license_file_exists",
            "description": "Check if license file exists",
            "files": ["LICENSE", "LICENSE.txt", "license.txt", "COPYING"],
            "required": true
        },
        {
            "name": "license_in_package",
            "description": "Check if license is specified in package metadata",
            "fields": {
                "npm": "package.json.license",
                "pypi": "setup.py.license",
                "cargo": "Cargo.toml.package.license",
                "maven": "pom.xml.licenses.license.name"
            },
            "required": true
        },
        {
            "name": "license_compatibility",
            "description": "Check license compatibility with target platforms",
            "compatible_licenses": [
                "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause",
                "ISC", "CC0-1.0", "Unlicense", "WTFPL"
            ],
            "required": true
        }
    ]
}
EOF

    cat > "$PAK_DATA_DIR/validation/checks/dependencies.json" << 'EOF'
{
    "name": "dependency_validation",
    "description": "Validate dependencies and resolve conflicts",
    "severity": "high",
    "platforms": ["all"],
    "checks": [
        {
            "name": "dependency_resolution",
            "description": "Check if all dependencies can be resolved",
            "required": true
        },
        {
            "name": "version_conflicts",
            "description": "Check for version conflicts in dependencies",
            "required": true
        },
        {
            "name": "security_vulnerabilities",
            "description": "Check for known security vulnerabilities",
            "required": false
        },
        {
            "name": "license_conflicts",
            "description": "Check for license conflicts in dependencies",
            "required": false
        }
    ]
}
EOF

    cat > "$PAK_DATA_DIR/validation/checks/integrity.json" << 'EOF'
{
    "name": "package_integrity",
    "description": "Validate package integrity and structure",
    "severity": "high",
    "platforms": ["all"],
    "checks": [
        {
            "name": "file_structure",
            "description": "Check if package has correct file structure",
            "required": true
        },
        {
            "name": "metadata_completeness",
            "description": "Check if all required metadata is present",
            "required": true
        },
        {
            "name": "file_permissions",
            "description": "Check file permissions are appropriate",
            "required": false
        },
        {
            "name": "binary_compatibility",
            "description": "Check binary compatibility for compiled packages",
            "required": false
        }
    ]
}
EOF

    cat > "$PAK_DATA_DIR/validation/checks/requirements.json" << 'EOF'
{
    "name": "platform_requirements",
    "description": "Check platform-specific requirements",
    "severity": "medium",
    "platforms": ["specific"],
    "checks": {
        "npm": [
            {
                "name": "package_json_valid",
                "description": "Check if package.json is valid JSON",
                "required": true
            },
            {
                "name": "name_field_present",
                "description": "Check if name field is present",
                "required": true
            },
            {
                "name": "version_field_present",
                "description": "Check if version field is present",
                "required": true
            },
            {
                "name": "main_field_present",
                "description": "Check if main field is present for libraries",
                "required": false
            }
        ],
        "pypi": [
            {
                "name": "setup_files_present",
                "description": "Check if setup.py or pyproject.toml is present",
                "required": true
            },
            {
                "name": "version_specified",
                "description": "Check if version is specified",
                "required": true
            },
            {
                "name": "dependencies_specified",
                "description": "Check if dependencies are specified",
                "required": true
            }
        ],
        "cargo": [
            {
                "name": "cargo_toml_present",
                "description": "Check if Cargo.toml is present",
                "required": true
            },
            {
                "name": "package_section_present",
                "description": "Check if [package] section is present",
                "required": true
            },
            {
                "name": "version_specified",
                "description": "Check if version is specified",
                "required": true
            }
        ],
        "docker": [
            {
                "name": "dockerfile_present",
                "description": "Check if Dockerfile is present",
                "required": true
            },
            {
                "name": "dockerfile_valid",
                "description": "Check if Dockerfile syntax is valid",
                "required": true
            },
            {
                "name": "base_image_specified",
                "description": "Check if base image is specified",
                "required": true
            }
        ]
    }
}
EOF
}

deployment_validation_init_tests() {
    # Create test configurations
    cat > "$PAK_DATA_DIR/validation/tests/config.json" << 'EOF'
{
    "test_suites": {
        "unit_tests": {
            "description": "Run unit tests",
            "platforms": ["all"],
            "commands": {
                "npm": "npm test",
                "yarn": "yarn test",
                "pypi": "python -m pytest",
                "cargo": "cargo test",
                "go": "go test ./...",
                "maven": "mvn test",
                "dotnet": "dotnet test"
            },
            "timeout": 300,
            "required": true
        },
        "integration_tests": {
            "description": "Run integration tests",
            "platforms": ["all"],
            "commands": {
                "npm": "npm run test:integration",
                "yarn": "yarn test:integration",
                "pypi": "python -m pytest tests/integration",
                "cargo": "cargo test --test integration",
                "go": "go test ./... -tags=integration",
                "maven": "mvn verify",
                "dotnet": "dotnet test --filter Category=Integration"
            },
            "timeout": 600,
            "required": false
        },
        "build_tests": {
            "description": "Test package building",
            "platforms": ["all"],
            "commands": {
                "npm": "npm run build",
                "yarn": "yarn build",
                "pypi": "python -m build",
                "cargo": "cargo build --release",
                "go": "go build -o bin/app .",
                "maven": "mvn clean package",
                "dotnet": "dotnet build --configuration Release"
            },
            "timeout": 300,
            "required": true
        },
        "install_tests": {
            "description": "Test package installation",
            "platforms": ["all"],
            "commands": {
                "npm": "npm install -g .",
                "yarn": "yarn global add .",
                "pypi": "pip install -e .",
                "cargo": "cargo install --path .",
                "go": "go install .",
                "maven": "mvn install",
                "dotnet": "dotnet pack"
            },
            "timeout": 300,
            "required": true
        }
    }
}
EOF
}

deployment_validation_init_reports() {
    # Create report templates
    cat > "$PAK_DATA_DIR/validation/reports/template.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PAK.sh Deployment Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .check { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .check.pass { border-left-color: #4CAF50; background: #f1f8e9; }
        .check.fail { border-left-color: #f44336; background: #ffebee; }
        .check.warn { border-left-color: #ff9800; background: #fff3e0; }
        .summary { background: #e3f2fd; padding: 15px; border-radius: 5px; }
        .platform { margin: 15px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>PAK.sh Deployment Validation Report</h1>
        <p>Generated: {timestamp}</p>
        <p>Project: {project_name}</p>
        <p>Version: {version}</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Checks: {total_checks}</p>
        <p>Passed: {passed_checks}</p>
        <p>Failed: {failed_checks}</p>
        <p>Warnings: {warning_checks}</p>
    </div>
    
    {platform_sections}
</body>
</html>
EOF
}

deployment_validation_main() {
    local action="$1"
    local project_dir="$2"
    local platforms="${3:-all}"
    
    case "$action" in
        pre)
            deployment_validation_pre "$project_dir" "$platforms"
            ;;
        post)
            deployment_validation_post "$project_dir" "$platforms"
            ;;
        license)
            deployment_validation_license "$project_dir"
            ;;
        deps)
            deployment_validation_dependencies "$project_dir"
            ;;
        conflicts)
            deployment_validation_conflicts "$project_dir"
            ;;
        integrity)
            deployment_validation_integrity "$project_dir"
            ;;
        health)
            deployment_validation_health "$project_dir"
            ;;
        *)
            deployment_validation_usage
            ;;
    esac
}

deployment_validation_pre() {
    local project_dir="$1"
    local platforms="$2"
    
    log INFO "Running pre-deployment validation"
    log INFO "Project: $project_dir"
    log INFO "Platforms: $platforms"
    
    # Create validation session
    local session_id=$(date +%s)
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    # Initialize validation session
    deployment_validation_create_session "$session_id" "$project_dir" "$platforms" "$session_file"
    
    # Run all pre-deployment checks
    deployment_validation_run_license_checks "$project_dir" "$session_id"
    deployment_validation_run_dependency_checks "$project_dir" "$session_id"
    deployment_validation_run_integrity_checks "$project_dir" "$session_id"
    deployment_validation_run_requirement_checks "$project_dir" "$platforms" "$session_id"
    
    # Run tests
    deployment_validation_run_tests "$project_dir" "$platforms" "$session_id"
    
    # Generate report
    deployment_validation_generate_report "$session_id" "$session_file"
    
    # Check if validation passed
    local failed_checks=$(jq -r '.checks[] | select(.status == "failed") | .name' "$session_file" 2>/dev/null)
    
    if [[ -n "$failed_checks" ]]; then
        log ERROR "Pre-deployment validation failed"
        log ERROR "Failed checks: $failed_checks"
        return 1
    else
        log SUCCESS "Pre-deployment validation passed"
        return 0
    fi
}

deployment_validation_post() {
    local project_dir="$1"
    local platforms="$2"
    
    log INFO "Running post-deployment validation"
    log INFO "Project: $project_dir"
    log INFO "Platforms: $platforms"
    
    # Create validation session
    local session_id=$(date +%s)
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    # Initialize validation session
    deployment_validation_create_session "$session_id" "$project_dir" "$platforms" "$session_file"
    
    # Run post-deployment checks
    deployment_validation_run_health_checks "$project_dir" "$platforms" "$session_id"
    deployment_validation_run_availability_checks "$project_dir" "$platforms" "$session_id"
    deployment_validation_run_functionality_checks "$project_dir" "$platforms" "$session_id"
    
    # Generate report
    deployment_validation_generate_report "$session_id" "$session_file"
    
    # Check if validation passed
    local failed_checks=$(jq -r '.checks[] | select(.status == "failed") | .name' "$session_file" 2>/dev/null)
    
    if [[ -n "$failed_checks" ]]; then
        log ERROR "Post-deployment validation failed"
        log ERROR "Failed checks: $failed_checks"
        return 1
    else
        log SUCCESS "Post-deployment validation passed"
        return 0
    fi
}

deployment_validation_create_session() {
    local session_id="$1"
    local project_dir="$2"
    local platforms="$3"
    local session_file="$4"
    
    jq --null-input \
       --arg id "$session_id" \
       --arg project_dir "$project_dir" \
       --arg platforms "$platforms" \
       --arg started_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '{
           "session_id": $id,
           "project_dir": $project_dir,
           "platforms": ($platforms | split(" ") | map(select(length > 0))),
           "started_at": $started_at,
           "status": "in_progress",
           "checks": [],
           "tests": [],
           "errors": []
       }' > "$session_file"
}

deployment_validation_run_license_checks() {
    local project_dir="$1"
    local session_id="$2"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    log INFO "Running license validation checks"
    
    cd "$project_dir"
    
    # Check if license file exists
    local license_files=("LICENSE" "LICENSE.txt" "license.txt" "COPYING")
    local license_found=false
    
    for file in "${license_files[@]}"; do
        if [[ -f "$file" ]]; then
            license_found=true
            break
        fi
    done
    
    if [[ "$license_found" == "true" ]]; then
        deployment_validation_log_check "$session_id" "license_file_exists" "passed" "License file found"
    else
        deployment_validation_log_check "$session_id" "license_file_exists" "failed" "No license file found"
    fi
    
    # Check license in package metadata
    if [[ -f "package.json" ]]; then
        local license=$(jq -r '.license' package.json 2>/dev/null)
        if [[ "$license" != "null" && "$license" != "" ]]; then
            deployment_validation_log_check "$session_id" "license_in_package" "passed" "License specified in package.json: $license"
        else
            deployment_validation_log_check "$session_id" "license_in_package" "failed" "No license specified in package.json"
        fi
    elif [[ -f "setup.py" ]]; then
        local license=$(grep -o "license=['\"][^'\"]*['\"]" setup.py | head -1 | cut -d"'" -f2)
        if [[ -n "$license" ]]; then
            deployment_validation_log_check "$session_id" "license_in_package" "passed" "License specified in setup.py: $license"
        else
            deployment_validation_log_check "$session_id" "license_in_package" "failed" "No license specified in setup.py"
        fi
    elif [[ -f "Cargo.toml" ]]; then
        local license=$(grep -A 10 "\[package\]" Cargo.toml | grep "license = " | head -1 | cut -d'"' -f2)
        if [[ -n "$license" ]]; then
            deployment_validation_log_check "$session_id" "license_in_package" "passed" "License specified in Cargo.toml: $license"
        else
            deployment_validation_log_check "$session_id" "license_in_package" "failed" "No license specified in Cargo.toml"
        fi
    else
        deployment_validation_log_check "$session_id" "license_in_package" "warning" "No package metadata file found"
    fi
}

deployment_validation_run_dependency_checks() {
    local project_dir="$1"
    local session_id="$2"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    log INFO "Running dependency validation checks"
    
    cd "$project_dir"
    
    # Check dependency resolution
    if [[ -f "package.json" ]]; then
        if npm install --dry-run >/dev/null 2>&1; then
            deployment_validation_log_check "$session_id" "dependency_resolution" "passed" "NPM dependencies can be resolved"
        else
            deployment_validation_log_check "$session_id" "dependency_resolution" "failed" "NPM dependency resolution failed"
        fi
    elif [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        if pip install -e . --dry-run >/dev/null 2>&1; then
            deployment_validation_log_check "$session_id" "dependency_resolution" "passed" "Python dependencies can be resolved"
        else
            deployment_validation_log_check "$session_id" "dependency_resolution" "failed" "Python dependency resolution failed"
        fi
    elif [[ -f "Cargo.toml" ]]; then
        if cargo check >/dev/null 2>&1; then
            deployment_validation_log_check "$session_id" "dependency_resolution" "passed" "Cargo dependencies can be resolved"
        else
            deployment_validation_log_check "$session_id" "dependency_resolution" "failed" "Cargo dependency resolution failed"
        fi
    else
        deployment_validation_log_check "$session_id" "dependency_resolution" "warning" "No dependency file found"
    fi
    
    # Check for security vulnerabilities (if tools available)
    if command -v npm-audit >/dev/null && [[ -f "package.json" ]]; then
        if npm audit --audit-level=moderate >/dev/null 2>&1; then
            deployment_validation_log_check "$session_id" "security_vulnerabilities" "passed" "No security vulnerabilities found"
        else
            deployment_validation_log_check "$session_id" "security_vulnerabilities" "warning" "Security vulnerabilities found"
        fi
    fi
}

deployment_validation_run_integrity_checks() {
    local project_dir="$1"
    local session_id="$2"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    log INFO "Running package integrity checks"
    
    cd "$project_dir"
    
    # Check file structure
    local required_files=()
    
    if [[ -f "package.json" ]]; then
        required_files=("package.json" "README.md")
    elif [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        required_files=("README.md")
    elif [[ -f "Cargo.toml" ]]; then
        required_files=("Cargo.toml" "src")
    elif [[ -f "go.mod" ]]; then
        required_files=("go.mod" "README.md")
    fi
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        deployment_validation_log_check "$session_id" "file_structure" "passed" "All required files present"
    else
        deployment_validation_log_check "$session_id" "file_structure" "failed" "Missing files: ${missing_files[*]}"
    fi
    
    # Check metadata completeness
    local metadata_complete=true
    local missing_metadata=()
    
    if [[ -f "package.json" ]]; then
        local fields=("name" "version" "description")
        for field in "${fields[@]}"; do
            local value=$(jq -r ".$field" package.json 2>/dev/null)
            if [[ "$value" == "null" || "$value" == "" ]]; then
                metadata_complete=false
                missing_metadata+=("$field")
            fi
        done
    fi
    
    if [[ "$metadata_complete" == "true" ]]; then
        deployment_validation_log_check "$session_id" "metadata_completeness" "passed" "All required metadata present"
    else
        deployment_validation_log_check "$session_id" "metadata_completeness" "failed" "Missing metadata: ${missing_metadata[*]}"
    fi
}

deployment_validation_run_requirement_checks() {
    local project_dir="$1"
    local platforms="$2"
    local session_id="$3"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    log INFO "Running platform requirement checks"
    
    cd "$project_dir"
    
    # Load requirements configuration
    local requirements_file="$PAK_DATA_DIR/validation/checks/requirements.json"
    
    for platform in $platforms; do
        local platform_checks=$(jq -r ".checks.$platform[] | .name" "$requirements_file" 2>/dev/null)
        
        for check in $platform_checks; do
            case "$check" in
                package_json_valid)
                    if [[ -f "package.json" ]] && jq . package.json >/dev/null 2>&1; then
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "package.json is valid JSON"
                    else
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "package.json is not valid JSON"
                    fi
                    ;;
                name_field_present)
                    if [[ -f "package.json" ]]; then
                        local name=$(jq -r '.name' package.json 2>/dev/null)
                        if [[ "$name" != "null" && "$name" != "" ]]; then
                            deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "Name field present: $name"
                        else
                            deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "Name field missing"
                        fi
                    fi
                    ;;
                version_field_present)
                    if [[ -f "package.json" ]]; then
                        local version=$(jq -r '.version' package.json 2>/dev/null)
                        if [[ "$version" != "null" && "$version" != "" ]]; then
                            deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "Version field present: $version"
                        else
                            deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "Version field missing"
                        fi
                    fi
                    ;;
                setup_files_present)
                    if [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "Setup files present"
                    else
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "No setup.py or pyproject.toml found"
                    fi
                    ;;
                cargo_toml_present)
                    if [[ -f "Cargo.toml" ]]; then
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "Cargo.toml present"
                    else
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "Cargo.toml not found"
                    fi
                    ;;
                dockerfile_present)
                    if [[ -f "Dockerfile" ]]; then
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "passed" "Dockerfile present"
                    else
                        deployment_validation_log_check "$session_id" "${platform}_${check}" "failed" "Dockerfile not found"
                    fi
                    ;;
            esac
        done
    done
}

deployment_validation_run_tests() {
    local project_dir="$1"
    local platforms="$2"
    local session_id="$3"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    log INFO "Running validation tests"
    
    cd "$project_dir"
    
    # Load test configuration
    local test_config="$PAK_DATA_DIR/validation/tests/config.json"
    
    # Run tests for each platform
    for platform in $platforms; do
        local test_suites=$(jq -r '.test_suites | keys[]' "$test_config")
        
        for suite in $test_suites; do
            local command=$(jq -r ".test_suites.$suite.commands.$platform" "$test_config" 2>/dev/null)
            local timeout=$(jq -r ".test_suites.$suite.timeout" "$test_config")
            local required=$(jq -r ".test_suites.$suite.required" "$test_config")
            
            if [[ "$command" != "null" && "$command" != "" ]]; then
                log INFO "Running $suite test for $platform"
                
                # Run test with timeout
                if timeout "$timeout" bash -c "$command" >/dev/null 2>&1; then
                    deployment_validation_log_test "$session_id" "$platform" "$suite" "passed" "Test completed successfully"
                else
                    if [[ "$required" == "true" ]]; then
                        deployment_validation_log_test "$session_id" "$platform" "$suite" "failed" "Test failed"
                    else
                        deployment_validation_log_test "$session_id" "$platform" "$suite" "warning" "Optional test failed"
                    fi
                fi
            fi
        done
    done
}

deployment_validation_run_health_checks() {
    local project_dir="$1"
    local platforms="$2"
    local session_id="$3"
    
    log INFO "Running health checks"
    
    # Platform-specific health checks
    for platform in $platforms; do
        case "$platform" in
            npm)
                # Check npm registry health
                if curl -s https://registry.npmjs.org/-/ping >/dev/null; then
                    deployment_validation_log_check "$session_id" "${platform}_health" "passed" "NPM registry is healthy"
                else
                    deployment_validation_log_check "$session_id" "${platform}_health" "failed" "NPM registry is not responding"
                fi
                ;;
            pypi)
                # Check PyPI health
                if curl -s https://pypi.org/health >/dev/null; then
                    deployment_validation_log_check "$session_id" "${platform}_health" "passed" "PyPI is healthy"
                else
                    deployment_validation_log_check "$session_id" "${platform}_health" "failed" "PyPI is not responding"
                fi
                ;;
            cargo)
                # Check crates.io health
                if curl -s https://crates.io/api/v1/summary >/dev/null; then
                    deployment_validation_log_check "$session_id" "${platform}_health" "passed" "Crates.io is healthy"
                else
                    deployment_validation_log_check "$session_id" "${platform}_health" "failed" "Crates.io is not responding"
                fi
                ;;
        esac
    done
}

deployment_validation_run_availability_checks() {
    local project_dir="$1"
    local platforms="$2"
    local session_id="$3"
    
    log INFO "Running availability checks"
    
    # Get package metadata
    local package_name=$(basename "$project_dir")
    local version=$(deployment_validation_get_version "$project_dir")
    
    # Check if package is available on platforms
    for platform in $platforms; do
        case "$platform" in
            npm)
                if npm view "$package_name@$version" version >/dev/null 2>&1; then
                    deployment_validation_log_check "$session_id" "${platform}_availability" "passed" "Package available on NPM"
                else
                    deployment_validation_log_check "$session_id" "${platform}_availability" "failed" "Package not available on NPM"
                fi
                ;;
            pypi)
                if pip show "$package_name" | grep -q "Version: $version" 2>/dev/null; then
                    deployment_validation_log_check "$session_id" "${platform}_availability" "passed" "Package available on PyPI"
                else
                    deployment_validation_log_check "$session_id" "${platform}_availability" "failed" "Package not available on PyPI"
                fi
                ;;
            cargo)
                if cargo search "$package_name" | grep -q "$version" 2>/dev/null; then
                    deployment_validation_log_check "$session_id" "${platform}_availability" "passed" "Package available on Crates.io"
                else
                    deployment_validation_log_check "$session_id" "${platform}_availability" "failed" "Package not available on Crates.io"
                fi
                ;;
        esac
    done
}

deployment_validation_run_functionality_checks() {
    local project_dir="$1"
    local platforms="$2"
    local session_id="$3"
    
    log INFO "Running functionality checks"
    
    # Basic functionality tests
    for platform in $platforms; do
        case "$platform" in
            npm)
                # Test if package can be installed
                if npm install -g "$package_name@$version" >/dev/null 2>&1; then
                    deployment_validation_log_check "$session_id" "${platform}_functionality" "passed" "Package can be installed"
                else
                    deployment_validation_log_check "$session_id" "${platform}_functionality" "failed" "Package cannot be installed"
                fi
                ;;
            pypi)
                # Test if package can be installed
                if pip install "$package_name==$version" >/dev/null 2>&1; then
                    deployment_validation_log_check "$session_id" "${platform}_functionality" "passed" "Package can be installed"
                else
                    deployment_validation_log_check "$session_id" "${platform}_functionality" "failed" "Package cannot be installed"
                fi
                ;;
        esac
    done
}

deployment_validation_generate_report() {
    local session_id="$1"
    local session_file="$2"
    
    log INFO "Generating validation report"
    
    # Get session data
    local project_name=$(basename "$(jq -r '.project_dir' "$session_file")")
    local version=$(deployment_validation_get_version "$(jq -r '.project_dir' "$session_file")")
    local timestamp=$(jq -r '.started_at' "$session_file")
    
    # Count results
    local total_checks=$(jq '.checks | length' "$session_file")
    local passed_checks=$(jq '.checks | map(select(.status == "passed")) | length' "$session_file")
    local failed_checks=$(jq '.checks | map(select(.status == "failed")) | length' "$session_file")
    local warning_checks=$(jq '.checks | map(select(.status == "warning")) | length' "$session_file")
    
    # Generate HTML report
    local report_file="$PAK_DATA_DIR/validation/reports/report_${session_id}.html"
    local template_file="$PAK_DATA_DIR/validation/reports/template.html"
    
    # Replace placeholders in template
    sed "s/{timestamp}/$timestamp/g; s/{project_name}/$project_name/g; s/{version}/$version/g; s/{total_checks}/$total_checks/g; s/{passed_checks}/$passed_checks/g; s/{failed_checks}/$failed_checks/g; s/{warning_checks}/$warning_checks/g" "$template_file" > "$report_file"
    
    log SUCCESS "Validation report generated: $report_file"
}

# Helper functions
deployment_validation_log_check() {
    local session_id="$1"
    local check_name="$2"
    local status="$3"
    local message="$4"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    jq --arg name "$check_name" --arg status "$status" --arg message "$message" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.checks += [{"name": $name, "status": $status, "message": $message, "timestamp": $timestamp}]' \
       "$session_file" > temp.json && mv temp.json "$session_file"
}

deployment_validation_log_test() {
    local session_id="$1"
    local platform="$2"
    local test_name="$3"
    local status="$4"
    local message="$5"
    local session_file="$PAK_DATA_DIR/validation/session_${session_id}.json"
    
    jq --arg platform "$platform" --arg test "$test_name" --arg status "$status" --arg message "$message" --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.tests += [{"platform": $platform, "test": $test, "status": $status, "message": $message, "timestamp": $timestamp}]' \
       "$session_file" > temp.json && mv temp.json "$session_file"
}

deployment_validation_get_version() {
    local project_dir="$1"
    
    cd "$project_dir"
    
    if [[ -f "package.json" ]]; then
        jq -r '.version' package.json 2>/dev/null
    elif [[ -f "setup.py" ]]; then
        grep -o "version=['\"][^'\"]*['\"]" setup.py | head -1 | cut -d"'" -f2
    elif [[ -f "Cargo.toml" ]]; then
        grep -A 10 "\[package\]" Cargo.toml | grep "version = " | head -1 | cut -d'"' -f2
    else
        echo "unknown"
    fi
}

deployment_validation_usage() {
    echo "PAK.sh Deployment Validation"
    echo "============================"
    echo ""
    echo "Usage: validate <action> <project_dir> [platforms]"
    echo ""
    echo "Actions:"
    echo "  pre        - Run pre-deployment validation"
    echo "  post       - Run post-deployment validation"
    echo "  license    - Validate license compatibility"
    echo "  deps       - Validate dependencies"
    echo "  conflicts  - Check for version conflicts"
    echo "  integrity  - Validate package integrity"
    echo "  health     - Check platform health"
    echo ""
    echo "Examples:"
    echo "  validate pre ./my-project"
    echo "  validate pre ./my-project npm pypi"
    echo "  validate post ./my-project"
    echo "  validate license ./my-project"
    echo "  validate deps ./my-project"
    echo "  validate integrity ./my-project"
    echo "  validate health ./my-project"
}

# Export functions
export -f deployment_validation_main deployment_validation_pre deployment_validation_post deployment_validation_license deployment_validation_dependencies deployment_validation_conflicts deployment_validation_integrity deployment_validation_health 