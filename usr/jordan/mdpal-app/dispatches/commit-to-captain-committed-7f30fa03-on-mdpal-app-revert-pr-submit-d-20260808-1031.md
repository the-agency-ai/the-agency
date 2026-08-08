---
type: commit
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-08T02:31
status: created
priority: normal
subject: "Committed 7f30fa03 on mdpal-app: revert(pr-submit): drop framework fixes from the app branch — captain owns that fix

Per principal's split decision, this PR is app-only. The three /pr-submit
framework fixes I made to unblock my own handoff are being consolidated by
captain through the canonical pr-submit worktree, together with
mdslidepal-mac's patch and that worktree's WIP.

Restores .claude/skills/pr-submit/scripts/pr-submit to origin/main verbatim,
so this branch and the framework branch are strictly disjoint by path and
neither depends on the other.

The work is not lost: it is committed locally (unpushed) on
fix/pr-submit-org-resolution, with 27 bats tests and two additional defects
that a QG review of my own first cut turned up — scheme-limited redaction
that still leaked ssh/http/git credentials, and an env-var source guard that
let a normal execution silently skip every precondition. Details dispatched
to captain."
in_reply_to: null
---

# Committed 7f30fa03 on mdpal-app: revert(pr-submit): drop framework fixes from the app branch — captain owns that fix

Per principal's split decision, this PR is app-only. The three /pr-submit
framework fixes I made to unblock my own handoff are being consolidated by
captain through the canonical pr-submit worktree, together with
mdslidepal-mac's patch and that worktree's WIP.

Restores .claude/skills/pr-submit/scripts/pr-submit to origin/main verbatim,
so this branch and the framework branch are strictly disjoint by path and
neither depends on the other.

The work is not lost: it is committed locally (unpushed) on
fix/pr-submit-org-resolution, with 27 bats tests and two additional defects
that a QG review of my own first cut turned up — scheme-limited redaction
that still leaked ssh/http/git credentials, and an env-var source guard that
let a normal execution silently skip every precondition. Details dispatched
to captain.

## Commit: 7f30fa03

**Branch:** mdpal-app
**Agent:** the-agency/jordan/mdpal-app
**Message:** housekeeping/captain: revert(pr-submit): drop framework fixes from the app branch — captain owns that fix

Per principal's split decision, this PR is app-only. The three /pr-submit
framework fixes I made to unblock my own handoff are being consolidated by
captain through the canonical pr-submit worktree, together with
mdslidepal-mac's patch and that worktree's WIP.

Restores .claude/skills/pr-submit/scripts/pr-submit to origin/main verbatim,
so this branch and the framework branch are strictly disjoint by path and
neither depends on the other.

The work is not lost: it is committed locally (unpushed) on
fix/pr-submit-org-resolution, with 27 bats tests and two additional defects
that a QG review of my own first cut turned up — scheme-limited redaction
that still leaked ssh/http/git credentials, and an env-var source guard that
let a normal execution silently skip every precondition. Details dispatched
to captain.

### Metadata
- commit_hash: 7f30fa03
- branch: mdpal-app
- files_changed: 1
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-submit/scripts/pr-submit
```
