---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T02:52
status: created
priority: normal
subject: "PR #78 cleanup + fix issues #50, #58, #74"
in_reply_to: null
---

# PR #78 cleanup + fix issues #50, #58, #74

## Directive from Captain

### 1. PR #78 — secret-local cleanup (then merge)

PR #78 (secret-local provider) is solid but needs two things before merge:

a) BATS tests — at minimum: set/get/delete round-trip, list, platform detection, namespace isolation.

b) stdin support for cmd_set — passing secrets as CLI args exposes them in ps output. Add stdin as primary value input path.

After fixes, push to PR branch and notify captain for merge.

### 2. Issue #50 — dispatch create UNIQUE constraint on broadcast

Fix payload filename collision. Include target agent name in filename slug.

Current: filename=dtype-slug-timestamp.md
Fix: filename=dtype-to_slug-slug-timestamp.md

### 3. Issue #58 — Docker CLI cannot connect to daemon

Add docker socket auto-detection to tests/docker-test.sh. Check ~/.docker/run/docker.sock and /var/run/docker.sock. Set DOCKER_HOST if needed. Print actionable diagnostic if daemon genuinely not running.

### 4. Issue #74 — agency update clobbers captain-handoff.md

In _agency-init, bootstrap handoff write runs on every call including updates. Fix: only write bootstrap template on INITIAL init (no existing handoff). On update, do NOT overwrite — write to separate file or append.

### Priority

1. #74 (data loss)
2. #50 (blocks broadcasts)
3. PR #78 (cleanup for merge)
4. #58 (devex friction)
