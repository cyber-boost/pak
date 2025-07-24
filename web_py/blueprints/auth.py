#!/usr/bin/env python3
"""
PAK.sh Authentication Blueprint
User authentication and session management
"""

import datetime
import secrets
from flask import Blueprint, request, render_template, redirect, url_for, flash, session, jsonify
from flask_login import login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from app_factory import db, limiter
from models import User, UserSession, PasswordReset, LoginAttempt

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
@limiter.limit("5 per minute")
def login():
    """User login page"""
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        remember = request.form.get('remember', False)
        
        if not email or not password:
            flash('Email and password are required', 'error')
            return render_template('auth/login.html')
        
        user = User.query.filter_by(email=email).first()
        
        if not user or not user.check_password(password):
            # Record failed login attempt
            if user:
                user.record_failed_login()
                db.session.commit()
            
            # Log login attempt
            attempt = LoginAttempt(
                email=email,
                ip_address=request.remote_addr,
                user_agent=request.headers.get('User-Agent'),
                success=False,
                failure_reason='Invalid credentials'
            )
            db.session.add(attempt)
            db.session.commit()
            
            flash('Invalid email or password', 'error')
            return render_template('auth/login.html')
        
        if user.is_locked():
            flash('Account is locked due to too many failed attempts', 'error')
            return render_template('auth/login.html')
        
        if not user.is_active:
            flash('Account is disabled', 'error')
            return render_template('auth/login.html')
        
        # Reset failed attempts on successful login
        user.reset_failed_attempts()
        user.last_login = datetime.datetime.utcnow()
        db.session.commit()
        
        # Log successful login
        attempt = LoginAttempt(
            email=email,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent'),
            success=True
        )
        db.session.add(attempt)
        db.session.commit()
        
        # Create user session
        session_id = secrets.token_urlsafe(32)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=7 if remember else 1)
        
        user_session = UserSession(
            user_id=user.id,
            session_id=session_id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent'),
            expires_at=expires_at
        )
        db.session.add(user_session)
        db.session.commit()
        
        # Login user
        login_user(user, remember=remember)
        
        # Redirect to intended page or dashboard
        next_page = request.args.get('next')
        if not next_page or not next_page.startswith('/'):
            next_page = url_for('dashboard.index')
        
        flash('Login successful!', 'success')
        return redirect(next_page)
    
    return render_template('auth/login.html')

@auth_bp.route('/register', methods=['GET', 'POST'])
@limiter.limit("3 per minute")
def register():
    """User registration page"""
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        name = request.form.get('name')
        
        # Validate input
        if not all([email, password, confirm_password, name]):
            flash('All fields are required', 'error')
            return render_template('auth/register.html')
        
        if password != confirm_password:
            flash('Passwords do not match', 'error')
            return render_template('auth/register.html')
        
        if len(password) < 8:
            flash('Password must be at least 8 characters long', 'error')
            return render_template('auth/register.html')
        
        # Check if user already exists
        if User.query.filter_by(email=email).first():
            flash('User with this email already exists', 'error')
            return render_template('auth/register.html')
        
        # Create user
        user = User(
            email=email,
            name=name
        )
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        flash('Registration successful! Please log in.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/register.html')

@auth_bp.route('/logout')
@login_required
def logout():
    """User logout"""
    # Invalidate user session
    if current_user.is_authenticated:
        UserSession.query.filter_by(user_id=current_user.id).delete()
        db.session.commit()
    
    logout_user()
    flash('You have been logged out', 'info')
    return redirect(url_for('auth.login'))

@auth_bp.route('/forgot-password', methods=['GET', 'POST'])
@limiter.limit("3 per minute")
def forgot_password():
    """Forgot password page"""
    if request.method == 'POST':
        email = request.form.get('email')
        
        if not email:
            flash('Email is required', 'error')
            return render_template('auth/forgot_password.html')
        
        user = User.query.filter_by(email=email).first()
        
        if user and user.is_active:
            # Create password reset token
            token = secrets.token_urlsafe(32)
            expires_at = datetime.datetime.utcnow() + datetime.timedelta(hours=24)
            
            # Remove any existing reset tokens for this user
            PasswordReset.query.filter_by(user_id=user.id).delete()
            
            reset_token = PasswordReset(
                user_id=user.id,
                token=token,
                expires_at=expires_at
            )
            db.session.add(reset_token)
            db.session.commit()
            
            # TODO: Send password reset email
            # For now, just show the token (in production, send via email)
            flash(f'Password reset token: {token}', 'info')
        
        # Always show success message to prevent email enumeration
        flash('If an account with that email exists, a password reset link has been sent', 'info')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/forgot_password.html')

