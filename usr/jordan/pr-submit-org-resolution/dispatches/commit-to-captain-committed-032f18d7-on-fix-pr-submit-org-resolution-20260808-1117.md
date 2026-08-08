---
type: commit
from: the-agency/jordan/pr-submit-org-resolution
to: the-agency/jordan/captain
date: 2026-08-08T03:17
status: created
priority: normal
subject: "Committed 032f18d7 on fix/pr-submit-org-resolution: fix(pr-lifecycle): make PR landing main-aware + fix receipt-churn

pr-captain-land hardcoded 'master' in three live places (origin/master diff
base, switch-branch master, gh-release --target master), which fails closed on
a repo whose default branch is main — blocking every captain PR landing here.

- pr-captain-land: resolve the default branch and use it everywhere; source the
  shared, tested pr-submit helpers (redact_remote_url/parse_org/parse_repo/
  resolve_default_branch) instead of re-deriving ORG/REPO inline; redact the
  remote on the parse-failure path (no PAT leak).
- pr-submit: add parse_repo_from_remote (companion to parse_org) for the lib.
- diff-hash: exclude active + archived handoffs — fixes receipt-churn where
  /pr-submit and /handoff committed a handoff into the hashed set, invalidating
  the just-signed receipt (one landing cost five re-signs).
- sync src/ source-of-truth copies to running (self-bootstrapping payload;
  src/agency/tools/diff-hash also catches up the Issue #254 guard it lacked).
- tests: +7 repo-parser, +9 pr-captain-land regression guards, +3 handoff-
  exclusion. 67 relevant bats green.

Consolidates the /pr-submit framework fixes (F1 default-branch, F2 credential
leak, F3 dead ERE branch + two QG-found: scheme-limited redaction, bypassable
lib guard) surfaced by mdpal-app and mdslidepal-mac agents."
in_reply_to: null
---

# Committed 032f18d7 on fix/pr-submit-org-resolution: fix(pr-lifecycle): make PR landing main-aware + fix receipt-churn

pr-captain-land hardcoded 'master' in three live places (origin/master diff
base, switch-branch master, gh-release --target master), which fails closed on
a repo whose default branch is main — blocking every captain PR landing here.

- pr-captain-land: resolve the default branch and use it everywhere; source the
  shared, tested pr-submit helpers (redact_remote_url/parse_org/parse_repo/
  resolve_default_branch) instead of re-deriving ORG/REPO inline; redact the
  remote on the parse-failure path (no PAT leak).
- pr-submit: add parse_repo_from_remote (companion to parse_org) for the lib.
- diff-hash: exclude active + archived handoffs — fixes receipt-churn where
  /pr-submit and /handoff committed a handoff into the hashed set, invalidating
  the just-signed receipt (one landing cost five re-signs).
- sync src/ source-of-truth copies to running (self-bootstrapping payload;
  src/agency/tools/diff-hash also catches up the Issue #254 guard it lacked).
- tests: +7 repo-parser, +9 pr-captain-land regression guards, +3 handoff-
  exclusion. 67 relevant bats green.

Consolidates the /pr-submit framework fixes (F1 default-branch, F2 credential
leak, F3 dead ERE branch + two QG-found: scheme-limited redaction, bypassable
lib guard) surfaced by mdpal-app and mdslidepal-mac agents.

## Commit: 032f18d7

**Branch:** fix/pr-submit-org-resolution
**Agent:** the-agency/jordan/pr-submit-org-resolution
**Message:** fix/pr-submit-org: fix(pr-lifecycle): make PR landing main-aware + fix receipt-churn

pr-captain-land hardcoded 'master' in three live places (origin/master diff
base, switch-branch master, gh-release --target master), which fails closed on
a repo whose default branch is main — blocking every captain PR landing here.

- pr-captain-land: resolve the default branch and use it everywhere; source the
  shared, tested pr-submit helpers (redact_remote_url/parse_org/parse_repo/
  resolve_default_branch) instead of re-deriving ORG/REPO inline; redact the
  remote on the parse-failure path (no PAT leak).
- pr-submit: add parse_repo_from_remote (companion to parse_org) for the lib.
- diff-hash: exclude active + archived handoffs — fixes receipt-churn where
  /pr-submit and /handoff committed a handoff into the hashed set, invalidating
  the just-signed receipt (one landing cost five re-signs).
- sync src/ source-of-truth copies to running (self-bootstrapping payload;
  src/agency/tools/diff-hash also catches up the Issue #254 guard it lacked).
- tests: +7 repo-parser, +9 pr-captain-land regression guards, +3 handoff-
  exclusion. 67 relevant bats green.

Consolidates the /pr-submit framework fixes (F1 default-branch, F2 credential
leak, F3 dead ERE branch + two QG-found: scheme-limited redaction, bypassable
lib guard) surfaced by mdpal-app and mdslidepal-mac agents.

### Metadata
- commit_hash: 032f18d7
- branch: fix/pr-submit-org-resolution
- files_changed: 10
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-captain-land/scripts/pr-captain-land
.claude/skills/pr-submit/scripts/pr-submit
agency/tools/diff-hash
src/agency/tools/diff-hash
src/claude/skills/pr-captain-land/scripts/pr-captain-land
src/claude/skills/pr-submit/scripts/pr-submit
src/tests/skills/pr-captain-land-helpers.bats
src/tests/skills/pr-submit-helpers.bats
src/tests/tools/diff-hash.bats
usr/jordan/pr-submit-org-resolution/dispatches/commit-to-captain-committed-7d9fc73c-on-fix-pr-submit-org-resolution-20260808-1030.md
```
