#!/usr/bin/env python3
"""
PAK.sh Webhooks Blueprint
Webhook management and event delivery
"""

import json
import time
import requests
import hmac
import hashlib
from flask import Blueprint, request, jsonify, current_app
from app_factory import db
from models import Webhook, WebhookDelivery
from services.webhook_service import WebhookService

webhook_bp = Blueprint('webhooks', __name__)

@webhook_bp.route('/deliver', methods=['POST'])
def deliver_webhook():
    """Deliver webhook event"""
    event_type = request.json.get('event')
    payload = request.json.get('payload', {})
    
    if not event_type:
        return jsonify({'error': 'Event type is required'}), 400
    
    webhook_service = WebhookService()
    result = webhook_service.deliver_event(event_type, payload)
    
    return jsonify(result)

@webhook_bp.route('/test/<int:webhook_id>', methods=['POST'])
def test_webhook(webhook_id):
    """Test webhook delivery"""
    webhook = Webhook.query.get_or_404(webhook_id)
    
    if not webhook.is_active:
        return jsonify({'error': 'Webhook is not active'}), 400
    
    # Create test payload
    test_payload = {
        'event': 'test',
        'timestamp': time.time(),
        'data': {
            'message': 'This is a test webhook delivery',
            'webhook_id': webhook.id,
            'webhook_name': webhook.name
        }
    }
    
    webhook_service = WebhookService()
    result = webhook_service.deliver_to_webhook(webhook, 'test', test_payload)
    
    return jsonify(result)

@webhook_bp.route('/events')
def list_events():
    """List available webhook events"""
    events = [
        'project.created',
        'project.updated',
        'project.deleted',
        'deployment.started',
        'deployment.completed',
        'deployment.failed',
        'security.scan.completed',
        'user.registered',
        'user.login',
        'api.usage.exceeded'
    ]
    
    return jsonify({
        'status': 'success',
        'data': events
    })

@webhook_bp.route('/deliveries/<int:webhook_id>')
def webhook_deliveries(webhook_id):
    """Get webhook delivery history"""
    webhook = Webhook.query.get_or_404(webhook_id)
    
    page = request.args.get('page', 1, type=int)
    per_page = 50
    
    deliveries = WebhookDelivery.query.filter_by(
        webhook_id=webhook_id
    ).order_by(
        WebhookDelivery.created_at.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'status': 'success',
        'data': [{
            'id': d.id,
            'event': d.event,
            'status_code': d.status_code,
            'duration': d.duration,
            'retry_count': d.retry_count,
            'created_at': d.created_at.isoformat()
        } for d in deliveries.items],
        'pagination': {
            'page': deliveries.page,
            'pages': deliveries.pages,
            'per_page': deliveries.per_page,
            'total': deliveries.total
        }
    })

@webhook_bp.route('/stats')
def webhook_stats():
    """Get webhook statistics"""
    total_webhooks = Webhook.query.count()
    active_webhooks = Webhook.query.filter_by(is_active=True).count()
    
    total_deliveries = WebhookDelivery.query.count()
    successful_deliveries = WebhookDelivery.query.filter(
        WebhookDelivery.status_code.between(200, 299)
    ).count()
    failed_deliveries = total_deliveries - successful_deliveries
    
    success_rate = (successful_deliveries / total_deliveries * 100) if total_deliveries > 0 else 0
    
    return jsonify({
        'status': 'success',
        'data': {
            'total_webhooks': total_webhooks,
            'active_webhooks': active_webhooks,
            'total_deliveries': total_deliveries,
            'successful_deliveries': successful_deliveries,
            'failed_deliveries': failed_deliveries,
            'success_rate': round(success_rate, 2)
        }
    }) 