# PAK.sh Flask Integration Guide

This document describes the comprehensive PAK.sh integration features in the Flask web application.

## 🚀 Overview

The Flask application now provides a complete web interface for managing PAK.sh projects, including:

- **Project Management**: View, deploy, and package PAK.sh projects
- **Credential Management**: Secure storage and management of project credentials
- **Deployment Tracking**: Monitor deployment status and history
- **System Status**: Real-time PAK.sh system health monitoring
- **Configuration Management**: View and manage project configurations

## 📁 Project Structure

```
web_py/
├── app.py                 # Main Flask application with PAK.sh integration
├── templates/
│   ├── projects.html      # Project listing and management
│   ├── project_detail.html # Individual project details and actions
│   ├── credentials.html   # Credential management interface
│   └── ...               # Other templates
├── PakManager.py          # PAK.sh integration class
└── PAK_INTEGRATION.md     # This file
```

## 🔧 PAK.sh Integration Features

### 1. Project Discovery

The application automatically discovers PAK.sh projects by scanning for configuration files:

- `pak.yaml` / `pak.yml` - YAML configuration files
- `pak.json` - JSON configuration files  
- `peanu.tsk` - TuskLang configuration files

**Location**: `/projects` - Lists all discovered projects

### 2. Project Deployment

Deploy projects to different environments through the web interface:

```bash
# Web Interface Action
POST /deploy/<project_name>
{
    "environment": "production|staging|development|testing"
}

# Executes
cd /path/to/project && ./pak.sh deploy --environment production
```

**Features**:
- Environment selection (production, staging, development, testing)
- Real-time deployment status tracking
- Deployment history and logs
- Success/failure notifications

### 3. Project Packaging

Package projects with optional version specification:

```bash
# Web Interface Action
POST /package/<project_name>
{
    "version": "1.0.0"  # Optional
}

# Executes
cd /path/to/project && ./pak.sh package --version 1.0.0
```

### 4. Credential Management

Secure credential storage and management:

**Supported Credential Types**:
- Database credentials (host, port, name, user, password)
- API credentials (key, secret, endpoint)
- SSH credentials (host, port, user, key path)
- Cloud credentials (AWS access keys, regions)

**Storage**: `credentials.yaml` in project directory
**Security**: File-based storage with .gitignore recommendations

### 5. Configuration Management

View and manage project configurations:

- **YAML/JSON**: Pretty-printed configuration display
- **TSK Files**: Raw content display
- **Configuration Validation**: Syntax checking
- **Configuration History**: Track changes over time

### 6. System Status Monitoring

Real-time PAK.sh system health monitoring:

- **Version Information**: PAK.sh version detection
- **Active Projects**: Count of discovered projects
- **Configuration Files**: List of system config files
- **Recent Deployments**: Latest deployment activity
- **System Health**: Overall system status

## 🗄️ Database Schema

### New Tables

```sql
-- Project tracking
CREATE TABLE pak_projects (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    config_path VARCHAR(500),
    status VARCHAR(50) DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(id)
);

-- Deployment tracking
CREATE TABLE pak_deployments (
    id INTEGER PRIMARY KEY,
    project_id INTEGER REFERENCES pak_projects(id),
    environment VARCHAR(50),
    status VARCHAR(50),
    logs TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    created_by INTEGER REFERENCES users(id)
);
```

## 🔐 Security Features

### Credential Security

1. **File-based Storage**: Credentials stored in project-specific `credentials.yaml`
2. **Gitignore Protection**: Automatic .gitignore recommendations
3. **Environment Variables**: Support for environment variable overrides
4. **Access Control**: Role-based access to credential management

### Command Execution Security

1. **Timeout Protection**: 5-minute timeout on all PAK.sh commands
2. **Working Directory Isolation**: Commands run in project-specific directories
3. **Error Handling**: Comprehensive error capture and logging
4. **User Tracking**: All actions logged with user attribution

## 🌐 API Endpoints

### Project Management

```
GET  /projects                    # List all projects
GET  /projects/<name>             # Project details
POST /deploy/<name>               # Deploy project
POST /package/<name>              # Package project
GET  /credentials/<name>          # View credentials
POST /credentials/<name>          # Update credentials
```

### System Status

```
GET  /dashboard                   # System overview with PAK.sh status
GET  /telemetry                   # Telemetry dashboard
```

## 🎨 User Interface

### Projects Page (`/projects`)

