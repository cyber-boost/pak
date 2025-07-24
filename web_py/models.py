#!/usr/bin/env python3
"""
PAK.sh Web API Database Models
Comprehensive data models for the modern web API
"""

import datetime
import secrets
import hashlib
from sqlalchemy import event
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import relationship
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from app_factory import db

class TimestampMixin:
    """Mixin for timestamp fields"""
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class User(UserMixin, db.Model, TimestampMixin):
    """User model with enhanced features"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(50), default='user', index=True)
    is_active = db.Column(db.Boolean, default=True, index=True)
    email_verified = db.Column(db.Boolean, default=False)
    last_login = db.Column(db.DateTime)
    failed_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime)
    
    # Profile fields
    avatar_url = db.Column(db.String(500))
    bio = db.Column(db.Text)
    timezone = db.Column(db.String(50), default='UTC')
    language = db.Column(db.String(10), default='en')
    
    # API access
    api_key = db.Column(db.String(64), unique=True, index=True)
    api_key_created = db.Column(db.DateTime)
    api_quota_daily = db.Column(db.Integer, default=1000)
    api_quota_monthly = db.Column(db.Integer, default=30000)
    
    # Relationships
    projects = relationship('PakProject', back_populates='owner', cascade='all, delete-orphan')
    deployments = relationship('PakDeployment', back_populates='user', cascade='all, delete-orphan')
    sessions = relationship('UserSession', back_populates='user', cascade='all, delete-orphan')
    webhooks = relationship('Webhook', back_populates='user', cascade='all, delete-orphan')
    api_usage = relationship('ApiUsage', back_populates='user', cascade='all, delete-orphan')
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.api_key:
            self.generate_api_key()
    
    def set_password(self, password):
        """Set user password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check user password"""
        return check_password_hash(self.password_hash, password)
    
    def generate_api_key(self):
        """Generate new API key"""
        self.api_key = secrets.token_urlsafe(32)
        self.api_key_created = datetime.datetime.utcnow()
    
    def is_admin(self):
        """Check if user is admin"""
        return self.role == 'admin'
    
    def is_locked(self):
        """Check if user account is locked"""
        if self.locked_until and self.locked_until > datetime.datetime.utcnow():
            return True
        return False
    
    def record_failed_login(self):
        """Record failed login attempt"""
        self.failed_attempts += 1
        if self.failed_attempts >= 5:
            self.locked_until = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
    
    def reset_failed_attempts(self):
        """Reset failed login attempts"""
        self.failed_attempts = 0
        self.locked_until = None

class UserSession(db.Model, TimestampMixin):
    """User session model"""
    __tablename__ = 'sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    session_id = db.Column(db.String(255), unique=True, nullable=False, index=True)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    expires_at = db.Column(db.DateTime, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    user = relationship('User', back_populates='sessions')
    
    def is_expired(self):
        """Check if session is expired"""
        return datetime.datetime.utcnow() > self.expires_at

class PakProject(db.Model, TimestampMixin):
    """PAK project model"""
    __tablename__ = 'pak_projects'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False, index=True)
    description = db.Column(db.Text)
    config_path = db.Column(db.String(500))
    status = db.Column(db.String(50), default='active', index=True)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Project metadata
    version = db.Column(db.String(50))
    platform = db.Column(db.String(100))
    language = db.Column(db.String(50))
    framework = db.Column(db.String(100))
    
    # Configuration
    config_data = db.Column(db.JSON)
    environment_vars = db.Column(db.JSON)
    dependencies = db.Column(db.JSON)
    
    # Statistics
    deployment_count = db.Column(db.Integer, default=0)
    last_deployment = db.Column(db.DateTime)
    success_rate = db.Column(db.Float, default=0.0)
    
    # Relationships
    owner = relationship('User', back_populates='projects')
    deployments = relationship('PakDeployment', back_populates='project', cascade='all, delete-orphan')
    webhooks = relationship('ProjectWebhook', back_populates='project', cascade='all, delete-orphan')
    
    @hybrid_property
    def is_active(self):
        """Check if project is active"""
        return self.status == 'active'
    
    def get_latest_deployment(self):
        """Get the latest deployment"""
        return PakDeployment.query.filter_by(project_id=self.id).order_by(PakDeployment.created_at.desc()).first()

class PakDeployment(db.Model, TimestampMixin):
    """PAK deployment model"""
    __tablename__ = 'pak_deployments'
    
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('pak_projects.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Deployment details
    environment = db.Column(db.String(50), index=True)  # staging, production, etc.
    status = db.Column(db.String(50), index=True)  # pending, running, success, failed, cancelled
    version = db.Column(db.String(50))
    
    # Execution details
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    duration = db.Column(db.Integer)  # seconds
    
    # Logs and output
    logs = db.Column(db.Text)
    output = db.Column(db.JSON)
    error_message = db.Column(db.Text)
    
    # Configuration
    config_snapshot = db.Column(db.JSON)
    environment_vars = db.Column(db.JSON)
    
    # Relationships
    project = relationship('PakProject', back_populates='deployments')
    user = relationship('User', back_populates='deployments')
    
    @hybrid_property
    def is_running(self):
        """Check if deployment is running"""
        return self.status == 'running'
    
    @hybrid_property
    def is_completed(self):
        """Check if deployment is completed"""
        return self.status in ['success', 'failed', 'cancelled']
    
    def calculate_duration(self):
        """Calculate deployment duration"""
        if self.started_at and self.completed_at:
            self.duration = int((self.completed_at - self.started_at).total_seconds())

class Webhook(db.Model, TimestampMixin):
    """Webhook model for integrations"""
    __tablename__ = 'webhooks'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    url = db.Column(db.String(500), nullable=False)
    secret = db.Column(db.String(255))
    
    # Configuration
    events = db.Column(db.JSON)  # List of events to trigger on
    is_active = db.Column(db.Boolean, default=True)
    retry_count = db.Column(db.Integer, default=3)
    timeout = db.Column(db.Integer, default=30)
    
    # Statistics
    success_count = db.Column(db.Integer, default=0)
    failure_count = db.Column(db.Integer, default=0)
    last_triggered = db.Column(db.DateTime)
    
    # Relationships
    user = relationship('User', back_populates='webhooks')
    deliveries = relationship('WebhookDelivery', back_populates='webhook', cascade='all, delete-orphan')
    
    def generate_secret(self):
        """Generate webhook secret"""
        self.secret = secrets.token_urlsafe(32)

class WebhookDelivery(db.Model, TimestampMixin):
    """Webhook delivery tracking"""
    __tablename__ = 'webhook_deliveries'
    
    id = db.Column(db.Integer, primary_key=True)
    webhook_id = db.Column(db.Integer, db.ForeignKey('webhooks.id'), nullable=False)
    event = db.Column(db.String(100), nullable=False)
    payload = db.Column(db.JSON)
    
    # Delivery details
    status_code = db.Column(db.Integer)
    response_body = db.Column(db.Text)
    duration = db.Column(db.Float)  # seconds
    retry_count = db.Column(db.Integer, default=0)
    
    # Relationships
    webhook = relationship('Webhook', back_populates='deliveries')

class ProjectWebhook(db.Model, TimestampMixin):
    """Project-specific webhooks"""
    __tablename__ = 'project_webhooks'
    
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('pak_projects.id'), nullable=False)
    webhook_id = db.Column(db.Integer, db.ForeignKey('webhooks.id'), nullable=False)
    
    # Configuration
    events = db.Column(db.JSON)  # Override webhook events for this project
    
    # Relationships
    project = relationship('PakProject', back_populates='webhooks')
    webhook = relationship('Webhook')

class ApiUsage(db.Model, TimestampMixin):
    """API usage tracking"""
    __tablename__ = 'api_usage'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    endpoint = db.Column(db.String(255), nullable=False)
    method = db.Column(db.String(10), nullable=False)
    status_code = db.Column(db.Integer)
    duration = db.Column(db.Float)  # seconds
    ip_address = db.Column(db.String(45))
    
    # Relationships
    user = relationship('User', back_populates='api_usage')

class Analytics(db.Model, TimestampMixin):
    """Analytics data model"""
    __tablename__ = 'analytics'
    
    id = db.Column(db.Integer, primary_key=True)
    metric_name = db.Column(db.String(255), nullable=False, index=True)
    metric_value = db.Column(db.Float, nullable=False)
    metric_unit = db.Column(db.String(50))
    
    # Dimensions
    project_id = db.Column(db.Integer, db.ForeignKey('pak_projects.id'))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    environment = db.Column(db.String(50))
    platform = db.Column(db.String(100))
    
    # Timestamp for time-series data
    recorded_at = db.Column(db.DateTime, default=datetime.datetime.utcnow, index=True)
    
    # Relationships
    project = relationship('PakProject')
    user = relationship('User')

class Notification(db.Model, TimestampMixin):
    """User notification model"""
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    message = db.Column(db.Text, nullable=False)
    type = db.Column(db.String(50), default='info')  # info, success, warning, error
    is_read = db.Column(db.Boolean, default=False)
    
    # Action data
    action_url = db.Column(db.String(500))
    action_text = db.Column(db.String(100))
    
    # Relationships
    user = relationship('User')

class PasswordReset(db.Model, TimestampMixin):
    """Password reset token model"""
    __tablename__ = 'password_resets'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    token = db.Column(db.String(255), unique=True, nullable=False, index=True)
    expires_at = db.Column(db.DateTime, nullable=False)
    used = db.Column(db.Boolean, default=False)
    
    # Relationships
    user = relationship('User')
    
    def is_expired(self):
        """Check if token is expired"""
        return datetime.datetime.utcnow() > self.expires_at

class LoginAttempt(db.Model, TimestampMixin):
    """Login attempt tracking"""
    __tablename__ = 'login_attempts'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), nullable=False, index=True)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    success = db.Column(db.Boolean, default=False)
    
    # Additional data
    failure_reason = db.Column(db.String(100))

# Event listeners for automatic updates
@event.listens_for(PakDeployment, 'before_update')
def update_deployment_stats(mapper, connection, target):
    """Update project statistics when deployment is updated"""
    if target.is_completed and not target.duration:
        target.calculate_duration()

@event.listens_for(PakDeployment, 'after_insert')
def update_project_stats(mapper, connection, target):
    """Update project statistics when deployment is created"""
    project = target.project
    project.deployment_count += 1
    project.last_deployment = target.created_at
    
    # Calculate success rate
    total_deployments = PakDeployment.query.filter_by(project_id=project.id).count()
    successful_deployments = PakDeployment.query.filter_by(
        project_id=project.id, status='success'
    ).count()
    
    if total_deployments > 0:
        project.success_rate = (successful_deployments / total_deployments) * 100 