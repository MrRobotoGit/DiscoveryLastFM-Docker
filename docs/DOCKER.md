# DiscoveryLastFM Docker Guide 🐳

This comprehensive guide covers everything you need to know about running DiscoveryLastFM in Docker.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Deployment Scenarios](#deployment-scenarios)
- [Performance Tuning](#performance-tuning)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Installation

### Prerequisites

- Docker 20.10+ or Docker Desktop
- Docker Compose 2.0+ (or docker-compose 1.29+)
- 512MB+ available RAM
- 1GB+ available disk space

### Quick Installation

#### Method 1: Automated Script
```bash
curl -sSL https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/scripts/setup-docker.sh | bash
```

#### Method 2: Manual Setup
```bash
# Download compose file
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/MrRobotoGit/DiscoveryLastFM-Docker/main/.env.example

# Configure
cp .env.example .env
nano .env

# Deploy
docker-compose up -d
```

#### Method 3: Git Clone
```bash
git clone https://github.com/MrRobotoGit/DiscoveryLastFM-Docker.git
cd DiscoveryLastFM-Docker
cp .env.example .env
nano .env
docker-compose up -d
```

### Platform Support

| Platform | Architecture | Status |
|----------|--------------|--------|
| Intel/AMD 64-bit | `linux/amd64` | ✅ Fully Supported |
| ARM 64-bit (Pi 4+) | `linux/arm64` | ✅ Fully Supported |
| ARM 32-bit (Pi 3) | `linux/arm/v7` | 🔄 Planned |

## Configuration

### Environment Variables

#### Required Configuration
```bash
# Last.fm credentials (required)
LASTFM_USERNAME=your_username
LASTFM_API_KEY=your_api_key

# Music service selection
MUSIC_SERVICE=lidarr  # or 'headphones'
```

#### Service-Specific Configuration

**For Lidarr:**
```bash
LIDARR_API_KEY=your_lidarr_api_key
LIDARR_ENDPOINT=http://lidarr:8686
LIDARR_ROOT_FOLDER=/music
LIDARR_QUALITY_PROFILE_ID=1
LIDARR_METADATA_PROFILE_ID=1
```

**For Headphones:**
```bash
HP_API_KEY=your_headphones_api_key
HP_ENDPOINT=http://headphones:8181
```

#### Discovery Parameters
```bash
# How many months of listening history to analyze
RECENT_MONTHS=3

# Minimum plays required to consider an artist
MIN_PLAYS=20

# Similarity threshold (0.0-1.0)
SIMILAR_MATCH_MIN=0.46

# Maximum similar artists to process per artist
MAX_SIMILAR_PER_ART=20

# Maximum albums to fetch per artist
MAX_POP_ALBUMS=5

# Cache time-to-live in hours
CACHE_TTL_HOURS=24
```

#### Container Operation
```bash
# Operation mode
DISCOVERY_MODE=cron  # sync, cron, daemon, test

# Cron schedule (for cron mode)
CRON_SCHEDULE=0 3 * * *

# Sleep time between runs (for daemon mode)
SLEEP_HOURS=3

# Enable dry run (no actual changes)
DRY_RUN=false

# Enable debug logging
DEBUG=false
```

### Configuration Validation

Test your configuration:
```bash
# Validate configuration
docker-compose exec discoverylastfm python /app/config.py

# Test service connectivity
docker-compose exec discoverylastfm /usr/local/bin/health-check config
```

## Deployment Scenarios

### Scenario 1: Home Server with Lidarr

**Setup:**
- DiscoveryLastFM + Lidarr + Redis
- Scheduled daily discovery
- Automatic updates

```yaml
# docker-compose.yml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - DISCOVERY_MODE=cron
      - CRON_SCHEDULE=0 3 * * *
      - MUSIC_SERVICE=lidarr
      # ... other config
    depends_on:
      - lidarr
      - redis

  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    # ... lidarr config

  redis:
    image: redis:7-alpine
    # ... redis config
```

### Scenario 2: Raspberry Pi Minimal Setup

**Setup:**
- DiscoveryLastFM only
- ARM64 optimized
- Resource constrained

```yaml
version: '3.8'

services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - DISCOVERY_MODE=daemon
      - SLEEP_HOURS=6
      - MUSIC_SERVICE=headphones
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
    restart: unless-stopped
```

### Scenario 3: Development Environment

**Setup:**
- All services with debug tools
- Source code mounting
- Development overrides

```bash
# Use development compose
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Scenario 4: High-Performance Setup

**Setup:**
- Multiple Lidarr instances
- Redis cluster
- Performance optimizations

```yaml
services:
  discoverylastfm:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - DISCOVERY_MODE=daemon
      - SLEEP_HOURS=2
      - MAX_SIMILAR_PER_ART=50
      - MAX_POP_ALBUMS=10
      - ENABLE_REDIS_CACHE=true
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2.0'
        reservations:
          memory: 512M
          cpus: '0.5'
```

## Performance Tuning

### Resource Optimization

#### Memory Usage
```bash
# Monitor memory usage
docker stats discoverylastfm

# Optimize memory settings
RECENT_MONTHS=2         # Reduce history scope
MAX_SIMILAR_PER_ART=15  # Reduce processing load
CACHE_TTL_HOURS=48      # Increase cache retention
```

#### CPU Usage
```bash
# Set CPU limits
services:
  discoverylastfm:
    deploy:
      resources:
        limits:
          cpus: '1.0'        # Max 1 CPU core
        reservations:
          cpus: '0.25'       # Guaranteed allocation
```

#### Network Optimization
```bash
# Reduce API call frequency
REQUEST_LIMIT=0.1         # Slower Last.fm requests
MBZ_DELAY=2.0            # Longer MusicBrainz delays

# Enable connection pooling
ENABLE_REDIS_CACHE=true   # Use Redis for caching
```

### Cache Optimization

#### Redis Configuration
```yaml
redis:
  image: redis:7-alpine
  command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
  deploy:
    resources:
      limits:
        memory: 256M
```

#### File System Cache
```bash
# Use tmpfs for temporary data
services:
  discoverylastfm:
    tmpfs:
      - /tmp:size=100M,noexec,nosuid,nodev
```

### Scaling Strategies

#### Horizontal Scaling
```yaml
# Multiple discovery instances
services:
  discoverylastfm-recent:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - RECENT_MONTHS=1
      - CRON_SCHEDULE=0 */6 * * *  # Every 6 hours

  discoverylastfm-historical:
    image: mrrobotogit/discoverylastfm:latest
    environment:
      - RECENT_MONTHS=6
      - CRON_SCHEDULE=0 0 * * 0    # Weekly
```

#### Load Balancing
```yaml
# HAProxy load balancer
haproxy:
  image: haproxy:alpine
  volumes:
    - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
  ports:
    - "8080:8080"
```

## Security

### Container Security

#### Non-Root User
```dockerfile
# Containers run as non-root user
USER discoverylastfm
```

#### Read-Only Root Filesystem
```yaml
services:
  discoverylastfm:
    read_only: true
    tmpfs:
      - /tmp:size=100M,noexec,nosuid,nodev
```

#### Security Context
```yaml
services:
  discoverylastfm:
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
```

### Network Security

#### Internal Networks
```yaml
networks:
  internal:
    driver: bridge
    internal: true  # No external access

services:
  discoverylastfm:
    networks:
      - internal
```

#### Firewall Rules
```bash
# UFW rules for Docker
ufw allow from 172.20.0.0/16 to any port 8686  # Lidarr
ufw allow from 172.20.0.0/16 to any port 6379  # Redis
```

### Secrets Management

#### Docker Secrets
```yaml
secrets:
  lastfm_api_key:
    file: ./secrets/lastfm_api_key.txt
  lidarr_api_key:
    file: ./secrets/lidarr_api_key.txt

services:
  discoverylastfm:
    secrets:
      - lastfm_api_key
      - lidarr_api_key
    environment:
      - LASTFM_API_KEY_FILE=/run/secrets/lastfm_api_key
      - LIDARR_API_KEY_FILE=/run/secrets/lidarr_api_key
```

#### External Secret Management
```yaml
# HashiCorp Vault integration
services:
  discoverylastfm:
    environment:
      - VAULT_ADDR=https://vault.example.com
      - VAULT_TOKEN_FILE=/run/secrets/vault_token
```

## Monitoring

### Health Checks

#### Built-in Health Check
```bash
# Manual health check
docker-compose exec discoverylastfm /usr/local/bin/health-check

# Check specific components
docker-compose exec discoverylastfm /usr/local/bin/health-check config
docker-compose exec discoverylastfm /usr/local/bin/health-check quick
```

#### Custom Health Checks
```yaml
services:
  discoverylastfm:
    healthcheck:
      test: ["/usr/local/bin/health-check", "quick"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

### Logging

#### Log Configuration
```yaml
services:
  discoverylastfm:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service=discoverylastfm"
```

#### Log Aggregation
```yaml
# ELK Stack integration
services:
  discoverylastfm:
    logging:
      driver: "fluentd"
      options:
        fluentd-address: "fluentd:24224"
        tag: "discoverylastfm"
```

#### Log Analysis
```bash
# View logs with filtering
docker-compose logs --since=1h discoverylastfm | grep ERROR

# Follow logs in real-time
docker-compose logs -f --tail=100 discoverylastfm

# Export logs for analysis
docker-compose logs --no-color discoverylastfm > discoverylastfm.log
```

### Metrics Collection

#### Prometheus Integration
```yaml
# Prometheus configuration
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

# prometheus.yml
scrape_configs:
  - job_name: 'discoverylastfm'
    static_configs:
      - targets: ['discoverylastfm:8080']
```

#### Grafana Dashboard
```yaml
services:
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### Alerting

#### Webhook Notifications
```bash
# Discord webhook
WEBHOOK_URL="https://discord.com/api/webhooks/..."
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content":"DiscoveryLastFM: Discovery completed successfully"}'
```

#### Email Notifications
```yaml
# SMTP configuration
services:
  discoverylastfm:
    environment:
      - SMTP_HOST=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USER=user@gmail.com
      - SMTP_PASS=app_password
      - NOTIFICATION_EMAIL=admin@example.com
```

## Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check container logs
docker-compose logs discoverylastfm

# Check configuration
docker-compose config

# Validate environment
docker-compose exec discoverylastfm env | grep -E "(LASTFM|LIDARR|HP)_"
```

#### Performance Issues
```bash
# Monitor resource usage
docker stats

# Check for memory leaks
docker-compose exec discoverylastfm ps aux

# Analyze slow queries
docker-compose logs discoverylastfm | grep "took.*ms"
```

#### Network Connectivity
```bash
# Test Last.fm connectivity
docker-compose exec discoverylastfm curl -I "http://ws.audioscrobbler.com"

# Test Lidarr connectivity
docker-compose exec discoverylastfm curl -I "http://lidarr:8686"

# Check DNS resolution
docker-compose exec discoverylastfm nslookup lidarr
```

### Debug Mode

#### Enable Debug Logging
```bash
# Temporary debug mode
docker-compose exec discoverylastfm sh -c 'export DEBUG=true && python /app/DiscoveryLastFM.py'

# Persistent debug mode
echo "DEBUG=true" >> .env
docker-compose restart discoverylastfm
```

#### Interactive Debugging
```bash
# Enter container shell
docker-compose exec discoverylastfm bash

# Run discovery manually
python /app/DiscoveryLastFM.py

# Test specific components
python -c "from services.factory import MusicServiceFactory; print('OK')"
```

### Recovery Procedures

#### Reset Configuration
```bash
# Backup current config
docker-compose exec discoverylastfm cp /app/config.py /app/config.py.backup

# Reset to defaults
docker-compose exec discoverylastfm cp /app/config.example.py /app/config.py

# Restart with clean config
docker-compose restart discoverylastfm
```

#### Clear Cache
```bash
# Clear application cache
docker-compose exec discoverylastfm rm -f /app/cache/*

# Clear Redis cache
docker-compose exec redis redis-cli FLUSHALL

# Restart services
docker-compose restart
```

#### Rollback Image
```bash
# Pull previous version
docker pull mrrobotogit/discoverylastfm:v2.0.1

# Update compose file
sed -i 's/:latest/:v2.0.1/' docker-compose.yml

# Restart with previous version
docker-compose up -d
```

## Advanced Usage

### Custom Builds

#### Build from Source
```bash
# Clone repositories
git clone https://github.com/MrRobotoGit/DiscoveryLastFM.git
git clone https://github.com/MrRobotoGit/DiscoveryLastFM-Docker.git

# Build custom image
cd DiscoveryLastFM-Docker
docker build -t my-discoverylastfm .
```

#### Multi-Architecture Build
```bash
# Use build script
./scripts/build-multiarch.sh --platforms linux/amd64,linux/arm64 --push
```

### Integration Examples

#### Home Assistant Integration
```yaml
# Home Assistant automation
automation:
  - alias: "Music Discovery Complete"
    trigger:
      platform: state
      entity_id: sensor.discoverylastfm_status
      to: "completed"
    action:
      service: notify.mobile_app
      data:
        message: "New music discovered and added to library"
```

#### Plex Integration
```bash
# Trigger Plex library scan after discovery
docker-compose exec discoverylastfm sh -c '
  python /app/DiscoveryLastFM.py && 
  curl -X POST "http://plex:32400/library/sections/1/refresh?X-Plex-Token=$PLEX_TOKEN"
'
```

#### Webhook Integration
```yaml
services:
  discoverylastfm:
    environment:
      - WEBHOOK_URL=http://webhook.site/your-unique-url
      - WEBHOOK_EVENTS=discovery_complete,error
```

### Performance Monitoring

#### Custom Metrics
```python
# Custom metrics collection
import time
import requests

def send_metrics(metric_name, value, tags=None):
    data = {
        'metric': metric_name,
        'value': value,
        'timestamp': time.time(),
        'tags': tags or {}
    }
    requests.post('http://metrics-collector:8080/metrics', json=data)
```

#### Database Integration
```yaml
# PostgreSQL for metrics storage
services:
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=discoverylastfm_metrics
      - POSTGRES_USER=metrics
      - POSTGRES_PASSWORD=secure_password
```

This comprehensive guide should cover most Docker deployment scenarios for DiscoveryLastFM. For additional help, refer to the troubleshooting section or open an issue on GitHub.
