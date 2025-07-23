#!/bin/bash
# Enhanced DevEx module - Developer experience enhancements

devex_init() {
    log DEBUG "Enhanced DevEx module initialized"
    
    # Create DevEx directories
    mkdir -p "$PAK_TEMPLATES_DIR/projects"
    mkdir -p "$PAK_TEMPLATES_DIR/docs"
    mkdir -p "$PAK_SCRIPTS_DIR/devex"
    mkdir -p "$PAK_CONFIG_DIR/devex"
    
    # Initialize DevEx templates
    devex_init_templates
}

devex_register_commands() {
    register_command "wizard" "devex" "devex_wizard"
    register_command "template" "devex" "devex_template"
    register_command "docs" "devex" "devex_docs"
    register_command "setup" "devex" "devex_setup"
    register_command "init" "devex" "devex_init_project"
    register_command "scaffold" "devex" "devex_scaffold"
    register_command "env" "devex" "devex_environment"
    register_command "lint" "devex" "devex_lint"
    register_command "format" "devex" "devex_format"
}

devex_init_templates() {
    local templates_dir="$PAK_TEMPLATES_DIR/projects"
    
    # TypeScript NPM template
    cat > "$templates_dir/npm-typescript/package.json" << 'EOF'
{
  "name": "{{name}}",
  "version": "0.1.0",
  "description": "{{description}}",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts",
    "dev": "ts-node src/index.ts",
    "clean": "rm -rf dist"
  },
  "keywords": {{keywords}},
  "author": "{{author}}",
  "license": "{{license}}",
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "prettier": "^3.0.0",
    "ts-jest": "^29.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  }
}
EOF

    # Python CLI template
    cat > "$templates_dir/python-cli/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel", "setuptools_scm>=6.2"]
build-backend = "setuptools.build_meta"

[project]
name = "{{name}}"
version = "0.1.0"
description = "{{description}}"
authors = [{name = "{{author}}", email = "{{email}}"}]
license = {text = "{{license}}"}
readme = "README.md"
requires-python = ">=3.8"
dependencies = [
    "click>=8.0.0",
    "rich>=13.0.0"
]

[project.optional-dependencies]
dev = ["pytest", "black", "flake8", "mypy"]

[project.scripts]
{{name}} = "{{name}}.cli:main"

[tool.black]
line-length = 88
target-version = ['py38']

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF

    # Rust WASM template
    cat > "$templates_dir/rust-wasm/Cargo.toml" << 'EOF'
[package]
name = "{{name}}"
version = "0.1.0"
edition = "2021"
description = "{{description}}"
authors = ["{{author}}"]
license = "{{license}}"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
js-sys = "0.3"
web-sys = { version = "0.3", features = ["console"] }

[dev-dependencies]
wasm-bindgen-test = "0.3"

[profile.release]
opt-level = "s"
EOF
}

devex_wizard() {
    log INFO "🧙 Starting Enhanced Package Creation Wizard"
    
    # Interactive prompts with validation
    echo "Let's create a new package!"
    echo
    
    # Package name with validation
    while true; do
        read -p "Package name (lowercase, hyphens only): " package_name
        if [[ "$package_name" =~ ^[a-z0-9-]+$ ]]; then
            break
        else
            echo "❌ Invalid package name. Use lowercase letters, numbers, and hyphens only."
        fi
    done
    
    read -p "Description: " description
    read -p "Author name: " author_name
    read -p "Author email: " author_email
    
    # License selection
    echo
    echo "Available licenses:"
    echo "1) MIT (recommended)"
    echo "2) Apache-2.0"
    echo "3) BSD-3-Clause"
    echo "4) GPL-3.0"
    echo "5) Custom"
    read -p "Select license (1-5): " license_choice
    
    case "$license_choice" in
        1) license="MIT" ;;
        2) license="Apache-2.0" ;;
        3) license="BSD-3-Clause" ;;
        4) license="GPL-3.0" ;;
        5) read -p "Custom license: " license ;;
        *) license="MIT" ;;
    esac
    
    # Platform selection
    echo
    echo "Which platforms would you like to support?"
    echo "1) JavaScript/NPM (Node.js)"
    echo "2) TypeScript/NPM"
    echo "3) Python/PyPI"
    echo "4) Python CLI"
    echo "5) Rust/Cargo"
    echo "6) Rust WebAssembly"
    echo "7) Go/Modules"
    echo "8) Multi-platform"
    read -p "Select (1-8): " platform_choice
    
    # Create package structure
    local package_dir="./$package_name"
    mkdir -p "$package_dir"
    cd "$package_dir"
    
    # Generate files based on selection
    case "$platform_choice" in
        1) devex_create_npm_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        2) devex_create_typescript_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        3) devex_create_python_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        4) devex_create_python_cli "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        5) devex_create_rust_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        6) devex_create_rust_wasm "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        7) devex_create_go_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        8) devex_create_multi_platform "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
        *) devex_create_npm_package "$package_name" "$description" "$author_name" "$author_email" "$license" ;;
    esac
    
    # Initialize git
    git init
    
    # Create comprehensive README
    devex_create_readme "$package_name" "$description" "$platform_choice"
    
    # Setup development environment
    devex_setup_development_environment
    
    # Setup CI/CD
    devex_setup_cicd "$platform_choice"
    
    log SUCCESS "Package created successfully in: $package_dir"
    echo
    echo "🎉 Your package is ready!"
    echo
    echo "Next steps:"
    echo "  cd $package_name"
    echo "  pak setup        # Complete setup"
    echo "  pak track        # Start tracking"
    echo "  pak deploy       # Deploy when ready"
    echo
    echo "📚 Documentation: README.md"
    echo "🔧 Development: pak devex setup"
}

