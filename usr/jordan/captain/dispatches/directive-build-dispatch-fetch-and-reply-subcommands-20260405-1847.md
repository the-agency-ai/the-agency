---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T10:47
status: created
priority: high
subject: "Build dispatch fetch and reply subcommands"
in_reply_to: null
---

# Build dispatch fetch and reply subcommands

## Context

ISCP v1 is live. Dispatches and flags work. But worktree agents face friction: `dispatch read` marks items as read (no peek), and there's no lightweight reply mechanism. These two subcommands complete the dispatch lifecycle for practical agent use.

**CRITICAL CONSTRAINT:** The shared DB at `~/.agency/the-agency/iscp.db` is used by ALL agents (captain, mdpal-cli, mdpal-app, mock-and-mark, you). Do NOT bump `ISCP_SCHEMA_VERSION` — the version guard in `_iscp-db` will FATAL every other agent if they see a newer schema version. All changes must work with the existing schema (version 1).

## Directive

### 1. `dispatch fetch <id>` — Read-only peek

Add a `cmd_fetch` function to `agency/tools/dispatch`. Same logic as `cmd_read` (resolve payload path, read from main checkout or `git show main:path`) but **do not** update the dispatch status to `read`. This lets agents inspect a dispatch before committing to process it.

Usage: `dispatch fetch <id>`

### 2. `dispatch reply <id> "message"` — Quick response

Add a `cmd_reply` function. Creates a new dispatch with:
- `--to` set to the original dispatch's `from_agent`
- `--type dispatch`
- `--reply-to <id>` (sets `in_reply_to` FK)
- `--subject "Re: {original subject}"`
- Payload file contains the reply message

This is syntactic sugar over `dispatch create --to ... --reply-to ...` — it auto-resolves the recipient from the original dispatch and prefixes the subject.

Usage: `dispatch reply <id> "Acknowledged — working on it"`

### 3. Default branch detection in `cmd_read`

Replace the hardcoded `master`/`main` fallback in the `git show` path (currently lines 375-385) with dynamic detection:

```bash
_default_branch=$(git -C "$PROJECT_ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
_default_branch="${_default_branch:-main}"
git show "${_default_branch}:${payload_path}" 2>/dev/null
```

This handles repos that use `main`, `master`, `develop`, or any other default.

## Acceptance Criteria

- [ ] `dispatch fetch <id>` reads payload without changing status (verify with `dispatch status <id>` before and after)
- [ ] `dispatch reply <id> "message"` creates a new dispatch addressed to the original sender with correct `in_reply_to`
- [ ] Default branch detection works (no more failed `git show master:` attempts in repos using `main`)
- [ ] All existing 142+ BATS tests still pass
- [ ] New BATS tests for `fetch` and `reply` subcommands
- [ ] No schema version changes — existing agents must continue working
- [ ] Send a reply dispatch to `the-agency/jordan/captain` confirming completion
