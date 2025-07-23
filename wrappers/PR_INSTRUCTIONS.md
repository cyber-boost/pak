# Manual PR Instructions for Homebrew and Scoop

## 🍺 Homebrew PR Instructions

### Step 1: Fork homebrew-core
1. Go to https://github.com/Homebrew/homebrew-core
2. Click "Fork" in the top right
3. Clone your fork locally:
```bash
git clone https://github.com/YOUR_USERNAME/homebrew-core.git
cd homebrew-core
```

### Step 2: Add the Formula
1. Copy the formula file:
```bash
cp /path/to/your/wrappers/pak-sh.rb Formula/pak-sh.rb
```

2. Calculate the SHA256 hash:
```bash
# Download the release tarball
curl -L https://github.com/cyber-boost/pak/archive/v2.0.1.tar.gz -o pak-sh-2.0.1.tar.gz

# Calculate SHA256
shasum -a 256 pak-sh-2.0.1.tar.gz
```

3. Update the formula with the correct SHA256:
```ruby
sha256 "YOUR_CALCULATED_SHA256_HERE"
```

### Step 3: Test the Formula
```bash
# Test the formula
brew install --build-from-source ./Formula/pak-sh.rb

# Test that it works
pak-sh --version
```

### Step 4: Submit PR
```bash
git add Formula/pak-sh.rb
git commit -m "pak-sh 2.0.1

- PAK.sh Universal Package Automation Kit Wrapper
- https://pak.sh"
git push origin main
```

5. Go to your fork on GitHub and click "Compare & pull request"
6. Title: `pak-sh 2.0.1`
7. Description:
```
PAK.sh - Universal Package Automation Kit Wrapper

- Homepage: https://pak.sh
- Repository: https://github.com/cyber-boost/pak
- Documentation: https://pak.sh/docs

This formula installs the PAK.sh wrapper script which provides
easy installation and management of PAK.sh via various package managers.
```

---

## 🥄 Scoop PR Instructions

### Step 1: Fork main bucket
1. Go to https://github.com/ScoopInstaller/Main
2. Click "Fork" in the top right
3. Clone your fork locally:
```bash
git clone https://github.com/YOUR_USERNAME/Main.git
cd Main
```

### Step 2: Add the Manifest
1. Copy the manifest file:
```bash
cp /path/to/your/wrappers/pak-sh.json bucket/pak-sh.json
```

2. Calculate the SHA256 hash for Windows releases:
```bash
# Download the Windows release
curl -L https://github.com/cyber-boost/pak/releases/download/v2.0.1/pak-sh-windows-x64.zip -o pak-sh-windows-x64.zip

# Calculate SHA256
shasum -a 256 pak-sh-windows-x64.zip
```

3. Update the manifest with the correct SHA256:
```json
"hash": "YOUR_CALCULATED_SHA256_HERE"
```

### Step 3: Test the Manifest
```bash
# Test the manifest
scoop install ./bucket/pak-sh.json

# Test that it works
pak-sh --version
```

### Step 4: Submit PR
```bash
git add bucket/pak-sh.json
git commit -m "pak-sh: Add PAK.sh wrapper

- PAK.sh Universal Package Automation Kit Wrapper
- https://pak.sh"
git push origin main
```

5. Go to your fork on GitHub and click "Compare & pull request"
6. Title: `pak-sh: Add PAK.sh wrapper`
7. Description:
```
PAK.sh - Universal Package Automation Kit Wrapper

- Homepage: https://pak.sh
- Repository: https://github.com/cyber-boost/pak
- Documentation: https://pak.sh/docs

This manifest installs the PAK.sh wrapper script which provides
easy installation and management of PAK.sh via various package managers.
```

---

## 📋 PR Checklist

### Before Submitting:
- [ ] Formula/manifest has correct version (2.0.1)
- [ ] SHA256 hash is calculated and correct
- [ ] URLs point to your repository (cyber-boost/pak)
- [ ] Formula/manifest has been tested locally
- [ ] All links work correctly

### After PR is Merged:
- [ ] Test installation from the official repositories
- [ ] Update documentation with new installation methods
- [ ] Announce the new installation options

---

## 🚀 Quick Commands

### Test Homebrew Formula:
```bash
brew install --build-from-source ./Formula/pak-sh.rb
```

### Test Scoop Manifest:
```bash
scoop install ./bucket/pak-sh.json
```

### Calculate SHA256:
```bash
# For Homebrew (tarball)
curl -L https://github.com/cyber-boost/pak/archive/v2.0.1.tar.gz | shasum -a 256

# For Scoop (Windows zip)
curl -L https://github.com/cyber-boost/pak/releases/download/v2.0.1/pak-sh-windows-x64.zip | shasum -a 256
``` 