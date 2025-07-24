#!/usr/bin/env python3
"""
PAK.sh Admin Blueprint
Administrative functions and system management
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
from app_factory import db
from models import User, PakProject, PakDeployment, ApiUsage, Webhook
from services.analytics_service import AnalyticsService
from services.pak_service import PakService
from functools import wraps

admin_bp = Blueprint('admin', __name__)

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not current_user.is_admin():
            flash('Admin access required', 'error')
            return redirect(url_for('dashboard.index'))
        return f(*args, **kwargs)
    return decorated_function

@admin_bp.route('/')
@login_required
@admin_required
def index():
    """Admin dashboard"""
    analytics_service = AnalyticsService()
    analytics = analytics_service.get_system_analytics()
    
    # Get system health metrics
    pak_service = PakService()
    system_metrics = pak_service.get_system_metrics()
    
    return render_template('admin/index.html',
                         analytics=analytics,
                         system_metrics=system_metrics)

@admin_bp.route('/users')
@login_required
@admin_required
def users():
    """User management"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    users = User.query.paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('admin/users.html', users=users)

@admin_bp.route('/users/<int:user_id>')
@login_required
@admin_required
def user_detail(user_id):
    """User detail page"""
    user = User.query.get_or_404(user_id)
    
    # Get user statistics
    user_projects = PakProject.query.filter_by(created_by=user_id).count()
    user_deployments = PakDeployment.query.filter_by(user_id=user_id).count()
    user_api_usage = ApiUsage.query.filter_by(user_id=user_id).count()
    
    return render_template('admin/user_detail.html',
                         user=user,
                         stats={
                             'projects': user_projects,
                             'deployments': user_deployments,
                             'api_usage': user_api_usage
                         })

@admin_bp.route('/users/<int:user_id>/toggle-status', methods=['POST'])
@login_required
@admin_required
def toggle_user_status(user_id):
    """Toggle user active status"""
    user = User.query.get_or_404(user_id)
    
    if user.id == current_user.id:
        flash('Cannot modify your own account status', 'error')
        return redirect(url_for('admin.user_detail', user_id=user_id))
    
    user.is_active = not user.is_active
    db.session.commit()
    
    status = 'activated' if user.is_active else 'deactivated'
    flash(f'User {user.email} has been {status}', 'success')
    
    return redirect(url_for('admin.user_detail', user_id=user_id))

@admin_bp.route('/users/<int:user_id>/change-role', methods=['POST'])
@login_required
@admin_required
def change_user_role(user_id):
    """Change user role"""
    user = User.query.get_or_404(user_id)
    new_role = request.form.get('role')
    
    if user.id == current_user.id:
        flash('Cannot modify your own role', 'error')
        return redirect(url_for('admin.user_detail', user_id=user_id))
    
    if new_role in ['user', 'admin']:
        user.role = new_role
        db.session.commit()
        flash(f'User {user.email} role changed to {new_role}', 'success')
    else:
        flash('Invalid role', 'error')
    
    return redirect(url_for('admin.user_detail', user_id=user_id))

@admin_bp.route('/system')
@login_required
@admin_required
def system():
    """System monitoring"""
    pak_service = PakService()
    system_metrics = pak_service.get_system_metrics()
    
    # Get system status
    pak_status = pak_service.get_status()
    
    return render_template('admin/system.html',
                         system_metrics=system_metrics,
                         pak_status=pak_status)

@admin_bp.route('/api-usage')
@login_required
@admin_required
def api_usage():
    """API usage monitoring"""
    page = request.args.get('page', 1, type=int)
    per_page = 50
    
    # Get API usage statistics
    from sqlalchemy import func
    usage_stats = db.session.query(
        ApiUsage.endpoint,
        func.count(ApiUsage.id).label('count'),
        func.avg(ApiUsage.duration).label('avg_duration'),
        func.max(ApiUsage.created_at).label('last_used')
    ).group_by(ApiUsage.endpoint).order_by(
        func.count(ApiUsage.id).desc()
    ).all()
    
    # Get recent API calls
    recent_calls = ApiUsage.query.order_by(
        ApiUsage.created_at.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)
    
    return render_template('admin/api_usage.html',
                         usage_stats=usage_stats,
                         recent_calls=recent_calls)

