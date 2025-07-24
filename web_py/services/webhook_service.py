#!/usr/bin/env python3
"""
PAK.sh Webhook Service
Webhook delivery and event management
"""

import json
import time
import requests
import hmac
import hashlib
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from app_factory import db
from models import Webhook, WebhookDelivery

logger = logging.getLogger(__name__)

class WebhookService:
    """Service for webhook delivery and management"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.timeout = 30
    
    def deliver_event(self, event_type: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Deliver event to all matching webhooks"""
        try:
            # Find webhooks that should receive this event
            webhooks = Webhook.query.filter(
                Webhook.is_active == True,
                Webhook.events.contains([event_type])
            ).all()
            
            if not webhooks:
                return {
                    'success': True,
                    'message': 'No webhooks configured for this event',
                    'deliveries': 0
                }
            
            successful_deliveries = 0
            failed_deliveries = 0
            
            for webhook in webhooks:
                result = self.deliver_to_webhook(webhook, event_type, payload)
                if result['success']:
                    successful_deliveries += 1
                else:
                    failed_deliveries += 1
            
            return {
                'success': True,
                'message': f'Event delivered to {len(webhooks)} webhooks',
                'deliveries': len(webhooks),
                'successful': successful_deliveries,
                'failed': failed_deliveries
            }
            
        except Exception as e:
            logger.error(f"Error delivering event {event_type}: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def deliver_to_webhook(self, webhook: Webhook, event_type: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Deliver event to a specific webhook"""
        start_time = time.time()
        
        try:
            # Prepare headers
            headers = {
                'Content-Type': 'application/json',
                'User-Agent': 'PAK.sh-Webhook/1.0',
                'X-Webhook-Event': event_type,
                'X-Webhook-ID': str(webhook.id),
                'X-Webhook-Timestamp': str(int(time.time()))
            }
            
            # Add signature if secret is configured
            if webhook.secret:
                signature = self._generate_signature(webhook.secret, payload)
                headers['X-Webhook-Signature'] = signature
            
            # Prepare request data
            request_data = {
                'event': event_type,
                'timestamp': time.time(),
                'data': payload
            }
            
            # Make the request
            response = self.session.post(
                webhook.url,
                headers=headers,
                json=request_data,
                timeout=webhook.timeout or 30
            )
            
            duration = time.time() - start_time
            
            # Record delivery
            delivery = WebhookDelivery(
                webhook_id=webhook.id,
                event=event_type,
                payload=request_data,
                status_code=response.status_code,
                response_body=response.text[:1000],  # Limit response body
                duration=duration
            )
            
            db.session.add(delivery)
            
            # Update webhook statistics
            webhook.last_triggered = datetime.utcnow()
            if 200 <= response.status_code < 300:
                webhook.success_count += 1
            else:
                webhook.failure_count += 1
            
            db.session.commit()
            
            success = 200 <= response.status_code < 300
            
            return {
                'success': success,
                'webhook_id': webhook.id,
                'webhook_name': webhook.name,
                'status_code': response.status_code,
                'duration': round(duration, 3),
                'response_body': response.text[:200] if not success else None
            }
            
        except requests.exceptions.Timeout:
            duration = time.time() - start_time
            return self._handle_delivery_error(webhook, event_type, payload, 'timeout', duration)
            
        except requests.exceptions.ConnectionError:
            duration = time.time() - start_time
            return self._handle_delivery_error(webhook, event_type, payload, 'connection_error', duration)
            
        except Exception as e:
            duration = time.time() - start_time
            return self._handle_delivery_error(webhook, event_type, payload, str(e), duration)
    
    def _handle_delivery_error(self, webhook: Webhook, event_type: str, payload: Dict[str, Any], 
                              error: str, duration: float) -> Dict[str, Any]:
        """Handle webhook delivery errors"""
        try:
            # Record failed delivery
            delivery = WebhookDelivery(
                webhook_id=webhook.id,
                event=event_type,
                payload={'event': event_type, 'data': payload},
                status_code=None,
                response_body=error,
                duration=duration
            )
            
            db.session.add(delivery)
            
            # Update webhook statistics
            webhook.last_triggered = datetime.utcnow()
            webhook.failure_count += 1
            
            db.session.commit()
            
            return {
                'success': False,
                'webhook_id': webhook.id,
                'webhook_name': webhook.name,
                'error': error,
                'duration': round(duration, 3)
            }
            
        except Exception as e:
            logger.error(f"Error recording webhook delivery failure: {e}")
            return {
                'success': False,
                'webhook_id': webhook.id,
                'webhook_name': webhook.name,
                'error': f"Delivery failed: {error}. Recording failed: {str(e)}"
            }
    
    def _generate_signature(self, secret: str, payload: Dict[str, Any]) -> str:
        """Generate HMAC signature for webhook payload"""
        payload_str = json.dumps(payload, sort_keys=True)
        signature = hmac.new(
            secret.encode('utf-8'),
            payload_str.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        return f"sha256={signature}"
    
    def retry_failed_deliveries(self, max_retries: int = 3) -> Dict[str, Any]:
        """Retry failed webhook deliveries"""
        try:
            # Find failed deliveries that haven't exceeded max retries
            failed_deliveries = WebhookDelivery.query.filter(
                WebhookDelivery.status_code.is_(None),
                WebhookDelivery.retry_count < max_retries
            ).all()
            
            if not failed_deliveries:
                return {
                    'success': True,
                    'message': 'No failed deliveries to retry',
                    'retried': 0
                }
            
            successful_retries = 0
            failed_retries = 0
            
            for delivery in failed_deliveries:
                webhook = Webhook.query.get(delivery.webhook_id)
                if not webhook or not webhook.is_active:
                    continue
                
                # Retry the delivery
                result = self.deliver_to_webhook(
                    webhook,
                    delivery.event,
                    delivery.payload.get('data', {}) if delivery.payload else {}
                )
                
                if result['success']:
                    successful_retries += 1
                    # Mark original delivery as retried successfully
                    delivery.retry_count += 1
                    delivery.status_code = 200
                else:
                    failed_retries += 1
                    delivery.retry_count += 1
            
            db.session.commit()
            
            return {
                'success': True,
                'message': f'Retried {len(failed_deliveries)} failed deliveries',
                'retried': len(failed_deliveries),
                'successful': successful_retries,
                'failed': failed_retries
            }
            
        except Exception as e:
            logger.error(f"Error retrying failed deliveries: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def cleanup_old_deliveries(self, days: int = 90) -> Dict[str, Any]:
        """Clean up old webhook deliveries"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # Count deliveries to be deleted
            count = WebhookDelivery.query.filter(
                WebhookDelivery.created_at < cutoff_date
            ).count()
            
            # Delete old deliveries
            WebhookDelivery.query.filter(
                WebhookDelivery.created_at < cutoff_date
            ).delete()
            
            db.session.commit()
            
            return {
                'success': True,
                'message': f'Cleaned up {count} old webhook deliveries',
                'deleted': count
            }
            
        except Exception as e:
            logger.error(f"Error cleaning up old deliveries: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_webhook_stats(self, webhook_id: int) -> Dict[str, Any]:
        """Get statistics for a specific webhook"""
        try:
            webhook = Webhook.query.get_or_404(webhook_id)
            
            # Get delivery statistics
            total_deliveries = WebhookDelivery.query.filter_by(webhook_id=webhook_id).count()
            successful_deliveries = WebhookDelivery.query.filter(
                WebhookDelivery.webhook_id == webhook_id,
                WebhookDelivery.status_code.between(200, 299)
            ).count()
            failed_deliveries = total_deliveries - successful_deliveries
            
            success_rate = (successful_deliveries / total_deliveries * 100) if total_deliveries > 0 else 0
            
            # Get recent deliveries
            recent_deliveries = WebhookDelivery.query.filter_by(
                webhook_id=webhook_id
            ).order_by(
                WebhookDelivery.created_at.desc()
            ).limit(10).all()
            
            return {
                'success': True,
                'data': {
                    'webhook': {
                        'id': webhook.id,
                        'name': webhook.name,
                        'url': webhook.url,
                        'is_active': webhook.is_active,
                        'events': webhook.events or [],
                        'created_at': webhook.created_at.isoformat()
                    },
                    'statistics': {
                        'total_deliveries': total_deliveries,
                        'successful_deliveries': successful_deliveries,
                        'failed_deliveries': failed_deliveries,
                        'success_rate': round(success_rate, 2)
                    },
                    'recent_deliveries': [{
                        'id': d.id,
                        'event': d.event,
                        'status_code': d.status_code,
                        'duration': d.duration,
                        'retry_count': d.retry_count,
                        'created_at': d.created_at.isoformat()
                    } for d in recent_deliveries]
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting webhook stats: {e}")
            return {
                'success': False,
                'error': str(e)
            } 