#!/bin/bash
# ==============================================================================
# DiscoveryLastFM Health Check Script
# Used by Docker HEALTHCHECK and monitoring systems
# ==============================================================================

set -euo pipefail

# Default paths
CONFIG_PATH="${CONFIG_PATH:-/app/config.py}"
LOG_PATH="${LOG_PATH:-/app/logs}"
# APP_PID_FILE="/tmp/discoverylastfm.pid"  # Currently unused

# Health check timeout
TIMEOUT=${HEALTH_CHECK_TIMEOUT:-10}

# Exit codes
EXIT_OK=0
EXIT_WARNING=1
EXIT_CRITICAL=2
EXIT_UNKNOWN=3

log_info() {
    echo "[HEALTH] $1"
}

log_error() {
    echo "[HEALTH ERROR] $1" >&2
}

# ==============================================================================
# Health Check Functions
# ==============================================================================

check_configuration() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_error "Configuration file not found: $CONFIG_PATH"
        return $EXIT_CRITICAL
    fi
    
    if [[ ! -r "$CONFIG_PATH" ]]; then
        log_error "Configuration file not readable: $CONFIG_PATH"
        return $EXIT_CRITICAL
    fi
    
    # Test configuration loading
    if ! timeout "$TIMEOUT" python -c "exec(open('$CONFIG_PATH').read()); print('Config OK')" >/dev/null 2>&1; then
        log_error "Configuration validation failed"
        return $EXIT_CRITICAL
    fi
    
    return $EXIT_OK
}

check_application_files() {
    local required_files=(
        "/app/DiscoveryLastFM.py"
        "/app/services/__init__.py"
        "/app/services/base.py"
        "/app/services/factory.py"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file missing: $file"
            return $EXIT_CRITICAL
        fi
    done
    
    return $EXIT_OK
}

check_python_imports() {
    # Test critical imports
    if ! timeout "$TIMEOUT" python -c "
import sys
sys.path.append('/app')

# Test configuration loading
exec(open('$CONFIG_PATH').read())

# Test service imports
from services.factory import MusicServiceFactory
from services.base import MusicServiceBase

print('Imports OK')
" >/dev/null 2>&1; then
        log_error "Python imports failed"
        return $EXIT_CRITICAL
    fi
    
    return $EXIT_OK
}

check_directories() {
    local required_dirs=(
        "/app"
        "$LOG_PATH"
        "$(dirname "$CONFIG_PATH")"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Required directory missing: $dir"
            return $EXIT_CRITICAL
        fi
        
        if [[ ! -w "$dir" ]]; then
            log_error "Directory not writable: $dir"
            return $EXIT_WARNING
        fi
    done
    
    return $EXIT_OK
}

check_external_services() {
    # This is a lightweight check - just verify configuration has required fields
    local service_ok=true
    
    # Extract service type from config
    local music_service
    music_service=$(python -c "
exec(open('$CONFIG_PATH').read())
print(globals().get('MUSIC_SERVICE', 'headphones'))
" 2>/dev/null) || {
        log_error "Cannot determine music service from config"
        return $EXIT_CRITICAL
    }
    
    # Check service-specific required config
    case "$music_service" in
        "headphones")
            if ! python -c "
exec(open('$CONFIG_PATH').read())
required = ['HP_API_KEY', 'HP_ENDPOINT']
missing = [k for k in required if not globals().get(k)]
if missing:
    raise Exception(f'Missing HP config: {missing}')
print('HP config OK')
" >/dev/null 2>&1; then
                log_error "Headphones configuration incomplete"
                service_ok=false
            fi
            ;;
            
        "lidarr")
            if ! python -c "
exec(open('$CONFIG_PATH').read())
required = ['LIDARR_API_KEY', 'LIDARR_ENDPOINT', 'LIDARR_ROOT_FOLDER']
missing = [k for k in required if not globals().get(k)]
if missing:
    raise Exception(f'Missing Lidarr config: {missing}')
print('Lidarr config OK')
" >/dev/null 2>&1; then
                log_error "Lidarr configuration incomplete"
                service_ok=false
            fi
            ;;
            
        *)
            log_error "Unknown music service: $music_service"
            service_ok=false
            ;;
    esac
    
    # Check Last.fm config
    if ! python -c "
