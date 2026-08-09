---
type: commit
from: the-agency/jordan/pr-lifecycle-v2
to: the-agency/jordan/captain
date: 2026-08-09T15:35
status: created
priority: normal
subject: "Committed 9786aac1 on pr-lifecycle-v2: devex/pr-lifecycle-v2: feat(pr-captain-land): local-first landing via scratch worktree + shared default-branch primitive

Re-orients the captain PR-landing lifecycle to LOCAL-FIRST per
plan-pr-captain-land-localfirst-20260809 v2 (MAR-reviewed).

The whole landing now runs in a dedicated scratch worktree cut from
origin/<agent-branch>. The main checkout is never switched, local main is
never merged into or reset, and rollback at any pre-publish failure is
'delete the scratch worktree'. Validation happens LOCALLY before a PR
exists; GitHub confirms rather than gates.

New primitives:
- agency/tools/resolve-default-branch — union of the 7 drifted resolvers,
  with --strict so fail-closed consumers keep failing loud
- agency/tools/pkg-manager — lockfile-based package-manager resolver, so
  skills never name one inline

Converged onto resolve-default-branch: git-captain (--strict), pr-create
(--strict), pr-submit (thin wrapper, name preserved for pr-captain-land),
_sync-main-ref (was hardcoded origin/main). dispatch/pr-build/worktree-sync
are explicitly deferred.

Also: worktree-create gains --from <ref> and allows a leading underscore;
workstream-create validates its name (it was creating a literal
'test; rm -rf ' directory in the real repo on every full test run).

Tests: resolve-default-branch (15), pkg-manager (9),
pr-captain-land-localfirst (30), plus fixture fixes to git-captain,
worktree-create, worktree-cwd-check (dark since the great rename),
scaffolding, triage-wave-I.

All 21 agency/ <-> src/ mirror pairs byte-identical."
in_reply_to: null
---

# Committed 9786aac1 on pr-lifecycle-v2: devex/pr-lifecycle-v2: feat(pr-captain-land): local-first landing via scratch worktree + shared default-branch primitive

Re-orients the captain PR-landing lifecycle to LOCAL-FIRST per
plan-pr-captain-land-localfirst-20260809 v2 (MAR-reviewed).

The whole landing now runs in a dedicated scratch worktree cut from
origin/<agent-branch>. The main checkout is never switched, local main is
never merged into or reset, and rollback at any pre-publish failure is
'delete the scratch worktree'. Validation happens LOCALLY before a PR
exists; GitHub confirms rather than gates.

New primitives:
- agency/tools/resolve-default-branch — union of the 7 drifted resolvers,
  with --strict so fail-closed consumers keep failing loud
- agency/tools/pkg-manager — lockfile-based package-manager resolver, so
  skills never name one inline

Converged onto resolve-default-branch: git-captain (--strict), pr-create
(--strict), pr-submit (thin wrapper, name preserved for pr-captain-land),
_sync-main-ref (was hardcoded origin/main). dispatch/pr-build/worktree-sync
are explicitly deferred.

Also: worktree-create gains --from <ref> and allows a leading underscore;
workstream-create validates its name (it was creating a literal
'test; rm -rf ' directory in the real repo on every full test run).

Tests: resolve-default-branch (15), pkg-manager (9),
pr-captain-land-localfirst (30), plus fixture fixes to git-captain,
worktree-create, worktree-cwd-check (dark since the great rename),
scaffolding, triage-wave-I.

All 21 agency/ <-> src/ mirror pairs byte-identical.

## Commit: 9786aac1

**Branch:** pr-lifecycle-v2
**Agent:** the-agency/jordan/pr-lifecycle-v2
**Message:** housekeeping/captain: devex/pr-lifecycle-v2: feat(pr-captain-land): local-first landing via scratch worktree + shared default-branch primitive

Re-orients the captain PR-landing lifecycle to LOCAL-FIRST per
plan-pr-captain-land-localfirst-20260809 v2 (MAR-reviewed).

The whole landing now runs in a dedicated scratch worktree cut from
origin/<agent-branch>. The main checkout is never switched, local main is
never merged into or reset, and rollback at any pre-publish failure is
'delete the scratch worktree'. Validation happens LOCALLY before a PR
exists; GitHub confirms rather than gates.

New primitives:
- agency/tools/resolve-default-branch — union of the 7 drifted resolvers,
  with --strict so fail-closed consumers keep failing loud
- agency/tools/pkg-manager — lockfile-based package-manager resolver, so
  skills never name one inline

Converged onto resolve-default-branch: git-captain (--strict), pr-create
(--strict), pr-submit (thin wrapper, name preserved for pr-captain-land),
_sync-main-ref (was hardcoded origin/main). dispatch/pr-build/worktree-sync
are explicitly deferred.

Also: worktree-create gains --from <ref> and allows a leading underscore;
workstream-create validates its name (it was creating a literal
'test; rm -rf ' directory in the real repo on every full test run).

Tests: resolve-default-branch (15), pkg-manager (9),
pr-captain-land-localfirst (30), plus fixture fixes to git-captain,
worktree-create, worktree-cwd-check (dark since the great rename),
scaffolding, triage-wave-I.

All 21 agency/ <-> src/ mirror pairs byte-identical.

### Metadata
- commit_hash: 9786aac1
- branch: pr-lifecycle-v2
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/captain-sync-all/reference.md
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-land/examples.md
.claude/skills/pr-captain-land/reference.md
.claude/skills/pr-captain-land/scripts/pr-captain-land
.claude/skills/pr-captain-merge/SKILL.md
.claude/skills/pr-captain-merge/examples.md
.claude/skills/pr-captain-merge/reference.md
.claude/skills/pr-captain-post-merge/SKILL.md
.claude/skills/pr-captain-post-merge/examples.md
.claude/skills/pr-captain-post-merge/reference.md
.claude/skills/pr-submit/scripts/pr-submit
agency/REFERENCE/REFERENCE-CODE-REVIEW-LIFECYCLE.md
agency/REFERENCE/REFERENCE-SKILLS-INDEX.md
agency/tools/_sync-main-ref
agency/tools/git-captain
agency/tools/pkg-manager
agency/tools/pr-create
agency/tools/resolve-default-branch
agency/tools/workstream-create
```