devex_create_typescript_package() {
    local name="$1"
    local description="$2"
    local author_name="$3"
    local author_email="$4"
    local license="$5"
    
    # Create package.json
    cat > package.json << EOF
{
  "name": "$name",
  "version": "0.1.0",
  "description": "$description",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts",
    "dev": "ts-node src/index.ts",
    "clean": "rm -rf dist"
  },
  "keywords": ["typescript", "node"],
  "author": "$author_name <$author_email>",
  "license": "$license",
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "prettier": "^3.0.0",
    "ts-jest": "^29.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  }
}
EOF
    
    # Create TypeScript config
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF
    
    # Create source files
    mkdir -p src
    cat > src/index.ts << 'EOF'
/**
 * Main entry point for the package
 */

export interface PackageConfig {
  name: string;
  version: string;
}

export class Package {
  private config: PackageConfig;

  constructor(config: PackageConfig) {
    this.config = config;
  }

  public getName(): string {
    return this.config.name;
  }

  public getVersion(): string {
    return this.config.version;
  }

  public hello(): string {
    return `Hello from ${this.config.name} v${this.config.version}!`;
  }
}

// Default export
export default Package;
EOF
    
    # Create tests
    mkdir -p __tests__
    cat > __tests__/index.test.ts << 'EOF'
import Package from '../src/index';

describe('Package', () => {
  it('should create a package instance', () => {
    const pkg = new Package({ name: 'test', version: '1.0.0' });
    expect(pkg.getName()).toBe('test');
    expect(pkg.getVersion()).toBe('1.0.0');
  });

  it('should return hello message', () => {
    const pkg = new Package({ name: 'test', version: '1.0.0' });
    expect(pkg.hello()).toBe('Hello from test v1.0.0!');
  });
});
EOF
    
    # Create ESLint config
    cat > .eslintrc.js << 'EOF'
module.exports = {
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
  ],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
  },
};
EOF
    
    # Create Prettier config
    cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOF
}

devex_create_python_cli() {
    local name="$1"
    local description="$2"
    local author_name="$3"
    local author_email="$4"
    local license="$5"
    
    # Create pyproject.toml
    cat > pyproject.toml << EOF
[build-system]
requires = ["setuptools>=45", "wheel", "setuptools_scm>=6.2"]
build-backend = "setuptools.build_meta"

[project]
name = "$name"
version = "0.1.0"
description = "$description"
authors = [{name = "$author_name", email = "$author_email"}]
license = {text = "$license"}
readme = "README.md"
requires-python = ">=3.8"
dependencies = [
    "click>=8.0.0",
    "rich>=13.0.0"
]

[project.optional-dependencies]
dev = ["pytest", "black", "flake8", "mypy"]

[project.scripts]
$name = "${name//-/_}.cli:main"

[tool.black]
line-length = 88
target-version = ['py38']

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
EOF
    
    # Create package structure
    local pkg_name=${name//-/_}
    mkdir -p "$pkg_name"
    
    # Create __init__.py
    cat > "$pkg_name/__init__.py" << EOF
"""$description"""

__version__ = "0.1.0"

def hello():
    """Return a greeting."""
    return "Hello from your CLI package!"
EOF
    
    # Create CLI module
    cat > "$pkg_name/cli.py" << 'EOF'
#!/usr/bin/env python3
"""Command-line interface for the package."""

import click
from rich.console import Console
from rich.table import Table

console = Console()

@click.group()
@click.version_option()
def main():
    """Main CLI application."""
    pass

@main.command()
@click.option('--name', default='World', help='Name to greet')
def hello(name):
    """Say hello to someone."""
    console.print(f"[green]Hello, {name}![/green]")

@main.command()
def status():
    """Show package status."""
    table = Table(title="Package Status")
    table.add_column("Property", style="cyan")
    table.add_column("Value", style="magenta")
    
    table.add_row("Name", "{{name}}")
    table.add_row("Version", "0.1.0")
    table.add_row("Status", "Active")
    
    console.print(table)

if __name__ == '__main__':
    main()
EOF
    
    # Create tests
    mkdir -p tests
    cat > tests/test_cli.py << 'EOF'
"""Tests for CLI functionality."""

import pytest
from click.testing import CliRunner
from {{name//-/_}}.cli import main

def test_hello_command():
    """Test hello command."""
    runner = CliRunner()
    result = runner.invoke(main, ['hello'])
    assert result.exit_code == 0
    assert 'Hello, World!' in result.output

def test_hello_command_with_name():
    """Test hello command with custom name."""
    runner = CliRunner()
    result = runner.invoke(main, ['hello', '--name', 'Alice'])
    assert result.exit_code == 0
    assert 'Hello, Alice!' in result.output
EOF
}

devex_create_rust_wasm() {
    local name="$1"
    local description="$2"
    local author_name="$3"
    local author_email="$4"
    local license="$5"
    
    # Create Cargo.toml
    cat > Cargo.toml << EOF
[package]
name = "$name"
version = "0.1.0"
edition = "2021"
description = "$description"
authors = ["$author_name <$author_email>"]
license = "$license"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
js-sys = "0.3"
web-sys = { version = "0.3", features = ["console"] }

[dev-dependencies]
wasm-bindgen-test = "0.3"

[profile.release]
opt-level = "s"
EOF
    
    # Create lib.rs
    mkdir -p src
    cat > src/lib.rs << 'EOF'
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to Rust WASM!", name)
}

#[wasm_bindgen]
pub struct Calculator {
    value: i32,
}

#[wasm_bindgen]
impl Calculator {
    pub fn new() -> Calculator {
        Calculator { value: 0 }
    }

    pub fn add(&mut self, x: i32) {
        self.value += x;
    }

    pub fn get_value(&self) -> i32 {
        self.value
    }
}
EOF
    
    # Create tests
    cat > src/lib.rs << 'EOF'
use wasm_bindgen::prelude::*;
use wasm_bindgen_test::*;

#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to Rust WASM!", name)
}

#[wasm_bindgen]
pub struct Calculator {
    value: i32,
}

#[wasm_bindgen]
impl Calculator {
    pub fn new() -> Calculator {
        Calculator { value: 0 }
    }

    pub fn add(&mut self, x: i32) {
        self.value += x;
    }

    pub fn get_value(&self) -> i32 {
        self.value
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        assert_eq!(greet("World"), "Hello, World! Welcome to Rust WASM!");
    }

    #[test]
    fn test_calculator() {
        let mut calc = Calculator::new();
        assert_eq!(calc.get_value(), 0);
        calc.add(5);
        assert_eq!(calc.get_value(), 5);
    }
}
EOF
    
    # Create wasm-pack config
    cat > wasm-pack.toml << 'EOF'
[package]
name = "{{name}}"
version = "0.1.0"
authors = ["{{author}}"]
description = "{{description}}"
license = "{{license}}"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"
EOF
}

devex_create_go_package() {
    local name="$1"
    local description="$2"
    local author_name="$3"
    local author_email="$4"
    local license="$5"
    
    # Create go.mod
    cat > go.mod << EOF
module github.com/$author_name/$name

go 1.21

require (
    github.com/spf13/cobra v1.7.0
    github.com/spf13/viper v1.16.0
)
EOF
    
    # Create main.go
    cat > main.go << 'EOF'
package main

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "{{name}}",
    Short: "{{description}}",
    Long:  `A longer description of your application.`,
}

var versionCmd = &cobra.Command{
    Use:   "version",
    Short: "Print the version number",
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("{{name}} v0.1.0")
    },
}

