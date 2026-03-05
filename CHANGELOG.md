# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2026-03-05
### Fixed
- Updated docker-compose configuration to properly map all environment variables from .env file. Contributed by @Alon-L (PR #6).
- Enhanced configuration healthcheck logic to prevent false failures for valid values. Contributed by @nacho692 (PR #8).
- Fixed GitHub Container Registry (GHCR) authentication in the Docker Publish workflow.

### Fixed
- Fixed Redis container startup failure due to incorrect command format
- Resolved permission issues on macOS and Windows with mounted volumes
- Improved PUID/PGID environment variable handling for cross-platform compatibility
- Fixed configuration validation errors in health check function
- Enhanced directory permission handling to gracefully handle mounted volume restrictions
- **NEW**: Fixed macOS configuration write permission issues with progressive fallback system
- **NEW**: Improved error handling for mounted volume write failures on Docker Desktop

### Changed
- Updated Redis command format to use array syntax for proper argument parsing
- Improved error handling for permission operations on mounted volumes
- Enhanced logging for debugging permission issues across different platforms
- Added safer configuration file validation using compile() instead of exec()

## [2.1.0] - Previous Release
- Auto-update system implementation
- Enhanced Docker configuration
- Multi-architecture support (ARM64/AMD64)