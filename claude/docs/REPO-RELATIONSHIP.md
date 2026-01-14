# The Agency Repository Relationship

## Overview

`the-agency` is the private development repo. `the-agency-starter` is a **separate sibling repository** that serves as the public distribution.

The two repos live side-by-side:
```
code/
  ├── the-agency/            # Private development repo (source of truth)
  └── the-agency-starter/    # Public distribution repo (build target)
```

## Repository Flow

### Development Flow (Downstream to Users)
```
Commit → Push to the-agency (private)
       → Run ./tools/starter-release
       → Sync files to ../the-agency-starter/ (sibling repo)
       → Push to the-agency-starter (public repo)
```

### User Installation Flow
```
End users install from the-agency-starter public repo (using install script)
       → They have a local repo
       → They use ./tools/project-new + the-agency-starter to spin up new projects
```

### Contribution Flow (Upstream from Users)
```
User extracts from their local project
       → Merges into their local the-agency-starter repo
       → Makes edits to objects in their local the-agency-starter
       → Submits PR to the-agency-starter public repo
       → We accept/reject
       → We sync/merge accepted changes back into the-agency
```

## Current State (as of 2026-01-14)

The-agency-starter has been extracted from the-agency repo and now lives as a separate sibling repository. The sync process uses `./tools/starter-release` to copy files from the-agency → the-agency-starter.

## Platform Support

**Current Release**: macOS only
- `setup-mac` - Installs CLI tools via Homebrew
- `setup-icloud` - iCloud Drive integration
- `setup-iterm` - iTerm2 dynamic profiles

**Future**: Linux and Windows support planned
- `setup-linux` - Exists in the-agency but NOT in the-agency-starter (not yet supported)

## Sync Rules

### Tools
- **Source of truth**: the-agency
- All tools in the-agency → must exist in the-agency-starter (except platform-specific unsupported ones)
- Tools should be identical between repos
- Exception: `setup-linux` is in the-agency only (Linux not yet supported)

### Tool Versioning
Every tool has its own version number:
- Format: `{SEMANTIC}-{YYYYMMDD}-{BUILDNUMBER}`
- Example: `1.0.0-20260109-000001`
- Build numbers have 6-digit leading zeros
- Display via `--version` or `-v` flag
- All tools support `--help` / `-h` as well

### Project Versioning
- Format: `{YYYY-MM-DD}-{BUILDNUMBER}`
- Example: `2026-01-09-000003`
- Stored in `VERSION` file
- Bumped via `./tools/version-bump`

### Files That SHOULD Differ
These files are intentionally different between repos:
- `CLAUDE.md` - Different identity/context per repo
- `README.md` - Different audience (internal vs public)
- `package.json` - Different metadata
- `.gitignore` - Different ignore patterns
- `VERSION` - Track independently
- `CHANGELOG.md` - Different release notes

### Files Only in the-agency-starter
These are public-facing files for end users:
- `install.sh` - Installation script for users
- `CONTRIBUTING.md` - Contribution guidelines
- `GETTING_STARTED.md` - User onboarding
- `PHILOSOPHY.md` - Project philosophy
- `WORKSHOP.md` - Workshop/tutorial content
- `pnpm-workspace.yaml` - Monorepo config
- `packages/` - Shared packages

### Files Only in the-agency (Instance-Specific)
- Session backups
- Adhoc worklogs
- Agent-specific state
- Principal-specific data
- `setup-linux` (until Linux is supported)

## Sync Process

### Using starter-release Tool

The recommended way to sync changes:

```bash
# Sync files only (no version bump)
./tools/starter-release --sync-only

# Cut a full release (sync + version + commit + tag)
./tools/starter-release patch    # Bump patch version (0.1.0 -> 0.1.1)
./tools/starter-release minor    # Bump minor version (0.1.0 -> 0.2.0)
./tools/starter-release major    # Bump major version (0.1.0 -> 1.0.0)
./tools/starter-release 1.5.0    # Specific version

# Dry run (see what would happen)
./tools/starter-release --dry-run
```

### What Gets Synced

The starter-release tool syncs:
- `.claude/` directory (settings, hooks, commands)
- `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`
- `claude/agents/captain/` (agent files, not session state)
- `claude/config`, `claude/docs`, `claude/knowledge`, `claude/templates`, `claude/workstreams`
- `tools/` (all CLI tools)
- `source/apps/agency-bench` and `source/services/agency-service`

What does NOT get synced:
- `claude/principals/` (private/instance-specific)
- Session backups and logs
- Agent state files (SESSION-*, backups/)
- Platform-specific unsupported tools (e.g., setup-linux)
- Build artifacts (node_modules, target/, .next/)

### Verification Tools

```bash
# Verify the starter build
./tools/starter-verify

# Compare starter to a test install
./tools/starter-compare
```

### Manual Sync Rules

When syncing manually (not recommended, use starter-release instead):
1. Make changes in the-agency (source of truth)
2. Never copy platform-specific tools to starter if that platform isn't supported
3. Never sync the "intentionally different" files
4. Never sync instance-specific files

---
*Last Updated: 2026-01-14*
