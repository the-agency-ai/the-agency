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

## What Gets Synced

The following are synced from the-agency to the-agency-starter:

- `.claude/settings.json` and hooks
- `CLAUDE.md`, `README.md`, `LICENSE`
- `claude/agents/captain/` (agent.md, KNOWLEDGE.md, worklogs)
- `claude/config/`
- `claude/docs/` (selected documentation)
- `claude/integrations/`
- `claude/knowledge/`
- `claude/templates/`
- `claude/workstreams/`
- `tools/`
- `source/apps/agency-bench/`
- `source/services/agency-service/`

## What Gets Cleaned

The following are automatically removed during release:

- `.DS_Store` files
- `*.log`, `*.db`, `*.pid` files
- `node_modules/` directories
- Build artifacts (`.next/`, `target/`, `out/`)
- Session files (`SESSION-*.md`)
- Private principals (`jordan/`)
- Push logs and release history

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
