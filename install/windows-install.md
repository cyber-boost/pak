# Windows Installation Guide for PAK.sh

## 🎯 Recommended: WSL2 Installation

Windows Subsystem for Linux 2 (WSL2) provides the best experience for running PAK.sh on Windows, offering full Linux compatibility with excellent performance.

### Quick Start (WSL2)

1. **Install WSL2**
   ```powershell
   # Open PowerShell as Administrator and run:
   wsl --install
   ```

2. **Restart Your Computer**
   - WSL2 requires a restart to complete installation

3. **Set Up Ubuntu**
   - Ubuntu will launch automatically after restart
   - Create a username and password when prompted

4. **Install PAK.sh**
   ```bash
   # In the Ubuntu terminal:
   curl -sSL https://pak.sh/install | bash
   ```

5. **Verify Installation**
   ```bash
   pak --version
   ```

### Alternative: Git Bash

If you prefer not to use WSL2, Git Bash provides a bash environment on Windows:

1. **Install Git for Windows**
   - Download from: https://git-scm.com/download/win
   - During installation, ensure "Git Bash" is selected

2. **Install PAK.sh**
   ```bash
   # Open Git Bash and run:
   curl -sSL https://pak.sh/install | bash
   ```

### Advanced: PowerShell with WSL

For advanced users who want to run PAK.sh from PowerShell:

```powershell
# Install WSL2 first
wsl --install

# Then run PAK.sh commands through WSL
wsl pak --version
wsl pak deploy my-package
```

## 🔧 WSL2 Benefits

- **Full Linux Compatibility**: Run all existing bash scripts without modification
- **Native Performance**: WSL2 uses a real Linux kernel
- **File System Access**: Seamless access to Windows files from Linux
- **Package Management**: Use apt, npm, pip, cargo, etc. natively
- **Development Tools**: Full access to Linux development ecosystem

## 🚨 Troubleshooting

### WSL2 Installation Issues

```powershell
# Check WSL status
wsl --list --verbose

# Update WSL
wsl --update

# Set WSL2 as default
wsl --set-default-version 2
```

### PAK.sh Installation Issues

```bash
# Check if curl is available
which curl

# Install curl if missing
sudo apt update && sudo apt install curl

# Check bash version
bash --version
```

### File Permission Issues

```bash
# Fix file permissions
chmod +x ~/.local/bin/pak

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 📁 File Locations

When using WSL2, PAK.sh files are stored in the Linux file system:

- **Executable**: `/usr/local/bin/pak` or `~/.local/bin/pak`
- **Configuration**: `/etc/pak/` or `~/.config/pak/`
- **Data**: `/var/lib/pak/` or `~/.local/share/pak/`
- **Logs**: `/var/log/pak/` or `~/.local/share/pak/logs/`

## 🔗 Integration with Windows

### Access Windows Files from WSL2
```bash
# Windows C: drive is mounted at /mnt/c/
cd /mnt/c/Users/YourUsername/Projects

# Run PAK.sh on Windows projects
pak init
```

### Access WSL2 Files from Windows
```bash
# WSL2 files are accessible via:
# \\wsl$\Ubuntu\home\username\
```

## 🎉 Next Steps

After installation, you can:

1. **Initialize a Project**
   ```bash
   pak init
   ```

2. **Register with Platforms**
   ```bash
   pak register
   ```

3. **Deploy Your First Package**
   ```bash
   pak deploy --version 1.0.0
   ```

4. **Track Statistics**
   ```bash
   pak track
   ```

## 📞 Support

- **WSL2 Issues**: Microsoft WSL Documentation
- **PAK.sh Issues**: GitHub Issues or Documentation
- **Linux Commands**: Ubuntu Documentation

---

*WSL2 provides the most seamless experience for running PAK.sh on Windows, allowing you to use all Linux tools and scripts without any modifications.* 