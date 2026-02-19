# ==============================================================================
# DiscoveryLastFM Docker Configuration Template
# This file is used inside the Docker container
# Copy to config.py and customize with your values
# ==============================================================================

import os

# =============================================================================
# MUSIC SERVICE SELECTION
# =============================================================================
# Choose your music management service: "headphones" or "lidarr"
MUSIC_SERVICE = os.getenv("MUSIC_SERVICE", "lidarr")

# =============================================================================
# LAST.FM CONFIGURATION (REQUIRED)
# =============================================================================
LASTFM_USERNAME = os.getenv("LASTFM_USERNAME", "your_lastfm_username")
LASTFM_API_KEY = os.getenv("LASTFM_API_KEY", "your_lastfm_api_key")

# =============================================================================
# LIDARR CONFIGURATION (Required if MUSIC_SERVICE=lidarr)
# =============================================================================
LIDARR_API_KEY = os.getenv("LIDARR_API_KEY", "your_lidarr_api_key")
LIDARR_ENDPOINT = os.getenv("LIDARR_ENDPOINT", "http://lidarr:8686")
LIDARR_ROOT_FOLDER = os.getenv("LIDARR_ROOT_FOLDER", "/music")

# Lidarr Profile Configuration
LIDARR_QUALITY_PROFILE_ID = int(os.getenv("LIDARR_QUALITY_PROFILE_ID", "1"))
LIDARR_METADATA_PROFILE_ID = int(os.getenv("LIDARR_METADATA_PROFILE_ID", "1"))

# Lidarr Behavior Configuration
LIDARR_MONITOR_MODE = os.getenv("LIDARR_MONITOR_MODE", "all")
LIDARR_SEARCH_ON_ADD = os.getenv("LIDARR_SEARCH_ON_ADD", "true").lower() == "true"
LIDARR_ALBUM_FOLDER_FORMAT = os.getenv("LIDARR_ALBUM_FOLDER_FORMAT", "{Artist Name} - {Album Title}")

# Lidarr Advanced Options
LIDARR_MAX_RETRIES = int(os.getenv("LIDARR_MAX_RETRIES", "3"))
LIDARR_RETRY_DELAY = int(os.getenv("LIDARR_RETRY_DELAY", "5"))
LIDARR_TIMEOUT = int(os.getenv("LIDARR_TIMEOUT", "60"))

# =============================================================================
# HEADPHONES CONFIGURATION (Required if MUSIC_SERVICE=headphones)
# =============================================================================
HP_API_KEY = os.getenv("HP_API_KEY", "your_headphones_api_key")
HP_ENDPOINT = os.getenv("HP_ENDPOINT", "http://headphones:8181")

# Headphones Advanced Options
HP_MAX_RETRIES = int(os.getenv("HP_MAX_RETRIES", "3"))
HP_RETRY_DELAY = int(os.getenv("HP_RETRY_DELAY", "5"))
HP_TIMEOUT = int(os.getenv("HP_TIMEOUT", "60"))

# =============================================================================
# DISCOVERY PARAMETERS
# =============================================================================
RECENT_MONTHS = int(os.getenv("RECENT_MONTHS", "3"))
MIN_PLAYS = int(os.getenv("MIN_PLAYS", "20"))
SIMILAR_MATCH_MIN = float(os.getenv("SIMILAR_MATCH_MIN", "0.46"))
MAX_SIMILAR_PER_ART = int(os.getenv("MAX_SIMILAR_PER_ART", "20"))
MAX_POP_ALBUMS = int(os.getenv("MAX_POP_ALBUMS", "5"))
CACHE_TTL_HOURS = int(os.getenv("CACHE_TTL_HOURS", "24"))

# =============================================================================
# API RATE LIMITING
# =============================================================================
REQUEST_LIMIT = float(os.getenv("REQUEST_LIMIT", "0.2"))
MBZ_DELAY = float(os.getenv("MBZ_DELAY", "1.1"))

# =============================================================================
# DEBUGGING AND LOGGING
# =============================================================================
DEBUG_PRINT = os.getenv("DEBUG", "false").lower() == "true"

# =============================================================================
# CONTAINER-SPECIFIC SETTINGS
# =============================================================================
# Override paths for container environment
LOG_PATH = os.getenv("LOG_PATH", "/app/logs")
CACHE_PATH = os.getenv("CACHE_PATH", "/app/cache")

# Container operation mode
CONTAINER_MODE = os.getenv("DISCOVERY_MODE", "sync")
DRY_RUN_MODE = os.getenv("DRY_RUN", "false").lower() == "true"

# =============================================================================
# FILTERING CONFIGURATION
# =============================================================================
# These secondary types are excluded from album selection
EXCLUDED_SECONDARY_TYPES = {
    "Compilation", "Live", "Remix", "Soundtrack", "DJ-Mix",
    "Mixtape/Street", "EP", "Single", "Interview", "Audiobook",
    "Demo", "Bootleg"
}

# Alias for backward compatibility
BAD_SEC = EXCLUDED_SECONDARY_TYPES

