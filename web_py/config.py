#!/usr/bin/env python3
"""
PAK.sh Web API Configuration
Environment-based configuration management
"""

import os
import secrets
from pathlib import Path
from datetime import timedelta

class Config:
    """Base configuration class"""
    
    # Flask Configuration
    SECRET_KEY = os.environ.get('SECRET_KEY') or secrets.token_hex(32)
    FLASK_ENV = os.environ.get('FLASK_ENV', 'development')
    DEBUG = os.environ.get('DEBUG', 'True').lower() == 'true'
    
    # Database Configuration
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///pak_herd.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
    }
    
    # Redis Configuration (for caching and sessions)
    REDIS_URL = os.environ.get('REDIS_URL') or 'redis://localhost:6379/0'
    
    # JWT Configuration
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or secrets.token_hex(32)
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_ERROR_MESSAGE_KEY = 'message'
    
    # Rate Limiting
    RATELIMIT_DEFAULT = "200 per day;50 per hour;10 per minute"
    RATELIMIT_STORAGE_URL = REDIS_URL
    
    # File Upload Configuration
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    UPLOAD_FOLDER = 'uploads'
    ALLOWED_EXTENSIONS = {
        'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'svg',
        'yaml', 'yml', 'json', 'sh', 'zip', 'tar', 'gz'
    }
    
    # PAK.sh Integration
    PAK_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    PAK_CONFIG_DIR = os.path.join(PAK_ROOT, 'config')
    PAK_SCRIPTS_DIR = os.path.join(PAK_ROOT, 'scripts')
    PAK_DATA_DIR = os.path.join(PAK_ROOT, 'data')
    PAK_LOGS_DIR = os.path.join(PAK_ROOT, 'logs')
    
    # WebSocket Configuration
    SOCKETIO_MESSAGE_QUEUE = REDIS_URL
    SOCKETIO_ASYNC_MODE = 'eventlet'
    
    # Caching Configuration
    CACHE_TYPE = 'redis'
    CACHE_REDIS_URL = REDIS_URL
    CACHE_DEFAULT_TIMEOUT = 300
    
    # Security Configuration
    SESSION_COOKIE_SECURE = False  # Set to True in production with HTTPS
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)
    
    # CORS Configuration
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*').split(',')
    CORS_SUPPORTS_CREDENTIALS = True
    
    # Logging Configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # API Configuration
    API_TITLE = 'PAK.sh Web API'
    API_VERSION = 'v1'
    API_DESCRIPTION = 'Package Automation Kit Web API'
    API_DOC_URL = '/api/docs'
    
    # TSK Configuration
    TSK_ENABLED = os.environ.get('TSK_ENABLED', 'True').lower() == 'true'
    TSK_CONFIG_PATH = os.environ.get('TSK_CONFIG_PATH', os.path.join(PAK_ROOT, 'tsk'))
    TSK_TEMPLATE_PATH = os.environ.get('TSK_TEMPLATE_PATH', os.path.join(PAK_ROOT, 'templates'))
    TSK_CACHE_ENABLED = os.environ.get('TSK_CACHE_ENABLED', 'True').lower() == 'true'
    TSK_CACHE_TIMEOUT = int(os.environ.get('TSK_CACHE_TIMEOUT', 300))
    
    # Webhook Configuration
    WEBHOOK_TIMEOUT = 30
    WEBHOOK_MAX_RETRIES = 3
    WEBHOOK_RETRY_DELAY = 5
    
    # Analytics Configuration
    ANALYTICS_ENABLED = os.environ.get('ANALYTICS_ENABLED', 'True').lower() == 'true'
    ANALYTICS_RETENTION_DAYS = 90
    
    # Email Configuration (for notifications)
    MAIL_SERVER = os.environ.get('MAIL_SERVER', 'localhost')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'True').lower() == 'true'
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    MAIL_DEFAULT_SENDER = os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@pak.sh')
    
    # Celery Configuration (for background tasks)
    CELERY_BROKER_URL = REDIS_URL
    CELERY_RESULT_BACKEND = REDIS_URL
    CELERY_TASK_SERIALIZER = 'json'
    CELERY_RESULT_SERIALIZER = 'json'
    CELERY_ACCEPT_CONTENT = ['json']
    CELERY_TIMEZONE = 'UTC'
    CELERY_ENABLE_UTC = True

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///pak_herd_dev.db'
    REDIS_URL = 'redis://localhost:6379/1'
    CACHE_TYPE = 'simple'
    
    # Development-specific settings
    SOCKETIO_DEBUG = True
    SOCKETIO_LOGGER = True
    SOCKETIO_ENGINEIO_LOGGER = True

class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    REDIS_URL = 'redis://localhost:6379/2'
    CACHE_TYPE = 'simple'
    WTF_CSRF_ENABLED = False
    
    # Disable external services for testing
    ANALYTICS_ENABLED = False
    MAIL_SUPPRESS_SEND = True

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    FLASK_ENV = 'production'
    
    # Security settings for production
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Strict'
    
    # Production-specific settings
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    REDIS_URL = os.environ.get('REDIS_URL')
    
    # Disable debug features
    SOCKETIO_DEBUG = False
    SOCKETIO_LOGGER = False
    SOCKETIO_ENGINEIO_LOGGER = False

class StagingConfig(Config):
    """Staging configuration"""
    DEBUG = True
    FLASK_ENV = 'staging'
    
    # Staging-specific settings
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    REDIS_URL = os.environ.get('REDIS_URL')

# Configuration mapping
config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'staging': StagingConfig,
    'default': DevelopmentConfig
}

def get_config():
    """Get configuration based on environment"""
    config_name = os.environ.get('FLASK_ENV', 'development')
    return config.get(config_name, config['default']) 