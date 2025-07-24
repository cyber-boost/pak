#!/bin/bash
# Enhanced Automation module - CI/CD and automated workflows

automation_init() {
    log DEBUG "Enhanced Automation module initialized"
    
    # Create automation directories
    mkdir -p "$PAK_CONFIG_DIR/pipelines"
    mkdir -p "$PAK_CONFIG_DIR/hooks"
    mkdir -p "$PAK_TEMPLATES_DIR/ci"
    mkdir -p "$PAK_SCRIPTS_DIR/automation"
    
    # Initialize automation templates
    automation_init_templates
}

automation_register_commands() {
    register_command "auto-deploy" "automation" "automation_deploy"
    register_command "pipeline" "automation" "automation_pipeline"
    register_command "schedule" "automation" "automation_schedule"
    register_command "hooks" "automation" "automation_hooks"
    register_command "release" "automation" "automation_release"
    register_command "test" "automation" "automation_test"
    register_command "build" "automation" "automation_build"
    register_command "deploy" "automation" "automation_deploy_package"
    register_command "rollback" "automation" "automation_rollback"
    register_command "monitor" "automation" "automation_monitor"
}

automation_init_templates() {
    local templates_dir="$PAK_TEMPLATES_DIR/ci"
    
    # GitHub Actions template
    cat > "$templates_dir/github-actions.yml" << 'EOF'
name: PAK CI/CD Pipeline

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  release:
    types: [ published ]

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.11'
  RUST_VERSION: '1.70'

jobs:
  test:
    name: Test Suite
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [ubuntu-latest, macos-latest, windows-latest]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Node.js
        if: hashFiles('package.json') != ''
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          
      - name: Setup Python
        if: hashFiles('requirements.txt') != '' || hashFiles('setup.py') != ''
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          
      - name: Setup Rust
        if: hashFiles('Cargo.toml') != ''
        uses: actions-rs/toolchain@v1
        with:
          toolchain: ${{ env.RUST_VERSION }}
          
      - name: Install dependencies
        run: |
          if [ -f package.json ]; then npm ci; fi
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f Cargo.toml ]; then cargo build; fi
          
      - name: Run tests
        run: |
          if [ -f package.json ] && npm run test; then npm test; fi
          if [ -f pytest.ini ] || [ -f pyproject.toml ]; then pytest; fi
          if [ -f Cargo.toml ]; then cargo test; fi
          
      - name: Run security scan
        run: |
          if command -v pak; then
            pak scan . --platform all
          fi

  build:
    name: Build Package
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup build environment
        run: |
          curl -sSL https://pak.sh/install | bash
          echo "$HOME/.pak/bin" >> $GITHUB_PATH
          
      - name: Build package
        run: pak build . --version ${{ github.event.release.tag_name }}
        
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: package-artifacts
          path: dist/

  deploy:
    name: Deploy Package
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Download artifacts
        uses: actions/download-artifact@v3
        with:
          name: package-artifacts
          path: dist/
          
      - name: Setup deployment
        run: |
          curl -sSL https://pak.sh/install | bash
          echo "$HOME/.pak/bin" >> $GITHUB_PATH
          
      - name: Deploy to NPM
        if: hashFiles('package.json') != ''
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: pak deploy . --platform npm --version ${{ github.event.release.tag_name }}
        
      - name: Deploy to PyPI
        if: hashFiles('setup.py') != '' || hashFiles('pyproject.toml') != ''
        env:
          PYPI_TOKEN: ${{ secrets.PYPI_TOKEN }}
        run: pak deploy . --platform pypi --version ${{ github.event.release.tag_name }}
        
      - name: Deploy to Cargo
        if: hashFiles('Cargo.toml') != ''
        env:
          CARGO_TOKEN: ${{ secrets.CARGO_TOKEN }}
        run: pak deploy . --platform cargo --version ${{ github.event.release.tag_name }}

  notify:
    name: Notify Team
    needs: [test, deploy]
    runs-on: ubuntu-latest
    if: always()
    
    steps:
      - name: Notify Slack
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          status: failure
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          
      - name: Notify Discord
        if: success()
        uses: sarisia/actions-status-discord@v1
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          status: success
EOF

    # GitLab CI template
    cat > "$templates_dir/gitlab-ci.yml" << 'EOF'
