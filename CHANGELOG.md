# Changelog

All notable changes to The Agency will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Agency 2.0 Contribution (2026-03-29)

**Source:** Ported from monofolk production monorepo. Lineage: NextGen → Agency 1.0 → Monofolk → Agency 2.0.

### Added
- **Development methodology** — AIADLC process: Seed → Discussion → PVR → A&D → Plan, Phase.Iteration numbering, living documents
- **Quality gate protocol** — 10-step QG with parallel review agents, red-green cycle, QGR format
- **8 agents** — project-manager (PM), 5 reviewer agents (code, design, scorer, security, test), CoS (Chief of Staff), captain (merged with PR lifecycle)
- **6 hooks** — ref-injector, session-handoff, quality-check, plan-capture, branch-freshness, tool-telemetry
- **Worktree management** — tools/worktree-create, worktree-list, worktree-delete as first-class primitives
- **Path abstraction** — tools/_path-resolve for principal-aware path resolution
- **15 hookify rules** — behavioral guardrails (block force-push, no-verify bypass, system installs; warn on secrets, env files, compound bash, etc.)
- **/discuss skill** — structured 1B1 (one-by-one) discussion protocol
- **CLAUDE templates** — CLAUDE-USER.md and CLAUDE-PROJECT.md for agency init
- **Principal v2** — usr/{principal}/ directory convention replaces claude/principals/
- **Reference docs** — QUALITY-GATE, DEVELOPMENT-METHODOLOGY, CODE-REVIEW-LIFECYCLE, FEEDBACK-FORMAT, PR-LIFECYCLE, TELEMETRY
- **Provider abstraction** — secrets.provider in agency.yaml, pluggable infrastructure slots
- **Hookify plugin** — enabled in settings.json

### Changed
- **add-principal** — scaffolds to usr/{principal}/ (v2), backward-compat with claude/principals/
- **principal-create** — scaffolds to usr/{principal}/ (v2), uses principal-v2 template
- **Captain agent** — merged PR lifecycle, dispatch, review tools, coordination conventions
- **agency.yaml** — extended with methodology, sandbox, worktrees, secrets, telemetry sections
- **registry.json** — 3 new components: methodology, worktree-management, reviewer-agents
- **settings.json** — hookify enabled, new hooks wired, worktree tool permissions
- **SECRETS.md** — added pluggable provider interface header

### Design Decisions
- Worktree isolation is a first-class primitive (enables parallel agents)
- Plugin slots for infrastructure (secrets, testing, CI), fixed conventions for methodology
- usr/{principal}/ replaces claude/principals/ — v2 principal directory convention
- Handoff.md is additive to existing JSONL context restoration
- "No pre-commit code reviews" — review before PR, not after

## [1.1.0] - 2026-01-15

### Added
- **Agency Hub (MVH)** - Agent-driven project management
  - `./agency` command to launch Hub Agent
  - Hub Agent for managing starter and all projects
  - Project manifest system (`.agency/manifest.json`)
  - Component registry (`registry.json`)
  - Project registry (`.agency/projects.json`)
- **Manifest Generation**
  - `project-create` now generates manifest on project creation
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

### Changed
- Renamed `project-new` to `project-create` for consistency with other create tools (agent-create, workstream-create, etc.)
- Deprecated `agency-update` - use `project-update` instead (shows runtime warning)

### Security
- Added path traversal validation to `agency-update` manifest source path

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
