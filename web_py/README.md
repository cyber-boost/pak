# PAK.sh Flask Web Application

A modern Flask-based web interface for the PAK.sh (Package Automation Kit) system, providing secure authentication, telemetry dashboard, and user management.

## 🚀 Features

- **Secure Authentication**: User registration, login, and password reset with PakHerd system
- **Telemetry Dashboard**: Real-time monitoring and analytics
- **User Management**: Admin interface for managing users and system statistics
- **API Endpoints**: RESTful API for telemetry data collection
- **Modern UI**: Beautiful, responsive interface with dark theme
- **SQLite Database**: Lightweight database with SQLAlchemy ORM

## 📋 Requirements

- Python 3.8+
- Flask 2.3.3+
- SQLAlchemy 2.0+
- Other dependencies listed in `requirements.txt`

## 🛠️ Installation

### Quick Start

1. **Clone or navigate to the web_py directory**
   ```bash
   cd web_py
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**
   ```bash
   python run.py
   ```

4. **Access the application**
   - Main application: http://localhost:5000
   - Admin interface: http://localhost:5000/admin/users
   - Telemetry dashboard: http://localhost:5000/telemetry

### Production Deployment

1. **Run the deployment script**
   ```bash
   python deploy.py
   ```

2. **Follow the setup instructions** provided by the deployment script

3. **Configure your domain** in the nginx configuration

## 🔐 Authentication

The application uses the PakHerd authentication system with the following features:

- **User Registration**: Self-service user registration
- **Login/Logout**: Secure session management
- **Password Reset**: Email-based password reset (configure email in production)
- **Account Lockout**: Automatic lockout after 5 failed attempts
- **Session Management**: Secure session handling with expiration

### Default Admin Password

The admin interface uses a simple password: `pak-admin-2025`

**⚠️ Important**: Change this password in production!

## 📊 Database Schema

The application uses SQLite with the following tables:

- **users**: User accounts and authentication data
- **sessions**: Active user sessions
- **password_resets**: Password reset tokens
- **login_attempts**: Login attempt logging for security

## 🌐 API Endpoints

### Telemetry API

- `POST /api/telemetry` - Submit telemetry data
- `POST /webhook/telemetry` - Webhook endpoint

Both endpoints require an API key in the `X-API-Key` header.

### Example Usage

```bash
curl -X POST http://yourdomain.com/api/telemetry \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY_HERE" \
  -d '{"package": "example", "action": "install", "status": "success"}'
```

## 🎨 UI Components

### Templates

- `base.html` - Base template with navigation and styling
- `auth.html` - Beautiful authentication page with terminal theme
- `dashboard.html` - User dashboard with statistics
- `telemetry.html` - Telemetry dashboard and API documentation
- `commands.html` - PAK.sh command reference
- `admin_users.html` - User management interface

### Styling

The application uses a modern dark theme with:
- CSS custom properties for consistent theming
- Responsive grid layouts
- Terminal-inspired design elements
- Smooth animations and transitions

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
SECRET_KEY=your-super-secret-key-change-this-in-production
FLASK_ENV=production
FLASK_DEBUG=0
DATABASE_URL=sqlite:///pak_herd.db
```

### API Configuration

Update the API key in `app.py` for the telemetry endpoints:

```python
if api_key != 'YOUR_API_KEY_HERE':
    return jsonify({'error': 'Invalid API key'}), 401
```

## 📁 Project Structure

```
web_py/
├── app.py                 # Main Flask application
├── run.py                 # Application runner
├── deploy.py              # Production deployment script
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── templates/            # Jinja2 templates
│   ├── base.html
│   ├── auth.html
│   ├── dashboard.html
│   ├── telemetry.html
│   ├── commands.html
│   ├── admin_users.html
│   ├── 404.html
│   └── 500.html
├── uploads/              # File upload directory
├── logs/                 # Application logs
└── pak_herd.db          # SQLite database (created automatically)
```

## 🚀 Development

### Running in Development Mode

```bash
python run.py
```

The application will run in debug mode with auto-reload enabled.

### Database Management

The database is automatically created when the application starts. To reset the database:

```bash
rm pak_herd.db
python run.py
```

### Adding New Features

1. Add routes to `app.py`
2. Create templates in `templates/`
3. Update navigation in `base.html`
4. Add any new dependencies to `requirements.txt`

## 🔒 Security Considerations

- Change the default admin password
- Use a strong SECRET_KEY in production
- Configure HTTPS in production
- Set up proper firewall rules
- Consider adding IP restrictions for admin interface
- Implement rate limiting for API endpoints

## 📞 Support

For issues and questions:
- Check the logs in the `logs/` directory
- Review the Flask application logs
- Ensure all dependencies are installed correctly

## 📄 License

This is part of the PAK.sh (Package Automation Kit) project. 