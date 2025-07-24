#!/usr/bin/env python3
"""
PAK.sh Web API REST Endpoints
Comprehensive REST API for all PAK operations
"""

import datetime
import json
from flask import Blueprint, request, jsonify, current_app
from flask_restx import Api, Resource, fields, Namespace
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token, create_refresh_token
from flask_limiter.util import get_remote_address
from marshmallow import Schema, fields as ma_fields, ValidationError
from app_factory import db, cache, limiter
from models import User, PakProject, PakDeployment, Webhook, Analytics, ApiUsage
from services.pak_service import PakService
from services.analytics_service import AnalyticsService
from services.webhook_service import WebhookService

# Create API blueprint
api_bp = Blueprint('api', __name__)

# Create Flask-RESTX API
api = Api(api_bp,
    title='PAK.sh Web API',
    version='1.0',
    description='Package Automation Kit Web API',
    doc='/docs',
    authorizations={
        'apikey': {
            'type': 'apiKey',
            'in': 'header',
            'name': 'X-API-Key'
        },
        'jwt': {
            'type': 'apiKey',
            'in': 'header',
            'name': 'Authorization',
            'description': 'JWT token in format: Bearer <token>'
        }
    },
    security=['jwt', 'apikey']
)

# Create namespaces
auth_ns = Namespace('auth', description='Authentication operations')
packages_ns = Namespace('packages', description='Package management operations')
deployments_ns = Namespace('deployments', description='Deployment operations')
platforms_ns = Namespace('platforms', description='Platform configuration')
analytics_ns = Namespace('analytics', description='Analytics and metrics')
security_ns = Namespace('security', description='Security scanning')
webhooks_ns = Namespace('webhooks', description='Webhook management')
users_ns = Namespace('users', description='User management')

# Add namespaces to API
api.add_namespace(auth_ns)
api.add_namespace(packages_ns)
api.add_namespace(deployments_ns)
api.add_namespace(platforms_ns)
api.add_namespace(analytics_ns)
api.add_namespace(security_ns)
api.add_namespace(webhooks_ns)
api.add_namespace(users_ns)

# Define models for API documentation
user_model = api.model('User', {
    'id': fields.Integer(readonly=True),
    'email': fields.String(required=True, description='User email'),
    'name': fields.String(required=True, description='User name'),
    'role': fields.String(description='User role'),
    'is_active': fields.Boolean(description='User active status'),
    'created_at': fields.DateTime(readonly=True),
    'api_key': fields.String(description='API key')
})

project_model = api.model('Project', {
    'id': fields.Integer(readonly=True),
    'name': fields.String(required=True, description='Project name'),
    'description': fields.String(description='Project description'),
    'status': fields.String(description='Project status'),
    'version': fields.String(description='Project version'),
    'platform': fields.String(description='Target platform'),
    'language': fields.String(description='Programming language'),
    'framework': fields.String(description='Framework used'),
    'deployment_count': fields.Integer(description='Number of deployments'),
    'success_rate': fields.Float(description='Deployment success rate'),
    'created_at': fields.DateTime(readonly=True),
    'last_deployment': fields.DateTime(description='Last deployment date')
})

deployment_model = api.model('Deployment', {
    'id': fields.Integer(readonly=True),
    'project_id': fields.Integer(required=True, description='Project ID'),
    'environment': fields.String(required=True, description='Deployment environment'),
    'status': fields.String(description='Deployment status'),
    'version': fields.String(description='Deployed version'),
    'started_at': fields.DateTime(description='Deployment start time'),
    'completed_at': fields.DateTime(description='Deployment completion time'),
    'duration': fields.Integer(description='Deployment duration in seconds'),
    'error_message': fields.String(description='Error message if failed'),
    'created_at': fields.DateTime(readonly=True)
})

webhook_model = api.model('Webhook', {
    'id': fields.Integer(readonly=True),
    'name': fields.String(required=True, description='Webhook name'),
    'url': fields.String(required=True, description='Webhook URL'),
    'events': fields.List(fields.String, description='Events to trigger on'),
    'is_active': fields.Boolean(description='Webhook active status'),
    'success_count': fields.Integer(description='Successful deliveries'),
    'failure_count': fields.Integer(description='Failed deliveries'),
    'created_at': fields.DateTime(readonly=True)
})