var helloCmd = &cobra.Command{
    Use:   "hello [name]",
    Short: "Say hello to someone",
    Args:  cobra.MaximumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        name := "World"
        if len(args) > 0 {
            name = args[0]
        }
        fmt.Printf("Hello, %s!\n", name)
    },
}

func init() {
    rootCmd.AddCommand(versionCmd)
    rootCmd.AddCommand(helloCmd)
}

func main() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}
EOF
    
    # Create package structure
    mkdir -p pkg
    cat > pkg/package.go << 'EOF'
package pkg

import "fmt"

// Package represents the main package
type Package struct {
    Name    string
    Version string
}

// New creates a new Package instance
func New(name, version string) *Package {
    return &Package{
        Name:    name,
        Version: version,
    }
}

// Hello returns a greeting message
func (p *Package) Hello() string {
    return fmt.Sprintf("Hello from %s v%s!", p.Name, p.Version)
}

// GetInfo returns package information
func (p *Package) GetInfo() map[string]string {
    return map[string]string{
        "name":    p.Name,
        "version": p.Version,
    }
}
EOF
    
    # Create tests
    mkdir -p pkg
    cat > pkg/package_test.go << 'EOF'
package pkg

import "testing"

func TestPackage_Hello(t *testing.T) {
    pkg := New("test", "1.0.0")
    expected := "Hello from test v1.0.0!"
    if got := pkg.Hello(); got != expected {
        t.Errorf("Package.Hello() = %v, want %v", got, expected)
    }
}

func TestPackage_GetInfo(t *testing.T) {
    pkg := New("test", "1.0.0")
    info := pkg.GetInfo()
    
    if info["name"] != "test" {
        t.Errorf("Expected name to be 'test', got %s", info["name"])
    }
    
    if info["version"] != "1.0.0" {
        t.Errorf("Expected version to be '1.0.0', got %s", info["version"])
    }
}
EOF
}

devex_setup_development_environment() {
    log INFO "Setting up development environment..."
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
__pycache__/
*.pyc
target/
*.so
*.dylib
*.dll

# Build output
dist/
build/
*.egg-info/
*.whl
*.tar.gz

# Environment
.env
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Coverage
coverage/
.coverage
*.lcov

# PAK
.pak/
pak-data/

# Temporary files
*.tmp
*.temp
EOF
    
    # Create .editorconfig
    cat > .editorconfig << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,jsx,ts,tsx,json,yml,yaml}]
indent_style = space
indent_size = 2

[*.{py}]
indent_style = space
indent_size = 4

[*.{rs}]
indent_style = space
indent_size = 4

[*.{go}]
indent_style = tab
indent_size = 4