stages:
  - test
  - build
  - deploy
  - notify

variables:
  NODE_VERSION: "18"
  PYTHON_VERSION: "3.11"
  RUST_VERSION: "1.70"

.test_template: &test_template
  stage: test
  script:
    - |
      if [ -f package.json ]; then
        npm ci
        npm test
      fi
      if [ -f requirements.txt ]; then
        pip install -r requirements.txt
        pytest
      fi
      if [ -f Cargo.toml ]; then
        cargo test
      fi
      if command -v pak; then
        pak scan . --platform all
      fi

test:node:
  <<: *test_template
  image: node:$NODE_VERSION
  only:
    changes:
      - package.json
      - package-lock.json
      - "**/*.js"
      - "**/*.ts"

test:python:
  <<: *test_template
  image: python:$PYTHON_VERSION
  only:
    changes:
      - requirements.txt
      - setup.py
      - pyproject.toml
      - "**/*.py"

test:rust:
  <<: *test_template
  image: rust:$RUST_VERSION
  only:
    changes:
      - Cargo.toml
      - Cargo.lock
      - "**/*.rs"

build:
  stage: build
  image: alpine:latest
  script:
    - apk add --no-cache curl bash
    - curl -sSL https://pak.sh/install | bash
    - pak build . --version $CI_COMMIT_TAG
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  only:
    - tags

deploy:npm:
  stage: deploy
  image: node:$NODE_VERSION
  script:
    - curl -sSL https://pak.sh/install | bash
    - pak deploy . --platform npm --version $CI_COMMIT_TAG
  environment:
    name: production
  only:
    - tags
  when: manual

deploy:pypi:
  stage: deploy
  image: python:$PYTHON_VERSION
  script:
    - curl -sSL https://pak.sh/install | bash
    - pak deploy . --platform pypi --version $CI_COMMIT_TAG
  environment:
    name: production
  only:
    - tags
  when: manual

notify:success:
  stage: notify
  script:
    - echo "Deployment successful: $CI_COMMIT_TAG"
  only:
    - tags
  when: on_success

notify:failure:
  stage: notify
  script:
    - echo "Deployment failed: $CI_COMMIT_TAG"
  only:
    - tags
  when: on_failure
EOF

    # Jenkins pipeline template
    cat > "$templates_dir/Jenkinsfile" << 'EOF'
pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        PYTHON_VERSION = '3.11'
        RUST_VERSION = '1.70'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            parallel {
                stage('Setup Node.js') {
                    when {
                        anyOf {
                            changeset pattern: "package.json", comparator: "REGEXP"
                            changeset pattern: ".*\\.js$", comparator: "REGEXP"
                            changeset pattern: ".*\\.ts$", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
                        sh 'source ~/.bashrc && nvm install $NODE_VERSION && nvm use $NODE_VERSION'
                    }
                }
                
                stage('Setup Python') {
                    when {
                        anyOf {
                            changeset pattern: "requirements.txt", comparator: "REGEXP"
                            changeset pattern: "setup.py", comparator: "REGEXP"
                            changeset pattern: ".*\\.py$", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'pyenv install $PYTHON_VERSION && pyenv global $PYTHON_VERSION'
                    }
                }
                
                stage('Setup Rust') {
                    when {
                        anyOf {
                            changeset pattern: "Cargo.toml", comparator: "REGEXP"
                            changeset pattern: ".*\\.rs$", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
                        sh 'source ~/.cargo/env && rustup default $RUST_VERSION'
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    if (fileExists('package.json')) {
                        sh 'npm ci'
                    }
                    if (fileExists('requirements.txt')) {
                        sh 'pip install -r requirements.txt'
                    }
                    if (fileExists('Cargo.toml')) {
                        sh 'cargo build'
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Node.js Tests') {
                    when {
                        anyOf {
                            changeset pattern: "package.json", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'npm test'
                    }
                }
                
                stage('Python Tests') {
                    when {
                        anyOf {
                            changeset pattern: "requirements.txt", comparator: "REGEXP"
                            changeset pattern: "setup.py", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'pytest'
                    }
                }
                
                stage('Rust Tests') {
                    when {
                        anyOf {
                            changeset pattern: "Cargo.toml", comparator: "REGEXP"
                        }
                    }
                    steps {
                        sh 'cargo test'
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'curl -sSL https://pak.sh/install | bash'
                sh 'pak scan . --platform all'
            }
        }
        
        stage('Build') {
            when {
                tag pattern: "v*", comparator: "REGEXP"
            }
            steps {
                script {
                    def version = env.TAG_NAME.replaceAll('v', '')
                    sh "pak build . --version $version"
                }
            }
        }
        
        stage('Deploy') {
            when {
                tag pattern: "v*", comparator: "REGEXP"
            }
            parallel {
                stage('Deploy to NPM') {
                    when {
                        anyOf {
                            changeset pattern: "package.json", comparator: "REGEXP"
                        }
                    }
                    steps {
                        script {
                            def version = env.TAG_NAME.replaceAll('v', '')
                            withCredentials([string(credentialsId: 'npm-token', variable: 'NPM_TOKEN')]) {
                                sh "pak deploy . --platform npm --version $version"
                            }
                        }
                    }
                }
                
                stage('Deploy to PyPI') {
                    when {
                        anyOf {
                            changeset pattern: "requirements.txt", comparator: "REGEXP"
                            changeset pattern: "setup.py", comparator: "REGEXP"
                        }
                    }
                    steps {
                        script {
                            def version = env.TAG_NAME.replaceAll('v', '')
                            withCredentials([string(credentialsId: 'pypi-token', variable: 'PYPI_TOKEN')]) {
                                sh "pak deploy . --platform pypi --version $version"
                            }
                        }
                    }
                }
                
                stage('Deploy to Cargo') {
                    when {
                        anyOf {
                            changeset pattern: "Cargo.toml", comparator: "REGEXP"
                        }
                    }
                    steps {
                        script {
                            def version = env.TAG_NAME.replaceAll('v', '')
                            withCredentials([string(credentialsId: 'cargo-token', variable: 'CARGO_TOKEN')]) {
                                sh "pak deploy . --platform cargo --version $version"
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
EOF
}

automation_deploy() {
    local package="$1"
    local trigger="${2:-manual}"
    local environment="${3:-production}"
    
    log INFO "Starting automated deployment for: $package (trigger: $trigger, env: $environment)"
    
    # Run pre-deployment checks
    if ! automation_pre_deploy_checks "$package"; then
        log ERROR "Pre-deployment checks failed"
        return 1
    fi
    
    # Determine version
    local version=$(automation_determine_version "$package")
    
    # Build package
    if ! automation_build_package "$package" "$version"; then
        log ERROR "Build failed"
        return 1
    fi
    
    # Deploy
    if ! automation_deploy_package "$package" "$version" "$environment"; then
        log ERROR "Deployment failed"
        automation_rollback "$package" "$version"
        return 1
    fi
    
    # Post-deployment tasks
    automation_post_deploy_tasks "$package" "$version" "$environment"
    
    log SUCCESS "Automated deployment completed successfully"
}

automation_pre_deploy_checks() {
    local package="$1"
    
    log INFO "Running pre-deployment checks..."
    
    # Run tests
    if ! automation_run_tests "$package"; then
        log ERROR "Tests failed"
        return 1
    fi
    
    # Run security scan
    if ! security_scan "$package" "all" "comprehensive"; then
        log ERROR "Security scan failed"
        return 1
    fi
    
    # Check branch
    local current_branch=$(git branch --show-current 2>/dev/null)
    if [[ "$current_branch" != "main" ]] && [[ "$current_branch" != "master" ]]; then
        log WARN "Not on main branch: $current_branch"
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log WARN "Uncommitted changes detected"
    fi
    
    return 0
}

automation_run_tests() {
    local package="$1"
    
    log INFO "Running test suite..."
    
    # Node.js tests
    if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
        if ! npm test; then
            log ERROR "Node.js tests failed"
            return 1
        fi
    fi
    
    # Python tests
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        if ! pytest; then
            log ERROR "Python tests failed"
            return 1
        fi
    fi
    
    # Rust tests
    if [[ -f "Cargo.toml" ]]; then
        if ! cargo test; then
            log ERROR "Rust tests failed"
            return 1
        fi
    fi
    
    log SUCCESS "All tests passed"
    return 0
}

automation_build_package() {
    local package="$1"
    local version="$2"
    
    log INFO "Building package: $package v$version"
    
    # Node.js build
    if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
        npm run build
    fi
    
    # Python build
    if [[ -f "setup.py" ]]; then
        python setup.py sdist bdist_wheel
    fi
    
    # Rust build
    if [[ -f "Cargo.toml" ]]; then
        cargo build --release
    fi
    
    log SUCCESS "Build completed"
    return 0
}

automation_deploy_package() {
    local package="$1"
    local version="$2"
    local environment="$3"
    
    log INFO "Deploying package: $package v$version to $environment"
    
    # Deploy to NPM
    if [[ -f "package.json" ]]; then
        if ! pak deploy "$package" --platform npm --version "$version"; then
            log ERROR "NPM deployment failed"
            return 1
        fi
    fi
    
    # Deploy to PyPI
    if [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        if ! pak deploy "$package" --platform pypi --version "$version"; then
            log ERROR "PyPI deployment failed"
            return 1
        fi
    fi
    
    # Deploy to Cargo
    if [[ -f "Cargo.toml" ]]; then
        if ! pak deploy "$package" --platform cargo --version "$version"; then
            log ERROR "Cargo deployment failed"
            return 1
        fi
    fi
    
    log SUCCESS "Deployment completed"
    return 0
}

automation_post_deploy_tasks() {
    local package="$1"
    local version="$2"
    local environment="$3"
    
    log INFO "Running post-deployment tasks..."
    
    # Update deployment history
    local deploy_log="$PAK_DATA_DIR/deployments/${package}-${version}.json"
    echo "{
        \"package\": \"$package\",
        \"version\": \"$version\",
        \"environment\": \"$environment\",
        \"deploy_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"status\": \"success\"
    }" > "$deploy_log"
    
    # Send notifications
    automation_send_notifications "$package" "$version" "$environment" "success"
    
    # Update monitoring
    automation_update_monitoring "$package" "$version"
}

automation_determine_version() {
    local package="$1"
    local bump_type="${AUTO_VERSION_BUMP:-patch}"
    
    # Get current version
    local current_version=""
    
    if [[ -f "package.json" ]]; then
        current_version=$(jq -r '.version' package.json)
    elif [[ -f "setup.py" ]]; then
        current_version=$(grep -E "version\s*=\s*['\"]" setup.py | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
    elif [[ -f "Cargo.toml" ]]; then
        current_version=$(grep -E '^version\s*=' Cargo.toml | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"')
    fi
    
    # Bump version
    if command -v semver &>/dev/null; then
        semver -i "$bump_type" "$current_version"
    else
        echo "$current_version"
    fi
}

automation_pipeline() {
    local action="${1:-show}"
    local pipeline_name="${2:-default}"
    local platform="${3:-github}"
    
    case "$action" in
        create)
            automation_create_pipeline "$pipeline_name" "$platform"
            ;;
        run)
            automation_run_pipeline "$pipeline_name"
            ;;
        show)
            automation_show_pipeline "$pipeline_name"
            ;;
        validate)
            automation_validate_pipeline "$pipeline_name"
            ;;
        *)
            log ERROR "Unknown pipeline action: $action"
            return 1
            ;;
    esac
}

automation_create_pipeline() {
    local name="$1"
    local platform="$2"
    local template_file="$PAK_TEMPLATES_DIR/ci/${platform}-ci.yml"
    
    if [[ ! -f "$template_file" ]]; then
        log ERROR "Template not found for platform: $platform"
        return 1
    fi
    
    # Copy template to project
    case "$platform" in
        github)
            mkdir -p .github/workflows
            cp "$template_file" ".github/workflows/${name}.yml"
            ;;
        gitlab)
            cp "$template_file" ".gitlab-ci.yml"
            ;;
        jenkins)
            cp "$template_file" "Jenkinsfile"
            ;;
        *)
            log ERROR "Unsupported platform: $platform"
            return 1
            ;;
    esac
    
    log SUCCESS "Pipeline created: $name for $platform"
}

automation_schedule() {
    local package="$1"
    local schedule="$2"
    local action="${3:-deploy}"
    
    log INFO "Scheduling $action for $package: $schedule"
    
    # Create cron entry
    local cron_cmd="$PAK_DIR/pak.sh $action $package --auto"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "pak.*$package.*$action"; echo "$schedule $cron_cmd") | crontab -
    
    log SUCCESS "Scheduled $action for $package"
}

automation_hooks() {
    local action="${1:-list}"
    
    case "$action" in
        install)
            automation_install_git_hooks
            ;;
        list)
            echo "Installed hooks:"
            ls -la .git/hooks/ 2>/dev/null | grep -v "\.sample$"
            ;;
        remove)
            automation_remove_git_hooks
            ;;
        *)
            log ERROR "Unknown hooks action: $action"
            return 1
            ;;
    esac
}

automation_install_git_hooks() {
    log INFO "Installing git hooks..."
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOFH'
#!/bin/bash
# PAK pre-commit hook

echo "Running pre-commit checks..."

# Run linting
if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
    npm run lint || exit 1
fi

if [[ -f "pyproject.toml" ]] && grep -q "black" pyproject.toml; then
    black --check . || exit 1
fi

# Run tests
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    npm test || exit 1
fi

echo "Pre-commit checks passed!"
EOFH
    
    chmod +x .git/hooks/pre-commit
    
    # Pre-push hook
    cat > .git/hooks/pre-push << 'EOFH'
#!/bin/bash
# PAK pre-push hook

echo "Running pre-push checks..."

# Security scan
if command -v pak; then
    pak scan . || exit 1
fi

# Run full test suite
if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    npm test || exit 1
fi

echo "Pre-push checks passed!"
EOFH
    
    chmod +x .git/hooks/pre-push
    
    # Post-merge hook
    cat > .git/hooks/post-merge << 'EOFH'
#!/bin/bash
# PAK post-merge hook

echo "Running post-merge tasks..."

# Install dependencies
if [[ -f "package.json" ]]; then
    npm install
fi

if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
fi

if [[ -f "Cargo.toml" ]]; then
    cargo build
fi

echo "Post-merge tasks completed!"
EOFH
    
    chmod +x .git/hooks/post-merge
    
    log SUCCESS "Git hooks installed"
}

automation_remove_git_hooks() {
    log INFO "Removing git hooks..."
    
    rm -f .git/hooks/pre-commit
    rm -f .git/hooks/pre-push
    rm -f .git/hooks/post-merge
    
    log SUCCESS "Git hooks removed"
}

automation_release() {
    local package="$1"
    local version="${2:-}"
    local release_type="${3:-patch}"
    
    log INFO "Creating release for: $package"
    
    # Determine version if not provided
    if [[ -z "$version" ]]; then
        version=$(automation_determine_version "$package" "$release_type")
    fi
    
    # Create git tag
    git tag -a "v$version" -m "Release v$version"
    git push origin "v$version"
    
    # Create GitHub release
    if command -v gh &>/dev/null; then
        gh release create "v$version" --title "Release v$version" --notes "Automated release v$version"
    fi
    
    log SUCCESS "Release v$version created"
}

automation_test() {
    local package="$1"
    local test_type="${2:-all}"
    
    log INFO "Running tests for: $package ($test_type)"
    
    case "$test_type" in
        unit)
            automation_run_unit_tests "$package"
            ;;
        integration)
            automation_run_integration_tests "$package"
            ;;
        e2e)
            automation_run_e2e_tests "$package"
            ;;
        all)
            automation_run_unit_tests "$package"
            automation_run_integration_tests "$package"
            automation_run_e2e_tests "$package"
            ;;
        *)
            log ERROR "Unknown test type: $test_type"
            return 1
            ;;
    esac
}