# Authentication endpoints
@auth_ns.route('/login')
class AuthLogin(Resource):
    @auth_ns.expect(api.model('LoginRequest', {
        'email': fields.String(required=True, description='User email'),
        'password': fields.String(required=True, description='User password')
    }))
    @auth_ns.response(200, 'Login successful', api.model('LoginResponse', {
        'access_token': fields.String(description='JWT access token'),
        'refresh_token': fields.String(description='JWT refresh token'),
        'user': fields.Nested(user_model)
    }))
    @auth_ns.response(401, 'Invalid credentials')
    def post(self):
        """User login"""
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return {'error': 'Email and password required'}, 400
        
        user = User.query.filter_by(email=email).first()
        
        if not user or not user.check_password(password):
            # Record failed login attempt
            if user:
                user.record_failed_login()
                db.session.commit()
            
            # Log login attempt
            from models import LoginAttempt
            attempt = LoginAttempt(
                email=email,
                ip_address=request.remote_addr,
                user_agent=request.headers.get('User-Agent'),
                success=False,
                failure_reason='Invalid credentials'
            )
            db.session.add(attempt)
            db.session.commit()
            
            return {'error': 'Invalid credentials'}, 401
        
        if user.is_locked():
            return {'error': 'Account is locked'}, 423
        
        if not user.is_active:
            return {'error': 'Account is disabled'}, 403
        
        # Reset failed attempts on successful login
        user.reset_failed_attempts()
        user.last_login = datetime.datetime.utcnow()
        db.session.commit()
        
        # Log successful login
        from models import LoginAttempt
        attempt = LoginAttempt(
            email=email,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent'),
            success=True
        )
        db.session.add(attempt)
        db.session.commit()
        
        # Generate tokens
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)
        
        return {
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': {
                'id': user.id,
                'email': user.email,
                'name': user.name,
                'role': user.role,
                'is_active': user.is_active
            }
        }

@auth_ns.route('/refresh')
class AuthRefresh(Resource):
    @jwt_required(refresh=True)
    @auth_ns.response(200, 'Token refreshed', api.model('RefreshResponse', {
        'access_token': fields.String(description='New JWT access token')
    }))
    def post(self):
        """Refresh access token"""
        current_user_id = get_jwt_identity()
        new_token = create_access_token(identity=current_user_id)
        return {'access_token': new_token}