[*.md]
trim_trailing_whitespace = false
EOF
    
    log SUCCESS "Development environment setup complete"
}

devex_setup_cicd() {
    local platform_choice="$1"
    
    log INFO "Setting up CI/CD pipeline..."
    
    case "$platform_choice" in
        1|2) # NPM/TypeScript
            mkdir -p .github/workflows
            cp "$PAK_TEMPLATES_DIR/ci/github-actions.yml" .github/workflows/pak.yml
            ;;
        3|4) # Python
            mkdir -p .github/workflows
            cp "$PAK_TEMPLATES_DIR/ci/github-actions.yml" .github/workflows/pak.yml
            ;;
        5|6) # Rust
            mkdir -p .github/workflows
            cp "$PAK_TEMPLATES_DIR/ci/github-actions.yml" .github/workflows/pak.yml
            ;;
        7) # Go
            mkdir -p .github/workflows
            cp "$PAK_TEMPLATES_DIR/ci/github-actions.yml" .github/workflows/pak.yml
            ;;
        *) # Default
            mkdir -p .github/workflows
            cp "$PAK_TEMPLATES_DIR/ci/github-actions.yml" .github/workflows/pak.yml
            ;;
    esac
    
    log SUCCESS "CI/CD pipeline setup complete"
}

devex_template() {
    local action="${1:-list}"
    local template_name="${2:-}"
    
    case "$action" in
        list)
            echo "Available templates:"
            echo "  - npm-typescript    TypeScript NPM package"
            echo "  - python-cli        Python CLI application"
            echo "  - rust-wasm         Rust WebAssembly package"
            echo "  - go-module         Go module package"
            echo "  - multi-platform    Multi-platform package"
            ;;
        create)
            if [[ -n "$template_name" ]]; then
                devex_create_from_template "$template_name"
            else
                log ERROR "Template name required"
                return 1
            fi
            ;;
        *)
            log ERROR "Unknown template action: $action"
            return 1
            ;;
    esac
}

devex_docs() {
    local action="${1:-generate}"
    
    case "$action" in
        generate)
            devex_generate_docs
            ;;
        serve)
            devex_serve_docs
            ;;
        *)
            log ERROR "Unknown docs action: $action"
            return 1
            ;;
    esac
}

devex_generate_docs() {
    log INFO "Generating documentation..."
    
    mkdir -p docs
    
    # Generate API docs
    if [[ -f "package.json" ]] && command -v jsdoc &>/dev/null; then
        jsdoc -c jsdoc.json -d docs/api
    fi
    
    if [[ -f "pyproject.toml" ]] && command -v sphinx-build &>/dev/null; then
        sphinx-build -b html docs/source docs/build
    fi
    
    # Generate PAK docs
    cat > docs/pak-guide.md << 'EOF'
# PAK Integration Guide

This package is managed by PAK (Package Automation Kit).

## Quick Start

```bash
# Initialize PAK
pak init

# Track package
pak track [package-name]

# Deploy package
pak deploy [package-name] --version [version]

# Security scan
pak scan [package-name]

# Generate analytics
pak analyze [package-name]
```

## Development Workflow

1. **Setup**: `pak devex setup`
2. **Development**: `pak devex dev`
3. **Testing**: `pak test`
4. **Security**: `pak scan`
5. **Deploy**: `pak deploy`

## Configuration

- **Package Config**: `package-config.json`
- **PAK Config**: `.pak/config.json`
- **Templates**: `.pak/templates/`

## Security

- **Vulnerability Scan**: `pak scan`
- **License Check**: `pak license-check`
- **Dependency Audit**: `pak dependency-check`

## Automation

- **CI/CD**: `pak pipeline create`
- **Git Hooks**: `pak hooks install`
- **Release**: `pak release`
EOF
    
    log SUCCESS "Documentation generated in: docs/"
}

devex_setup() {
    log INFO "Setting up development environment..."
    
    # Install dependencies
    if [[ -f "package.json" ]]; then
        npm install
    fi
    
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    if [[ -f "pyproject.toml" ]]; then
        pip install -e .
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        cargo build
    fi
    
    if [[ -f "go.mod" ]]; then
        go mod tidy
    fi
    
    # Setup git hooks
    automation_install_git_hooks
    
    # Create environment template
    if [[ ! -f ".env" ]]; then
        cat > .env.example << 'EOF'
# PAK Configuration
PAK_NPM_TOKEN=
PAK_PYPI_TOKEN=
PAK_CARGO_TOKEN=

# Notifications
PAK_SLACK_WEBHOOK=
PAK_DISCORD_WEBHOOK=

# Development
NODE_ENV=development
DEBUG=true
EOF
    fi
    
    log SUCCESS "Development environment ready!"
}

devex_init_project() {
    local project_type="${1:-auto}"
    
    log INFO "Initializing project: $project_type"
    
    case "$project_type" in
        auto)
            devex_auto_detect_and_init
            ;;
        npm|node)
            devex_init_npm_project
            ;;
        python)
            devex_init_python_project
            ;;
        rust)
            devex_init_rust_project
            ;;
        go)
            devex_init_go_project
            ;;
        *)
            log ERROR "Unknown project type: $project_type"
            return 1
            ;;
    esac
}

