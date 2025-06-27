#!/bin/bash
# ==============================================================================
# DiscoveryLastFM Docker Entrypoint Script
# Handles container initialization, configuration, and startup modes
# ==============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Default paths
CONFIG_PATH="${CONFIG_PATH:-/app/config/config.py}"
CONFIG_EXAMPLE_PATH="/app/config.example.py"
LOG_PATH="${LOG_PATH:-/app/logs}"
CACHE_PATH="${CACHE_PATH:-/app/cache}"

# Environment variables with defaults
DISCOVERY_MODE="${DISCOVERY_MODE:-sync}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"
DRY_RUN="${DRY_RUN:-false}"
DEBUG="${DEBUG:-false}"

# ==============================================================================
# User/Group Management
# ==============================================================================

setup_user() {
    # Support for PUID/PGID environment variables (like LinuxServer.io containers)
    local PUID=${PUID:-1000}
    local PGID=${PGID:-1000}
    
    log_debug "PUID=$PUID, PGID=$PGID, Current UID=$(id -u), Current GID=$(id -g)"
    
    # Only modify user if running as root and PUID/PGID are different from current
    if [[ "$(id -u)" -eq 0 ]]; then
        if [[ "$PUID" != "$(id -u discoverylastfm 2>/dev/null || echo 1000)" || "$PGID" != "$(id -g discoverylastfm 2>/dev/null || echo 1000)" ]]; then
            log_info "Modifying user permissions: PUID=$PUID, PGID=$PGID"
            
            # Modify the user and group IDs
            groupmod -o -g "$PGID" discoverylastfm 2>/dev/null || {
                log_warn "Failed to modify group ID, creating new group"
                groupadd -g "$PGID" discoverylastfm-runtime 2>/dev/null || true
            }
            usermod -o -u "$PUID" -g "$PGID" discoverylastfm 2>/dev/null || {
                log_warn "Failed to modify user ID"
            }
            
            # Ensure proper ownership of app directories (ignore failures on mounted volumes)
            chown -R "$PUID:$PGID" /app 2>/dev/null || log_warn "Cannot chown /app (mounted volume - this is normal on macOS/Windows)"
            
            log_info "User setup completed"
        else
            log_debug "PUID/PGID already match current user, no changes needed"
        fi
    else
        log_debug "Using default user (UID=$(id -u), GID=$(id -g))"
    fi
}

# ==============================================================================
# Configuration Management
# ==============================================================================

setup_configuration() {
    log_info "Setting up configuration..."
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$CONFIG_PATH")"
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_warn "Configuration file not found at $CONFIG_PATH"
        
        # Check for environment variables configuration
        if [[ -n "${LASTFM_USERNAME:-}" && -n "${LASTFM_API_KEY:-}" && -n "${MUSIC_SERVICE:-}" ]]; then
            log_info "Creating configuration from environment variables..."
            create_config_from_env
            # Update CONFIG_PATH environment variable if it was changed in create_config_from_env
            export CONFIG_PATH
        else
            log_warn "No environment variables found for configuration"
            
            # Copy example configuration
            if [[ -f "$CONFIG_EXAMPLE_PATH" ]]; then
                log_info "Copying example configuration to $CONFIG_PATH"
                cp "$CONFIG_EXAMPLE_PATH" "$CONFIG_PATH"
                log_warn "Please edit $CONFIG_PATH with your credentials before running"
            else
                log_error "No example configuration found at $CONFIG_EXAMPLE_PATH"
                exit 1
            fi
        fi
    else
        log_info "Configuration file found at $CONFIG_PATH"
    fi
    
    # Validate configuration exists and is readable
    if [[ ! -r "$CONFIG_PATH" ]]; then
        log_error "Configuration file is not readable: $CONFIG_PATH"
        exit 1
    fi
}