automation_run_unit_tests() {
    local package="$1"
    
    log INFO "Running unit tests..."
    
    # Node.js unit tests
    if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
        npm test
    fi
    
    # Python unit tests
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        pytest tests/unit/
    fi
    
    # Rust unit tests
    if [[ -f "Cargo.toml" ]]; then
        cargo test --lib
    fi
}

automation_run_integration_tests() {
    local package="$1"
    
    log INFO "Running integration tests..."
    
    # Node.js integration tests
    if [[ -f "package.json" ]] && grep -q '"test:integration"' package.json; then
        npm run test:integration
    fi
    
    # Python integration tests
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        pytest tests/integration/
    fi
    
    # Rust integration tests
    if [[ -f "Cargo.toml" ]]; then
        cargo test --test '*'
    fi
}

automation_run_e2e_tests() {
    local package="$1"
    
    log INFO "Running end-to-end tests..."
    
    # Node.js e2e tests
    if [[ -f "package.json" ]] && grep -q '"test:e2e"' package.json; then
        npm run test:e2e
    fi
    
    # Python e2e tests
    if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        pytest tests/e2e/
    fi
}

automation_build() {
    local package="$1"
    local version="${2:-}"
    local build_type="${3:-release}"
    
    log INFO "Building package: $package ($build_type)"
    
    # Determine version if not provided
    if [[ -z "$version" ]]; then
        version=$(automation_determine_version "$package")
    fi
    
    # Node.js build
    if [[ -f "package.json" ]]; then
        case "$build_type" in
            debug)
                npm run build:debug
                ;;
            release)
                npm run build
                ;;
            *)
                npm run build
                ;;
        esac
    fi
    
    # Python build
    if [[ -f "setup.py" ]]; then
        python setup.py sdist bdist_wheel
    fi
    
    # Rust build
    if [[ -f "Cargo.toml" ]]; then
        case "$build_type" in
            debug)
                cargo build
                ;;
            release)
                cargo build --release
                ;;
            *)
                cargo build --release
                ;;
        esac
    fi
    
    log SUCCESS "Build completed: $package v$version"
}

