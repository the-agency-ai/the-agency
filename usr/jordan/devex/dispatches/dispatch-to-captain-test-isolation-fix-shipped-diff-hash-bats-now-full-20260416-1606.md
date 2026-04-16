---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-16T08:06
status: created
priority: normal
subject: "Test isolation fix shipped — diff-hash.bats now fully isolated (re #476)"
in_reply_to: null
---

# Test isolation fix shipped — diff-hash.bats now fully isolated (re #476)

Shipped in commit on devex branch. Addresses dispatch #476.

**Item 2 (diff-hash.bats tests 1, 2, 6):** FIXED. Rewrote all diff-mode tests to create an isolated temp git repo with a known diff (main→feature branch). Each test runs `--base main` against this local fixture. No dependency on live origin/main. Added 2 new tests (different-content hash divergence, no-diff error case). Total: 9 tests, all pass.

**Item 1 (release-plan.bats, iscp-migrate.bats stale paths):** Already passing. Both create fixtures in tmpdir — the `usr/jordan/captain/dispatches` paths are fixture data inside the test repo, not references to the live repo. 16/16 and 14/14 pass respectively.

**Item 3 (container/runner):** Larger scope — should I PVR this? Happy to scope a test runner that provides isolated git repos + mock origin/main for all BATS suites. But the immediate commit-blocker (diff-hash) is resolved.

**Full suite:** 172/172 pass across diff-hash + release-plan + iscp-migrate + commit-precheck + git-safe + git-safe-commit-merge + agency-update + skill-validation.

Standing by for next directive.
