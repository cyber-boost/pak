#!/usr/bin/env python3
"""
PAK.sh Analytics Blueprint
Analytics and metrics endpoints
"""

from flask import Blueprint, request, jsonify
from flask_login import login_required, current_user
from app_factory import cache
from services.analytics_service import AnalyticsService

analytics_bp = Blueprint('analytics', __name__)

@analytics_bp.route('/metrics/<metric_name>')
@login_required
@cache.cached(timeout=300)
def get_metrics(metric_name):
    """Get metrics for a specific metric name"""
    days = request.args.get('days', 30, type=int)
    project_id = request.args.get('project_id', type=int)
    
    analytics_service = AnalyticsService()
    metrics = analytics_service.get_metrics(metric_name, days, project_id)
    
    return jsonify({
        'status': 'success',
        'data': {
            'metric_name': metric_name,
            'days': days,
            'project_id': project_id,
            'metrics': metrics
        }
    })

@analytics_bp.route('/deployment-trends')
@login_required
@cache.cached(timeout=300)
def deployment_trends():
    """Get deployment trends over time"""
    days = request.args.get('days', 30, type=int)
    project_id = request.args.get('project_id', type=int)
    
    analytics_service = AnalyticsService()
    
    if project_id:
        analytics = analytics_service.get_project_analytics(project_id)
        trends = analytics.get('monthly_trends', [])
    else:
        if current_user.is_admin():
            analytics = analytics_service.get_system_analytics()
        else:
            analytics = analytics_service.get_user_analytics(current_user.id)
        trends = analytics.get('deployment_trends', [])
    
    return jsonify({
        'status': 'success',
        'data': trends
    })

@analytics_bp.route('/platform-distribution')
@login_required
@cache.cached(timeout=300)
def platform_distribution():
    """Get platform distribution statistics"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics = analytics_service.get_system_analytics()
    else:
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    platforms = analytics.get('platforms', [])
    
    return jsonify({
        'status': 'success',
        'data': platforms
    })

@analytics_bp.route('/language-distribution')
@login_required
@cache.cached(timeout=300)
def language_distribution():
    """Get language distribution statistics"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics = analytics_service.get_system_analytics()
    else:
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    languages = analytics.get('languages', [])
    
    return jsonify({
        'status': 'success',
        'data': languages
    })

@analytics_bp.route('/api-usage-stats')
@login_required
@cache.cached(timeout=300)
def api_usage_stats():
    """Get API usage statistics"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics = analytics_service.get_system_analytics()
    else:
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    api_usage = analytics.get('api_usage', [])
    
    return jsonify({
        'status': 'success',
        'data': api_usage
    })

@analytics_bp.route('/webhook-analytics')
@login_required
@cache.cached(timeout=300)
def webhook_analytics():
    """Get webhook analytics"""
    analytics_service = AnalyticsService()
    analytics = analytics_service.get_webhook_analytics()
    
    return jsonify({
        'status': 'success',
        'data': analytics
    })

@analytics_bp.route('/performance-metrics')
@login_required
def performance_metrics():
    """Get performance metrics"""
    project_id = request.args.get('project_id', type=int)
    
    analytics_service = AnalyticsService()
    
    if project_id:
        analytics = analytics_service.get_project_analytics(project_id)
        performance = analytics.get('performance', {})
    else:
        # Get overall performance metrics
        performance = {
            'avg_deployment_duration': 0,
            'min_deployment_duration': 0,
            'max_deployment_duration': 0
        }
    
    return jsonify({
        'status': 'success',
        'data': performance
    })

@analytics_bp.route('/recent-activity')
@login_required
def recent_activity():
    """Get recent activity"""
    limit = request.args.get('limit', 10, type=int)
    
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics = analytics_service.get_system_analytics()
    else:
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    recent_activity = analytics.get('recent_activity', [])
    
    # Limit the results
    if limit and len(recent_activity) > limit:
        recent_activity = recent_activity[:limit]
    
    return jsonify({
        'status': 'success',
        'data': recent_activity
    })

@analytics_bp.route('/summary')
@login_required
@cache.cached(timeout=300)
def analytics_summary():
    """Get analytics summary"""
    analytics_service = AnalyticsService()
    
    if current_user.is_admin():
        analytics = analytics_service.get_system_analytics()
    else:
        analytics = analytics_service.get_user_analytics(current_user.id)
    
    summary = {
        'overview': analytics.get('overview', {}),
        'deployments': analytics.get('deployments', {}),
        'platforms': analytics.get('platforms', []),
        'languages': analytics.get('languages', []),
        'api_usage': analytics.get('api_usage', [])
    }
    
    return jsonify({
        'status': 'success',
        'data': summary
    }) 