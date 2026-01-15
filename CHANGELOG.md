# Changelog

All notable changes to The Agency will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-15

### Added
- **Agency Hub (MVH)** - Agent-driven project management
  - `./agency` command to launch Hub Agent
  - Hub Agent for managing starter and all projects
  - Project manifest system (`.agency/manifest.json`)
  - Component registry (`registry.json`)
  - Project registry (`.agency/projects.json`)
- **Manifest Generation**
  - `project-new` now generates manifest on project creation
  - `project-update --init` generates manifest for existing projects
  - `project-update --check --json` for machine-readable status
  - SHA256 file hashing for modification detection
- **Terminal Integration** (macOS + iTerm2)
  - `./tools/launch-project` - Open project in new iTerm2 tab
  - Automatic tab naming ("Agency: project-name")
- **Service Check** - `myclaude` now offers to start services on launch
- **Session Start Improvements**
  - Auto-check for news on session start
  - Auto-check for pending collaborations
- **Test Suite** - 76 tests covering MVH functionality

### Fixed
- Coordination tool permissions (news-post, collaboration-respond, etc.)
- Schema validation improvements (version patterns, hash formats)

## [Unreleased]

## [2026-01-09-000003]

## [2026-01-09-2]

### Added
- MIT License
- README.md
- CHANGELOG.md and VERSION tracking
- `tools/recipes/` for Anthropic cookbook patterns
- `./tools/myclaude --update`, `--rollback`, `--version` flags
- `./tools/version-bump` for version management

## [0.2.0] - 2026-01-08

### Added
- Claude Cookbooks knowledge cache (`claude/docs/cookbooks/`)
- COOKBOOK-SUMMARY.md with full index of 63 cookbooks
- Proposals system for tracking enhancements
- Browser integration documentation (CHROME_INTEGRATION.md)
- PROP-0015: Capture Web Content tool proposal
- PROP-0013: Open Webpage tool proposal

### Changed
- Enhanced session backup workflow

## [0.1.0] - 2026-01-01

### Added
- Initial The Agency framework
- Core tools: myclaude, agent-create, create-workstream
- Collaboration tools: collaborate, news-post, news-read
- Quality tools: commit-precheck, code-review
- Session tools: welcomeback, session-backup
- Principal/agent/workstream directory structure
- CLAUDE.md constitution

[Unreleased]: https://github.com/the-agency-ai/the-agency/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/the-agency-ai/the-agency/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/the-agency-ai/the-agency/releases/tag/v0.1.0
