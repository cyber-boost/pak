// PAK.sh Flask Web Application - Main JavaScript

// Utility functions
const PakApp = {
    // Show notification
    showNotification: function(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            notification.remove();
        }, 5000);
    },
    
    // Confirm action
    confirmAction: function(message) {
        return confirm(message);
    },
    
    // Format date
    formatDate: function(date) {
        return new Date(date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },
    
    // Copy to clipboard
    copyToClipboard: function(text) {
        navigator.clipboard.writeText(text).then(() => {
            this.showNotification('Copied to clipboard!', 'success');
        }).catch(() => {
            this.showNotification('Failed to copy to clipboard', 'error');
        });
    },
    
    // Toggle element visibility
    toggleElement: function(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.style.display = element.style.display === 'none' ? 'block' : 'none';
        }
    },
    
    // Load more content (for pagination)
    loadMore: function(url, containerId, page = 1) {
        fetch(`${url}?page=${page}`)
            .then(response => response.json())
            .then(data => {
                const container = document.getElementById(containerId);
                if (container && data.content) {
                    container.innerHTML += data.content;
                }
            })
            .catch(error => {
                console.error('Error loading more content:', error);
                this.showNotification('Failed to load more content', 'error');
            });
    }
};

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Add notification styles
    const style = document.createElement('style');
    style.textContent = `
        .notification {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem;
            border-radius: 6px;
            color: white;
            z-index: 1000;
            animation: slideIn 0.3s ease-out;
        }
        
        .notification-success {
            background: var(--accent-green);
        }
        
        .notification-error {
            background: var(--accent-red);
        }
        
        .notification-info {
            background: var(--accent-blue);
        }
        
        .notification-warning {
            background: #F59E0B;
        }
        
        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
    `;
    document.head.appendChild(style);
    
    // Initialize any page-specific functionality
    if (typeof initPage !== 'undefined') {
        initPage();
    }
});

// Export for use in other scripts
window.PakApp = PakApp; 