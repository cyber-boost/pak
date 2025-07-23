#!/bin/bash
# PAK.sh Embed Demo - Shows how to integrate telemetry into user packages

# This is an example of how to integrate embed.sh into a user package
# The embed.sh script provides telemetry and engagement tracking

# Demo package configuration
PACKAGE_NAME="my-awesome-tool"
PACKAGE_VERSION="1.2.3"
WEBHOOK_URL="https://pak.sh/webhook/telemetry"

# Set environment variables for embed.sh
export PAK_EMBED_PACKAGE_NAME="$PACKAGE_NAME"
export PAK_EMBED_PACKAGE_VERSION="$PACKAGE_VERSION"
export PAK_EMBED_WEBHOOK_URL="$WEBHOOK_URL"
export PAK_EMBED_ENABLED="true"

# Source the embed script (this would be included in the user's package)
# In a real package, you would copy embed.sh to the package directory
EMBED_SCRIPT="$(dirname "$0")/embed.sh"

if [[ ! -f "$EMBED_SCRIPT" ]]; then
    echo "Error: embed.sh not found. Please ensure it's in the same directory."
    exit 1
fi

# Source the embed script to get access to its functions
source "$EMBED_SCRIPT"

# Initialize the embed system
embed_init

echo "🚀 Starting $PACKAGE_NAME v$PACKAGE_VERSION with telemetry enabled"
echo "📊 Telemetry data will be sent to: $WEBHOOK_URL"
echo ""

# Track session start
embed_track_session_start

# Demo: Track package installation
echo "📦 Installing $PACKAGE_NAME..."
sleep 1
embed_track_install "demo_install" "true" ""

# Demo: Track command execution
echo "⚡ Running main command..."
start_time=$(date +%s)
sleep 2
end_time=$(date +%s)
duration=$((end_time - start_time))
embed_track_command "main" '["--verbose", "--output=json"]' "true" "$duration"

# Demo: Track feature usage
echo "🔧 Using advanced feature..."
embed_track_feature "advanced_processing" '{"mode": "fast", "threads": 4}'

# Demo: Track successful operation
echo "✅ Operation completed successfully"
embed_track_event "operation_complete" '{"result": "success", "processing_time": 2.5}'

# Demo: Track error (simulated)
echo "⚠️ Simulating an error..."
embed_track_error "validation_error" "Invalid input format" '{"input": "malformed_data", "expected": "json"}'

# Demo: Track user interaction
echo "👤 User interacted with interface..."
embed_track_feature "ui_interaction" '{"action": "button_click", "element": "export_button"}'

# Show current statistics
echo ""
echo "📊 Current Telemetry Statistics:"
embed_get_stats

# Show status
echo ""
echo "📋 Embed System Status:"
embed_status

# Track session end
session_duration=$((end_time - start_time))
embed_track_session_end "$session_duration"

echo ""
echo "✅ Demo completed! Check the telemetry dashboard at:"
echo "   https://pak.sh/telemetry"
echo ""
echo "📁 Local telemetry data stored in: ~/.pak-embed/"
echo "🗄️ SQLite database: ~/.pak-embed/telemetry.db"
echo "📝 Log file: ~/.pak-embed/telemetry.log" 