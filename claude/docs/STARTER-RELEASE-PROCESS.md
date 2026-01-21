# Starter Release Process

This document describes the process for releasing new versions of the-agency-starter.

## Overview

The Agency Starter is maintained as a sibling repository to the-agency. Releases are cut from the-agency using the `starter-*` tools, which sync files, clean sensitive content, and tag releases.

## Tools

| Tool | Purpose |
|------|---------|
| `./tools/starter-release` | Cut a release (sync, clean, verify, tag) |
| `./tools/starter-verify` | Verify starter against test installation |
| `./tools/starter-compare` | Compare source vs installed files |
| `./tools/starter-test` | Run full test suite |
| `./tools/starter-cleanup` | Clean test artifacts |

## Release Workflow

### 1. Pre-Release Checks

Before cutting a release, ensure:

```bash
# Run tests
./tools/starter-test --local

# Verify current state
./tools/starter-verify --install

# Compare files
./tools/starter-compare --install
```

All tests should pass and no unexpected differences should be found.

### 2. Cut the Release

```bash
# Patch release (0.1.0 -> 0.1.1)
./tools/starter-release patch

# Minor release (0.1.0 -> 0.2.0)
./tools/starter-release minor

# Major release (0.1.0 -> 1.0.0)
./tools/starter-release major

# Specific version
./tools/starter-release 1.2.3

# Dry run first
./tools/starter-release patch --dry-run
```

The release tool:
1. Syncs files from the-agency to the-agency-starter
2. Cleans cruft (logs, databases, .DS_Store)
3. Removes sensitive content (jordan principal, session files)
4. Verifies required files exist
5. Scans for secrets
6. Updates VERSION file
7. Creates git commit and tag

### 3. Push to GitHub

After the release is cut:

```bash
cd /path/to/the-agency-starter

# Push commit
git push origin main

# Push tag
git push origin v1.2.3

# Or create GitHub release with notes
gh release create v1.2.3 --generate-notes
```

### 4. Post-Release Verification

```bash
# Return to the-agency
cd /path/to/the-agency

# Run tests against the released version
./tools/starter-test

# Verify compare still passes
./tools/starter-compare
```

## Sync-Only Mode

To sync files without cutting a release:

```bash
./tools/starter-release --sync-only
```

This updates the starter with latest changes but doesn't bump the version or create a commit.

## Turnkey Principle

**CRITICAL: The starter MUST be a complete, turnkey experience.**

There are NO "advanced" or "optional" features that get excluded. Unless explicitly documented as internal-only (private principal data, work notes, extraction plans), ALL features, documentation, and agents ship with the starter.

When adding new features to the-agency:
1. **Add to sync list** - Update `tools/starter-release` immediately
2. **Ensure turnkey** - Feature must work out-of-the-box
3. **Include docs** - All related documentation must be synced

**Anti-pattern:** Excluding features because they "seem advanced"
**Correct approach:** Include everything; let users choose what to use

## What Gets Synced

The following are synced from the-agency to the-agency-starter:

**Core Files:**
- `.claude/settings.json`, `.claude/settings.local.json.example`, hooks, commands
- `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`

**Agents:**
- `claude/agents/captain/` - The guide agent
- `claude/agents/browser/` - Browser automation agent
- `claude/agents/collaboration/` - Cleaned (only .gitkeep)

**Documentation (ALL docs except internal notes):**
- `claude/docs/*.md` - All feature documentation
- `claude/docs/cookbooks/` - How-to guides
- `claude/docs/guides/` - Reference guides
- `claude/docs/tutorials/` - Step-by-step tutorials

**Configuration & Templates:**
- `claude/config/`
- `claude/integrations/`
- `claude/knowledge/`
- `claude/templates/`
- `claude/workstreams/`

**Tools & Services:**
- `tools/` - All CLI tools
- `tests/tools/` - Tool tests
- `source/apps/agency-bench/`
- `source/services/agency-service/`

**GitHub Workflows:**
- `.github/workflows/starter-*.yml` → `.github/workflows/*.yml`

## What Gets Cleaned

The following are automatically removed during release:

**Build Artifacts (regenerated on install):**
- `.DS_Store` files
- `*.log`, `*.db`, `*.pid` files
- `node_modules/` directories
- Build outputs (`.next/`, `target/`, `out/`)

**Private/Internal Content:**
- Session files (`SESSION-*.md`) - User-specific
- Private principals (`jordan/`) - Maintainer-specific
- Push logs and release history - Internal tracking
- `WORKNOTE-*.md` files - Internal work notes
- `EXTRACTION_PLAN.md` - Internal planning
- `claude/proposals/` - Development proposals

**Project-Specific Agents (removed, only core agents kept):**
- `apple/`, `discord/`, `gumroad/`, `hub/`, etc. - Project-specific agents
- Only `captain/`, `browser/`, `collaboration/` are shipped

## Security Checks

The release process includes:

1. **Required files check** - Verifies essential files exist
2. **Secrets scan** - Uses `./tools/secrets-scan` or fallback patterns
3. **No private principals** - Ensures `jordan/` is not synced
4. **Large file warning** - Flags files >1MB

## Troubleshooting

### "Starter directory not found"

Set the environment variable or ensure repos are siblings:

```bash
export THE_AGENCY_STARTER_DIR=/path/to/the-agency-starter
./tools/starter-release patch
```

### "Secrets detected in starter"

Review the flagged content and either:
- Remove the secret from source
- Add to `.gitignore` if it's a generated file
- Update the pattern if it's a false positive

### Tests failing

Run verbose tests to debug:

```bash
./tools/starter-test --local --verbose --keep
```

The `--keep` flag preserves test artifacts for inspection.

## Version Scheme

The starter follows semantic versioning:

- **Major**: Breaking changes to structure or tools
- **Minor**: New features or tools
- **Patch**: Bug fixes and minor improvements

Version is stored in `VERSION` file and used for:
- Git tags (`v1.2.3`)
- Manifest tracking in created projects
- Update comparison

## Related Documentation

- [REPO-RELATIONSHIP.md](./REPO-RELATIONSHIP.md) - How the repos relate
- [PERMISSIONS.md](./PERMISSIONS.md) - Permission model
- [SECRETS.md](./SECRETS.md) - Secrets management
