#!/usr/bin/env python3
"""
PAK.sh Analytics Service
Comprehensive analytics and metrics for the web API
"""

import datetime
from typing import Dict, List, Any, Optional
from sqlalchemy import func, desc, and_
from app_factory import db, cache
from models import User, PakProject, PakDeployment, Analytics, ApiUsage, Webhook
from services.pak_service import PakService

class AnalyticsService:
    """Service for analytics and metrics"""
    
    def __init__(self):
        self.pak_service = PakService()
    
    def get_system_analytics(self) -> Dict[str, Any]:
        """Get system-wide analytics for admin dashboard"""
        
        # Get basic counts
        total_users = User.query.count()
        total_projects = PakProject.query.count()
        total_deployments = PakDeployment.query.count()
        active_projects = PakProject.query.filter_by(status='active').count()
        
        # Get deployment statistics
        successful_deployments = PakDeployment.query.filter_by(status='success').count()
        failed_deployments = PakDeployment.query.filter_by(status='failed').count()
        running_deployments = PakDeployment.query.filter_by(status='running').count()
        
        # Calculate success rate
        total_completed = successful_deployments + failed_deployments
        success_rate = (successful_deployments / total_completed * 100) if total_completed > 0 else 0
        
        # Get recent activity
        recent_deployments = PakDeployment.query.order_by(
            desc(PakDeployment.created_at)
        ).limit(10).all()
        
        # Get platform distribution
        platform_stats = db.session.query(
            PakProject.platform,
            func.count(PakProject.id).label('count')
        ).filter(
            PakProject.platform.isnot(None)
        ).group_by(PakProject.platform).all()
        
        # Get language distribution
        language_stats = db.session.query(
            PakProject.language,
            func.count(PakProject.id).label('count')
        ).filter(
            PakProject.language.isnot(None)
        ).group_by(PakProject.language).all()
        
        # Get deployment trends (last 30 days)
        thirty_days_ago = datetime.datetime.utcnow() - datetime.timedelta(days=30)
        daily_deployments = db.session.query(
            func.date(PakDeployment.created_at).label('date'),
            func.count(PakDeployment.id).label('count')
        ).filter(
            PakDeployment.created_at >= thirty_days_ago
        ).group_by(
            func.date(PakDeployment.created_at)
        ).order_by(
            func.date(PakDeployment.created_at)
        ).all()
        
        # Get API usage statistics
        api_usage_stats = db.session.query(
            ApiUsage.endpoint,
            func.count(ApiUsage.id).label('count'),
            func.avg(ApiUsage.duration).label('avg_duration')
        ).group_by(ApiUsage.endpoint).order_by(
            desc(func.count(ApiUsage.id))
        ).limit(10).all()
        
        # Get system metrics
        system_metrics = self.pak_service.get_system_metrics()
        
        return {
            'overview': {
                'total_users': total_users,
                'total_projects': total_projects,
                'active_projects': active_projects,
                'total_deployments': total_deployments,
                'success_rate': round(success_rate, 2)
            },
            'deployments': {
                'successful': successful_deployments,
                'failed': failed_deployments,
                'running': running_deployments,
                'success_rate': round(success_rate, 2)
            },
            'recent_activity': [{
                'id': d.id,
                'project_name': d.project.name if d.project else 'Unknown',
                'environment': d.environment,
                'status': d.status,
                'created_at': d.created_at.isoformat(),
                'duration': d.duration
            } for d in recent_deployments],
            'platforms': [{
                'platform': p.platform,
                'count': p.count
            } for p in platform_stats],
            'languages': [{
                'language': l.language,
                'count': l.count
            } for l in language_stats],
            'deployment_trends': [{
                'date': str(d.date),
                'count': d.count
            } for d in daily_deployments],
            'api_usage': [{
                'endpoint': u.endpoint,
                'count': u.count,
                'avg_duration': round(u.avg_duration, 3) if u.avg_duration else 0
            } for u in api_usage_stats],
            'system_metrics': system_metrics
        }
    
    def get_user_analytics(self, user_id: int) -> Dict[str, Any]:
        """Get user-specific analytics"""
        
        user = User.query.get(user_id)
        if not user:
            return {'error': 'User not found'}
        
        # Get user's projects
        user_projects = PakProject.query.filter_by(created_by=user_id).all()
        project_ids = [p.id for p in user_projects]
        
        # Get user's deployments
        user_deployments = PakDeployment.query.filter_by(user_id=user_id).all()
        
        # Calculate statistics
        total_deployments = len(user_deployments)
        successful_deployments = len([d for d in user_deployments if d.status == 'success'])
        failed_deployments = len([d for d in user_deployments if d.status == 'failed'])
        running_deployments = len([d for d in user_deployments if d.status == 'running'])
        
        success_rate = (successful_deployments / total_deployments * 100) if total_deployments > 0 else 0
        
        # Get recent deployments
        recent_deployments = PakDeployment.query.filter_by(
            user_id=user_id
        ).order_by(
            desc(PakDeployment.created_at)
        ).limit(5).all()
        
        # Get project statistics
        project_stats = []
        for project in user_projects:
            project_deployments = PakDeployment.query.filter_by(project_id=project.id).all()
            project_success_rate = 0
            if project_deployments:
                successful = len([d for d in project_deployments if d.status == 'success'])
                project_success_rate = (successful / len(project_deployments)) * 100
            
            project_stats.append({
                'id': project.id,
                'name': project.name,
                'deployment_count': len(project_deployments),
                'success_rate': round(project_success_rate, 2),
                'last_deployment': project.last_deployment.isoformat() if project.last_deployment else None
            })
        
        # Get API usage for user
        user_api_usage = ApiUsage.query.filter_by(user_id=user_id).all()
        api_calls_today = len([u for u in user_api_usage 
                             if u.created_at.date() == datetime.datetime.utcnow().date()])
        api_calls_month = len([u for u in user_api_usage 
                             if u.created_at >= datetime.datetime.utcnow() - datetime.timedelta(days=30)])
        
        return {
            'user': {
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'role': user.role,
                'created_at': user.created_at.isoformat()
            },
            'overview': {
                'total_projects': len(user_projects),
                'total_deployments': total_deployments,
                'success_rate': round(success_rate, 2)
            },
            'deployments': {
                'total': total_deployments,
                'successful': successful_deployments,
                'failed': failed_deployments,
                'running': running_deployments,
                'success_rate': round(success_rate, 2)
            },
            'projects': project_stats,
            'recent_deployments': [{
                'id': d.id,
                'project_name': d.project.name if d.project else 'Unknown',
                'environment': d.environment,
                'status': d.status,
                'created_at': d.created_at.isoformat(),
                'duration': d.duration
            } for d in recent_deployments],
            'api_usage': {
                'calls_today': api_calls_today,
                'calls_month': api_calls_month,
                'quota_daily': user.api_quota_daily,
                'quota_monthly': user.api_quota_monthly
            }
        }
    
    def get_project_analytics(self, project_id: int) -> Dict[str, Any]:
        """Get project-specific analytics"""
        
        project = PakProject.query.get(project_id)
        if not project:
            return {'error': 'Project not found'}
        
        # Get all deployments for this project
        deployments = PakDeployment.query.filter_by(project_id=project_id).all()
        
        # Calculate statistics
        total_deployments = len(deployments)
        successful_deployments = len([d for d in deployments if d.status == 'success'])
        failed_deployments = len([d for d in deployments if d.status == 'failed'])
        running_deployments = len([d for d in deployments if d.status == 'running'])
        
        success_rate = (successful_deployments / total_deployments * 100) if total_deployments > 0 else 0
        
        # Get deployment history (last 30 days)
        thirty_days_ago = datetime.datetime.utcnow() - datetime.timedelta(days=30)
        recent_deployments = PakDeployment.query.filter(
            and_(
                PakDeployment.project_id == project_id,
                PakDeployment.created_at >= thirty_days_ago
            )
        ).order_by(desc(PakDeployment.created_at)).all()
        
        # Get environment distribution
        environment_stats = db.session.query(
            PakDeployment.environment,
            func.count(PakDeployment.id).label('count'),
            func.avg(PakDeployment.duration).label('avg_duration')
        ).filter(
            PakDeployment.project_id == project_id
        ).group_by(PakDeployment.environment).all()
        
        # Get deployment duration statistics
        completed_deployments = [d for d in deployments if d.duration is not None]
        avg_duration = sum(d.duration for d in completed_deployments) / len(completed_deployments) if completed_deployments else 0
        min_duration = min(d.duration for d in completed_deployments) if completed_deployments else 0
        max_duration = max(d.duration for d in completed_deployments) if completed_deployments else 0
        
        # Get monthly deployment trends
        monthly_deployments = db.session.query(
            func.date_trunc('month', PakDeployment.created_at).label('month'),
            func.count(PakDeployment.id).label('count')
        ).filter(
            PakDeployment.project_id == project_id
        ).group_by(
            func.date_trunc('month', PakDeployment.created_at)
        ).order_by(
            func.date_trunc('month', PakDeployment.created_at)
        ).all()
        
        return {
            'project': {
                'id': project.id,
                'name': project.name,
                'description': project.description,
                'status': project.status,
                'version': project.version,
                'platform': project.platform,
                'language': project.language,
                'framework': project.framework,
                'created_at': project.created_at.isoformat()
            },
            'overview': {
                'total_deployments': total_deployments,
                'success_rate': round(success_rate, 2),
                'last_deployment': project.last_deployment.isoformat() if project.last_deployment else None
            },
            'deployments': {
                'total': total_deployments,
                'successful': successful_deployments,
                'failed': failed_deployments,
                'running': running_deployments,
                'success_rate': round(success_rate, 2)
            },
            'performance': {
                'avg_duration': round(avg_duration, 2),
                'min_duration': min_duration,
                'max_duration': max_duration
            },
            'environments': [{
                'environment': e.environment,
                'count': e.count,
                'avg_duration': round(e.avg_duration, 2) if e.avg_duration else 0
            } for e in environment_stats],
            'recent_deployments': [{
                'id': d.id,
                'environment': d.environment,
                'status': d.status,
                'version': d.version,
                'created_at': d.created_at.isoformat(),
                'duration': d.duration,
                'error_message': d.error_message
            } for d in recent_deployments],
            'monthly_trends': [{
                'month': str(m.month),
                'count': m.count
            } for m in monthly_deployments]
        }
    
    def get_deployment_analytics(self, deployment_id: int) -> Dict[str, Any]:
        """Get deployment-specific analytics"""
        
        deployment = PakDeployment.query.get(deployment_id)
        if not deployment:
            return {'error': 'Deployment not found'}
        
        # Get deployment details
        deployment_data = {
            'id': deployment.id,
            'project_name': deployment.project.name if deployment.project else 'Unknown',
            'environment': deployment.environment,
            'status': deployment.status,
            'version': deployment.version,
            'started_at': deployment.started_at.isoformat() if deployment.started_at else None,
            'completed_at': deployment.completed_at.isoformat() if deployment.completed_at else None,
            'duration': deployment.duration,
            'error_message': deployment.error_message,
            'created_at': deployment.created_at.isoformat()
        }
        
        # Get similar deployments for comparison
        similar_deployments = PakDeployment.query.filter(
            and_(
                PakDeployment.project_id == deployment.project_id,
                PakDeployment.environment == deployment.environment,
                PakDeployment.id != deployment.id
            )
        ).order_by(desc(PakDeployment.created_at)).limit(5).all()
        
        # Calculate performance comparison
        if similar_deployments:
            avg_duration = sum(d.duration or 0 for d in similar_deployments) / len(similar_deployments)
            deployment_data['performance_comparison'] = {
                'similar_deployments_count': len(similar_deployments),
                'average_duration': round(avg_duration, 2),
                'this_deployment_duration': deployment.duration or 0,
                'performance_ratio': round((deployment.duration or 0) / avg_duration, 2) if avg_duration > 0 else 0
            }
        
        return deployment_data
    
    def record_metric(self, metric_name: str, metric_value: float, 
                     project_id: Optional[int] = None, user_id: Optional[int] = None,
                     environment: Optional[str] = None, platform: Optional[str] = None,
                     metric_unit: Optional[str] = None) -> bool:
        """Record a new metric"""
        try:
            metric = Analytics(
                metric_name=metric_name,
                metric_value=metric_value,
                metric_unit=metric_unit,
                project_id=project_id,
                user_id=user_id,
                environment=environment,
                platform=platform
            )
            
            db.session.add(metric)
            db.session.commit()
            return True
        except Exception as e:
            db.session.rollback()
            return False
    
    def get_metrics(self, metric_name: str, days: int = 30, 
                   project_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """Get metrics for a specific metric name"""
        
        start_date = datetime.datetime.utcnow() - datetime.timedelta(days=days)
        
        query = Analytics.query.filter(
            and_(
                Analytics.metric_name == metric_name,
                Analytics.recorded_at >= start_date
            )
        )
        
        if project_id:
            query = query.filter(Analytics.project_id == project_id)
        
        metrics = query.order_by(Analytics.recorded_at).all()
        
        return [{
            'timestamp': m.recorded_at.isoformat(),
            'value': m.metric_value,
            'unit': m.metric_unit,
            'project_id': m.project_id,
            'user_id': m.user_id,
            'environment': m.environment,
            'platform': m.platform
        } for m in metrics]
    
    def get_webhook_analytics(self) -> Dict[str, Any]:
        """Get webhook analytics"""
        
        total_webhooks = Webhook.query.count()
        active_webhooks = Webhook.query.filter_by(is_active=True).count()
        
        # Get webhook delivery statistics
        from models import WebhookDelivery
        total_deliveries = WebhookDelivery.query.count()
        successful_deliveries = WebhookDelivery.query.filter(
            WebhookDelivery.status_code.between(200, 299)
        ).count()
        failed_deliveries = total_deliveries - successful_deliveries
        
        success_rate = (successful_deliveries / total_deliveries * 100) if total_deliveries > 0 else 0
        
        # Get recent webhook activity
        recent_deliveries = WebhookDelivery.query.order_by(
            desc(WebhookDelivery.created_at)
        ).limit(10).all()
        
        return {
            'overview': {
                'total_webhooks': total_webhooks,
                'active_webhooks': active_webhooks,
                'total_deliveries': total_deliveries,
                'success_rate': round(success_rate, 2)
            },
            'deliveries': {
                'total': total_deliveries,
                'successful': successful_deliveries,
                'failed': failed_deliveries,
                'success_rate': round(success_rate, 2)
            },
            'recent_activity': [{
                'id': d.id,
                'webhook_name': d.webhook.name if d.webhook else 'Unknown',
                'event': d.event,
                'status_code': d.status_code,
                'duration': d.duration,
                'created_at': d.created_at.isoformat()
            } for d in recent_deliveries]
        } 