create_config_from_env() {
    # Check if we can write to the config directory
    local config_dir
    config_dir="$(dirname "$CONFIG_PATH")"
    
    # Test write access by attempting to create a test file
    if ! touch "$config_dir/.test_write" 2>/dev/null; then
        log_warn "Cannot write to config directory $config_dir. Using read-only fallback."
        # Use a temporary config in container filesystem
        CONFIG_PATH="/tmp/config.py"
        log_warn "Using temporary config at $CONFIG_PATH"
        # Ensure temp directory exists and is writable
        mkdir -p "$(dirname "$CONFIG_PATH")" 2>/dev/null || true
    else
        # Clean up test file
        rm -f "$config_dir/.test_write" 2>/dev/null || true
    fi
    
    # Attempt to write configuration with better error handling
    if ! cat > "$CONFIG_PATH" 2>/dev/null << EOF
# DiscoveryLastFM Configuration - Generated from Environment Variables
# Generated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# === MUSIC SERVICE SELECTION ===
MUSIC_SERVICE = "${MUSIC_SERVICE:-headphones}"

# === LAST.FM CONFIGURATION ===
LASTFM_USERNAME = "${LASTFM_USERNAME}"
LASTFM_API_KEY = "${LASTFM_API_KEY}"

# === HEADPHONES CONFIGURATION ===
$(if [[ "${MUSIC_SERVICE:-headphones}" == "headphones" ]]; then
cat << 'HPEOF'
HP_API_KEY = "${HP_API_KEY:-}"
HP_ENDPOINT = "${HP_ENDPOINT:-http://headphones:8181}"
HP_MAX_RETRIES = ${HP_MAX_RETRIES:-3}
HP_RETRY_DELAY = ${HP_RETRY_DELAY:-5}
HP_TIMEOUT = ${HP_TIMEOUT:-60}
HPEOF
fi)

# === LIDARR CONFIGURATION ===
$(if [[ "${MUSIC_SERVICE:-}" == "lidarr" ]]; then
cat << 'LIDARREOF'
LIDARR_API_KEY = "${LIDARR_API_KEY:-}"
LIDARR_ENDPOINT = "${LIDARR_ENDPOINT:-http://lidarr:8686}"
LIDARR_ROOT_FOLDER = "${LIDARR_ROOT_FOLDER:-/music}"
LIDARR_QUALITY_PROFILE_ID = ${LIDARR_QUALITY_PROFILE_ID:-1}
LIDARR_METADATA_PROFILE_ID = ${LIDARR_METADATA_PROFILE_ID:-1}
LIDARR_MONITOR_MODE = "${LIDARR_MONITOR_MODE:-all}"
LIDARR_SEARCH_ON_ADD = ${LIDARR_SEARCH_ON_ADD:-True}
LIDARR_MAX_RETRIES = ${LIDARR_MAX_RETRIES:-3}
LIDARR_RETRY_DELAY = ${LIDARR_RETRY_DELAY:-5}
LIDARR_TIMEOUT = ${LIDARR_TIMEOUT:-60}
LIDARREOF
fi)

# === DISCOVERY PARAMETERS ===
RECENT_MONTHS = ${RECENT_MONTHS:-3}
MIN_PLAYS = ${MIN_PLAYS:-20}
SIMILAR_MATCH_MIN = ${SIMILAR_MATCH_MIN:-0.46}
MAX_SIMILAR_PER_ART = ${MAX_SIMILAR_PER_ART:-20}
MAX_POP_ALBUMS = ${MAX_POP_ALBUMS:-5}
CACHE_TTL_HOURS = ${CACHE_TTL_HOURS:-24}

# === API RATE LIMITING ===
REQUEST_LIMIT = ${REQUEST_LIMIT:-0.2}
MBZ_DELAY = ${MBZ_DELAY:-1.1}

# === DEBUGGING ===
DEBUG_PRINT = ${DEBUG_PRINT:-False}

# === AUTO-UPDATE SYSTEM (v2.1.0+) ===
AUTO_UPDATE_ENABLED = ${AUTO_UPDATE_ENABLED:-False}
UPDATE_CHECK_INTERVAL_HOURS = ${UPDATE_CHECK_INTERVAL_HOURS:-24}
BACKUP_RETENTION_DAYS = ${BACKUP_RETENTION_DAYS:-7}
ALLOW_PRERELEASE_UPDATES = ${ALLOW_PRERELEASE_UPDATES:-False}
GITHUB_TOKEN = "${GITHUB_TOKEN:-}"
GITHUB_REPO_OWNER = "MrRobotoGit"
GITHUB_REPO_NAME = "DiscoveryLastFM"
EOF
    then
        log_info "Configuration created from environment variables at $CONFIG_PATH"
    else
        log_warn "Failed to write configuration file to $CONFIG_PATH. Trying final fallback."
        # Final fallback: try /tmp if not already there
        if [[ "$CONFIG_PATH" != "/tmp/config.py" ]]; then
            CONFIG_PATH="/tmp/config.py"
            log_warn "Using final fallback location: $CONFIG_PATH"
            # Create a simplified fallback configuration with proper variable expansion
            cat > "$CONFIG_PATH" 2>/dev/null << FALLBACK_EOF || {
                log_error "Final fallback configuration write failed"
                return 0  # Don't fail the container, continue anyway
            }
# DiscoveryLastFM Configuration - Generated from Environment Variables (Fallback)
# Generated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# === MUSIC SERVICE SELECTION ===
MUSIC_SERVICE = "${MUSIC_SERVICE:-headphones}"

# === LAST.FM CONFIGURATION ===
LASTFM_USERNAME = "${LASTFM_USERNAME}"
LASTFM_API_KEY = "${LASTFM_API_KEY}"

# === HEADPHONES CONFIGURATION ===
HP_API_KEY = "${HP_API_KEY:-}"
HP_ENDPOINT = "${HP_ENDPOINT:-http://headphones:8181}"

# === LIDARR CONFIGURATION ===
LIDARR_API_KEY = "${LIDARR_API_KEY:-}"
LIDARR_ENDPOINT = "${LIDARR_ENDPOINT:-http://lidarr:8686}"
LIDARR_ROOT_FOLDER = "${LIDARR_ROOT_FOLDER:-/music}"
LIDARR_QUALITY_PROFILE_ID = ${LIDARR_QUALITY_PROFILE_ID:-1}
LIDARR_METADATA_PROFILE_ID = ${LIDARR_METADATA_PROFILE_ID:-1}
LIDARR_MONITOR_MODE = "${LIDARR_MONITOR_MODE:-all}"
LIDARR_SEARCH_ON_ADD = ${LIDARR_SEARCH_ON_ADD:-True}

# === DISCOVERY PARAMETERS ===
RECENT_MONTHS = ${RECENT_MONTHS:-3}
MIN_PLAYS = ${MIN_PLAYS:-20}
SIMILAR_MATCH_MIN = ${SIMILAR_MATCH_MIN:-0.46}
MAX_SIMILAR_PER_ART = ${MAX_SIMILAR_PER_ART:-20}
MAX_POP_ALBUMS = ${MAX_POP_ALBUMS:-5}
CACHE_TTL_HOURS = ${CACHE_TTL_HOURS:-24}

# === API RATE LIMITING ===
REQUEST_LIMIT = ${REQUEST_LIMIT:-0.2}
MBZ_DELAY = ${MBZ_DELAY:-1.1}

# === DEBUGGING ===
DEBUG_PRINT = ${DEBUG_PRINT:-False}

# === AUTO-UPDATE SYSTEM (v2.1.0+) ===
AUTO_UPDATE_ENABLED = ${AUTO_UPDATE_ENABLED:-False}
UPDATE_CHECK_INTERVAL_HOURS = ${UPDATE_CHECK_INTERVAL_HOURS:-24}
BACKUP_RETENTION_DAYS = ${BACKUP_RETENTION_DAYS:-7}
ALLOW_PRERELEASE_UPDATES = ${ALLOW_PRERELEASE_UPDATES:-False}
GITHUB_TOKEN = "${GITHUB_TOKEN:-}"
GITHUB_REPO_OWNER = "MrRobotoGit"
GITHUB_REPO_NAME = "DiscoveryLastFM"
FALLBACK_EOF
        then
            log_info "Configuration created using final fallback at $CONFIG_PATH"
        else
            log_error "Final fallback also failed. Container may not function properly."
            # Don't return 1 here - let it continue and hope for the best
        fi
    fi
}