# =============================================================================
# OPTIONAL: REDIS CACHING (if Redis service is available)
# =============================================================================
ENABLE_REDIS_CACHE = os.getenv("ENABLE_REDIS_CACHE", "false").lower() == "true"
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_DB = int(os.getenv("REDIS_DB", "0"))

# =============================================================================
# AUTO-UPDATE SYSTEM (v2.1.0+ Features)
# =============================================================================
# Enable automatic update checking
AUTO_UPDATE_ENABLED = os.getenv("AUTO_UPDATE_ENABLED", "false").lower() == "true"

# How often to check for updates (in hours)
UPDATE_CHECK_INTERVAL_HOURS = int(os.getenv("UPDATE_CHECK_INTERVAL_HOURS", "24"))

# How long to keep backup files (in days)
BACKUP_RETENTION_DAYS = int(os.getenv("BACKUP_RETENTION_DAYS", "7"))

# Allow installation of pre-release versions
ALLOW_PRERELEASE_UPDATES = os.getenv("ALLOW_PRERELEASE_UPDATES", "false").lower() == "true"

# GitHub personal access token for higher API rate limits (optional)
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")

# Auto-update repository information
GITHUB_REPO_OWNER = "MrRobotoGit"
GITHUB_REPO_NAME = "DiscoveryLastFM"

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================
def validate_configuration():
    """Validate configuration for Docker environment"""
    errors = []
    
    # Check required Last.fm credentials
    if not LASTFM_USERNAME or LASTFM_USERNAME == "your_lastfm_username":
        errors.append("LASTFM_USERNAME is required")
    
    if not LASTFM_API_KEY or LASTFM_API_KEY == "your_lastfm_api_key":
        errors.append("LASTFM_API_KEY is required")
    
    # Check service-specific configuration
    if MUSIC_SERVICE == "lidarr":
        if not LIDARR_API_KEY or LIDARR_API_KEY == "your_lidarr_api_key":
            errors.append("LIDARR_API_KEY is required when using Lidarr")
        if not LIDARR_ENDPOINT:
            errors.append("LIDARR_ENDPOINT should be configured")
    
    elif MUSIC_SERVICE == "headphones":
        if not HP_API_KEY or HP_API_KEY == "your_headphones_api_key":
            errors.append("HP_API_KEY is required when using Headphones")
        if not HP_ENDPOINT:
            errors.append("HP_ENDPOINT should be configured")
    
    else:
        errors.append(f"Unknown MUSIC_SERVICE: {MUSIC_SERVICE} (must be 'lidarr' or 'headphones')")
    
    # Validate numeric ranges
    if not 1 <= RECENT_MONTHS <= 12:
        errors.append("RECENT_MONTHS must be between 1 and 12")
    
    if not 1 <= MIN_PLAYS <= 1000:
        errors.append("MIN_PLAYS must be between 1 and 1000")
    
    if not 0.0 <= SIMILAR_MATCH_MIN <= 1.0:
        errors.append("SIMILAR_MATCH_MIN must be between 0.0 and 1.0")
    
    if not 1 <= MAX_SIMILAR_PER_ART <= 100:
        errors.append("MAX_SIMILAR_PER_ART must be between 1 and 100")
    
    if not 1 <= MAX_POP_ALBUMS <= 50:
        errors.append("MAX_POP_ALBUMS must be between 1 and 50")
    
    if not 1 <= CACHE_TTL_HOURS <= 168:
        errors.append("CACHE_TTL_HOURS must be between 1 and 168 (1 week)")
    
    # Validate auto-update settings
    if not 1 <= UPDATE_CHECK_INTERVAL_HOURS <= 168:
        errors.append("UPDATE_CHECK_INTERVAL_HOURS must be between 1 and 168 hours")
    
    if not 1 <= BACKUP_RETENTION_DAYS <= 30:
        errors.append("BACKUP_RETENTION_DAYS must be between 1 and 30 days")
    
    if errors:
        raise ValueError(f"Configuration validation failed:\n- " + "\n- ".join(errors))
    
    return True

# =============================================================================
# CONTAINER ENVIRONMENT INFO
# =============================================================================
def get_container_info():
    """Get container environment information for debugging"""
    return {
        "music_service": MUSIC_SERVICE,
        "container_mode": CONTAINER_MODE,
        "dry_run": DRY_RUN_MODE,
        "debug": DEBUG_PRINT,
        "log_path": LOG_PATH,
        "cache_path": CACHE_PATH,
        "redis_enabled": ENABLE_REDIS_CACHE,
        "auto_update_enabled": AUTO_UPDATE_ENABLED,
        "update_check_interval": UPDATE_CHECK_INTERVAL_HOURS,
        "backup_retention": BACKUP_RETENTION_DAYS,
        "allow_prerelease": ALLOW_PRERELEASE_UPDATES,
        "validation_passed": True
    }

# =============================================================================
# AUTO-VALIDATION (if run directly)
# =============================================================================
if __name__ == "__main__":
    try:
        validate_configuration()
        print("✅ Configuration validation passed")
        
        import json
        info = get_container_info()
        print("📋 Container configuration:")
        print(json.dumps(info, indent=2))
        
    except Exception as e:
        print(f"❌ Configuration validation failed: {e}")
        exit(1)
