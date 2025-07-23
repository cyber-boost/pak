# PAK.sh Platform Registration Guide

## Overview

PAK.sh provides a comprehensive registration system that makes it easy to register with all major package platforms. The registration wizard guides you through the process of setting up credentials for automated package deployment.

## Quick Start

### Interactive Registration Wizard

The easiest way to register with platforms is using the interactive wizard:

```bash
pak register
```

This will:
1. Show a welcome screen with PAK.sh branding
2. Ask for your name and email
3. Let you choose which platforms to register with
4. Guide you through credential setup for each platform
5. Test your credentials
6. Save them securely

### Command Line Registration

You can also register with specific platforms directly:

```bash
# Register with NPM
pak register-platform npm

# Register with PyPI
pak register-platform pypi

# Register with Cargo
pak register-platform cargo
```

## Supported Platforms

PAK.sh supports registration with 30+ platforms across 25+ programming languages:

### JavaScript/TypeScript
- **NPM** - Node.js packages
- **JSR** - Deno/TypeScript registry
- **Deno** - Deno modules
- **JSPM** - JavaScript package manager

### Python
- **PyPI** - Python Package Index
- **Conda** - Anaconda packages
- **Poetry** - Python dependency management

### Rust
- **Cargo** - Rust package manager
- **Crates** - Rust crates registry

### .NET
- **NuGet** - .NET packages

### Java
- **Maven** - Java build tool
- **JCenter** - Java packages

### PHP
- **Packagist** - PHP packages
- **PEAR** - PHP Extension and Application Repository
- **PECL** - PHP Extension Community Library

### Ruby
- **RubyGems** - Ruby gems
- **Bundler** - Ruby dependency manager

### Infrastructure
- **Helm** - Kubernetes packages
- **Terraform** - Infrastructure as Code

### Containers
- **Docker Hub** - Container images

### Cloud Platforms
- **AWS** - Amazon Web Services
- **GCP** - Google Cloud Platform

## Registration Process

### 1. Platform Selection

Choose from three options:
- **All platforms** - Register with all 30+ supported platforms
- **Popular platforms** - Register with npm, pypi, and cargo only
- **Custom selection** - Choose specific platforms

### 2. Credential Storage

Choose how to store your credentials:
- **Environment variables** (recommended) - Stored in `~/.pak/credentials/env.sh`
- **Configuration file** - Stored in `~/.pak/credentials/platforms.json`
- **Both** - Stored in both locations

### 3. Platform-Specific Setup

Each platform has its own registration process:

#### NPM Registration
1. Go to https://www.npmjs.com/signup
2. Create account with email
3. Verify email address
4. Go to https://www.npmjs.com/settings/tokens
5. Create new token with "Automation" type
6. Copy token to clipboard

#### PyPI Registration
1. Go to https://pypi.org/account/register/
2. Create account with email
3. Verify email address
4. Go to https://pypi.org/manage/account/token/
5. Create new token with "Entire account" scope
6. Copy token to clipboard

#### Cargo Registration
1. Go to https://crates.io/signup
2. Create account with GitHub
3. Verify GitHub authorization
4. Go to https://crates.io/settings/tokens
5. Create new token
6. Copy token to clipboard

## Available Commands

### Core Registration Commands

```bash
# Interactive registration wizard
pak register

# Register with all platforms
pak register-all

# Register with specific platform
pak register-platform <platform>

# Test platform credentials
pak register-test [platform]

# List registered platforms
pak register-list

# Export credentials
pak register-export [filename]

# Import credentials
pak register-import <filename>

# Clear all credentials
pak register-clear
```

### Examples

```bash
# Start the registration wizard
pak register

# Register specifically with NPM
pak register-platform npm

# Test NPM credentials
pak register-test npm

# Export credentials to file
pak register-export my-credentials.json

# Import credentials from file
pak register-import my-credentials.json

# List all registered platforms
pak register-list
```

## Credential Management

### Environment Variables

When using environment variable storage, credentials are saved to `~/.pak/credentials/env.sh`:

