#!/usr/bin/env python3
"""
PAK.sh Dashboard Blueprint
Main web interface for PAK.sh
"""

from flask import Blueprint, render_template, request, jsonify, current_app
from flask_login import login_required, current_user
from app_factory import db, cache
from models import PakProject, PakDeployment, User
from services.analytics_service import AnalyticsService
from services.pak_service import PakService

dashboard_bp = Blueprint('dashboard', __name__)

@dashboard_bp.route('/')
@login_required
def index():
    """Main dashboard page"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        # Admin gets system-wide analytics
        analytics = analytics_service.get_system_analytics()
    else:
        # Regular users get their own analytics
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    # Get recent projects
    if current_user.is_admin():
        recent_projects = PakProject.query.order_by(
            PakProject.created_at.desc()
        ).limit(5).all()
    else:
        recent_projects = PakProject.query.filter_by(
            created_by=current_user.id
        ).order_by(PakProject.created_at.desc()).limit(5).all()
    
    # Get recent deployments
    if current_user.is_admin():
        recent_deployments = PakDeployment.query.order_by(
            PakDeployment.created_at.desc()
        ).limit(10).all()
    else:
        recent_deployments = PakDeployment.query.filter_by(
            user_id=current_user.id
        ).order_by(PakDeployment.created_at.desc()).limit(10).all()
    
    return render_template('dashboard/index.html',
                         analytics=analytics,
                         recent_projects=recent_projects,
                         recent_deployments=recent_deployments)

@dashboard_bp.route('/projects')
@login_required
def projects():
    """Projects list page"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    if current_user.is_admin():
        projects = PakProject.query.paginate(
            page=page, per_page=per_page, error_out=False
        )
    else:
        projects = PakProject.query.filter_by(
            created_by=current_user.id
        ).paginate(page=page, per_page=per_page, error_out=False)
    
    return render_template('dashboard/projects.html', projects=projects)

@dashboard_bp.route('/projects/<int:project_id>')
@login_required
def project_detail(project_id):
    """Project detail page"""
    if current_user.is_admin():
        project = PakProject.query.get_or_404(project_id)
    else:
        project = PakProject.query.filter_by(
            id=project_id,
            created_by=current_user.id
        ).first_or_404()
    
    # Get project analytics
    analytics_service = AnalyticsService()
    analytics = analytics_service.get_project_analytics(project_id)
    
    # Get recent deployments
    recent_deployments = PakDeployment.query.filter_by(
        project_id=project_id
    ).order_by(PakDeployment.created_at.desc()).limit(10).all()
    
    return render_template('dashboard/project_detail.html',
                         project=project,
                         analytics=analytics,
                         recent_deployments=recent_deployments)

@dashboard_bp.route('/deployments')
@login_required
def deployments():
    """Deployments list page"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    # Get filter parameters
    project_id = request.args.get('project_id', type=int)
    environment = request.args.get('environment')
    status = request.args.get('status')
    
    query = PakDeployment.query
    
    if not current_user.is_admin():
        query = query.filter_by(user_id=current_user.id)
    
    if project_id:
        query = query.filter_by(project_id=project_id)
    if environment:
        query = query.filter_by(environment=environment)
    if status:
        query = query.filter_by(status=status)
    
    deployments = query.order_by(
        PakDeployment.created_at.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)
    
    # Get projects for filter dropdown
    if current_user.is_admin():
        projects = PakProject.query.all()
    else:
        projects = PakProject.query.filter_by(created_by=current_user.id).all()
    
    return render_template('dashboard/deployments.html',
                         deployments=deployments,
                         projects=projects)

@dashboard_bp.route('/deployments/<int:deployment_id>')
@login_required
def deployment_detail(deployment_id):
    """Deployment detail page"""
    if current_user.is_admin():
        deployment = PakDeployment.query.get_or_404(deployment_id)
    else:
        deployment = PakDeployment.query.filter_by(
            id=deployment_id,
            user_id=current_user.id
        ).first_or_404()
    
    # Get deployment analytics
    analytics_service = AnalyticsService()
    analytics = analytics_service.get_deployment_analytics(deployment_id)
    
    return render_template('dashboard/deployment_detail.html',
                         deployment=deployment,
                         analytics=analytics)

@dashboard_bp.route('/analytics')
@login_required
def analytics():
    """Analytics page"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics_data = analytics_service.get_system_analytics()
    else:
        analytics_data = analytics_service.get_user_analytics(current_user.id)
    
    return render_template('dashboard/analytics.html', analytics=analytics_data)

@dashboard_bp.route('/webhooks')
@login_required
def webhooks():
    """Webhooks management page"""
    from models import Webhook
    
    webhooks = Webhook.query.filter_by(user_id=current_user.id).all()
    
    return render_template('dashboard/webhooks.html', webhooks=webhooks)

@dashboard_bp.route('/settings')
@login_required
def settings():
    """User settings page"""
    return render_template('dashboard/settings.html')

@dashboard_bp.route('/api/status')
@login_required
def api_status():
    """API status endpoint for real-time updates"""
    pak_service = PakService()
    status = pak_service.get_status()
    
    return jsonify({
        'status': 'success',
        'data': status
    })

@dashboard_bp.route('/api/projects')
@login_required
@cache.cached(timeout=60)
def api_projects():
    """API endpoint for projects data"""
    if current_user.is_admin():
        projects = PakProject.query.all()
    else:
        projects = PakProject.query.filter_by(created_by=current_user.id).all()
    
    return jsonify({
        'status': 'success',
        'data': [{
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
            'created_at': p.created_at.isoformat(),
            'last_deployment': p.last_deployment.isoformat() if p.last_deployment else None
        } for p in projects]
    })

@dashboard_bp.route('/api/deployments')
@login_required
def api_deployments():
    """API endpoint for deployments data"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    query = PakDeployment.query
    
    if not current_user.is_admin():
        query = query.filter_by(user_id=current_user.id)
    
    deployments = query.order_by(
        PakDeployment.created_at.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'status': 'success',
        'data': [{
            'id': d.id,
            'project_name': d.project.name if d.project else 'Unknown',
            'environment': d.environment,
            'status': d.status,
            'version': d.version,
            'started_at': d.started_at.isoformat() if d.started_at else None,
            'completed_at': d.completed_at.isoformat() if d.completed_at else None,
            'duration': d.duration,
            'created_at': d.created_at.isoformat()
        } for d in deployments.items],
        'pagination': {
            'page': deployments.page,
            'pages': deployments.pages,
            'per_page': deployments.per_page,
            'total': deployments.total,
            'has_next': deployments.has_next,
            'has_prev': deployments.has_prev
        }
    })

@dashboard_bp.route('/api/analytics')
@login_required
@cache.cached(timeout=300)
def api_analytics():
    """API endpoint for analytics data"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics_data = analytics_service.get_system_analytics()
    else:
        analytics_data = analytics_service.get_user_analytics(current_user.id)
    
    return jsonify({
        'status': 'success',
        'data': analytics_data
    }) 