# REQUEST-jordan-0072: GitHub CLI wrapper with token injection and logging

**Status:** Open
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

Implementation options:
- ./tools/gh as a transparent wrapper that intercepts all gh commands
- Or specific wrappers for high-value operations (gh pr, gh release, gh api)

Benefits:
- No need to run gh auth login or manage GH_TOKEN manually
- Full observability of GitHub interactions
- Follows Agency patterns for external tool integration

Related: REQUEST-jordan-0029 (secrets infrastructure)

## Acceptance Criteria

- [ ] Criteria 1
- [ ] Criteria 2

## Work Completed

<!-- Document completed work here -->

---

## Activity Log

### 2026-01-20 - Created
- Request created by jordan