# ==============================================================================
# Logging Setup
# ==============================================================================

setup_logging() {
    log_info "Setting up logging directory..."
    
    # Create logs directory if it doesn't exist
    mkdir -p "$LOG_PATH"
    
    # Set proper permissions (ignore failures on mounted volumes)
    if chmod 755 "$LOG_PATH" 2>/dev/null; then
        log_debug "Set permissions on $LOG_PATH"
    else
        log_warn "Cannot set permissions on $LOG_PATH (mounted volume - this is normal on macOS/Windows)"
    fi
    
    # Try to create a test file to verify write access
    if touch "$LOG_PATH/.test_write" 2>/dev/null; then
        rm -f "$LOG_PATH/.test_write" 2>/dev/null
        log_debug "Log directory is writable at $LOG_PATH"
    else
        log_warn "Log directory $LOG_PATH may not be writable. Will attempt to continue."
        # Don't fail here, let the application handle logging issues
    fi
    
    log_debug "Log directory ready at $LOG_PATH"
}

# ==============================================================================
# Cache Setup
# ==============================================================================

setup_cache() {
    log_info "Setting up cache directory..."
    
    # Create cache directory if it doesn't exist
    mkdir -p "$CACHE_PATH"
    
    # Set proper permissions (ignore failures on mounted volumes)
    if chmod 755 "$CACHE_PATH" 2>/dev/null; then
        log_debug "Set permissions on $CACHE_PATH"
    else
        log_warn "Cannot set permissions on $CACHE_PATH (mounted volume - this is normal on macOS/Windows)"
    fi
    
    # Try to create a test file to verify write access
    if touch "$CACHE_PATH/.test_write" 2>/dev/null; then
        rm -f "$CACHE_PATH/.test_write" 2>/dev/null
        log_debug "Cache directory is writable at $CACHE_PATH"
    else
        log_warn "Cache directory $CACHE_PATH may not be writable. Will attempt to continue."
        # Don't fail here, let the application handle caching issues
    fi
    
    log_debug "Cache directory ready at $CACHE_PATH"
}

