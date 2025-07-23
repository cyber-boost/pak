#!/usr/bin/env python3
"""
PAK.sh Flask Application Runner
"""

import os
import sys
from app import app, db

def main():
    """Main entry point for the Flask application"""
    
    # Set up environment
    if not os.path.exists('uploads'):
        os.makedirs('uploads')
    
    # Create database tables
    with app.app_context():
        db.create_all()
        print("✅ Database initialized")
    
    # Run the application
    print("🚀 Starting PAK.sh Flask application...")
    print("📍 Access the application at: http://localhost:5000")
    print("🔐 Admin interface at: http://localhost:5000/admin/users")
    print("📊 Telemetry dashboard at: http://localhost:5000/telemetry")
    
    app.run(
        debug=True,
        host='0.0.0.0',
        port=5000,
        threaded=True
    )

if __name__ == '__main__':
    main() 