#!/usr/bin/env python3
"""
PAK.sh Service Layer
Integration with PAK.sh CLI system
"""

import os
import json
import subprocess
import yaml
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from pathlib import Path

logger = logging.getLogger(__name__)

class PakService:
    """Service for interacting with PAK.sh CLI"""
    
    def __init__(self):
        self.pak_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        self.pak_script = os.path.join(self.pak_root, 'pak', 'pak.sh')
        self.config_dir = os.path.join(self.pak_root, 'pak', 'config')
        self.data_dir = os.path.join(self.pak_root, 'pak', 'data')
        self.logs_dir = os.path.join(self.pak_root, 'pak', 'logs')
        
        # Ensure PAK.sh is executable
        if os.path.exists(self.pak_script):
            os.chmod(self.pak_script, 0o755)
    
    def _run_pak_command(self, command: str, cwd: Optional[str] = None, timeout: int = 300) -> Dict[str, Any]:
        """Run a PAK.sh command and return the result"""
        try:
            # Set environment variables
            env = os.environ.copy()
            env['PAK_QUIET_MODE'] = 'true'
            env['PAK_DEBUG_MODE'] = 'false'
            
            # Build full command
            full_command = f"{self.pak_script} {command}"
            
            logger.info(f"Running PAK command: {full_command}")
            
            # Execute command
            result = subprocess.run(
                full_command,
                shell=True,
                cwd=cwd or self.pak_root,
                env=env,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout.strip(),
                'stderr': result.stderr.strip(),
                'returncode': result.returncode,
                'command': full_command
            }
            
        except subprocess.TimeoutExpired:
            logger.error(f"PAK command timed out: {command}")
            return {
                'success': False,
                'stdout': '',
                'stderr': 'Command timed out',
                'returncode': -1,
                'command': command
            }
        except Exception as e:
            logger.error(f"Error running PAK command: {e}")
            return {
                'success': False,
                'stdout': '',
                'stderr': str(e),
                'returncode': -1,
                'command': command
            }
    
    def get_status(self) -> Dict[str, Any]:
        """Get PAK.sh system status"""
        result = self._run_pak_command('status')
        
        if result['success']:
            # Parse status output
            status_data = {
                'version': '2.0.0',  # Extract from output
                'status': 'running',
                'modules_loaded': 0,
                'config_path': self.config_dir,
                'data_path': self.data_dir,
                'logs_path': self.logs_dir
            }
            
            # Try to extract module count from output
            if 'modules' in result['stdout'].lower():
                try:
                    # Look for module count in output
                    lines = result['stdout'].split('\n')
                    for line in lines:
                        if 'modules' in line.lower() and any(char.isdigit() for char in line):
                            # Extract number from line
                            import re
                            numbers = re.findall(r'\d+', line)
                            if numbers:
                                status_data['modules_loaded'] = int(numbers[0])
                                break
                except:
                    pass
            
            return status_data
        else:
            return {
                'status': 'error',
                'error': result['stderr'],
                'version': 'unknown'
            }
    
    def list_projects(self) -> List[Dict[str, Any]]:
        """List all PAK projects"""
        result = self._run_pak_command('list')
        
        projects = []
        if result['success']:
            # Parse project list from output
            lines = result['stdout'].split('\n')
            for line in lines:
                line = line.strip()
                if line and not line.startswith('#'):
                    # Parse project line (format may vary)
                    parts = line.split()
                    if len(parts) >= 1:
                        project_name = parts[0]
                        project_data = {
                            'name': project_name,
                            'status': 'active',
                            'config_path': os.path.join(self.config_dir, f"{project_name}.yaml"),
                            'last_modified': datetime.now().isoformat()
                        }
                        projects.append(project_data)
        
        return projects
    
    def get_project_config(self, project_name: str) -> Dict[str, Any]:
        """Get project configuration"""
        config_path = os.path.join(self.config_dir, f"{project_name}.yaml")
        
        if not os.path.exists(config_path):
            return {'error': 'Project not found'}
        
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            return {
                'name': project_name,
                'config': config,
                'config_path': config_path,
                'last_modified': datetime.fromtimestamp(os.path.getmtime(config_path)).isoformat()
            }
        except Exception as e:
            logger.error(f"Error reading project config: {e}")
            return {'error': f'Failed to read config: {str(e)}'}
    
    def deploy_project(self, project_name: str, environment: str = 'production', version: Optional[str] = None) -> Dict[str, Any]:
        """Deploy a project"""
        command = f"deploy {project_name}"
        
        if environment:
            command += f" --env {environment}"
        
        if version:
            command += f" --version {version}"
        
        result = self._run_pak_command(command)
        
        deployment_data = {
            'project_name': project_name,
            'environment': environment,
            'version': version,
            'status': 'success' if result['success'] else 'failed',
            'started_at': datetime.now().isoformat(),
            'completed_at': datetime.now().isoformat(),
            'logs': result['stdout'],
            'error': result['stderr'] if not result['success'] else None
        }
        
        return deployment_data
    
    def package_project(self, project_name: str, version: Optional[str] = None) -> Dict[str, Any]:
        """Package a project"""
        command = f"package {project_name}"
        
        if version:
            command += f" --version {version}"
        
        result = self._run_pak_command(command)
        
        package_data = {
            'project_name': project_name,
            'version': version,
            'status': 'success' if result['success'] else 'failed',
            'started_at': datetime.now().isoformat(),
            'completed_at': datetime.now().isoformat(),
            'logs': result['stdout'],
            'error': result['stderr'] if not result['success'] else None
        }
        
        return package_data
    
    def get_available_platforms(self) -> List[str]:
        """Get list of available platforms"""
        result = self._run_pak_command('platforms')
        
        platforms = []
        if result['success']:
            # Parse platforms from output
            lines = result['stdout'].split('\n')
            for line in lines:
                line = line.strip()
                if line and not line.startswith('#'):
                    platforms.append(line)
        
        # Fallback to common platforms if command fails
        if not platforms:
            platforms = ['docker', 'kubernetes', 'aws', 'gcp', 'azure', 'heroku', 'digitalocean']
        
        return platforms
    
    def get_platform_config(self, platform_name: str) -> Dict[str, Any]:
        """Get platform configuration"""
        config_path = os.path.join(self.config_dir, 'platforms', f"{platform_name}.yaml")
        
        if not os.path.exists(config_path):
            return {'error': 'Platform not found'}
        
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            return {
                'platform': platform_name,
                'config': config,
                'config_path': config_path
            }
        except Exception as e:
            logger.error(f"Error reading platform config: {e}")
            return {'error': f'Failed to read config: {str(e)}'}
    
    def run_security_scan(self, project_name: str) -> Dict[str, Any]:
        """Run security scan on project"""
        command = f"security {project_name}"
        
        result = self._run_pak_command(command)
        
        scan_data = {
            'project_name': project_name,
            'status': 'success' if result['success'] else 'failed',
            'started_at': datetime.now().isoformat(),
            'completed_at': datetime.now().isoformat(),
            'results': result['stdout'],
            'error': result['stderr'] if not result['success'] else None
        }
        
        return scan_data
    
    def get_project_logs(self, project_name: str, lines: int = 100) -> Dict[str, Any]:
        """Get project logs"""
        log_path = os.path.join(self.logs_dir, f"{project_name}.log")
        
        if not os.path.exists(log_path):
            return {'error': 'Log file not found'}
        
        try:
            with open(log_path, 'r') as f:
                # Get last N lines
                all_lines = f.readlines()
                log_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines
            
            return {
                'project_name': project_name,
                'log_path': log_path,
                'lines': len(log_lines),
                'content': ''.join(log_lines),
                'last_modified': datetime.fromtimestamp(os.path.getmtime(log_path)).isoformat()
            }
        except Exception as e:
            logger.error(f"Error reading project logs: {e}")
            return {'error': f'Failed to read logs: {str(e)}'}
    
    def create_project(self, project_name: str, config_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new project"""
        config_path = os.path.join(self.config_dir, f"{project_name}.yaml")
        
        # Check if project already exists
        if os.path.exists(config_path):
            return {'error': 'Project already exists'}
        
        try:
            # Create config file
            with open(config_path, 'w') as f:
                yaml.dump(config_data, f, default_flow_style=False)
            
            return {
                'project_name': project_name,
                'config_path': config_path,
                'status': 'created',
                'created_at': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Error creating project: {e}")
            return {'error': f'Failed to create project: {str(e)}'}
    
    def update_project_config(self, project_name: str, config_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update project configuration"""
        config_path = os.path.join(self.config_dir, f"{project_name}.yaml")
        
        if not os.path.exists(config_path):
            return {'error': 'Project not found'}
        
        try:
            # Update config file
            with open(config_path, 'w') as f:
                yaml.dump(config_data, f, default_flow_style=False)
            
            return {
                'project_name': project_name,
                'config_path': config_path,
                'status': 'updated',
                'updated_at': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Error updating project: {e}")
            return {'error': f'Failed to update project: {str(e)}'}
    
    def delete_project(self, project_name: str) -> Dict[str, Any]:
        """Delete a project"""
        config_path = os.path.join(self.config_dir, f"{project_name}.yaml")
        log_path = os.path.join(self.logs_dir, f"{project_name}.log")
        
        if not os.path.exists(config_path):
            return {'error': 'Project not found'}
        
        try:
            # Remove config file
            os.remove(config_path)
            
            # Remove log file if exists
            if os.path.exists(log_path):
                os.remove(log_path)
            
            return {
                'project_name': project_name,
                'status': 'deleted',
                'deleted_at': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Error deleting project: {e}")
            return {'error': f'Failed to delete project: {str(e)}'}
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get system metrics"""
        metrics = {
            'timestamp': datetime.now().isoformat(),
            'projects_count': len(self.list_projects()),
            'disk_usage': self._get_disk_usage(),
            'memory_usage': self._get_memory_usage(),
            'uptime': self._get_uptime()
        }
        
        return metrics
    
    def _get_disk_usage(self) -> Dict[str, Any]:
        """Get disk usage information"""
        try:
            import shutil
            total, used, free = shutil.disk_usage(self.pak_root)
            
            return {
                'total_gb': round(total / (1024**3), 2),
                'used_gb': round(used / (1024**3), 2),
                'free_gb': round(free / (1024**3), 2),
                'usage_percent': round((used / total) * 100, 2)
            }
        except Exception as e:
            logger.error(f"Error getting disk usage: {e}")
            return {'error': str(e)}
    
    def _get_memory_usage(self) -> Dict[str, Any]:
        """Get memory usage information"""
        try:
            import psutil
            memory = psutil.virtual_memory()
            
            return {
                'total_gb': round(memory.total / (1024**3), 2),
                'used_gb': round(memory.used / (1024**3), 2),
                'free_gb': round(memory.available / (1024**3), 2),
                'usage_percent': round(memory.percent, 2)
            }
        except Exception as e:
            logger.error(f"Error getting memory usage: {e}")
            return {'error': str(e)}
    
    def _get_uptime(self) -> Dict[str, Any]:
        """Get system uptime"""
        try:
            import psutil
            import time
            boot_time = psutil.boot_time()
            uptime_seconds = time.time() - boot_time
            
            days = int(uptime_seconds // 86400)
            hours = int((uptime_seconds % 86400) // 3600)
            minutes = int((uptime_seconds % 3600) // 60)
            
            return {
                'days': days,
                'hours': hours,
                'minutes': minutes,
                'total_seconds': int(uptime_seconds)
            }
        except Exception as e:
            logger.error(f"Error getting uptime: {e}")
            return {'error': str(e)} 