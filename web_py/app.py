#!/usr/bin/env python3
"""
PAK.sh Flask Web Application
Package Automation Kit - Web Interface
"""

from flask import Flask, render_template, request, redirect, url_for, session, jsonify, flash
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import os
import sqlite3
import json
import datetime
import secrets
import hashlib
from functools import wraps
import logging
import subprocess
import yaml
import configparser
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'pak-secret-key-change-in-production')

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///pak_herd.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'yaml', 'yml', 'json', 'sh'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# PAK.sh integration
PAK_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAK_CONFIG_DIR = os.path.join(PAK_ROOT, 'config')
PAK_SCRIPTS_DIR = os.path.join(PAK_ROOT, 'scripts')

# Database Models
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(50), default='user')
    is_active = db.Column(db.Boolean, default=True)
    email_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    last_login = db.Column(db.DateTime)
    failed_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime)

class UserSession(db.Model):
    __tablename__ = 'sessions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    session_id = db.Column(db.String(255), unique=True, nullable=False)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)

class PasswordReset(db.Model):
    __tablename__ = 'password_resets'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    token = db.Column(db.String(255), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)
    used = db.Column(db.Boolean, default=False)

class LoginAttempt(db.Model):
    __tablename__ = 'login_attempts'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), nullable=False)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    success = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)

class PakProject(db.Model):
    __tablename__ = 'pak_projects'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    config_path = db.Column(db.String(500))
    status = db.Column(db.String(50), default='active')
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))

class PakDeployment(db.Model):
    __tablename__ = 'pak_deployments'
    
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('pak_projects.id'))
    environment = db.Column(db.String(50))  # staging, production, etc.
    status = db.Column(db.String(50))  # pending, running, success, failed
    logs = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))

# Authentication decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth'))
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth'))
        
        user = User.query.get(session['user_id'])
        if not user or user.role != 'admin':
            flash('Admin access required', 'error')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