# ==============================================================================
# Cron Setup (for scheduled mode)
# ==============================================================================

setup_cron() {
    log_info "Setting up cron for scheduled execution..."
    
    # Create cron job
    echo "$CRON_SCHEDULE cd /app && python DiscoveryLastFM.py >> $LOG_PATH/cron.log 2>&1" | crontab -
    
    log_info "Cron job scheduled: $CRON_SCHEDULE"
    
    # Start cron daemon
    log_info "Starting cron daemon..."
    cron
}

# ==============================================================================
# Health Check
# ==============================================================================

health_check() {
    log_info "Performing health check..."
    
    # Check if configuration file exists and is readable
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_error "Configuration file not found: $CONFIG_PATH"
        return 1
    fi
    
    if [[ ! -r "$CONFIG_PATH" ]]; then
        log_error "Configuration file not readable: $CONFIG_PATH"
        return 1
    fi
    
    # Check configuration syntax using safer method
    if ! python -c "
import sys
try:
    with open('$CONFIG_PATH', 'r') as f:
        config_content = f.read()
    # Try to compile the configuration as Python code
    compile(config_content, '$CONFIG_PATH', 'exec')
    print('Config syntax OK')
except SyntaxError as e:
    print(f'Config syntax error: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Config validation error: {e}', file=sys.stderr)
    sys.exit(1)
" >/dev/null 2>&1; then
        log_error "Configuration validation failed"
        return 1
    fi
    
    # Check if DiscoveryLastFM.py exists and is executable
    if [[ ! -f "/app/DiscoveryLastFM.py" ]]; then
        log_error "DiscoveryLastFM.py not found"
        return 1
    fi
    
    log_info "Health check passed"
    return 0
}

