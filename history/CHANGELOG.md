# Changelog

All notable changes to The Agency framework.

## [Unreleased]

### Added
- GitHub CLI wrapper REQUEST (REQUEST-0072) - pending implementation
- Investigation doc for iTerm tab shapes (BUG HOUSEKEEPING-00007)

### Changed
- `tools/release` now uses secret-service for GitHub token

### Fixed
- Principal detection bug when config tool errors

---

## [v106.0.0] - 2026-01

### Added
- Secret service with vault encryption
- Request service for work item tracking
- Test service for test execution tracking
- Bug service for issue tracking
- Observation service
- Idea service
- Principal tooling (`principal-create`, `add-principal`, `setup-agency`)
- Interactive onboarding (`/agency-welcome`, `/agency-tutorial`)
- Agency slash commands (`/agency-bug`, `/agency-request`, `/agency-help`)
- Tab status indicators (colors working, shapes via badge)
- Layered permissions model (`settings.json` + `settings.local.json`)
- Comprehensive documentation (SECRETS.md, PERMISSIONS.md, TESTING.md, EXTENDING.md)
- Research agent spec

### Changed
- Turnkey installation - myclaude auto-installs dependencies
- CLAUDE.md refactored to lean constitution with reference docs
- Development workflow documented (Red-Green model)

### Fixed
- Session context restoration
- Dependency tracking (requirements.txt, auto-install)

---

## Earlier Releases

See `git log` for detailed history of earlier versions.
