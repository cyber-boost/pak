#!/usr/bin/env python3
"""
PAK.sh TSK Blueprint
TuskLang integration for PAK.sh Web API
"""

import os
import json
import subprocess
from flask import Blueprint, request, jsonify, current_app
from flask_login import login_required, current_user
from app_factory import db, tsk
from models import PakProject, PakDeployment
from services.pak_service import PakService

tsk_bp = Blueprint('tsk', __name__)

@tsk_bp.route('/compile', methods=['POST'])
@login_required
def compile_tsk():
    """Compile TSK file"""
    try:
        data = request.get_json()
        tsk_file = data.get('tsk_file')
        output_format = data.get('output_format', 'json')
        
        if not tsk_file:
            return jsonify({'error': 'TSK file is required'}), 400
        
        # Use TSK manager to compile
        result = tsk.compile(tsk_file, output_format=output_format)
        
        return jsonify({
            'status': 'success',
            'data': result
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/validate', methods=['POST'])
@login_required
def validate_tsk():
    """Validate TSK file"""
    try:
        data = request.get_json()
        tsk_file = data.get('tsk_file')
        
        if not tsk_file:
            return jsonify({'error': 'TSK file is required'}), 400
        
        # Use TSK manager to validate
        result = tsk.validate(tsk_file)
        
        return jsonify({
            'status': 'success',
            'valid': result.get('valid', False),
            'errors': result.get('errors', []),
            'warnings': result.get('warnings', [])
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/execute', methods=['POST'])
@login_required
def execute_tsk():
    """Execute TSK file"""
    try:
        data = request.get_json()
        tsk_file = data.get('tsk_file')
        parameters = data.get('parameters', {})
        
        if not tsk_file:
            return jsonify({'error': 'TSK file is required'}), 400
        
        # Use TSK manager to execute
        result = tsk.execute(tsk_file, parameters=parameters)
        
        return jsonify({
            'status': 'success',
            'data': result
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/templates')
@login_required
def list_templates():
    """List available TSK templates"""
    try:
        template_path = current_app.config.get('TSK_TEMPLATE_PATH')
        
        if not os.path.exists(template_path):
            return jsonify({'templates': []})
        
        templates = []
        for file in os.listdir(template_path):
            if file.endswith('.tsk'):
                template_info = {
                    'name': file,
                    'path': os.path.join(template_path, file),
                    'size': os.path.getsize(os.path.join(template_path, file))
                }
                templates.append(template_info)
        
        return jsonify({
            'status': 'success',
            'templates': templates
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/templates/<template_name>')
@login_required
def get_template(template_name):
    """Get TSK template content"""
    try:
        template_path = current_app.config.get('TSK_TEMPLATE_PATH')
        template_file = os.path.join(template_path, template_name)
        
        if not os.path.exists(template_file):
            return jsonify({'error': 'Template not found'}), 404
        
        with open(template_file, 'r') as f:
            content = f.read()
        
        return jsonify({
            'status': 'success',
            'template': {
                'name': template_name,
                'content': content,
                'size': os.path.getsize(template_file)
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/configs')
@login_required
def list_configs():
    """List TSK configurations"""
    try:
        config_path = current_app.config.get('TSK_CONFIG_PATH')
        
        if not os.path.exists(config_path):
            return jsonify({'configs': []})
        
        configs = []
        for file in os.listdir(config_path):
            if file.endswith('.tsk'):
                config_info = {
                    'name': file,
                    'path': os.path.join(config_path, file),
                    'size': os.path.getsize(os.path.join(config_path, file))
                }
                configs.append(config_info)
        
        return jsonify({
            'status': 'success',
            'configs': configs
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/configs/<config_name>')
@login_required
def get_config(config_name):
    """Get TSK configuration content"""
    try:
        config_path = current_app.config.get('TSK_CONFIG_PATH')
        config_file = os.path.join(config_path, config_name)
        
        if not os.path.exists(config_file):
            return jsonify({'error': 'Configuration not found'}), 404
        
        with open(config_file, 'r') as f:
            content = f.read()
        
        return jsonify({
            'status': 'success',
            'config': {
                'name': config_name,
                'content': content,
                'size': os.path.getsize(config_file)
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/projects/<int:project_id>/tsk')
@login_required
def get_project_tsk(project_id):
    """Get TSK configuration for a project"""
    try:
        project = PakProject.query.get_or_404(project_id)
        
        # Check if user has access to this project
        if not current_user.is_admin() and project.created_by != current_user.id:
            return jsonify({'error': 'Access denied'}), 403
        
        pak_service = PakService()
        project_config = pak_service.get_project_config(project.name)
        
        # Look for TSK files in project
        tsk_files = []
        project_path = os.path.join(current_app.config['PAK_ROOT'], project.name)
        
        if os.path.exists(project_path):
            for file in os.listdir(project_path):
                if file.endswith('.tsk'):
                    tsk_files.append({
                        'name': file,
                        'path': os.path.join(project_path, file),
                        'size': os.path.getsize(os.path.join(project_path, file))
                    })
        
        return jsonify({
            'status': 'success',
            'project': {
                'id': project.id,
                'name': project.name,
                'tsk_files': tsk_files,
                'config': project_config
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/projects/<int:project_id>/tsk/execute', methods=['POST'])
@login_required
def execute_project_tsk(project_id):
    """Execute TSK file for a project"""
    try:
        project = PakProject.query.get_or_404(project_id)
        
        # Check if user has access to this project
        if not current_user.is_admin() and project.created_by != current_user.id:
            return jsonify({'error': 'Access denied'}), 403
        
        data = request.get_json()
        tsk_file = data.get('tsk_file')
        parameters = data.get('parameters', {})
        
        if not tsk_file:
            return jsonify({'error': 'TSK file is required'}), 400
        
        # Create deployment record
        deployment = PakDeployment(
            project_id=project.id,
            environment='tsk',
            status='running',
            user_id=current_user.id
        )
        db.session.add(deployment)
        db.session.commit()
        
        try:
            # Execute TSK file
            project_path = os.path.join(current_app.config['PAK_ROOT'], project.name)
            tsk_file_path = os.path.join(project_path, tsk_file)
            
            if not os.path.exists(tsk_file_path):
                raise FileNotFoundError(f"TSK file {tsk_file} not found")
            
            # Use TSK manager to execute
            result = tsk.execute(tsk_file_path, parameters=parameters)
            
            # Update deployment status
            deployment.status = 'success'
            deployment.logs = json.dumps(result)
            deployment.completed_at = db.func.now()
            
            return jsonify({
                'status': 'success',
                'deployment_id': deployment.id,
                'data': result
            })
            
        except Exception as e:
            # Update deployment status
            deployment.status = 'failed'
            deployment.logs = str(e)
            deployment.completed_at = db.func.now()
            db.session.commit()
            
            return jsonify({'error': str(e)}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@tsk_bp.route('/status')
@login_required
def tsk_status():
    """Get TSK system status"""
    try:
        # Check TSK CLI availability
        try:
            result = subprocess.run(['tsk', '--version'], 
                                  capture_output=True, text=True, timeout=10)
            tsk_version = result.stdout.strip() if result.returncode == 0 else 'Unknown'
        except:
            tsk_version = 'Not available'
        
        # Get TSK configuration status
        config_path = current_app.config.get('TSK_CONFIG_PATH')
        template_path = current_app.config.get('TSK_TEMPLATE_PATH')
        
        status = {
            'enabled': current_app.config.get('TSK_ENABLED', True),
            'version': tsk_version,
            'config_path': config_path,
            'template_path': template_path,
            'config_path_exists': os.path.exists(config_path),
            'template_path_exists': os.path.exists(template_path),
            'cache_enabled': current_app.config.get('TSK_CACHE_ENABLED', True),
            'cache_timeout': current_app.config.get('TSK_CACHE_TIMEOUT', 300)
        }
        
        return jsonify({
            'status': 'success',
            'data': status
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500 