# Session Summary: Repo Sync & Versioning
**Date**: 2026-01-09
**Version**: 2026-01-09-000003

## Overview

Major sync between `the-agency` and `the-agency-starter` repos, plus implementation of tool versioning system.

## Key Decisions

### Repository Relationship
- `the-agency` is the **source of truth**
- `the-agency-starter` is a **build artifact** within the-agency
- Changes flow: the-agency → the-agency-starter → public repo
- User contributions flow back via PRs

### Platform Support
- **Current**: macOS only
- `setup-linux` exists in the-agency but NOT in starter (Linux not supported yet)

### Versioning
- **Project version**: `YYYY-MM-DD-NNNNNN` (e.g., `2026-01-09-000003`)
- **Tool version**: `SEMANTIC-YYYYMMDD-NNNNNN` (e.g., `1.0.0-20260109-000001`)
- Build numbers have 6-digit leading zeros
- Every tool now has `--version` / `-v` support

## Changes Made

### Tools Synced (main → starter)
- `archive-session`
- `bench`
- `browser`
- `bump-version` (updated with leading zeros)
- `capture-proposal`
- `create-agent` (merged - has cloud storage feature)
- `create-principal`
- `myclaude` (merged - has --update, --rollback, --version, message check)
- `observe`
- `read-messages`
- `recipes/`
- `request`
- `send-message`
- `setup-icloud`
- `setup-iterm`

### Tools Synced (starter → main)
- `new-project`
- `setup-mac`
- `setup-linux` (moved to main only, removed from starter)

### New Tool Created
- `add-tool-version` - Adds version metadata to any tool

### All Tools Versioned
All 50+ tools now have:
- `TOOL_VERSION="1.0.0-20260109-000001"` embedded
- `--version` / `-v` flag support

### Apps
- `apps/agency-bench/` recovered and synced from starter (more complete version)

### Documentation
- `claude/docs/REPO-RELATIONSHIP.md` - Comprehensive sync rules and relationship docs
- `.claude/settings.json` - Pre-approved permissions for 40+ tools

## Files That Should Differ Between Repos
- `CLAUDE.md`
- `README.md`
- `package.json`
- `.gitignore`
- `VERSION`
- `CHANGELOG.md`

## Starter-Only Files
- `install.sh`
- `CONTRIBUTING.md`
- `GETTING_STARTED.md`
- `PHILOSOPHY.md`
- `WORKSHOP.md`
- `pnpm-workspace.yaml`
- `packages/`

## Next Steps
1. Verify agency-bench runs correctly
2. Consider creating automated sync script
3. Plan Linux support release

---
*Session archived for future reference*
