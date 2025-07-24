#!/usr/bin/env python3
"""
PAK.sh Web API Application Factory
Creates and configures the Flask application with all extensions
"""

import os
import logging
import structlog
from flask import Flask, request
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_socketio import SocketIO
from flask_caching import Cache
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_jwt_extended import JWTManager
from flask_tsk import TskManager
from flask_migrate import Migrate
from flask_compress import Compress
from prometheus_client import Counter, Histogram
import redis

from config import get_config

# Initialize extensions
db = SQLAlchemy()
login_manager = LoginManager()
socketio = SocketIO()
cache = Cache()
limiter = Limiter(key_func=get_remote_address)
jwt = JWTManager()
tsk = TskManager()
migrate = Migrate()
compress = Compress()

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')

def create_app(config_name=None):
    """Application factory function"""
    
    # Create Flask app
    app = Flask(__name__)
    
    # Load configuration
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    app.config.from_object(get_config())
    
    # Initialize logging
    setup_logging(app)
    
    # Initialize extensions
    initialize_extensions(app)
    
    # Register blueprints
    register_blueprints(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register CLI commands
    register_commands(app)
    
    # Setup middleware
    setup_middleware(app)
    
    # Initialize PAK.sh integration
    initialize_pak_integration(app)
    
    return app

def setup_logging(app):
    """Configure structured logging"""
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Set log level
    logging.basicConfig(
        level=getattr(logging, app.config['LOG_LEVEL']),
        format=app.config['LOG_FORMAT']
    )

def initialize_extensions(app):
    """Initialize all Flask extensions"""
    
    # Database
    db.init_app(app)
    
    # Login manager
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = 'Please log in to access this page.'
    login_manager.login_message_category = 'info'
    
    # JWT
    jwt.init_app(app)
    
    # TSK
    tsk.init_app(app)
    
    # Caching
    cache.init_app(app)
    
    # CORS
    CORS(app, origins=app.config['CORS_ORIGINS'], 
         supports_credentials=app.config['CORS_SUPPORTS_CREDENTIALS'])
    
    # Rate limiting
    limiter.init_app(app)
    
    # WebSocket
    socketio.init_app(app, 
                     message_queue=app.config['SOCKETIO_MESSAGE_QUEUE'],
                     async_mode=app.config['SOCKETIO_ASYNC_MODE'],
                     cors_allowed_origins=app.config['CORS_ORIGINS'])
    
    # Database migrations
    migrate.init_app(app, db)
    
    # Compression
    compress.init_app(app)
    
    # User loader for Flask-Login
    @login_manager.user_loader
    def load_user(user_id):
        from models import User
        return User.query.get(int(user_id))

def register_blueprints(app):
    """Register all application blueprints"""
    
    # Import blueprints
    from blueprints.auth import auth_bp
    from blueprints.api import api_bp
    from blueprints.dashboard import dashboard_bp
    from blueprints.admin import admin_bp
    from blueprints.webhooks import webhook_bp
    from blueprints.analytics import analytics_bp
    from blueprints.tsk import tsk_bp
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(api_bp, url_prefix='/api/v1')
    app.register_blueprint(dashboard_bp, url_prefix='/dashboard')
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.register_blueprint(webhook_bp, url_prefix='/webhooks')
    app.register_blueprint(analytics_bp, url_prefix='/analytics')
    app.register_blueprint(tsk_bp, url_prefix='/tsk')

def register_error_handlers(app):
    """Register error handlers"""
    
    @app.errorhandler(404)
    def not_found(error):
        return {'error': 'Not found', 'message': 'The requested resource was not found'}, 404
    
    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return {'error': 'Internal server error', 'message': 'An unexpected error occurred'}, 500
    
    @app.errorhandler(413)
    def too_large(error):
        return {'error': 'File too large', 'message': 'The uploaded file exceeds the maximum size limit'}, 413
    
    @app.errorhandler(429)
    def ratelimit_handler(error):
        return {'error': 'Rate limit exceeded', 'message': 'Too many requests, please try again later'}, 429

def register_commands(app):
    """Register CLI commands"""
    
    @app.cli.command('init-db')
    def init_db():
        """Initialize the database"""
        db.create_all()
        print('Database initialized!')
    
    @app.cli.command('create-admin')
    def create_admin():
        """Create an admin user"""
        from models import User
        from werkzeug.security import generate_password_hash
        
        email = input('Enter admin email: ')
        password = input('Enter admin password: ')
        name = input('Enter admin name: ')
        
        user = User(
            email=email,
            password_hash=generate_password_hash(password),
            name=name,
            role='admin',
            is_active=True,
            email_verified=True
        )
        
        db.session.add(user)
        db.session.commit()
        print(f'Admin user {email} created successfully!')
    
    @app.cli.command('test-pak')
    def test_pak():
        """Test PAK.sh integration"""
        from services.pak_service import PakService
        
        pak = PakService()
        status = pak.get_status()
        print(f'PAK.sh Status: {status}')

def setup_middleware(app):
    """Setup application middleware"""
    
    @app.before_request
    def before_request():
        """Log request metrics"""
        app.logger.info(f'Request: {request.method} {request.path}')
    
    @app.after_request
    def after_request(response):
        """Log response metrics"""
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.endpoint,
            status=response.status_code
        ).inc()
        
        app.logger.info(f'Response: {response.status_code}')
        return response

def initialize_pak_integration(app):
    """Initialize PAK.sh integration"""
    
    # Ensure PAK.sh directories exist
    pak_dirs = [
        app.config['PAK_CONFIG_DIR'],
        app.config['PAK_SCRIPTS_DIR'],
        app.config['PAK_DATA_DIR'],
        app.config['PAK_LOGS_DIR']
    ]
    
    for directory in pak_dirs:
        os.makedirs(directory, exist_ok=True)
    
    # Test PAK.sh availability
    try:
        from services.pak_service import PakService
        pak = PakService()
        status = pak.get_status()
        app.logger.info(f'PAK.sh integration initialized: {status}')
    except Exception as e:
        app.logger.warning(f'PAK.sh integration warning: {e}')

def create_socketio_app(app):
    """Create SocketIO application for real-time features"""
    return socketio.init_app(app)

# Export the socketio instance for use in other modules
__all__ = ['create_app', 'create_socketio_app', 'socketio', 'db', 'cache', 'limiter'] 