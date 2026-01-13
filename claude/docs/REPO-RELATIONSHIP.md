# The Agency Repository Relationship

## Overview

`the-agency` is the private development repo. `the-agency-starter` is a **build artifact** that lives as a directory within `the-agency` but is also published to a separate public repository.

## Repository Flow

### Development Flow (Downstream to Users)
```
Commit → Push to the-agency (private)
       → Extract from the-agency/the-agency-starter/
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

## Future State

Long-term: Remove the-agency-starter directory from the-agency repo entirely, and instead "build the artifacts" that get committed to the-agency-starter public repo.

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

When syncing:
1. Make changes in the-agency (source of truth)
2. Copy updated tools from the-agency → the-agency-starter
3. Never copy platform-specific tools to starter if that platform isn't supported
4. Never sync the "intentionally different" files
5. Never sync instance-specific files

### Quick Sync Command
```bash
# Sync all tools from main to starter (except setup-linux)
for tool in tools/*; do
  [ -d "$tool" ] && continue
  [ -L "$tool" ] && continue
  toolname=$(basename "$tool")
  [ "$toolname" = "setup-linux" ] && continue
  cp "$tool" "the-agency-starter/tools/$toolname"
done
```

---
*Last Updated: 2026-01-09*
