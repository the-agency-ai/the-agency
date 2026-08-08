---
type: commit
from: the-agency/jordan/pr-submit-org-resolution
to: the-agency/jordan/captain
date: 2026-08-08T03:49
status: created
priority: normal
subject: "Committed fd5d96fa on fix/pr-submit-org-resolution: fix(pr-lifecycle): QG round — harden test guards + de-stale docs

Quality-gate findings on the main-aware pr-lifecycle change, all fixed:
- test guards: the pr-captain-land 'no switch-branch master' / '--target master'
  guards false-negatived on the idiomatic QUOTED form ("master") — strengthened
  to catch both; helper-usage guards re-anchored to call sites (were matching the
  comment block → false-green); added a diff-hash file_count assertion (the
  FILE_COUNT invocation's handoff exclusion was unobserved by any test); added a
  pr-captain-land --help smoke test (exercises source+parse+resolve end-to-end and
  asserts no PAT leak); parse_repo_from_remote parity tests (dotted repo, empty).
- docs: replaced stale 'origin/master' / 'switch-branch master' / '--target master'
  in both skills' SKILL.md/reference.md/examples.md/README (the change made the code
  default-branch-aware but the docs still described the removed hardcode).
- src/ mirrors kept byte-identical.

71 relevant bats green. Deferred (noted for follow-up, not this PR): converge the
three default-branch resolvers (git-captain/pr-create/resolve_default_branch) into
one shared lib; resolve_default_branch's :-master fallback rides with that."
in_reply_to: null
---

# Committed fd5d96fa on fix/pr-submit-org-resolution: fix(pr-lifecycle): QG round — harden test guards + de-stale docs

Quality-gate findings on the main-aware pr-lifecycle change, all fixed:
- test guards: the pr-captain-land 'no switch-branch master' / '--target master'
  guards false-negatived on the idiomatic QUOTED form ("master") — strengthened
  to catch both; helper-usage guards re-anchored to call sites (were matching the
  comment block → false-green); added a diff-hash file_count assertion (the
  FILE_COUNT invocation's handoff exclusion was unobserved by any test); added a
  pr-captain-land --help smoke test (exercises source+parse+resolve end-to-end and
  asserts no PAT leak); parse_repo_from_remote parity tests (dotted repo, empty).
- docs: replaced stale 'origin/master' / 'switch-branch master' / '--target master'
  in both skills' SKILL.md/reference.md/examples.md/README (the change made the code
  default-branch-aware but the docs still described the removed hardcode).
- src/ mirrors kept byte-identical.

71 relevant bats green. Deferred (noted for follow-up, not this PR): converge the
three default-branch resolvers (git-captain/pr-create/resolve_default_branch) into
one shared lib; resolve_default_branch's :-master fallback rides with that.

## Commit: fd5d96fa

**Branch:** fix/pr-submit-org-resolution
**Agent:** the-agency/jordan/pr-submit-org-resolution
**Message:** fix/pr-submit-org: fix(pr-lifecycle): QG round — harden test guards + de-stale docs

Quality-gate findings on the main-aware pr-lifecycle change, all fixed:
- test guards: the pr-captain-land 'no switch-branch master' / '--target master'
  guards false-negatived on the idiomatic QUOTED form ("master") — strengthened
  to catch both; helper-usage guards re-anchored to call sites (were matching the
  comment block → false-green); added a diff-hash file_count assertion (the
  FILE_COUNT invocation's handoff exclusion was unobserved by any test); added a
  pr-captain-land --help smoke test (exercises source+parse+resolve end-to-end and
  asserts no PAT leak); parse_repo_from_remote parity tests (dotted repo, empty).
- docs: replaced stale 'origin/master' / 'switch-branch master' / '--target master'
  in both skills' SKILL.md/reference.md/examples.md/README (the change made the code
  default-branch-aware but the docs still described the removed hardcode).
- src/ mirrors kept byte-identical.

71 relevant bats green. Deferred (noted for follow-up, not this PR): converge the
three default-branch resolvers (git-captain/pr-create/resolve_default_branch) into
one shared lib; resolve_default_branch's :-master fallback rides with that.

### Metadata
- commit_hash: fd5d96fa
- branch: fix/pr-submit-org-resolution
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-land/examples.md
.claude/skills/pr-captain-land/reference.md
.claude/skills/pr-captain-land/scripts/pr-captain-land
.claude/skills/pr-submit/SKILL.md
.claude/skills/pr-submit/examples.md
.claude/skills/pr-submit/reference.md
.claude/skills/pr-submit/scripts/README.md
src/claude/skills/pr-captain-land/SKILL.md
src/claude/skills/pr-captain-land/examples.md
src/claude/skills/pr-captain-land/reference.md
src/claude/skills/pr-captain-land/scripts/pr-captain-land
src/claude/skills/pr-submit/SKILL.md
src/claude/skills/pr-submit/examples.md
src/claude/skills/pr-submit/reference.md
src/claude/skills/pr-submit/scripts/README.md
src/tests/skills/pr-captain-land-helpers.bats
src/tests/skills/pr-submit-helpers.bats
src/tests/tools/diff-hash.bats
usr/jordan/pr-submit-org-resolution/dispatches/commit-to-captain-committed-032f18d7-on-fix-pr-submit-org-resolution-20260808-1117.md
```