exec(open('$CONFIG_PATH').read())
required = ['LASTFM_USERNAME', 'LASTFM_API_KEY']
missing = [k for k in required if not globals().get(k)]
if missing:
    raise Exception(f'Missing Last.fm config: {missing}')
print('Last.fm config OK')
" >/dev/null 2>&1; then
        log_error "Last.fm configuration incomplete"
        service_ok=false
    fi
    
    if [[ "$service_ok" == "false" ]]; then
        return $EXIT_CRITICAL
    fi
    
    return $EXIT_OK
}

check_disk_space() {
    local min_free_mb=100
    local log_dir_free
    
    # Check free space in log directory
    log_dir_free=$(df "$LOG_PATH" | awk 'NR==2 {print int($4/1024)}')
    
    if [[ $log_dir_free -lt $min_free_mb ]]; then
        log_error "Low disk space in log directory: ${log_dir_free}MB free (minimum: ${min_free_mb}MB)"
        return $EXIT_WARNING
    fi
    
    return $EXIT_OK
}

check_recent_activity() {
    local log_file="$LOG_PATH/discover.log"
    local max_age_hours=25  # Allow for slightly over 24 hours
    
    if [[ -f "$log_file" ]]; then
        # Find the last modification time
        local last_modified
        last_modified=$(stat -c %Y "$log_file" 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        local age_hours
        age_hours=$(( (current_time - last_modified) / 3600 ))
        
        if [[ $age_hours -gt $max_age_hours ]]; then
            log_error "Log file hasn't been updated in ${age_hours} hours (expected: <${max_age_hours}h)"
            return $EXIT_WARNING
        fi
    fi
    
    return $EXIT_OK
}

# ==============================================================================
# Main Health Check
# ==============================================================================

main() {
    local overall_status=$EXIT_OK
    local checks=(
        "check_configuration:Configuration"
        "check_application_files:Application Files"
        "check_python_imports:Python Imports"
        "check_directories:Directories"
        "check_external_services:External Services Config"
        "check_disk_space:Disk Space"
        "check_recent_activity:Recent Activity"
    )
    
    log_info "Starting health check..."
    
    for check in "${checks[@]}"; do
        local func="${check%%:*}"
        local name="${check##*:}"
        
        log_info "Checking: $name"
        
        if $func; then
            log_info "✅ $name: OK"
        else
            local status=$?
            case $status in
                "$EXIT_WARNING")
                    log_info "⚠️  $name: WARNING"
                    if [[ $overall_status -eq $EXIT_OK ]]; then
                        overall_status=$EXIT_WARNING
                    fi
                    ;;
                "$EXIT_CRITICAL")
                    log_error "❌ $name: CRITICAL"
                    overall_status=$EXIT_CRITICAL
                    ;;
                *)
                    log_error "❓ $name: UNKNOWN"
                    if [[ $overall_status -ne $EXIT_CRITICAL ]]; then
                        overall_status=$EXIT_UNKNOWN
                    fi
                    ;;
            esac
        fi
    done
    
    # Final status
    case $overall_status in
        "$EXIT_OK")
            log_info "🎉 Health check PASSED - All systems operational"
            ;;
        "$EXIT_WARNING")
            log_info "⚠️  Health check completed with WARNINGS"
            ;;
        "$EXIT_CRITICAL")
            log_error "❌ Health check FAILED - Critical issues detected"
            ;;
        *)
            log_error "❓ Health check completed with UNKNOWN status"
            ;;
    esac
    
    exit $overall_status
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Handle command line options
case "${1:-health}" in
    "health"|"check")
        main
        ;;
    "quick")
        log_info "Quick health check..."
        check_configuration && check_application_files
        log_info "✅ Quick check passed"
        ;;
    "config")
        log_info "Configuration check only..."
        check_configuration && check_external_services
        log_info "✅ Configuration check passed"
        ;;
    *)
        echo "Usage: $0 [health|quick|config]"
        echo "  health: Full health check (default)"
        echo "  quick:  Quick check (config + files)"
        echo "  config: Configuration check only"
        exit $EXIT_UNKNOWN
        ;;
esac