```bash
# Source the environment file
source ~/.pak/credentials/env.sh

# Or add to your shell profile
echo "source ~/.pak/credentials/env.sh" >> ~/.bashrc
```

### Configuration File

Credentials are stored in JSON format at `~/.pak/credentials/platforms.json`:

```json
{
  "user": {
    "name": "Your Name",
    "email": "your.email@example.com",
    "registered_at": "2025-07-23T12:00:00Z"
  },
  "platforms": {
    "npm": {
      "NPM_TOKEN": "your_npm_token_here"
    },
    "pypi": {
      "PYPI_TOKEN": "your_pypi_token_here"
    },
    "cargo": {
      "CARGO_REGISTRY_TOKEN": "your_cargo_token_here"
    }
  }
}
```

## Security Best Practices

### 1. Secure Storage
- Store credentials in environment variables when possible
- Use secure file permissions (600) for credential files
- Add credential directories to `.gitignore`

### 2. Token Management
- Use API tokens instead of passwords when available
- Set appropriate token scopes (minimum required permissions)
- Rotate tokens regularly
- Use different tokens for different environments

### 3. Access Control
- Limit token access to specific repositories/projects
- Use organization-level tokens for team projects
- Monitor token usage and revoke unused tokens

### 4. Environment Separation
- Use different credentials for development, staging, and production
- Never commit credentials to version control
- Use CI/CD secrets management for automated deployments

## Troubleshooting

### Common Issues

#### "Module not found" Error
```bash
# Ensure PAK.sh is properly installed
pak version

# Check if registration module is loaded
pak register-list
```

#### "Credentials not found" Error
```bash
# Check if credentials are saved
pak register-list

# Re-register with platform
pak register-platform <platform>
```

#### "Authentication failed" Error
```bash
# Test credentials
pak register-test <platform>

# Re-register with new credentials
pak register-platform <platform>
```

#### "Permission denied" Error
```bash
# Check file permissions
ls -la ~/.pak/credentials/

# Fix permissions
chmod 600 ~/.pak/credentials/*
```

### Getting Help

```bash
# Show help
pak help

# Show registration help
pak register --help

# Enable debug mode
pak --debug register

# Show version information
pak version
```

## Integration with Deployment

Once registered, you can use your credentials for automated deployment:

```bash
# Deploy to NPM
pak deploy my-package --platform npm --version 1.0.0

# Deploy to multiple platforms
pak deploy my-package --platform npm,pypi,cargo --version 1.0.0

# Deploy with automatic versioning
pak deploy my-package --auto-version
```

## Advanced Features

### Batch Registration

Register with multiple platforms at once:

```bash
# Register with popular platforms
pak register-all

# Register with custom selection
pak register-platform npm,pypi,cargo
```

### Credential Export/Import

Share credentials across environments:

```bash
# Export credentials
pak register-export production-credentials.json

# Import credentials on another machine
pak register-import production-credentials.json
```

### Automated Testing

Test credentials automatically:

```bash
# Test all credentials
pak register-test

# Test specific platform
pak register-test npm
```

## Platform-Specific Notes

### NPM
- Requires npm CLI to be installed
- Token must have "Automation" type
- Test with: `npm whoami`

### PyPI
- Requires twine to be installed
- Token must have "Entire account" scope
- Test with: `twine check dist/*`

### Cargo
- Requires cargo CLI to be installed
- Token is used for publishing only
- Test with: `cargo login`

### Docker Hub
- Requires Docker CLI to be installed
- Uses username/password authentication
- Test with: `docker login`

## Future Enhancements

Planned features for future releases:

- **OAuth Integration** - Direct OAuth flow for supported platforms
- **Credential Encryption** - Encrypt stored credentials
- **Multi-Factor Authentication** - Support for MFA tokens
- **Credential Rotation** - Automatic token rotation
- **Audit Logging** - Track credential usage and changes
- **Team Management** - Share credentials across team members

## Support

For issues and questions:

- **Documentation**: https://pak.sh/docs
- **GitHub Issues**: https://github.com/pak-sh/pak/issues
- **Discord**: https://discord.gg/pak-sh
- **Email**: support@pak.sh

---

*Last updated: 2025-07-23* 