- **Project Cards**: Each project displayed as a card with status
- **Quick Actions**: Deploy, package, view details, manage credentials
- **Status Indicators**: Visual status badges for project health
- **Configuration Display**: Show detected config file types

### Project Detail Page (`/projects/<name>`)

- **Deployment Form**: Environment selection and deployment trigger
- **Packaging Form**: Version specification and packaging trigger
- **Configuration Viewer**: Pretty-printed configuration display
- **Action History**: Recent deployment and packaging activity

### Credentials Page (`/credentials/<name>`)

- **Credential Forms**: Organized by credential type (DB, API, SSH, Cloud)
- **Security Information**: Best practices and security recommendations
- **Environment Variables**: Example environment variable usage
- **File Management**: Credential file location and management

## 🔄 Integration Workflow

### Typical Usage Flow

1. **Project Discovery**: System scans for PAK.sh projects
2. **Project Setup**: User configures project credentials
3. **Deployment**: User deploys project to target environment
4. **Monitoring**: System tracks deployment status and logs
5. **Packaging**: User packages project for distribution
6. **History**: All actions logged for audit trail

### Command Execution Flow

1. **User Action**: User triggers action via web interface
2. **Validation**: System validates project existence and permissions
3. **Database Log**: Action logged in database with user attribution
4. **Command Execution**: PAK.sh command executed in project directory
5. **Result Capture**: Command output and status captured
6. **User Notification**: Success/failure message displayed to user
7. **History Update**: Deployment/packaging history updated

## 🛠️ Configuration

### Environment Variables

```bash
# PAK.sh Integration
PAK_ROOT=/path/to/pak/root          # PAK.sh root directory
PAK_CONFIG_DIR=/path/to/config      # Configuration directory
PAK_SCRIPTS_DIR=/path/to/scripts    # Scripts directory

# Security
SECRET_KEY=your-secret-key          # Flask secret key
ADMIN_PASSWORD=pak-admin-2025       # Admin interface password
```

### File Structure

```
/path/to/pak/root/
├── project1/
│   ├── pak.yaml
│   ├── credentials.yaml
│   └── scripts/
├── project2/
│   ├── peanu.tsk
│   ├── credentials.yaml
│   └── config/
└── web_py/
    ├── app.py
    ├── templates/
    └── pak_herd.db
```

## 🚀 Deployment

### Production Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**:
   ```bash
   export PAK_ROOT=/path/to/pak/root
   export SECRET_KEY=your-production-secret-key
   ```

3. **Initialize Database**:
   ```bash
   python -c "from app import app, db; app.app_context().push(); db.create_all()"
   ```

4. **Run Application**:
   ```bash
   gunicorn --workers 4 --bind 0.0.0.0:5000 app:app
   ```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Project Not Found**: Ensure project has valid config file (pak.yaml, pak.yml, pak.json, peanu.tsk)
2. **Permission Denied**: Check file permissions on PAK.sh scripts
3. **Command Timeout**: Increase timeout in PakManager.run_pak_command()
4. **Credential Errors**: Verify credential file format and permissions

### Debug Mode

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Log Files

- **Application Logs**: Check Flask application logs
- **PAK.sh Logs**: Check individual project log files
- **Database Logs**: Check SQLite database for deployment history

## 📈 Future Enhancements

### Planned Features

1. **Real-time Deployment Monitoring**: WebSocket-based live deployment status
2. **Rollback Functionality**: Deploy previous versions
3. **Multi-environment Support**: Manage multiple deployment environments
4. **Team Collaboration**: Share projects and credentials securely
5. **Advanced Analytics**: Deployment metrics and performance tracking
6. **CI/CD Integration**: Webhook support for automated deployments
7. **Backup Management**: Automated project and credential backups

### API Enhancements

1. **RESTful API**: Complete REST API for all PAK.sh operations
2. **Webhook Support**: External system integration
3. **GraphQL**: Advanced querying capabilities
4. **Rate Limiting**: API usage protection
5. **Authentication**: API key management

## 📞 Support

For issues and questions:

1. Check the application logs for error details
2. Verify PAK.sh installation and configuration
3. Ensure proper file permissions and paths
4. Review the troubleshooting section above
5. Check the PAK.sh documentation for command-specific issues

---

This integration provides a complete web interface for PAK.sh project management, making it easy to deploy, package, and manage projects through a modern web interface while maintaining all the power and flexibility of the command-line tools. 