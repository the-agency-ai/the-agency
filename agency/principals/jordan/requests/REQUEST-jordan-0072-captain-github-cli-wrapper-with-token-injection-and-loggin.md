# REQUEST-jordan-0072: GitHub CLI wrapper with token injection and logging

**Status:** Complete
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-20
**Updated:** 2026-01-20

## Summary

GitHub CLI wrapper with token injection and logging

## Details

Create a wrapper for the gh CLI that:

1. **Automatic token injection** - Gets GitHub token from secret-service (github-admin-token)
2. **Logging** - Logs all GitHub operations to log-service (PRs created, releases cut, API calls)
3. **Audit trail** - Track who did what to GitHub, when
4. **Consistent UX** - Same patterns as other Agency tools

Implementation approach:
- `./tools/gh` as a transparent wrapper that intercepts all gh commands
- Specific wrappers for high-value operations built on top

Benefits:
- No need to run gh auth login or manage GH_TOKEN manually
- Full observability of GitHub interactions
- Follows Agency patterns for external tool integration

Related: REQUEST-jordan-0029 (secrets infrastructure)

## Acceptance Criteria

- [x] `./tools/gh` transparent wrapper with token injection
- [x] Automatic token retrieval from secret-service (github-admin-token)
- [x] All operations logged to log-service via _log-helper
- [x] `./tools/gh-pr` wrapper for PR operations
- [x] `./tools/gh-release` wrapper for release operations
- [x] `./tools/gh-api` wrapper for API operations
- [x] --version, --help, --dry-run support
- [x] Follows Agency tool patterns (versioning, run IDs)

## Implementation

### Tools Created

1. **`./tools/gh`** - Base transparent wrapper
   - Automatically injects GH_TOKEN from secret-service
   - Logs all operations with run IDs
   - Pass-through to real `gh` CLI
   - Supports --dry-run for testing

2. **`./tools/gh-pr`** - PR operations
   - Convenience wrapper for `gh pr` commands
   - list, create, view, merge, close, checkout, diff, checks, comments

3. **`./tools/gh-release`** - Release operations
   - Convenience wrapper for `gh release` commands
   - list, create, view, delete, download, upload
   - Note: For full release workflow, use `./tools/release`

4. **`./tools/gh-api`** - API operations
   - Convenience wrapper for `gh api` commands
   - REST and GraphQL support
   - Useful for custom GitHub operations

### Usage Examples

```bash
# Base wrapper - any gh command
./tools/gh pr list
./tools/gh repo view

# PR operations
./tools/gh-pr list --state open
./tools/gh-pr create --title "My PR" --body "Description"
./tools/gh-pr merge 123 --squash

# Release operations
./tools/gh-release list --limit 5
./tools/gh-release view v1.0.0

# API operations
./tools/gh-api /user
./tools/gh-api /repos/{owner}/{repo}/pulls --jq '.[].title'
```

---

## Activity Log

### 2026-01-20 - Created
- Request created by jordan

### 2026-01-20 - Complete
- Implemented `./tools/gh` transparent wrapper with:
  - Automatic token injection from secret-service
  - Logging via _log-helper
  - --version, --help, --dry-run support
- Implemented convenience wrappers:
  - `./tools/gh-pr` for PR operations
  - `./tools/gh-release` for release operations
  - `./tools/gh-api` for API operations
- All tools tested and working