automation_rollback() {
    local package="$1"
    local version="$2"
    
    log INFO "Rolling back package: $package to version: $version"
    
    # Deploy previous version
    pak deploy "$package" --version "$version" --force
    
    log SUCCESS "Rollback completed"
}

automation_monitor() {
    local package="$1"
    local duration="${2:-24h}"
    
    log INFO "Monitoring package: $package for $duration"
    
    # Monitor deployment health
    local start_time=$(date +%s)
    local end_time=$((start_time + $(echo "$duration" | sed 's/h$/*3600/' | sed 's/m$/*60/' | sed 's/s$//' | bc)))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        # Check package health
        if ! pak health "$package"; then
            log ERROR "Package health check failed"
            automation_rollback "$package" "$(pak get-previous-version "$package")"
            return 1
        fi
        
        sleep 60
    done
    
    log SUCCESS "Monitoring completed"
}

automation_send_notifications() {
    local package="$1"
    local version="$2"
    local environment="$3"
    local status="$4"
    
    # Slack notification
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Deployment $status: $package v$version to $environment\"}" \
            "$SLACK_WEBHOOK"
    fi
    
    # Discord notification
    if [[ -n "$DISCORD_WEBHOOK" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"content\":\"Deployment $status: $package v$version to $environment\"}" \
            "$DISCORD_WEBHOOK"
    fi
}

automation_update_monitoring() {
    local package="$1"
    local version="$2"
    
    # Update monitoring dashboards
    local monitoring_file="$PAK_DATA_DIR/monitoring/${package}.json"
    echo "{
        \"package\": \"$package\",
        \"version\": \"$version\",
        \"last_deploy\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"status\": \"deployed\"
    }" > "$monitoring_file"
}
