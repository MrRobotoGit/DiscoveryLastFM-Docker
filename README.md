# DiscoveryLastFM Docker 🐳

[![Docker Pulls](https://img.shields.io/docker/pulls/mrrobotogit/discoverylastfm)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![Docker Image Size](https://img.shields.io/docker/image-size/mrrobotogit/discoverylastfm/latest)](https://hub.docker.com/r/mrrobotogit/discoverylastfm)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/MrRobotoGit/DiscoveryLastFM-Docker/docker-publish.yml)](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/actions)
[![License](https://img.shields.io/github/license/MrRobotoGit/DiscoveryLastFM-Docker)](LICENSE)

Containerized version of [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM) - an automated music discovery tool that integrates Last.fm with music management systems (Lidarr/Headphones).

> 🎉 **Recently Simplified!** This Docker setup has been streamlined for better usability - simpler configuration, essential services only, and improved docker-compose commands.

## 🆕 What's New in v2.1.0 Docker Setup

**DiscoveryLastFM v2.1.0 with Auto-Update System + Simplified Docker!**

### 🚀 New v2.1.0 Features:
- ✅ **Auto-Update System**: GitHub releases monitoring with backup and rollback
- ✅ **CLI Commands**: `--update`, `--update-status`, `--list-backups`, `--version`, `--cleanup`
- ✅ **Safe Updates**: Automatic backup creation and verification
- ✅ **Configurable**: Auto-update intervals, backup retention, pre-release support

### 🐳 Docker Improvements:
- ✅ **Simpler docker-compose.yml**: From 281 to ~93 lines
- ✅ **Auto-update ready**: All v2.1.0 environment variables supported
- ✅ **CLI support**: New commands work in Docker environment
- ✅ **Core services**: DiscoveryLastFM + Redis cache
- ✅ **Modern docker compose commands**: Full support for latest Docker Compose
- ✅ **Streamlined CI/CD**: Production-focused workflow for reliable builds

**What was removed:**
- Optional services (Watchtower, Portainer) - can be added separately if needed
- Complex networking configurations - uses Docker defaults
- Advanced resource limits - simplified for most use cases
- Lidarr service from compose (integrate with existing external instance)

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

#### Standard Setup
```bash
# Download the simplified setup files
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/.env.example

# Configure your environment (minimal setup required)
cp .env.example .env
nano .env  # Edit with your Last.fm and Lidarr/Headphones credentials

# ⚠️ IMPORTANT: Set these required variables in .env:
# AUTO_UPDATE_ENABLED=true
# UPDATE_CHECK_INTERVAL_HOURS=24

# Start the streamlined stack (DiscoveryLastFM + Redis)
# Note: First run will build the image with bash included
docker compose up -d
```

#### Synology Docker Setup

**Option A: Manual Setup (Recommended)**
1. Download the image `mrrobotogit/discoverylastfm:latest` from Registry
2. Follow the detailed [Synology Setup Instructions](synology-instructions.md)
3. Manually add the required environment variables

**Option B: Import Template**
```bash
# Download the Synology container template
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/synology-template.json

# Import in Synology Docker:
# 1. Go to Container tab
# 2. Click Settings → Import 
# 3. Upload synology-template.json
# 4. Edit environment variables with your credentials
```

**Required Variables to Set:**
- `LASTFM_USERNAME`: Your Last.fm username
- `LASTFM_API_KEY`: Your Last.fm API key
- `LIDARR_API_KEY`: Your Lidarr API key

### Option 2: Docker Run

#### With Lidarr (Recommended)
```bash
# First, build the image with bash included
docker build -t discoverylastfm-local .

# Then run the container
docker run -d \
  --name discoverylastfm \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=lidarr \
  -e LIDARR_API_KEY=your_lidarr_key \
  -e LIDARR_ENDPOINT=http://your-lidarr:8686 \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  -v discoverylastfm_config:/app/config \
  -v discoverylastfm_logs:/app/logs \
  discoverylastfm-local:latest
```

#### With Headphones
```bash
# First, build the image with bash included
docker build -t discoverylastfm-local .

# Then run the container
docker run -d \
  --name discoverylastfm \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e MUSIC_SERVICE=headphones \
  -e HP_API_KEY=your_headphones_key \
  -e HP_ENDPOINT=http://your-headphones:8181 \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  -v discoverylastfm_config:/app/config \
  -v discoverylastfm_logs:/app/logs \
  discoverylastfm-local:latest
```

### Option 3: Automated Setup Script

```bash
# Clone the repository
git clone https://github.com/MrRobotoGit/DiscoveryLastFM-Docker.git
cd DiscoveryLastFM-Docker

# Run the automated setup
./scripts/setup-docker.sh
```

## 📋 Features

### ✨ What's Included

- **🎵 DiscoveryLastFM**: Main application for music discovery
- **⚡ Redis Cache**: Improved performance with caching layer
- **📱 Multi-Architecture**: AMD64 and ARM64 (Raspberry Pi) support
- **🔧 Simple Configuration**: Streamlined environment-based setup
- **📈 Performance Optimized**: Multi-stage build, minimal base image
- **📊 Health Monitoring**: Built-in health checks and monitoring

### 🛠️ Integration Support

- **Lidarr**: Modern music collection manager
- **Headphones**: Alternative music management system
- **Last.fm API**: Music discovery and statistics

## 🏗️ Simplified Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Last.fm API   │────│ DiscoveryLastFM │────│  Lidarr/Headphones │
└─────────────────┘    │    + Redis      │    └─────────────────┘
                       └─────────────────┘
```

## 📖 Configuration

### Required Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `LASTFM_USERNAME` | Your Last.fm username | `john_doe` |
| `LASTFM_API_KEY` | Last.fm API key | `abc123def456...` |
| `MUSIC_SERVICE` | Music service (`lidarr` or `headphones`) | `lidarr` |

### Lidarr Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LIDARR_API_KEY` | Lidarr API key | Required |
| `LIDARR_ENDPOINT` | Lidarr server URL | `http://lidarr:8686` |
| `LIDARR_ROOT_FOLDER` | Music library path | `/music` |
| `LIDARR_QUALITY_PROFILE_ID` | Quality profile ID | `1` |
| `LIDARR_METADATA_PROFILE_ID` | Metadata profile ID | `1` |

### Headphones Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `HP_API_KEY` | Headphones API key | Required |
| `HP_ENDPOINT` | Headphones server URL | `http://headphones:8181` |

### Discovery Parameters

| Variable | Description | Default | Range |
|----------|-------------|---------|-------|
| `RECENT_MONTHS` | Months of recent plays | `3` | 1-12 |
| `MIN_PLAYS` | Minimum plays per artist | `20` | 1-1000 |
| `SIMILAR_MATCH_MIN` | Similarity threshold | `0.46` | 0.0-1.0 |
| `MAX_SIMILAR_PER_ART` | Max similar artists | `20` | 1-100 |
| `MAX_POP_ALBUMS` | Max albums per artist | `5` | 1-50 |

### Container Operation

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `DISCOVERY_MODE` | Operation mode | `cron` | `sync`, `cron`, `daemon`, `test` |
| `CRON_SCHEDULE` | Cron schedule | `0 3 * * *` | Cron expression |
| `DRY_RUN` | Test mode (no changes) | `false` | `true`, `false` |
| `DEBUG` | Debug logging | `false` | `true`, `false` |

### Auto-Update System (v2.1.0+) ⚠️ **REQUIRED**

> **⚠️ IMPORTANT**: The following variables are **REQUIRED** for the container to start properly:

| Variable | Description | Default | Required | Options |
|----------|-------------|---------|----------|---------|
| `AUTO_UPDATE_ENABLED` | Enable auto-update checking | `false` | **YES** | `true`, `false` |
| `UPDATE_CHECK_INTERVAL_HOURS` | Check interval in hours | `24` | **YES** | 1-168 |
| `BACKUP_RETENTION_DAYS` | Backup retention in days | `7` | NO | 1-30 |
| `ALLOW_PRERELEASE_UPDATES` | Include pre-releases | `false` | NO | `true`, `false` |
| `GITHUB_TOKEN` | GitHub API token | `` | NO | Optional for higher limits |

**🚨 Container Startup Error**: If `AUTO_UPDATE_ENABLED` and `UPDATE_CHECK_INTERVAL_HOURS` are not set, the container will fail to start with:
```
/usr/local/bin/docker-entrypoint.sh: line 270: syntax error near unexpected token 'else'
```

## 🎯 Operation Modes

### Sync Mode (One-time)
```bash
# Build image first
docker build -t discoverylastfm-local .

# Run in sync mode
docker run --rm \
  -e DISCOVERY_MODE=sync \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  discoverylastfm-local:latest
```

### Cron Mode (Scheduled)
```yaml
# docker-compose.yml
services:
  discoverylastfm:
    environment:
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 3 * * *  # Daily at 3 AM
```

### Daemon Mode (Continuous)
```yaml
services:
  discoverylastfm:
    environment:
      - DISCOVERY_MODE=daemon
      - SLEEP_HOURS=6  # Run every 6 hours
```

### Test Mode (Validation)
```bash
# Build image first
docker build -t discoverylastfm-local .

# Run in test mode
docker run --rm \
  -e DISCOVERY_MODE=test \
  -e LASTFM_USERNAME=your_username \
  -e LASTFM_API_KEY=your_api_key \
  -e AUTO_UPDATE_ENABLED=true \
  -e UPDATE_CHECK_INTERVAL_HOURS=24 \
  discoverylastfm-local:latest
```

### Auto-Update CLI Commands (v2.1.0+)
```bash
# Check update status
docker compose exec discoverylastfm python DiscoveryLastFM.py --update-status

# Install available updates
docker compose exec discoverylastfm python DiscoveryLastFM.py --update

# List available backups
docker compose exec discoverylastfm python DiscoveryLastFM.py --list-backups

# Check version
docker compose exec discoverylastfm python DiscoveryLastFM.py --version

# Clean temporary files
docker compose exec discoverylastfm python DiscoveryLastFM.py --cleanup
```

## 📦 Docker Compose Setup

### Default Setup (Simplified)
```bash
docker compose up -d
```
Includes: DiscoveryLastFM + Redis cache

### Development Profile
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```
Includes: Development tools + debugging + log viewer + additional services

### Standalone Mode (No Redis)
```bash
# Remove Redis dependency and start only main service
docker compose up -d discoverylastfm
# Note: This will skip Redis health check dependency
```

## 🔧 Management Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f discoverylastfm
```

### Health Check
```bash
# Container health
docker compose exec discoverylastfm /usr/local/bin/health-check

# Service status
docker compose ps
```

### Update Images
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

### Configuration Test
```bash
# Test configuration
docker compose exec discoverylastfm python /app/config.py
```

## 🚨 Troubleshooting

### Common Issues

#### Container Startup Error: `/usr/local/bin/docker-entrypoint.sh: line 270: syntax error near unexpected token 'else'`

This error occurs because the v2.1.0+ image doesn't include bash, but the entrypoint script requires it. 

**Solution:**
```bash
docker compose up -d
```

The docker-compose.yml automatically builds the image with bash included for compatibility.

**Alternative Causes (if still failing):**

**1. Windows line endings (CRLF) in .env file**
```bash
# Check line endings
file .env
# If shows "CRLF line terminators", fix with:
dos2unix .env
```

**2. Spaces around = in environment variables**
```bash
# ❌ Wrong (space before/after =)
AUTO_UPDATE_ENABLED = true

# ✅ Correct 
AUTO_UPDATE_ENABLED=true
```

**3. Values containing quotes, backslashes, or "EOF"**
```bash
# ❌ Problematic
GITHUB_TOKEN=ghp_AAA"BBB

# ✅ Correct
GITHUB_TOKEN="ghp_AAA\"BBB"
```

#### Container Won't Start (General)
```bash
# Check logs
docker compose logs discoverylastfm

# Validate configuration
docker compose exec discoverylastfm /usr/local/bin/health-check config
```

#### macOS/Windows Docker Desktop Issues ✅ **FIXED**

**Previous Issue**: Container crashes with `chmod: changing permissions of '/app/logs': Operation not permitted`

**✅ Resolution**: Fixed in latest version with improved cross-platform compatibility:
- Enhanced PUID/PGID handling for proper user mapping
- Graceful permission handling that doesn't fail on mounted volumes
- Improved error messages and fallback mechanisms

**Configuration for optimal performance**:
```bash
# Option 1: Use PUID/PGID (recommended for all platforms)
echo "PUID=$(id -u)" >> .env
echo "PGID=$(id -g)" >> .env
docker compose up -d

# Option 2: Use bind mounts with proper permissions
# Create local directories first
mkdir -p ./data/{config,logs,cache}
# Then modify docker-compose.yml volumes section:
# volumes:
#   - ./data/config:/app/config
#   - ./data/logs:/app/logs
#   - ./data/cache:/app/cache
```

#### Redis Container Issues ✅ **FIXED**

**Previous Issue**: Redis fails to start with "redis-server: not found" error

**✅ Resolution**: Fixed command format in docker-compose.yml for proper argument parsing

#### Configuration Validation Issues ✅ **FIXED**

**Previous Issue**: Health check fails with configuration validation errors

**✅ Resolution**: Implemented safer configuration validation using proper Python compile() method instead of unsafe exec()

#### Last.fm Connection Issues
```bash
# Test Last.fm connectivity
docker compose exec discoverylastfm curl -f "http://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=${LASTFM_USERNAME}&api_key=${LASTFM_API_KEY}&format=json"
```

#### Lidarr Connection Issues
```bash
# Test Lidarr connectivity
docker compose exec discoverylastfm curl -f -H "X-Api-Key: ${LIDARR_API_KEY}" "${LIDARR_ENDPOINT}/api/v1/system/status"
```

### Debug Mode
```bash
# Enable debug logging
docker compose exec discoverylastfm sh -c 'export DEBUG=true && python /app/DiscoveryLastFM.py'
```

## 🎛️ Advanced Configuration

### Custom Volumes
```yaml
services:
  discoverylastfm:
    volumes:
      - /host/path/to/config:/app/config
      - /host/path/to/logs:/app/logs
      - /host/path/to/music:/music:ro
```

### External Music Service Integration
```yaml
# If you have Lidarr running externally
services:
  discoverylastfm:
    environment:
      - LIDARR_ENDPOINT=http://your-lidarr-host:8686
    # Remove depends_on if using external services
```

## 🔐 Security

### Non-Root User
The container runs as a non-root user (`discoverylastfm:1000`) for security.

### Environment File Security
```bash
# Secure your .env file
chmod 600 .env

# Use environment variables instead of hardcoded values
export LASTFM_API_KEY="your_api_key_here"
docker compose up -d
```

## 📊 Monitoring

### Health Checks
Built-in health checks monitor:
- Configuration validity
- Service connectivity
- Application files
- Disk space
- Recent activity

### Access Application
```bash
# The application exposes port 8080 for health checks
# Check if it's running:
curl http://localhost:8080/health
```

### Log Aggregation
```yaml
# Configure logging driver
services:
  discoverylastfm:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🤖 Automation

### Backup Automation
```bash
# Backup script
#!/bin/bash
docker compose exec discoverylastfm tar czf /tmp/backup.tar.gz /app/config /app/cache
docker cp discoverylastfm:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

### Automated Image Updates
```bash
# Update script
#!/bin/bash
docker compose pull
docker compose up -d
docker image prune -f
```

## 🏷️ Available Tags

| Tag | Description | Architecture |
|-----|-------------|--------------|
| `latest` | Latest stable release (v2.1.0) | `amd64`, `arm64` |
| `v2.1.0` | Current stable version | `amd64`, `arm64` |
| `main` | Development branch | `amd64`, `arm64` |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [DiscoveryLastFM](https://github.com/MrRobotoGit/DiscoveryLastFM) - Original project
- [Lidarr](https://lidarr.audio/) - Music collection manager
- [Last.fm](https://www.last.fm/) - Music discovery platform

---

**📧 Support**: For issues and support, please open an issue on [GitHub](https://github.com/MrRobotoGit/DiscoveryLastFM-Docker/issues).

**🌟 Star this repo** if you find it useful!
