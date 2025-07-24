#!/usr/bin/env python3
"""
PAK.sh Web API Runner
Development and production server runner
"""

import os
import sys
from app_factory import create_app, create_socketio_app, socketio

def main():
    """Main application entry point"""
    
    # Set default environment
    if not os.environ.get('FLASK_ENV'):
        os.environ['FLASK_ENV'] = 'development'
    
    # Create Flask application
    app = create_app()
    
    # Create SocketIO application for real-time features
    socketio_app = create_socketio_app(app)
    
    # Get configuration
    debug = app.config.get('DEBUG', False)
    host = os.environ.get('HOST', '0.0.0.0')
    port = int(os.environ.get('PORT', 5000))
    
    print(f"🚀 Starting PAK.sh Web API...")
    print(f"   Environment: {os.environ.get('FLASK_ENV', 'development')}")
    print(f"   Debug: {debug}")
    print(f"   Host: {host}")
    print(f"   Port: {port}")
    print(f"   API Docs: http://{host}:{port}/api/v1/docs")
    print(f"   Dashboard: http://{host}:{port}/dashboard")
    print()
    
    try:
        # Run the application
        if os.environ.get('FLASK_ENV') == 'production':
            # Production mode with Gunicorn
            from gunicorn.app.base import BaseApplication
            
            class GunicornApp(BaseApplication):
                def __init__(self, app, options=None):
                    self.options = options or {}
                    self.application = app
                    super().__init__()
                
                def load_config(self):
                    for key, value in self.options.items():
                        self.cfg.set(key, value)
                
                def load(self):
                    return self.application
            
            options = {
                'bind': f'{host}:{port}',
                'workers': 4,
                'worker_class': 'eventlet',
                'worker_connections': 1000,
                'max_requests': 1000,
                'max_requests_jitter': 100,
                'timeout': 30,
                'keepalive': 2,
                'preload_app': True
            }
            
            GunicornApp(app, options).run()
        else:
            # Development mode with Flask-SocketIO
            socketio.run(
                app,
                host=host,
                port=port,
                debug=debug,
                use_reloader=debug,
                log_output=True
            )
    
    except KeyboardInterrupt:
        print("\n🛑 Shutting down PAK.sh Web API...")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Error starting PAK.sh Web API: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main() 