@auth_ns.route('/register')
class AuthRegister(Resource):
    @auth_ns.expect(api.model('RegisterRequest', {
        'email': fields.String(required=True, description='User email'),
        'password': fields.String(required=True, description='User password'),
        'name': fields.String(required=True, description='User name')
    }))
    @auth_ns.response(201, 'User created successfully', user_model)
    @auth_ns.response(400, 'Validation error')
    def post(self):
        """User registration"""
        data = request.get_json()
        
        # Validate required fields
        if not all(k in data for k in ['email', 'password', 'name']):
            return {'error': 'Email, password, and name are required'}, 400
        
        # Check if user already exists
        if User.query.filter_by(email=data['email']).first():
            return {'error': 'User with this email already exists'}, 400
        
        # Create user
        user = User(
            email=data['email'],
            name=data['name']
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()
        
        return {
            'id': user.id,
            'email': user.email,
            'name': user.name,
            'role': user.role,
            'is_active': user.is_active,
            'created_at': user.created_at
        }, 201

# Package management endpoints
@packages_ns.route('/')
class PackageList(Resource):
    @jwt_required()
    @packages_ns.doc('list_packages')
    @packages_ns.marshal_list_with(project_model)
    @limiter.limit("100 per minute")
    def get(self):
        """List all packages/projects"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        # Get projects based on user role
        if user.is_admin():
            projects = PakProject.query.all()
        else:
            projects = PakProject.query.filter_by(created_by=current_user_id).all()
        
        return [{
            'id': p.id,
            'name': p.name,
            'description': p.description,
            'status': p.status,
            'version': p.version,
            'platform': p.platform,
            'language': p.language,
            'framework': p.framework,
            'deployment_count': p.deployment_count,
            'success_rate': p.success_rate,
            'created_at': p.created_at,
            'last_deployment': p.last_deployment
        } for p in projects]

    @jwt_required()
    @packages_ns.expect(project_model)
    @packages_ns.marshal_with(project_model, code=201)
    def post(self):
        """Create a new package/project"""
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        # Validate required fields
        if not data.get('name'):
            return {'error': 'Project name is required'}, 400
        
        # Check if project already exists
        if PakProject.query.filter_by(name=data['name']).first():
            return {'error': 'Project with this name already exists'}, 400
        
        # Create project
        project = PakProject(
            name=data['name'],
            description=data.get('description'),
            version=data.get('version'),
            platform=data.get('platform'),
            language=data.get('language'),
            framework=data.get('framework'),
            config_data=data.get('config_data'),
            environment_vars=data.get('environment_vars'),
            dependencies=data.get('dependencies'),
            created_by=current_user_id
        )
        
        db.session.add(project)
        db.session.commit()
        
        return {
            'id': project.id,
            'name': project.name,
            'description': project.description,
            'status': project.status,
            'version': project.version,
            'platform': project.platform,
            'language': project.language,
            'framework': project.framework,
            'deployment_count': project.deployment_count,
            'success_rate': project.success_rate,
            'created_at': project.created_at,
            'last_deployment': project.last_deployment
        }, 201

@packages_ns.route('/<int:project_id>')
@packages_ns.param('project_id', 'The project identifier')
class PackageDetail(Resource):
    @jwt_required()
    @packages_ns.doc('get_package')
    @packages_ns.marshal_with(project_model)
    def get(self, project_id):
        """Get a specific package/project"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        project = PakProject.query.get_or_404(project_id)
        
        # Check permissions
        if not user.is_admin() and project.created_by != current_user_id:
            return {'error': 'Access denied'}, 403
        
        return {
            'id': project.id,
            'name': project.name,
            'description': project.description,
            'status': project.status,
            'version': project.version,
            'platform': project.platform,
            'language': project.language,
            'framework': project.framework,
            'deployment_count': project.deployment_count,
            'success_rate': project.success_rate,
            'created_at': project.created_at,
            'last_deployment': project.last_deployment
        }

    @jwt_required()
    @packages_ns.expect(project_model)
    @packages_ns.marshal_with(project_model)
    def put(self, project_id):
        """Update a package/project"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        project = PakProject.query.get_or_404(project_id)
        
        # Check permissions
        if not user.is_admin() and project.created_by != current_user_id:
            return {'error': 'Access denied'}, 403
        
        data = request.get_json()
        
        # Update fields
        if 'name' in data:
            project.name = data['name']
        if 'description' in data:
            project.description = data['description']
        if 'version' in data:
            project.version = data['version']
        if 'platform' in data:
            project.platform = data['platform']
        if 'language' in data:
            project.language = data['language']
        if 'framework' in data:
            project.framework = data['framework']
        if 'config_data' in data:
            project.config_data = data['config_data']
        if 'environment_vars' in data:
            project.environment_vars = data['environment_vars']
        if 'dependencies' in data:
            project.dependencies = data['dependencies']
        
        db.session.commit()
        
        return {
            'id': project.id,
            'name': project.name,
            'description': project.description,
            'status': project.status,
            'version': project.version,
            'platform': project.platform,
            'language': project.language,
            'framework': project.framework,
            'deployment_count': project.deployment_count,
            'success_rate': project.success_rate,
            'created_at': project.created_at,
            'last_deployment': project.last_deployment
        }

    @jwt_required()
    @packages_ns.response(204, 'Project deleted')
    def delete(self, project_id):
        """Delete a package/project"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        project = PakProject.query.get_or_404(project_id)
        
        # Check permissions
        if not user.is_admin() and project.created_by != current_user_id:
            return {'error': 'Access denied'}, 403
        
        db.session.delete(project)
        db.session.commit()
        
        return '', 204

# Deployment endpoints
@deployments_ns.route('/')
class DeploymentList(Resource):
    @jwt_required()
    @deployments_ns.doc('list_deployments')
    @deployments_ns.marshal_list_with(deployment_model)
    @limiter.limit("100 per minute")
    def get(self):
        """List all deployments"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        # Get query parameters
        project_id = request.args.get('project_id', type=int)
        environment = request.args.get('environment')
        status = request.args.get('status')
        limit = min(request.args.get('limit', 50, type=int), 100)
        offset = request.args.get('offset', 0, type=int)
        
        # Build query
        query = PakDeployment.query
        
        if not user.is_admin():
            query = query.filter_by(user_id=current_user_id)
        
        if project_id:
            query = query.filter_by(project_id=project_id)
        if environment:
            query = query.filter_by(environment=environment)
        if status:
            query = query.filter_by(status=status)
        
        # Apply pagination
        deployments = query.order_by(PakDeployment.created_at.desc()).offset(offset).limit(limit).all()
        
        return [{
            'id': d.id,
            'project_id': d.project_id,
            'environment': d.environment,
            'status': d.status,
            'version': d.version,
            'started_at': d.started_at,
            'completed_at': d.completed_at,
            'duration': d.duration,
            'error_message': d.error_message,
            'created_at': d.created_at
        } for d in deployments]

@deployments_ns.route('/<int:deployment_id>')
@deployments_ns.param('deployment_id', 'The deployment identifier')
class DeploymentDetail(Resource):
    @jwt_required()
    @deployments_ns.doc('get_deployment')
    @deployments_ns.marshal_with(deployment_model)
    def get(self, deployment_id):
        """Get a specific deployment"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        deployment = PakDeployment.query.get_or_404(deployment_id)
        
        # Check permissions
        if not user.is_admin() and deployment.user_id != current_user_id:
            return {'error': 'Access denied'}, 403
        
        return {
            'id': deployment.id,
            'project_id': deployment.project_id,
            'environment': deployment.environment,
            'status': deployment.status,
            'version': deployment.version,
            'started_at': deployment.started_at,
            'completed_at': deployment.completed_at,
            'duration': deployment.duration,
            'error_message': deployment.error_message,
            'created_at': deployment.created_at
        }

@deployments_ns.route('/<int:deployment_id>/logs')
@deployments_ns.param('deployment_id', 'The deployment identifier')
class DeploymentLogs(Resource):
    @jwt_required()
    @deployments_ns.doc('get_deployment_logs')
    def get(self, deployment_id):
        """Get deployment logs"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        deployment = PakDeployment.query.get_or_404(deployment_id)
        
        # Check permissions
        if not user.is_admin() and deployment.user_id != current_user_id:
            return {'error': 'Access denied'}, 403
        
        return {
            'deployment_id': deployment.id,
            'logs': deployment.logs or '',
            'status': deployment.status
        }

# Analytics endpoints
@analytics_ns.route('/dashboard')
class AnalyticsDashboard(Resource):
    @jwt_required()
    @analytics_ns.doc('get_dashboard_analytics')
    @cache.cached(timeout=300)  # Cache for 5 minutes
    def get(self):
        """Get dashboard analytics"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        analytics_service = AnalyticsService()
        
        if user.is_admin():
            # Admin gets system-wide analytics
            data = analytics_service.get_system_analytics()
        else:
            # Regular users get their own analytics
            data = analytics_service.get_user_analytics(current_user_id)
        
        return data

@analytics_ns.route('/projects/<int:project_id>')
@analytics_ns.param('project_id', 'The project identifier')
class ProjectAnalytics(Resource):
    @jwt_required()
    @analytics_ns.doc('get_project_analytics')
    @cache.cached(timeout=300)
    def get(self, project_id):
        """Get project-specific analytics"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        project = PakProject.query.get_or_404(project_id)
        
        # Check permissions
        if not user.is_admin() and project.created_by != current_user_id:
            return {'error': 'Access denied'}, 403
        
        analytics_service = AnalyticsService()
        data = analytics_service.get_project_analytics(project_id)
        
        return data

# Webhook endpoints
@webhooks_ns.route('/')
class WebhookList(Resource):
    @jwt_required()
    @webhooks_ns.doc('list_webhooks')
    @webhooks_ns.marshal_list_with(webhook_model)
    def get(self):
        """List user's webhooks"""
        current_user_id = get_jwt_identity()
        webhooks = Webhook.query.filter_by(user_id=current_user_id).all()
        
        return [{
            'id': w.id,
            'name': w.name,
            'url': w.url,
            'events': w.events or [],
            'is_active': w.is_active,
            'success_count': w.success_count,
            'failure_count': w.failure_count,
            'created_at': w.created_at
        } for w in webhooks]

    @jwt_required()
    @webhooks_ns.expect(webhook_model)
    @webhooks_ns.marshal_with(webhook_model, code=201)
    def post(self):
        """Create a new webhook"""
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data.get('name') or not data.get('url'):
            return {'error': 'Name and URL are required'}, 400
        
        webhook = Webhook(
            user_id=current_user_id,
            name=data['name'],
            url=data['url'],
            events=data.get('events', []),
            is_active=data.get('is_active', True)
        )
        
        if not webhook.secret:
            webhook.generate_secret()
        
        db.session.add(webhook)
        db.session.commit()
        
        return {
            'id': webhook.id,
            'name': webhook.name,
            'url': webhook.url,
            'events': webhook.events or [],
            'is_active': webhook.is_active,
            'success_count': webhook.success_count,
            'failure_count': webhook.failure_count,
            'created_at': webhook.created_at
        }, 201

# Platform endpoints
@platforms_ns.route('/')
class PlatformList(Resource):
    @jwt_required()
    @platforms_ns.doc('list_platforms')
    def get(self):
        """List available platforms"""
        pak_service = PakService()
        platforms = pak_service.get_available_platforms()
        return {'platforms': platforms}

@platforms_ns.route('/<platform_name>/config')
@platforms_ns.param('platform_name', 'The platform name')
class PlatformConfig(Resource):
    @jwt_required()
    @platforms_ns.doc('get_platform_config')
    def get(self, platform_name):
        """Get platform configuration"""
        pak_service = PakService()
        config = pak_service.get_platform_config(platform_name)
        return {'platform': platform_name, 'config': config}

# Security endpoints
@security_ns.route('/scan/<int:project_id>')
@security_ns.param('project_id', 'The project identifier')
class SecurityScan(Resource):
    @jwt_required()
    @security_ns.doc('run_security_scan')
    def post(self, project_id):
        """Run security scan on project"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        project = PakProject.query.get_or_404(project_id)
        
        # Check permissions
        if not user.is_admin() and project.created_by != current_user_id:
            return {'error': 'Access denied'}, 403
        
        # TODO: Implement security scanning
        return {'message': 'Security scan initiated', 'project_id': project_id}

# User management endpoints
@users_ns.route('/profile')
class UserProfile(Resource):
    @jwt_required()
    @users_ns.doc('get_user_profile')
    @users_ns.marshal_with(user_model)
    def get(self):
        """Get current user profile"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        return {
            'id': user.id,
            'email': user.email,
            'name': user.name,
            'role': user.role,
            'is_active': user.is_active,
            'created_at': user.created_at,
            'api_key': user.api_key
        }

    @jwt_required()
    @users_ns.expect(api.model('ProfileUpdate', {
        'name': fields.String(description='User name'),
        'bio': fields.String(description='User bio'),
        'timezone': fields.String(description='User timezone'),
        'language': fields.String(description='User language')
    }))
    @users_ns.marshal_with(user_model)
    def put(self):
        """Update user profile"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        data = request.get_json()
        
        if 'name' in data:
            user.name = data['name']
        if 'bio' in data:
            user.bio = data['bio']
        if 'timezone' in data:
            user.timezone = data['timezone']
        if 'language' in data:
            user.language = data['language']
        
        db.session.commit()
        
        return {
            'id': user.id,
            'email': user.email,
            'name': user.name,
            'role': user.role,
            'is_active': user.is_active,
            'created_at': user.created_at,
            'api_key': user.api_key
        }

@users_ns.route('/api-key')
class UserApiKey(Resource):
    @jwt_required()
    @users_ns.doc('regenerate_api_key')
    def post(self):
        """Regenerate API key"""
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        user.generate_api_key()
        db.session.commit()
        
        return {'api_key': user.api_key}

# Track API usage
@api_bp.before_request
def track_api_usage():
    """Track API usage for analytics"""
    if request.endpoint and 'api.' in request.endpoint:
        current_user_id = get_jwt_identity()
        if current_user_id:
            usage = ApiUsage(
                user_id=current_user_id,
                endpoint=request.endpoint,
                method=request.method,
                ip_address=request.remote_addr
            )
            db.session.add(usage)
            db.session.commit() 