# ==============================================================================
# Signal Handlers
# ==============================================================================

cleanup() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Kill background processes
    jobs -p | xargs -r kill
    
    # Stop cron if running
    pkill -f cron || true
    
    log_info "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# ==============================================================================
# Main Execution Logic
# ==============================================================================

main() {
    log_info "Starting DiscoveryLastFM Container..."
    log_info "Mode: $DISCOVERY_MODE"
    log_info "Debug: $DEBUG"
    
    # Setup steps
    setup_user
    setup_configuration
    setup_logging
    setup_cache
    
    # Health check
    if ! health_check; then
        log_error "Health check failed, exiting"
        exit 1
    fi
    
    # Change to app directory
    cd /app
    
    # Handle v2.1.0 CLI commands first
    if [[ "$1" == "--update" || "$1" == "--update-status" || "$1" == "--list-backups" || "$1" == "--version" || "$1" == "--cleanup" ]]; then
        log_info "Executing DiscoveryLastFM CLI command: $1"
        exec python DiscoveryLastFM.py "$@"
    fi
    
    case "$DISCOVERY_MODE" in
        "sync")
            log_info "Running one-time sync..."
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "DRY RUN MODE - No actual changes will be made"
                export DRY_RUN=true
            fi
            exec "$@"
            ;;
            
        "cron")
            log_info "Setting up scheduled execution..."
            setup_cron
            log_info "Container will run scheduled jobs. Keeping container alive..."
            # Keep container running for cron jobs
            while true; do
                sleep 60
            done
            ;;
            
        "daemon")
            log_info "Running in daemon mode..."
            while true; do
                log_info "Running scheduled discovery..."
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "DRY RUN MODE - No actual changes will be made"
                    export DRY_RUN=true
                fi
                python DiscoveryLastFM.py >> "$LOG_PATH/daemon.log" 2>&1 || log_error "Discovery run failed"
                
                # Calculate sleep time (default 3 hours)
                SLEEP_HOURS=${SLEEP_HOURS:-3}
                SLEEP_SECONDS=$((SLEEP_HOURS * 3600))
                log_info "Sleeping for $SLEEP_HOURS hours..."
                sleep $SLEEP_SECONDS
            done
            ;;
            
        "test")
            log_info "Running in test mode..."
            python -c "
import sys
sys.path.append('/app')
try:
    exec(open('$CONFIG_PATH').read())
    print('✅ Configuration loaded successfully')
    
    # Test imports
    from services.factory import MusicServiceFactory
    print('✅ Service factory imported successfully')
    
    # Test service creation (dry run)
    config_dict = {k: v for k, v in globals().items() if k.isupper()}
    service_type = config_dict.get('MUSIC_SERVICE', 'headphones')
    print(f'✅ Service type: {service_type}')
    
    print('✅ Test mode completed successfully')
except Exception as e:
    print(f'❌ Test failed: {e}')
    sys.exit(1)
"
            ;;
            
        *)
            log_error "Unknown mode: $DISCOVERY_MODE"
            log_info "Available modes: sync, cron, daemon, test"
            exit 1
            ;;
    esac
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Ensure we're running as the correct user
if [[ "$(id -u)" -eq 0 ]]; then
    log_warn "Running as root, this is not recommended for security"
fi

# Run main function with all arguments
main "$@"