devex_scaffold() {
    local scaffold_type="${1:-basic}"
    
    log INFO "Scaffolding project structure: $scaffold_type"
    
    case "$scaffold_type" in
        basic)
            devex_scaffold_basic
            ;;
        full)
            devex_scaffold_full
            ;;
        microservice)
            devex_scaffold_microservice
            ;;
        *)
            log ERROR "Unknown scaffold type: $scaffold_type"
            return 1
            ;;
    esac
}

devex_environment() {
    local action="${1:-setup}"
    
    case "$action" in
        setup)
            devex_setup_environment
            ;;
        check)
            devex_check_environment
            ;;
        fix)
            devex_fix_environment
            ;;
        *)
            log ERROR "Unknown environment action: $action"
            return 1
            ;;
    esac
}

devex_lint() {
    local target="${1:-.}"
    
    log INFO "Running linting on: $target"
    
    # JavaScript/TypeScript linting
    if [[ -f "package.json" ]]; then
        if grep -q '"lint"' package.json; then
            npm run lint
        elif command -v eslint &>/dev/null; then
            eslint "$target"
        fi
    fi
    
    # Python linting
    if [[ -f "pyproject.toml" ]] && command -v flake8 &>/dev/null; then
        flake8 "$target"
    fi
    
    # Rust linting
    if [[ -f "Cargo.toml" ]]; then
        cargo clippy
    fi
    
    # Go linting
    if [[ -f "go.mod" ]] && command -v golangci-lint &>/dev/null; then
        golangci-lint run
    fi
    
    log SUCCESS "Linting completed"
}

devex_format() {
    local target="${1:-.}"
    
    log INFO "Formatting code in: $target"
    
    # JavaScript/TypeScript formatting
    if [[ -f "package.json" ]] && grep -q '"format"' package.json; then
        npm run format
    elif command -v prettier &>/dev/null; then
        prettier --write "$target"
    fi
    
    # Python formatting
    if command -v black &>/dev/null; then
        black "$target"
    fi
    
    # Rust formatting
    if [[ -f "Cargo.toml" ]]; then
        cargo fmt
    fi
    
    # Go formatting
    if [[ -f "go.mod" ]]; then
        go fmt ./...
    fi
    
    log SUCCESS "Code formatting completed"
}

devex_auto_detect_and_init() {
    log INFO "Starting smart project detection and initialization"
    
    # Show PAK.sh welcome screen
    devex_show_welcome_screen
    
    # Phase 1: Project Discovery & Grouping
    devex_project_identification_phase
    
    # Phase 2: Package Detection
    devex_package_detection_phase
    
    # Phase 3: Configuration
    devex_configuration_phase
    
    # Phase 4: Final Setup
    devex_final_setup_phase
    
    log SUCCESS "Smart initialization completed successfully"
}

devex_show_welcome_screen() {
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
    echo "    │    PAK.sh - Package Automation Kit  │"
    echo "    │                                     │"
    echo "    │  🚀 Let's set up your project!      │"
    echo "    ╰─────────────────────────────────────╯"
    echo
    echo "📁 Project Setup Questionnaire"
    echo "=============================="
    echo
}

devex_project_identification_phase() {
    echo "1️⃣ PROJECT IDENTIFICATION"
    echo "-------------------------"
    echo
    
    # Get project name
    local default_name=$(basename "$(pwd)")
    echo -n "What's your project name? [$default_name]: "
    read -r project_name
    project_name="${project_name:-$default_name}"
    
    echo "This will group all related packages under \"$project_name\""
    echo
}

devex_package_detection_phase() {
    echo "2️⃣ PACKAGE DETECTION"
    echo "-------------------"
    echo
    
    echo "🔍 Scanning current directory for packages..."
    echo
    
    # Detect packages
    local detected_packages=()
    local package_types=()
    local package_paths=()
    
    # NPM packages
    if [[ -f "package.json" ]]; then
        detected_packages+=("npm")
        package_types+=("npm")
        package_paths+=("./")
    fi
    
    # Python packages
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        detected_packages+=("python")
        package_types+=("python")
        package_paths+=("./")
    fi
    
    # Rust packages
    if [[ -f "Cargo.toml" ]]; then
        detected_packages+=("rust")
        package_types+=("rust")
        package_paths+=("./")
    fi
    
    # Go packages
    if [[ -f "go.mod" ]]; then
        detected_packages+=("go")
        package_types+=("go")
        package_paths+=("./")
    fi
    
    # Docker
    if [[ -f "Dockerfile" ]]; then
        detected_packages+=("docker")
        package_types+=("docker")
        package_paths+=("./")
    fi
    
    # Check subdirectories
    for dir in */; do
        if [[ -d "$dir" ]]; then
            # NPM in subdirectory
            if [[ -f "${dir}package.json" ]]; then
                detected_packages+=("npm")
                package_types+=("npm")
                package_paths+=("$dir")
            fi
            
            # Python in subdirectory
            if [[ -f "${dir}pyproject.toml" ]] || [[ -f "${dir}setup.py" ]]; then
                detected_packages+=("python")
                package_types+=("python")
                package_paths+=("$dir")
            fi
            
            # Rust in subdirectory
            if [[ -f "${dir}Cargo.toml" ]]; then
                detected_packages+=("rust")
                package_types+=("rust")
                package_paths+=("$dir")
            fi
            
            # Go in subdirectory
            if [[ -f "${dir}go.mod" ]]; then
                detected_packages+=("go")
                package_types+=("go")
                package_paths+=("$dir")
            fi
            
            # Docker in subdirectory
            if [[ -f "${dir}Dockerfile" ]]; then
                detected_packages+=("docker")
                package_types+=("docker")
                package_paths+=("$dir")
            fi
        fi
    done
    
    # Display detected packages
    if [[ ${#detected_packages[@]} -gt 0 ]]; then
        echo "Found packages:"
        for i in "${!detected_packages[@]}"; do
            local icon=""
            case "${detected_packages[$i]}" in
                npm) icon="📦" ;;
                python) icon="🐍" ;;
                rust) icon="🦀" ;;
                go) icon="🐹" ;;
                docker) icon="🐳" ;;
                *) icon="📦" ;;
            esac
            echo "  $icon ${detected_packages[$i]}:     ${package_paths[$i]}"
        done
        echo
        
        echo -n "Is this correct? [Y/n]: "
        read -r confirm
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            echo "Please manually configure packages or run pak.sh init again"
            return 1
        fi
    else
        echo "No packages detected. Creating basic project structure..."
        echo
    fi
    
    # Store for later use
    export PAK_PROJECT_NAME="$project_name"
    export PAK_DETECTED_PACKAGES=("${detected_packages[@]}")
    export PAK_PACKAGE_TYPES=("${package_types[@]}")
    export PAK_PACKAGE_PATHS=("${package_paths[@]}")
}

