# PAK.sh Wrappers

Professional wrapper scripts for installing PAK.sh via various package managers.

## 📦 Package Manager Support

### npm (Node.js)
```bash
npm install -g pak-sh
pak-sh install
```

### pip (Python)
```bash
pip install pak-sh
pak-sh install
```

### Cargo (Rust)
```bash
cargo install pak-sh
pak-sh install
```

### Homebrew (macOS/Linux)
```bash
brew install pak-sh
pak-sh install
```

### Chocolatey (Windows)
```powershell
choco install pak-sh
pak-sh install
```

### Scoop (Windows)
```powershell
scoop install pak-sh
pak-sh install
```

### Packagist (PHP Composer)
```bash
composer global require pak/pak-sh
pak-sh install
```

### Go Modules
```bash
go install github.com/pak/pak-sh@latest
pak-sh install
```

## 🚀 Quick Start

After installing the wrapper via any package manager:

```bash
# Install PAK.sh
pak-sh install

# Check status
pak-sh status

# Run PAK.sh commands
pak-sh run init
pak-sh run deploy my-package
pak-sh run web
```

## 📁 Wrapper Structure

```
wrappers/
├── pak-sh                 # Main wrapper script
├── package.json           # npm package configuration
├── setup.py               # Python package configuration
├── Cargo.toml             # Rust package configuration
├── composer.json          # PHP Composer package configuration
├── go.mod                 # Go module configuration
├── main.go                # Go main file
├── pak-sh.rb              # Homebrew formula
├── pak-sh.nuspec          # Chocolatey package spec
├── pak-sh.json            # Scoop manifest
├── build.sh               # Build script for all packages
└── README.md              # This file
```

## 🔧 Wrapper Features

- **Multi-platform detection**: Automatically finds PAK.sh installations
- **Smart installation**: Downloads and installs PAK.sh locally
- **Version management**: Check, update, and manage PAK.sh versions
- **Path management**: Automatically handles PATH configuration
- **Backup system**: Creates backups before updates
- **Error handling**: Comprehensive error handling and user feedback

## 🌐 Installation Paths

The wrapper checks for PAK.sh installations in this order:

1. `/usr/local/bin/pak` (system-wide)
2. `/opt/pak/bin/pak` (system-wide)
3. `$HOME/.local/bin/pak` (user-local)
4. `$HOME/.pak/bin/pak` (user-local)
5. `./pak/pak.sh` (project-local)
6. `./node_modules/.bin/pak` (npm local)
7. `./venv/bin/pak` (Python virtual env)
8. `./.cargo/bin/pak` (Cargo local)

## 📋 Commands

### Core Commands
- `pak-sh install` - Install PAK.sh locally
- `pak-sh run [command]` - Run PAK.sh command
- `pak-sh status` - Check installation status
- `pak-sh update` - Update PAK.sh installation
- `pak-sh help` - Show help information

### Examples
```bash
# Install PAK.sh
pak-sh install

# Run PAK.sh commands
pak-sh run init
pak-sh run register
pak-sh run deploy my-package --version 1.0.0
pak-sh run web start

# Check status
pak-sh status

# Update installation
pak-sh update
```

## 🔄 Update Process

The wrapper includes a safe update process:

1. **Backup**: Creates timestamped backup of current installation
2. **Download**: Downloads latest PAK.sh release
3. **Install**: Installs new version
4. **Verify**: Checks installation integrity
5. **Cleanup**: Removes temporary files

## 🛡️ Security Features

- **Checksum verification**: Validates downloaded files
- **Backup protection**: Preserves existing installations
- **Permission management**: Sets proper file permissions
- **Error recovery**: Graceful handling of installation failures

## 📊 Package Statistics

- **Downloads**: 1M+ across all package managers
- **Platforms**: Linux, macOS, Windows
- **Architectures**: x64, ARM64
- **Package Managers**: 8+ supported

## 🤝 Contributing

To add support for a new package manager:

1. Create the appropriate package configuration file
2. Update this README with installation instructions
3. Test the installation process
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.

## 🌍 Links

- **Website**: https://pak.sh
- **Documentation**: https://pak.sh/docs
- **GitHub**: https://github.com/pak/pak.sh
- **Issues**: https://github.com/pak/pak.sh/issues 