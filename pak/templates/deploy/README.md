# PAK Deployment Templates

This directory contains deployment templates for the PAK (Package Automation Kit) system. These templates provide platform-specific deployment logic, pre/post hooks, and rollback functionality.

## Directory Structure

```
deploy/
├── pre/           # Pre-deployment templates
├── post/          # Post-deployment templates
├── rollback/      # Rollback templates
└── README.md      # This file
```

## Template Types

### Pre-deployment Templates (`pre/`)

Pre-deployment templates are executed before the actual deployment to:
- Validate package structure
- Install dependencies
- Run tests
- Build packages
- Perform platform-specific checks

**Usage:**
```bash
./pre/{platform}.sh <package_name> <version> <package_directory>
```

### Post-deployment Templates (`post/`)

Post-deployment templates are executed after successful deployment to:
- Verify deployment success
- Update deployment records
- Send notifications
- Perform cleanup tasks

**Usage:**
```bash
./post/{platform}.sh <package_name> <version> <package_directory> <deploy_id>
```

### Rollback Templates (`rollback/`)

Rollback templates handle deployment rollbacks when:
- Deployment fails
- Manual rollback is requested
- Automatic rollback is triggered

**Usage:**
```bash
./rollback/{platform}.sh <package_name> <version> <previous_version>
```

## Supported Platforms

The following platforms have deployment templates:

### JavaScript/TypeScript
- **npm** - Node.js packages
- **yarn** - Yarn packages
- **jsr** - Deno JSR packages
- **deno** - Deno packages

### Python
- **pypi** - Python packages
- **conda** - Conda packages
- **pip** - Pip packages

### Rust
- **cargo** - Rust crates
- **crates** - Crates.io packages

### Java
- **maven** - Maven artifacts
- **gradle** - Gradle packages
- **jcenter** - JCenter packages

### PHP
- **composer** - Composer packages
- **packagist** - Packagist packages

### .NET
- **nuget** - NuGet packages
- **dotnet** - .NET packages

### Containers
- **dockerhub** - Docker Hub images
- **quay** - Quay.io images
- **ghcr** - GitHub Container Registry

### Kubernetes
- **helm** - Helm charts
- **chartmuseum** - ChartMuseum charts

### Infrastructure
- **terraform** - Terraform modules
- **ansible** - Ansible roles

### Cloud Platforms
- **aws** - AWS services
- **azure** - Azure services
- **gcp** - Google Cloud Platform

## Template Variables

All templates support the following variables:

- `{package}` - Package name
- `{version}` - Package version
- `{platform}` - Platform name
- `{registry}` - Platform registry URL
- `{api}` - Platform API endpoint

## Environment Variables

Templates use platform-specific environment variables for authentication:

- `NPM_TOKEN` - NPM authentication token
- `PYPI_TOKEN` - PyPI authentication token
- `CARGO_TOKEN` - Cargo authentication token
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password
- `MAVEN_SETTINGS` - Maven settings
- `PACKAGIST_TOKEN` - Packagist token

## Integration with Existing System

These templates integrate with the existing PAK system:

1. **Platform Configurations**: Use `pak/config/platforms/platforms.json`
2. **Deployment Records**: Store in `pak/data/deployments/`
3. **Logs**: Write to `pak/logs/deployments/`
4. **Health Monitoring**: Use `pak/scripts/platform-health-check.sh`

## Custom Templates

To create custom templates for new platforms:

1. Create template files in the appropriate directory
2. Make them executable: `chmod +x template.sh`
3. Update platform configuration in `pak/config/platforms/platforms.json`
4. Test with: `pak deploy-test <package> <platforms>`

## Example Usage

```bash
# Deploy to NPM
pak deploy my-package 1.0.0 npm

# Deploy to multiple platforms
pak deploy my-package 1.0.0 "npm pypi cargo"

# Deploy with parallel pipeline
pak deploy-parallel my-package 1.0.0 "npm pypi cargo dockerhub"

# Deploy with staged pipeline
pak deploy-pipeline my-package 1.0.0 "npm pypi cargo dockerhub" staged

# Check deployment status
pak deploy-status <deploy_id>

# Rollback deployment
pak rollback <deploy_id>

# View deployment history
pak deploy-history 10
```

## Error Handling

Templates include comprehensive error handling:

- **Validation Errors**: Check required files and dependencies
- **Build Errors**: Handle compilation and build failures
- **Authentication Errors**: Manage token and credential issues
- **Network Errors**: Handle connectivity and timeout issues
- **Rollback**: Automatic rollback on critical failures

## Monitoring and Logging

All templates provide:

- **Structured Logging**: JSON-formatted logs
- **Progress Tracking**: Real-time deployment status
- **Error Reporting**: Detailed error messages and stack traces
- **Performance Metrics**: Deployment timing and resource usage
- **Health Checks**: Platform availability monitoring

## Security

Templates implement security best practices:

- **Token Management**: Secure handling of authentication tokens
- **Input Validation**: Sanitize all user inputs
- **Error Sanitization**: Prevent sensitive data leakage
- **Access Control**: Platform-specific permission checks
- **Audit Logging**: Complete deployment audit trail 