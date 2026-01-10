# Changelog

All notable changes to The Agency Starter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `services/agency-service/` - SOA service foundation with Hono + Bun
- `bug-service` - First embedded service for bug tracking
- `./tools/agency-service` - CLI for managing the agency-service
- `./tools/release-starter` - Tool for cutting starter releases
- `history/` directory for project history tracking
- `claude/config/` directory for configuration
- `claude/integrations/` directory for external tool integrations

### Changed
- Reorganized directory structure for clarity
- Service logs now live with their service (`services/*/logs/`)
- Config moved from `claude/config.yaml` to `claude/config/agency.yaml`

### Removed
- `claude/logs/` directory (logs now in respective services)

---

<!--
## [1.0.0] - YYYY-MM-DD

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
-->