devex_configuration_phase() {
    echo "3️⃣ CONFIGURATION"
    echo "---------------"
    echo
    
    # Registry configuration
    devex_configure_registries
    
    # Deployment strategy
    devex_configure_deployment
    
    # Tracking configuration
    devex_configure_tracking
    
    # Security configuration
    devex_configure_security
    
    # Monitoring configuration
    devex_configure_monitoring
    
    # Database configuration
    devex_configure_database
}

devex_configure_registries() {
    echo "🎯 PACKAGE REGISTRY CONFIGURATION"
    echo "--------------------------------"
    echo
    
    for i in "${!PAK_DETECTED_PACKAGES[@]}"; do
        local pkg_type="${PAK_DETECTED_PACKAGES[$i]}"
        local pkg_path="${PAK_PACKAGE_PATHS[$i]}"
        
        case "$pkg_type" in
            npm)
                echo "For npm packages ($pkg_path):"
                echo -n "  Registry: [https://registry.npmjs.org/]: "
                read -r npm_registry
                npm_registry="${npm_registry:-https://registry.npmjs.org/}"
                
                echo -n "  Scope: [@$PAK_PROJECT_NAME]: "
                read -r npm_scope
                npm_scope="${npm_scope:-@$PAK_PROJECT_NAME}"
                echo
                ;;
            python)
                echo "For Python packages ($pkg_path):"
                echo -n "  Repository: [https://pypi.org/]: "
                read -r python_repo
                python_repo="${python_repo:-https://pypi.org/}"
                
                echo -n "  Index URL: [https://pypi.org/simple/]: "
                read -r python_index
                python_index="${python_index:-https://pypi.org/simple/}"
                echo
                ;;
            rust)
                echo "For Rust packages ($pkg_path):"
                echo -n "  Registry: [https://crates.io/]: "
                read -r rust_registry
                rust_registry="${rust_registry:-https://crates.io/}"
                echo
                ;;
            docker)
                echo "For Docker images ($pkg_path):"
                echo -n "  Registry: [https://hub.docker.com/]: "
                read -r docker_registry
                docker_registry="${docker_registry:-https://hub.docker.com/}"
                
                echo -n "  Organization: [$PAK_PROJECT_NAME]: "
                read -r docker_org
                docker_org="${docker_org:-$PAK_PROJECT_NAME}"
                echo
                ;;
        esac
    done
}

devex_configure_deployment() {
    echo "🚀 DEPLOYMENT STRATEGY"
    echo "--------------------"
    echo
    
    echo "How would you like to deploy packages?"
    echo "1) Sequential (one at a time)"
    echo "2) Parallel (all at once)"
    echo "3) Smart (dependencies first)"
    echo "4) Manual (prompt for each)"
    echo
    
    echo -n "Choose option [3]: "
    read -r deploy_strategy
    deploy_strategy="${deploy_strategy:-3}"
    
    case "$deploy_strategy" in
        1) deploy_strategy="sequential" ;;
        2) deploy_strategy="parallel" ;;
        3) deploy_strategy="smart" ;;
        4) deploy_strategy="manual" ;;
        *) deploy_strategy="smart" ;;
    esac
    
    echo "Deployment strategy: $deploy_strategy"
    echo
}

devex_configure_tracking() {
    echo "📊 TRACKING CONFIGURATION"
    echo "------------------------"
    echo
    
    echo "Which metrics would you like to track?"
    echo "✅ Downloads & installs"
    echo "✅ Version history"
    echo "✅ Dependency updates"
    echo "✅ Security vulnerabilities"
    echo "✅ Performance metrics"
    echo "❌ User analytics (requires opt-in)"
    echo
    
    echo -n "Enable user analytics? [y/N]: "
    read -r enable_analytics
    enable_analytics="${enable_analytics:-N}"
    echo
}

