#!/usr/bin/env python3
"""
PAK.sh Flask Production Deployment Script
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def run_command(cmd, check=True):
    """Run a shell command"""
    print(f"🔄 Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"❌ Error: {result.stderr}")
        sys.exit(1)
    return result

def main():
    """Main deployment function"""
    print("🚀 PAK.sh Flask Production Deployment")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('app.py'):
        print("❌ Error: app.py not found. Run this script from the web_py directory.")
        sys.exit(1)
    
    # Install dependencies
    print("\n📦 Installing dependencies...")
    run_command("pip install -r requirements.txt")
    
    # Create necessary directories
    print("\n📁 Creating directories...")
    os.makedirs('uploads', exist_ok=True)
    os.makedirs('logs', exist_ok=True)
    
    # Set up environment variables
    print("\n🔧 Setting up environment...")
    env_file = Path('.env')
    if not env_file.exists():
        with open('.env', 'w') as f:
            f.write("""# PAK.sh Flask Environment Variables
SECRET_KEY=your-super-secret-key-change-this-in-production
FLASK_ENV=production
FLASK_DEBUG=0
DATABASE_URL=sqlite:///pak_herd.db
""")
        print("✅ Created .env file")
    
    # Initialize database
    print("\n🗄️ Initializing database...")
    run_command("python -c \"from app import app, db; app.app_context().push(); db.create_all(); print('Database initialized')\"")
    
    # Create systemd service file
    print("\n🔧 Creating systemd service...")
    service_content = """[Unit]
Description=PAK.sh Flask Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory={}
Environment=PATH={}/venv/bin
ExecStart={}/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:5000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
""".format(os.getcwd(), os.getcwd(), os.getcwd())
    
    with open('pak-flask.service', 'w') as f:
        f.write(service_content)
    
    print("✅ Created pak-flask.service")
    
    # Create nginx configuration
    print("\n🌐 Creating nginx configuration...")
    nginx_config = """server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static {
        alias /path/to/web_py/static;
        expires 30d;
    }
}
"""
    
    with open('nginx-pak-flask.conf', 'w') as f:
        f.write(nginx_config)
    
    print("✅ Created nginx-pak-flask.conf")
    
    # Create startup script
    print("\n📜 Creating startup script...")
    startup_script = """#!/bin/bash
# PAK.sh Flask Startup Script

cd "$(dirname "$0")"

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start the application
python run.py
"""
    
    with open('start.sh', 'w') as f:
        f.write(startup_script)
    
    os.chmod('start.sh', 0o755)
    print("✅ Created start.sh")
    
    print("\n🎉 Deployment setup complete!")
    print("\n📋 Next steps:")
    print("1. Update .env file with your secret key")
    print("2. Copy pak-flask.service to /etc/systemd/system/")
    print("3. Copy nginx-pak-flask.conf to /etc/nginx/sites-available/")
    print("4. Enable and start the service:")
    print("   sudo systemctl enable pak-flask")
    print("   sudo systemctl start pak-flask")
    print("5. Configure nginx and restart:")
    print("   sudo ln -s /etc/nginx/sites-available/pak-flask.conf /etc/nginx/sites-enabled/")
    print("   sudo systemctl restart nginx")
    print("\n🔗 Access your application at: http://your-domain.com")

if __name__ == '__main__':
    main() 