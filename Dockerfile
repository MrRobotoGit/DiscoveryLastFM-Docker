# ==============================================================================
# DiscoveryLastFM Docker Container
# Multi-stage build optimized for ARM64 (Raspberry Pi) and AMD64
# ==============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Dependencies
# -----------------------------------------------------------------------------
FROM python:3.11-slim as builder

# Build arguments
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETARCH

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt

# -----------------------------------------------------------------------------
# Stage 2: Runtime Image
# -----------------------------------------------------------------------------
FROM python:3.11-slim as runtime

# Metadata labels
LABEL maintainer="Matteo Rancilio (MrRobotoGit) <matteo.rancilio@gmail.com>"
LABEL org.opencontainers.image.title="DiscoveryLastFM"
LABEL org.opencontainers.image.description="Simplified automated music discovery integration for Last.fm, Headphones, and Lidarr"
LABEL org.opencontainers.image.url="https://github.com/MrRobotoGit/DiscoveryLastFM"
LABEL org.opencontainers.image.source="https://github.com/MrRobotoGit/DiscoveryLastFM-Docker"
LABEL org.opencontainers.image.version="2.1.0"
LABEL org.opencontainers.image.licenses="MIT"

# Install runtime dependencies including bash for entrypoint compatibility
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    cron \
    procps \
    && ln -sf /usr/sbin/cron /usr/sbin/crond \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -g 1000 discoverylastfm && useradd -u 1000 -g 1000 -s /bin/bash discoverylastfm

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set up application directory
WORKDIR /app

# Copy application code
COPY --chown=discoverylastfm:discoverylastfm DiscoveryLastFM.py /app/
COPY --chown=discoverylastfm:discoverylastfm services/ /app/services/
COPY --chown=discoverylastfm:discoverylastfm utils/ /app/utils/

# Copy Docker-specific configurations
COPY --chown=discoverylastfm:discoverylastfm config/docker.config.example.py /app/config.example.py
COPY --chown=discoverylastfm:discoverylastfm docker-entrypoint.sh /usr/local/bin/
COPY --chown=discoverylastfm:discoverylastfm scripts/health-check.sh /usr/local/bin/health-check

# Create required directories with proper permissions
RUN mkdir -p /app/{config,logs,cache} /tmp/cron \
    && chown -R discoverylastfm:discoverylastfm /app /tmp/cron \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/health-check

# Set up volumes for persistent data
VOLUME ["/app/config", "/app/logs", "/app/cache"]

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/health-check

# Expose metrics port (optional, for future monitoring)
EXPOSE 8080

# Switch to non-root user (commented out to allow cron setup as root)
USER discoverylastfm

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV CONFIG_PATH="/app/config.py"
ENV LOG_PATH="/app/logs"
ENV CACHE_PATH="/app/cache"

# Default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["python", "/app/DiscoveryLastFM.py"]