devex_configure_security() {
    echo "🔒 SECURITY & COMPLIANCE"
    echo "-----------------------"
    echo
    
    echo "Security scanning:"
    echo "✅ Vulnerability scanning"
    echo "✅ License compliance"
    echo "✅ Dependency audit"
    echo "✅ Code quality checks"
    echo
    
    echo "License for packages:"
    echo "1) MIT (permissive)"
    echo "2) Apache 2.0 (permissive)"
    echo "3) GPL-3.0 (copyleft)"
    echo "4) Custom"
    echo
    
    echo -n "Choose license [1]: "
    read -r license_choice
    license_choice="${license_choice:-1}"
    
    case "$license_choice" in
        1) license="MIT" ;;
        2) license="Apache-2.0" ;;
        3) license="GPL-3.0" ;;
        4) 
            echo -n "Enter custom license: "
            read -r license
            ;;
        *) license="MIT" ;;
    esac
    echo
}

devex_configure_monitoring() {
    echo "📈 MONITORING & ALERTS"
    echo "---------------------"
    echo
    
    echo "Alert channels:"
    echo "✅ Console output"
    echo "✅ Log files"
    echo "❌ Email notifications"
    echo "❌ Slack integration"
    echo "❌ Discord webhook"
    echo
    
    echo -n "Enable email notifications? [y/N]: "
    read -r enable_email
    enable_email="${enable_email:-N}"
    
    echo -n "Enable Slack integration? [y/N]: "
    read -r enable_slack
    enable_slack="${enable_slack:-N}"
    echo
}

devex_configure_database() {
    echo "🗄️  DATABASE CONFIGURATION"
    echo "------------------------"
    echo
    
    echo "How would you like to store PAK.sh data?"
    echo "1) JSON files (default) - Simple, portable"
    echo "2) SQLite database - Structured, queryable"
    echo "3) Both - JSON for portability, SQLite for queries"
    echo
    
    echo -n "Choose option [2]: "
    read -r database_choice
    database_choice="${database_choice:-2}"
    
    case "$database_choice" in
        1) database_type="json" ;;
        2) database_type="sqlite" ;;
        3) database_type="both" ;;
        *) database_type="sqlite" ;;
    esac
    
    if [[ "$database_type" == "sqlite" ]] || [[ "$database_type" == "both" ]]; then
        echo -n "SQLite database path [$PAK_DATA_DIR/pak.db]: "
        read -r sqlite_path
        sqlite_path="${sqlite_path:-$PAK_DATA_DIR/pak.db}"
        
        echo -n "Enable database encryption? (y/N): "
        read -r encrypt_db
        encrypt_db="${encrypt_db:-N}"
        
        if [[ "$encrypt_db" =~ ^[Yy]$ ]]; then
            echo -n "Database encryption key: "
            read -s -r db_encryption_key
            echo
            
            echo -n "Confirm encryption key: "
            read -s -r db_encryption_key_confirm
            echo
            
            if [[ "$db_encryption_key" != "$db_encryption_key_confirm" ]]; then
                echo "❌ Keys don't match. Using unencrypted database."
                encrypt_db="N"
            fi
        fi
        
        echo -n "Database backup interval (hours) [24]: "
        read -r db_backup_interval
        db_backup_interval="${db_backup_interval:-24}"
        
        echo -n "Database retention days [90]: "
        read -r db_retention_days
        db_retention_days="${db_retention_days:-90}"
        
        # Check if SQLite is available
        if ! command -v sqlite3 &> /dev/null; then
            echo "⚠️  SQLite3 not found. Installing..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y sqlite3
            elif command -v yum &> /dev/null; then
                sudo yum install -y sqlite
            elif command -v brew &> /dev/null; then
                brew install sqlite
            else
                echo "❌ Could not install SQLite3. Please install manually."
                database_type="json"
            fi
        fi
    fi
    
    echo
}

devex_final_setup_phase() {
    echo "4️⃣ FINAL CONFIGURATION"
    echo "--------------------"
    echo
    
    # Show configuration summary
    devex_show_configuration_summary
    
    echo -n "Create configuration? [Y/n]: "
    read -r create_config
    if [[ "$create_config" =~ ^[Nn]$ ]]; then
        echo "Configuration cancelled"
        return 1
    fi
    
    # Create configuration files
    devex_create_configuration_files
    
    # Initialize database if SQLite is enabled
    if [[ "$database_type" == "sqlite" ]] || [[ "$database_type" == "both" ]]; then
        devex_initialize_sqlite_database
    fi
    
    # Show success screen
    devex_show_success_screen
}

devex_show_configuration_summary() {
    echo "Configuration summary:"
    echo "  Project: $PAK_PROJECT_NAME"
    echo "  Packages: ${#PAK_DETECTED_PACKAGES[@]} (${PAK_DETECTED_PACKAGES[*]})"
    echo "  Deployment: $deploy_strategy"
    echo "  License: $license"
    echo "  Analytics: $enable_analytics"
    echo "  Database: $database_type"
    if [[ "$database_type" == "sqlite" ]] || [[ "$database_type" == "both" ]]; then
        echo "  SQLite path: $sqlite_path"
        echo "  Database encrypted: $encrypt_db"
    fi
    echo "  Email alerts: $enable_email"
    echo "  Slack alerts: $enable_slack"
    echo
}