@auth_bp.route('/reset-password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    """Reset password with token"""
    reset_record = PasswordReset.query.filter_by(token=token, used=False).first()
    
    if not reset_record or reset_record.is_expired():
        flash('Invalid or expired reset token', 'error')
        return redirect(url_for('auth.login'))
    
    if request.method == 'POST':
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        if not password or not confirm_password:
            flash('Both password fields are required', 'error')
            return render_template('auth/reset_password.html')
        
        if password != confirm_password:
            flash('Passwords do not match', 'error')
            return render_template('auth/reset_password.html')
        
        if len(password) < 8:
            flash('Password must be at least 8 characters long', 'error')
            return render_template('auth/reset_password.html')
        
        # Update user password
        user = User.query.get(reset_record.user_id)
        user.set_password(password)
        
        # Mark token as used
        reset_record.used = True
        
        db.session.commit()
        
        flash('Password has been reset successfully!', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/reset_password.html')

@auth_bp.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    """User profile page"""
    if request.method == 'POST':
        name = request.form.get('name')
        bio = request.form.get('bio')
        timezone = request.form.get('timezone')
        language = request.form.get('language')
        
        if name:
            current_user.name = name
        if bio is not None:
            current_user.bio = bio
        if timezone:
            current_user.timezone = timezone
        if language:
            current_user.language = language
        
        db.session.commit()
        flash('Profile updated successfully!', 'success')
        return redirect(url_for('auth.profile'))
    
    return render_template('auth/profile.html')

@auth_bp.route('/change-password', methods=['GET', 'POST'])
@login_required
def change_password():
    """Change password page"""
    if request.method == 'POST':
        current_password = request.form.get('current_password')
        new_password = request.form.get('new_password')
        confirm_password = request.form.get('confirm_password')
        
        if not all([current_password, new_password, confirm_password]):
            flash('All fields are required', 'error')
            return render_template('auth/change_password.html')
        
        if not current_user.check_password(current_password):
            flash('Current password is incorrect', 'error')
            return render_template('auth/change_password.html')
        
        if new_password != confirm_password:
            flash('New passwords do not match', 'error')
            return render_template('auth/change_password.html')
        
        if len(new_password) < 8:
            flash('Password must be at least 8 characters long', 'error')
            return render_template('auth/change_password.html')
        
        current_user.set_password(new_password)
        db.session.commit()
        
        flash('Password changed successfully!', 'success')
        return redirect(url_for('auth.profile'))
    
    return render_template('auth/change_password.html')

@auth_bp.route('/api-key', methods=['GET', 'POST'])
@login_required
def api_key():
    """API key management"""
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'regenerate':
            current_user.generate_api_key()
            db.session.commit()
            flash('API key regenerated successfully!', 'success')
        elif action == 'show':
            # Show API key (in production, this should be more secure)
            flash(f'Your API key: {current_user.api_key}', 'info')
        
        return redirect(url_for('auth.api_key'))
    
    return render_template('auth/api_key.html')

@auth_bp.route('/sessions')
@login_required
def sessions():
    """User sessions management"""
    user_sessions = UserSession.query.filter_by(
        user_id=current_user.id,
        is_active=True
    ).order_by(UserSession.created_at.desc()).all()
    
    return render_template('auth/sessions.html', sessions=user_sessions)

@auth_bp.route('/revoke-session/<int:session_id>', methods=['POST'])
@login_required
def revoke_session(session_id):
    """Revoke a user session"""
    session = UserSession.query.filter_by(
        id=session_id,
        user_id=current_user.id
    ).first()
    
    if session:
        session.is_active = False
        db.session.commit()
        flash('Session revoked successfully!', 'success')
    else:
        flash('Session not found', 'error')
    
    return redirect(url_for('auth.sessions')) 