# PAK.sh Integration Functions
class PakManager:
    @staticmethod
    def run_pak_command(command, cwd=None):
        """Run a pak.sh command and return the result"""
        try:
            if cwd is None:
                cwd = PAK_ROOT
            
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'returncode': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'stdout': '',
                'stderr': 'Command timed out after 5 minutes',
                'returncode': -1
            }
        except Exception as e:
            return {
                'success': False,
                'stdout': '',
                'stderr': str(e),
                'returncode': -1
            }
    
    @staticmethod
    def get_pak_status():
        """Get overall PAK.sh system status"""
        status = {
            'version': 'Unknown',
            'config_files': [],
            'active_projects': 0,
            'recent_deployments': [],
            'system_health': 'unknown'
        }
        
        # Try to get version
        version_result = PakManager.run_pak_command('./pak.sh --version')
        if version_result['success']:
            status['version'] = version_result['stdout'].strip()
        
        # Check for config files
        config_files = []
        if os.path.exists(PAK_CONFIG_DIR):
            for file in os.listdir(PAK_CONFIG_DIR):
                if file.endswith(('.yaml', '.yml', '.json', '.conf')):
                    config_files.append(file)
        status['config_files'] = config_files
        
        # Get active projects count
        status['active_projects'] = PakProject.query.filter_by(status='active').count()
        
        # Get recent deployments
        recent_deployments = PakDeployment.query.order_by(
            PakDeployment.created_at.desc()
        ).limit(5).all()
        
        status['recent_deployments'] = [
            {
                'id': d.id,
                'project': PakProject.query.get(d.project_id).name if d.project_id else 'Unknown',
                'environment': d.environment,
                'status': d.status,
                'created_at': d.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            for d in recent_deployments
        ]
        
        return status
    
    @staticmethod
    def list_projects():
        """List all PAK.sh projects"""
        projects = []
        
        # Look for project directories
        for item in os.listdir(PAK_ROOT):
            item_path = os.path.join(PAK_ROOT, item)
            if os.path.isdir(item_path):
                # Check for pak.sh config files
                config_files = ['pak.yaml', 'pak.yml', 'pak.json', 'peanu.tsk']
                for config_file in config_files:
                    if os.path.exists(os.path.join(item_path, config_file)):
                        projects.append({
                            'name': item,
                            'path': item_path,
                            'config_file': config_file,
                            'status': 'active'
                        })
                        break
        
        return projects
    
    @staticmethod
    def deploy_project(project_name, environment='production'):
        """Deploy a PAK.sh project"""
        project_path = os.path.join(PAK_ROOT, project_name)
        
        if not os.path.exists(project_path):
            return {'success': False, 'error': f'Project {project_name} not found'}
        
        # Create deployment record
        project = PakProject.query.filter_by(name=project_name).first()
        if not project:
            project = PakProject(name=project_name, config_path=project_path)
            db.session.add(project)
            db.session.commit()
        
        deployment = PakDeployment(
            project_id=project.id,
            environment=environment,
            status='running',
            created_by=session.get('user_id')
        )
        db.session.add(deployment)
        db.session.commit()
        
        # Run deployment command
        deploy_cmd = f'cd {project_path} && ./pak.sh deploy --environment {environment}'
        result = PakManager.run_pak_command(deploy_cmd, cwd=project_path)
        
        # Update deployment record
        deployment.status = 'success' if result['success'] else 'failed'
        deployment.logs = result['stdout'] + '\n' + result['stderr']
        deployment.completed_at = datetime.datetime.utcnow()
        db.session.commit()
        
        return {
            'success': result['success'],
            'deployment_id': deployment.id,
            'logs': result['stdout'] + '\n' + result['stderr']
        }
    
    @staticmethod
    def package_project(project_name, version=None):
        """Package a PAK.sh project"""
        project_path = os.path.join(PAK_ROOT, project_name)
        
        if not os.path.exists(project_path):
            return {'success': False, 'error': f'Project {project_name} not found'}
        
        # Run package command
        package_cmd = f'cd {project_path} && ./pak.sh package'
        if version:
            package_cmd += f' --version {version}'
        
        result = PakManager.run_pak_command(package_cmd, cwd=project_path)
        
        return {
            'success': result['success'],
            'output': result['stdout'],
            'error': result['stderr']
        }
    
    @staticmethod
    def setup_credentials(project_name, credentials_data):
        """Setup credentials for a project"""
        project_path = os.path.join(PAK_ROOT, project_name)
        
        if not os.path.exists(project_path):
            return {'success': False, 'error': f'Project {project_name} not found'}
        
        # Create credentials file
        credentials_file = os.path.join(project_path, 'credentials.yaml')
        
        try:
            with open(credentials_file, 'w') as f:
                yaml.dump(credentials_data, f, default_flow_style=False)
            
            return {'success': True, 'message': f'Credentials saved to {credentials_file}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def get_project_config(project_name):
        """Get project configuration"""
        project_path = os.path.join(PAK_ROOT, project_name)
        
        if not os.path.exists(project_path):
            return None
        
        # Look for config files
        config_files = ['pak.yaml', 'pak.yml', 'pak.json', 'peanu.tsk']
        config_data = {}
        
        for config_file in config_files:
            config_path = os.path.join(project_path, config_file)
            if os.path.exists(config_path):
                try:
                    if config_file.endswith(('.yaml', '.yml')):
                        with open(config_path, 'r') as f:
                            config_data = yaml.safe_load(f)
                    elif config_file.endswith('.json'):
                        with open(config_path, 'r') as f:
                            config_data = json.load(f)
                    else:
                        # For .tsk files, read as text
                        with open(config_path, 'r') as f:
                            config_data = {'content': f.read()}
                    
                    config_data['_config_file'] = config_file
                    break
                except Exception as e:
                    logger.error(f"Error reading config {config_path}: {e}")
        
        return config_data

# Authentication functions
class PakHerd:
    @staticmethod
    def create_user(user_data):
        try:
            # Check if user already exists
            existing_user = User.query.filter_by(email=user_data['email']).first()
            if existing_user:
                return {'success': False, 'message': 'User already exists'}
            
            # Create new user
            user = User(
                email=user_data['email'],
                password_hash=generate_password_hash(user_data['password']),
                name=user_data['name'],
                role=user_data.get('role', 'user')
            )
            
            db.session.add(user)
            db.session.commit()
            
            return {'success': True, 'message': 'User created successfully'}
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error creating user: {e}")
            return {'success': False, 'message': 'Error creating user'}
    
    @staticmethod
    def login(email, password, remember=False):
        try:
            # Check for account lockout
            user = User.query.filter_by(email=email).first()
            if user and user.locked_until and user.locked_until > datetime.datetime.utcnow():
                return {'success': False, 'message': 'Account is locked. Please try again later.'}
            
            # Verify credentials
            if user and check_password_hash(user.password_hash, password):
                # Reset failed attempts
                user.failed_attempts = 0
                user.locked_until = None
                user.last_login = datetime.datetime.utcnow()
                db.session.commit()
                
                # Create session
                session_id = secrets.token_urlsafe(32)
                session_expiry = datetime.datetime.utcnow() + datetime.timedelta(days=30 if remember else 1)
                
                user_session = UserSession(
                    user_id=user.id,
                    session_id=session_id,
                    ip_address=request.remote_addr,
                    user_agent=request.headers.get('User-Agent'),
                    expires_at=session_expiry
                )
                
                db.session.add(user_session)
                db.session.commit()
                
                # Set session
                session['user_id'] = user.id
                session['session_id'] = session_id
                session['user_role'] = user.role
                
                # Log successful attempt
                PakHerd._log_attempt(email, True)
                
                return {'success': True, 'message': 'Login successful'}
            else:
                # Increment failed attempts
                if user:
                    user.failed_attempts += 1
                    if user.failed_attempts >= 5:
                        user.locked_until = datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
                    db.session.commit()
                
                # Log failed attempt
                PakHerd._log_attempt(email, False)
                
                return {'success': False, 'message': 'Invalid credentials'}
        except Exception as e:
            logger.error(f"Error during login: {e}")
            return {'success': False, 'message': 'Login error'}
    
    @staticmethod
    def logout():
        if 'session_id' in session:
            UserSession.query.filter_by(session_id=session['session_id']).delete()
            db.session.commit()
        
        session.clear()
        return {'success': True, 'message': 'Logged out successfully'}
    
    @staticmethod
    def get_user(user_id):
        return User.query.get(user_id)
    
    @staticmethod
    def get_current_user():
        if 'user_id' in session:
            return User.query.get(session['user_id'])
        return None
    
    @staticmethod
    def request_password_reset(email):
        try:
            user = User.query.filter_by(email=email).first()
            if not user:
                return {'success': False, 'message': 'User not found'}
            
            # Generate reset token
            token = secrets.token_urlsafe(32)
            expires_at = datetime.datetime.utcnow() + datetime.timedelta(hours=24)
            
            # Create or update reset record
            reset_record = PasswordReset.query.filter_by(user_id=user.id, used=False).first()
            if reset_record:
                reset_record.token = token
                reset_record.expires_at = expires_at
            else:
                reset_record = PasswordReset(
                    user_id=user.id,
                    token=token,
                    expires_at=expires_at
                )
                db.session.add(reset_record)
            
            db.session.commit()
            
            # TODO: Send email with reset link
            # For now, just return the token (in production, send via email)
            return {
                'success': True, 
                'message': 'Password reset instructions sent',
                'token': token  # Remove this in production
            }
        except Exception as e:
            logger.error(f"Error requesting password reset: {e}")
            return {'success': False, 'message': 'Error requesting password reset'}
    
    @staticmethod
    def reset_password(token, password):
        try:
            reset_record = PasswordReset.query.filter_by(token=token, used=False).first()
            if not reset_record or reset_record.expires_at < datetime.datetime.utcnow():
                return {'success': False, 'message': 'Invalid or expired token'}
            
            # Update password
            user = User.query.get(reset_record.user_id)
            user.password_hash = generate_password_hash(password)
            reset_record.used = True
            
            db.session.commit()
            
            return {'success': True, 'message': 'Password reset successfully'}
        except Exception as e:
            logger.error(f"Error resetting password: {e}")
            return {'success': False, 'message': 'Error resetting password'}
    
    @staticmethod
    def get_stats():
        try:
            total_users = User.query.count()
            active_users = User.query.filter(
                User.last_login >= datetime.datetime.utcnow() - datetime.timedelta(days=30)
            ).count()
            active_sessions = UserSession.query.filter(
                UserSession.expires_at > datetime.datetime.utcnow()
            ).count()
            failed_attempts_today = LoginAttempt.query.filter(
                LoginAttempt.success == False,
                LoginAttempt.created_at >= datetime.datetime.utcnow().date()
            ).count()
            
            return {
                'total_users': total_users,
                'active_users': active_users,
                'active_sessions': active_sessions,
                'failed_attempts_today': failed_attempts_today
            }
        except Exception as e:
            logger.error(f"Error getting stats: {e}")
            return {
                'total_users': 0,
                'active_users': 0,
                'active_sessions': 0,
                'failed_attempts_today': 0
            }
    
    @staticmethod
    def _log_attempt(email, success):
        try:
            attempt = LoginAttempt(
                email=email,
                ip_address=request.remote_addr,
                user_agent=request.headers.get('User-Agent'),
                success=success
            )
            db.session.add(attempt)
            db.session.commit()
        except Exception as e:
            logger.error(f"Error logging attempt: {e}")

# Routes
@app.route('/')
def home():
    """Home page"""
    return render_template('home.html')

@app.route('/auth', methods=['GET', 'POST'])
def auth():
    """Authentication page"""
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'login':
            email = request.form.get('email')
            password = request.form.get('password')
            remember = 'remember' in request.form
            
            result = PakHerd.login(email, password, remember)
            if result['success']:
                return redirect(url_for('dashboard'))
            else:
                flash(result['message'], 'error')
        
        elif action == 'register':
            email = request.form.get('email')
            password = request.form.get('password')
            name = request.form.get('name')
            
            result = PakHerd.create_user({
                'email': email,
                'password': password,
                'name': name
            })
            
            if result['success']:
                flash('Account created successfully! You can now log in.', 'success')
            else:
                flash(result['message'], 'error')
        
        elif action == 'forgot_password':
            email = request.form.get('email')
            result = PakHerd.request_password_reset(email)
            flash(result['message'], 'success' if result['success'] else 'error')
        
        elif action == 'reset_password':
            token = request.form.get('token')
            password = request.form.get('password')
            result = PakHerd.reset_password(token, password)
            flash(result['message'], 'success' if result['success'] else 'error')
    
    # Check for password reset token
    reset_token = request.args.get('token')
    return render_template('auth.html', reset_token=reset_token)

@app.route('/logout')
def logout():
    """Logout user"""
    PakHerd.logout()
    return redirect(url_for('home'))

@app.route('/dashboard')
@login_required
def dashboard():
    """Dashboard page"""
    user = PakHerd.get_current_user()
    
    # Get PAK.sh system status
    pak_status = PakManager.get_pak_status()
    
    # Mock stats for now - in production, get from database
    stats = {
        'total_packages': 42,
        'active_installs': 15,
        'success_rate': 98,
        'uptime': 99.9
    }
    recent_activity = [
        {'action': 'Package Install', 'timestamp': '2024-01-15 14:30', 'description': 'nginx installed successfully'},
        {'action': 'System Update', 'timestamp': '2024-01-15 13:45', 'description': 'System packages updated'},
        {'action': 'Telemetry', 'timestamp': '2024-01-15 12:20', 'description': 'Telemetry data collected'}
    ]
    
    return render_template('dashboard.html', user=user, stats=stats, recent_activity=recent_activity, pak_status=pak_status)

@app.route('/projects')
@login_required
def projects():
    """Projects management page"""
    projects_list = PakManager.list_projects()
    return render_template('projects.html', projects=projects_list)

@app.route('/projects/<project_name>')
@login_required
def project_detail(project_name):
    """Project detail page"""
    config = PakManager.get_project_config(project_name)
    return render_template('project_detail.html', project_name=project_name, config=config)

@app.route('/deploy/<project_name>', methods=['POST'])
@login_required
def deploy_project_route(project_name):
    """Deploy a project"""
    environment = request.form.get('environment', 'production')
    
    result = PakManager.deploy_project(project_name, environment)
    
    if result['success']:
        flash(f'Project {project_name} deployed successfully!', 'success')
    else:
        flash(f'Deployment failed: {result.get("error", "Unknown error")}', 'error')
    
    return redirect(url_for('project_detail', project_name=project_name))

@app.route('/package/<project_name>', methods=['POST'])
@login_required
def package_project_route(project_name):
    """Package a project"""
    version = request.form.get('version')
    
    result = PakManager.package_project(project_name, version)
    
    if result['success']:
        flash(f'Project {project_name} packaged successfully!', 'success')
    else:
        flash(f'Packaging failed: {result.get("error", "Unknown error")}', 'error')
    
    return redirect(url_for('project_detail', project_name=project_name))

@app.route('/credentials/<project_name>', methods=['GET', 'POST'])
@login_required
def project_credentials(project_name):
    """Manage project credentials"""
    if request.method == 'POST':
        credentials_data = {}
        
        # Parse form data into credentials structure
        for key, value in request.form.items():
            if key.startswith('cred_') and value:
                cred_key = key[5:]  # Remove 'cred_' prefix
                credentials_data[cred_key] = value
        
        result = PakManager.setup_credentials(project_name, credentials_data)
        
        if result['success']:
            flash('Credentials saved successfully!', 'success')
        else:
            flash(f'Error saving credentials: {result.get("error", "Unknown error")}', 'error')
        
        return redirect(url_for('project_credentials', project_name=project_name))
    
    # Load existing credentials
    credentials_file = os.path.join(PAK_ROOT, project_name, 'credentials.yaml')
    existing_credentials = {}
    
    if os.path.exists(credentials_file):
        try:
            with open(credentials_file, 'r') as f:
                existing_credentials = yaml.safe_load(f) or {}
        except Exception as e:
            logger.error(f"Error reading credentials: {e}")
    
    return render_template('credentials.html', project_name=project_name, credentials=existing_credentials)

@app.route('/telemetry')
@login_required
def telemetry():
    """Telemetry dashboard"""
    # Mock telemetry data for now - in production, get from database
    telemetry_data = {
        'total_packages': 156,
        'active_installs': 23,
        'success_rate': 97.5,
        'uptime': 99.8,
        'recent_activity': [
            {'type': 'Package Install', 'timestamp': '2024-01-15 15:30', 'description': 'docker-ce installed on server-01'},
            {'type': 'System Update', 'timestamp': '2024-01-15 15:15', 'description': 'Security updates applied'},
            {'type': 'Telemetry', 'timestamp': '2024-01-15 15:00', 'description': 'Performance metrics collected'},
            {'type': 'Error', 'timestamp': '2024-01-15 14:45', 'description': 'Package conflict resolved automatically'}
        ]
    }
    return render_template('telemetry.html', data=telemetry_data)

@app.route('/commands')
@login_required
def commands():
    """Commands page"""
    return render_template('commands.html')

@app.route('/admin/users')
@admin_required
def admin_users():
    """Admin user management"""
    if request.method == 'POST':
        action = request.form.get('action')
        admin_password = request.form.get('admin_password')
        
        # Simple admin password check (enhance in production)
        if admin_password != 'pak-admin-2025':
            flash('Invalid admin password', 'error')
        else:
            if action == 'create_admin':
                result = PakHerd.create_user({
                    'email': request.form.get('email'),
                    'password': request.form.get('password'),
                    'name': request.form.get('name'),
                    'role': 'admin'
                })
                flash(result['message'], 'success' if result['success'] else 'error')
            
            elif action == 'create_user':
                result = PakHerd.create_user({
                    'email': request.form.get('email'),
                    'password': request.form.get('password'),
                    'name': request.form.get('name'),
                    'role': 'user'
                })
                flash(result['message'], 'success' if result['success'] else 'error')
    
    stats = PakHerd.get_stats()
    return render_template('admin_users.html', stats=stats)

@app.route('/api/telemetry', methods=['POST'])
def api_telemetry():
    """Telemetry API endpoint"""
    # TODO: Implement telemetry data collection
    api_key = request.headers.get('X-API-Key')
    if api_key != 'YOUR_API_KEY_HERE':
        return jsonify({'error': 'Invalid API key'}), 401
    
    data = request.get_json()
    # Process telemetry data
    return jsonify({'success': True})

@app.route('/webhook/telemetry', methods=['POST'])
def webhook_telemetry():
    """Telemetry webhook endpoint"""
    api_key = request.headers.get('X-API-Key')
    if api_key != 'YOUR_API_KEY_HERE':
        return jsonify({'error': 'Invalid API key'}), 401
    
    data = request.get_json()
    # Process webhook data
    return jsonify({'success': True})

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return render_template('500.html'), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000) 