@admin_bp.route('/webhooks')
@login_required
@admin_required
def webhooks():
    """Webhook management"""
    from models import Webhook, WebhookDelivery
    
    webhooks = Webhook.query.all()
    
    # Get webhook statistics
    webhook_stats = []
    for webhook in webhooks:
        deliveries = WebhookDelivery.query.filter_by(webhook_id=webhook.id).all()
        successful = len([d for d in deliveries if d.status_code and 200 <= d.status_code < 300])
        total = len(deliveries)
        success_rate = (successful / total * 100) if total > 0 else 0
        
        webhook_stats.append({
            'webhook': webhook,
            'total_deliveries': total,
            'successful_deliveries': successful,
            'success_rate': round(success_rate, 2)
        })
    
    return render_template('admin/webhooks.html', webhook_stats=webhook_stats)

@admin_bp.route('/logs')
@login_required
@admin_required
def logs():
    """System logs viewer"""
    log_type = request.args.get('type', 'application')
    lines = request.args.get('lines', 100, type=int)
    
    pak_service = PakService()
    
    if log_type == 'system':
        # System logs (would need to be implemented)
        log_content = "System logs not yet implemented"
    else:
        # Application logs
        log_content = "Application logs not yet implemented"
    
    return render_template('admin/logs.html',
                         log_content=log_content,
                         log_type=log_type,
                         lines=lines)

@admin_bp.route('/settings')
@login_required
@admin_required
def settings():
    """System settings"""
    return render_template('admin/settings.html')

@admin_bp.route('/api/system-metrics')
@login_required
@admin_required
def api_system_metrics():
    """API endpoint for system metrics"""
    pak_service = PakService()
    metrics = pak_service.get_system_metrics()
    
    return jsonify({
        'status': 'success',
        'data': metrics
    })

@admin_bp.route('/api/user-stats')
@login_required
@admin_required
def api_user_stats():
    """API endpoint for user statistics"""
    total_users = User.query.count()
    active_users = User.query.filter_by(is_active=True).count()
    admin_users = User.query.filter_by(role='admin').count()
    
    # Get recent registrations
    from sqlalchemy import desc
    recent_users = User.query.order_by(
        desc(User.created_at)
    ).limit(10).all()
    
    return jsonify({
        'status': 'success',
        'data': {
            'total_users': total_users,
            'active_users': active_users,
            'admin_users': admin_users,
            'recent_users': [{
                'id': u.id,
                'email': u.email,
                'name': u.name,
                'role': u.role,
                'is_active': u.is_active,
                'created_at': u.created_at.isoformat()
            } for u in recent_users]
        }
    })

@admin_bp.route('/api/deployment-stats')
@login_required
@admin_required
def api_deployment_stats():
    """API endpoint for deployment statistics"""
    total_deployments = PakDeployment.query.count()
    successful_deployments = PakDeployment.query.filter_by(status='success').count()
    failed_deployments = PakDeployment.query.filter_by(status='failed').count()
    running_deployments = PakDeployment.query.filter_by(status='running').count()
    
    success_rate = (successful_deployments / total_deployments * 100) if total_deployments > 0 else 0
    
    # Get recent deployments
    from sqlalchemy import desc
    recent_deployments = PakDeployment.query.order_by(
        desc(PakDeployment.created_at)
    ).limit(10).all()
    
    return jsonify({
        'status': 'success',
        'data': {
            'total_deployments': total_deployments,
            'successful_deployments': successful_deployments,
            'failed_deployments': failed_deployments,
            'running_deployments': running_deployments,
            'success_rate': round(success_rate, 2),
            'recent_deployments': [{
                'id': d.id,
                'project_name': d.project.name if d.project else 'Unknown',
                'environment': d.environment,
                'status': d.status,
                'created_at': d.created_at.isoformat()
            } for d in recent_deployments]
        }
    }) 