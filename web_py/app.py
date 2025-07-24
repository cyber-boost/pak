#!/usr/bin/env python3
"""
PAK.sh Web API - Main Application
Backward compatibility and main application entry point
"""

import os
from app_factory import create_app, socketio

# Create the Flask application
app = create_app()

# Create SocketIO application for real-time features
socketio_app = socketio.init_app(app)

# Import all models to ensure they're registered
from models import *

# Import all blueprints to ensure they're registered
from blueprints.auth import auth_bp
from blueprints.api import api_bp
from blueprints.dashboard import dashboard_bp
from blueprints.admin import admin_bp
from blueprints.webhooks import webhook_bp
from blueprints.analytics import analytics_bp
from blueprints.tsk import tsk_bp

# Register blueprints (in case they weren't registered by the factory)
if not app.blueprints.get('auth'):
    app.register_blueprint(auth_bp, url_prefix='/auth')
if not app.blueprints.get('api'):
    app.register_blueprint(api_bp, url_prefix='/api/v1')
if not app.blueprints.get('dashboard'):
    app.register_blueprint(dashboard_bp, url_prefix='/dashboard')
if not app.blueprints.get('admin'):
    app.register_blueprint(admin_bp, url_prefix='/admin')
if not app.blueprints.get('webhooks'):
    app.register_blueprint(webhook_bp, url_prefix='/webhooks')
if not app.blueprints.get('analytics'):
    app.register_blueprint(analytics_bp, url_prefix='/analytics')
if not app.blueprints.get('tsk'):
    app.register_blueprint(tsk_bp, url_prefix='/tsk')

# Backward compatibility routes
@app.route('/')
def home():
    """Home page - redirect to dashboard"""
    return app.redirect('/dashboard')

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'healthy', 'service': 'PAK.sh Web API'}

@app.route('/version')
def version():
    """Version information"""
    return {
        'version': '2.0.0',
        'service': 'PAK.sh Web API',
        'environment': os.environ.get('FLASK_ENV', 'development')
    }

# Initialize database tables
@app.before_first_request
def initialize_database():
    """Initialize database tables on first request"""
    from app_factory import db
    db.create_all()

if __name__ == '__main__':
    # This allows running the app directly for development
    app.run(debug=True, host='0.0.0.0', port=5000) 