devex_create_configuration_files() {
    echo "🔧 Setting up PAK configuration..."
    
    # Create pak.conf
    cat > "pak.conf" << EOF
# PAK.sh Configuration for: $PAK_PROJECT_NAME
[project]
name = $PAK_PROJECT_NAME
version = 1.0.0
license = $license
description = Multi-package project managed by PAK.sh

[deployment]
strategy = $deploy_strategy
auto_deploy = true
auto_track = true

[tracking]
downloads = true
versions = true
security = true
performance = true
analytics = $enable_analytics

[security]
vulnerability_scan = true
license_compliance = true
dependency_audit = true
code_quality = true

[monitoring]
console = true
logs = true
email = $enable_email
slack = $enable_slack

[database]
type = $database_type
EOF

    # Add SQLite configuration if enabled
    if [[ "$database_type" == "sqlite" ]] || [[ "$database_type" == "both" ]]; then
        cat >> "pak.conf" << EOF
sqlite_path = $sqlite_path
encrypted = $encrypt_db
backup_interval = $db_backup_interval
retention_days = $db_retention_days
EOF
    fi
EOF
    
    # Create .pakignore
    cat > ".pakignore" << EOF
# PAK.sh ignore file
node_modules/
__pycache__/
target/
dist/
build/
*.log
.env
EOF
    
    echo "✅ Configuration created!"
    echo
}

devex_show_success_screen() {
    echo
    echo "    ╭─────────────────────────────────────╮"
    echo "    │  🎉 PAK.sh Setup Complete!          │"
    echo "    │                                     │"
    echo "    │  📁 Project: $PAK_PROJECT_NAME     │"
    echo "    │  📦 Packages: ${#PAK_DETECTED_PACKAGES[@]} configured          │"
    echo "    │  🚀 Ready to deploy!                │"
    echo "    │                                     │"
    echo "    │  Next steps:                        │"
    echo "    │  • pak.sh deploy all                │"
    echo "    │  • pak.sh track all                 │"
    echo "    │  • pak.sh status                    │"
    echo "    │                                     │"
    echo "    │  💡 Run 'pak.sh help' for more info │"
    echo "    ╰─────────────────────────────────────╯"
    echo
}

devex_initialize_sqlite_database() {
    echo "🗄️  Initializing SQLite database..."
    
    # Create database directory
    mkdir -p "$(dirname "$sqlite_path")"
    
    # Initialize SQLite database with schema
    sqlite3 "$sqlite_path" << 'EOF'
-- PAK.sh Database Schema
-- Created: $(date)

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    version TEXT NOT NULL,
    description TEXT,
    license TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Packages table
CREATE TABLE IF NOT EXISTS packages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER,
    name TEXT NOT NULL,
    platform TEXT NOT NULL,
    version TEXT NOT NULL,
    path TEXT NOT NULL,
    enabled BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id),
    UNIQUE(name, platform)
);

-- Tracking data table
CREATE TABLE IF NOT EXISTS tracking_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    platform TEXT NOT NULL,
    downloads INTEGER DEFAULT 0,
    version TEXT,
    status_code INTEGER,
    response_time REAL,
    available BOOLEAN DEFAULT 1,
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Monitoring data table
CREATE TABLE IF NOT EXISTS monitoring_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    cpu_usage REAL,
    memory_usage REAL,
    disk_usage REAL,
    network_latency REAL,
    availability_score REAL,
    health_status TEXT,
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    alert_type TEXT NOT NULL,
    message TEXT NOT NULL,
    severity TEXT DEFAULT 'warning',
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Deployments table
CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER,
    version TEXT NOT NULL,
    platform TEXT NOT NULL,
    status TEXT NOT NULL,
    strategy TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Configuration table
CREATE TABLE IF NOT EXISTS configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tracking_data_package_time ON tracking_data(package_id, collected_at);
CREATE INDEX IF NOT EXISTS idx_monitoring_data_package_time ON monitoring_data(package_id, collected_at);
CREATE INDEX IF NOT EXISTS idx_alerts_package_time ON alerts(package_id, triggered_at);
CREATE INDEX IF NOT EXISTS idx_deployments_package_time ON deployments(package_id, started_at);

-- Insert initial configuration
INSERT OR REPLACE INTO configuration (key, value, category) VALUES
('database_version', '1.0.0', 'system'),
('created_at', '$(date -u +"%Y-%m-%dT%H:%M:%SZ")', 'system'),
('project_name', '$PAK_PROJECT_NAME', 'project'),
('database_type', '$database_type', 'system');

-- Insert project record
INSERT OR REPLACE INTO projects (name, version, description, license) VALUES
('$PAK_PROJECT_NAME', '1.0.0', 'Multi-package project managed by PAK.sh', '$license');

EOF

    # Set proper permissions
    chmod 644 "$sqlite_path"
    
    # Create backup directory
    mkdir -p "$(dirname "$sqlite_path")/backups"
    
    # Create initial backup
    cp "$sqlite_path" "$(dirname "$sqlite_path")/backups/pak-$(date +%Y%m%d-%H%M%S).db"
    
    echo "✅ SQLite database initialized at: $sqlite_path"
    echo "📊 Database schema includes:"
    echo "   • Projects and packages tracking"
    echo "   • Download statistics and monitoring"
    echo "   • Alert history and deployments"
    echo "   • Configuration management"
    echo
}
