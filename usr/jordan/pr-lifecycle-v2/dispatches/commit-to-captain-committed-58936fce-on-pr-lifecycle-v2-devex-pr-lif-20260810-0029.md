---
type: commit
from: the-agency/jordan/pr-lifecycle-v2
to: the-agency/jordan/captain
date: 2026-08-09T16:29
status: created
priority: normal
subject: "Committed 58936fce on pr-lifecycle-v2: devex/pr-lifecycle-v2: fix(pr-captain-land): QG fix cycle — 4-agent review findings

Fixes from the pre-PR quality gate (4 parallel reviewers on the local-first
rewrite). The reviewers found real defects, not nits.

CORRECTNESS
- LAND_SLUG collapsed only slashes while worktree-create rejects dots, so
  every dotted branch (v1.2, 46.20) was unlandable behind an opaque error.
- No EXIT trap: any set -e abort between steps 2 and 6 stranded the scratch
  worktree and wedged all future lands of that branch. Trap added, disarmed
  at the publish boundary.
- Step 0 checked only for a leftover scratch DIRECTORY; a crash leaving only
  the branch made worktree-create refuse forever with no visible cause.
- AGENT_HASH_E extraction had no '|| true' — a receipt lacking hash_e killed
  the script silently and made its own fallback dead code.
- Version bump: inline python sys.exit(1) killed the caller before its error
  could run. Extracted to agency/tools/agency-version-next (NOT version-next,
  which already exists for the VERSION file's build identifier).
- NO_CHECKS was fatal on the first poll — i.e. on almost every real land.
  3-minute grace window added.
- mktemp -t is a BSD-ism; PR_NUM/PR_URL scraping could kill the script after
  publishing. Both fixed.

TRUST / SECURITY
- Every verifying and publishing tool (receipt-verify, diff-hash, pr-create,
  git-safe-commit, ...) was executed FROM the branch under review. A branch
  shipping its own receipt-verify passed its own gate. All now resolve from
  $TOOLS = the captain's checkout, with cwd in the scratch.
- --principal-approved was hardcoded on pr-merge, making branch-protection
  bypass the default merge mode. Now an explicit flag, also recorded in the
  receipt's hash_d_source.
- Validation steps run with GH_TOKEN/GITHUB_TOKEN/SSH_AUTH_SOCK scrubbed;
  their output is tailed to the transcript on failure.
- pr-submit's ${PRIORITY:+--priority "$PRIORITY"} word-split, allowing flag
  injection into dispatch create. Priority is validated at parse time.

DESIGN
- resolve-default-branch probed LOCAL refs first, so a stale local 'main' in
  a master-default clone made every consumer build a nonexistent origin/main
  — issue #107 through the local-refs door. Order is now remote-authoritative;
  local refs are the offline fallback. Conflict cases now tested.
- commit-precheck counted as a validation step while inspecting nothing (the
  scratch tree is clean), which suppressed the no-validation path and put a
  false step count into a signed receipt. Removed from the ladder.
- Zero validation steps now ABORTS (--allow-unvalidated to override) instead
  of signing a receipt for a gate that never ran.
- Fetch failure is fatal. post-merge-state is checked at preflight and no
  longer cleared when no release was cut.
- Dispatch recipient resolved against the agent registry, not guessed.

TESTS
- New: ci-rollup-verdict.bats (32) — the CI classifier extracted from a
  heredoc where every guard passed with PASS/FAIL swapped.
- New: agency-version-next.bats (19). pkg-manager.bats rewritten with PATH
  stubs (22, was skip-dependent). resolve-default-branch.bats +6 conflict
  cases. pr-captain-land-localfirst.bats 30 → 44, tautological guards
  replaced with real unit tests.
- scaffolding.bats now cleans up after itself: it was leaving
  agency/agents/testname in the real repo, reddening two other suites.

Full suite: 1398 pass / 323 fail — zero new failures vs main's baseline
(333), and 10 pre-existing failures fixed. All 25 agency/ <-> src/ mirror
pairs byte-identical."
in_reply_to: null
---

# Committed 58936fce on pr-lifecycle-v2: devex/pr-lifecycle-v2: fix(pr-captain-land): QG fix cycle — 4-agent review findings

Fixes from the pre-PR quality gate (4 parallel reviewers on the local-first
rewrite). The reviewers found real defects, not nits.

CORRECTNESS
- LAND_SLUG collapsed only slashes while worktree-create rejects dots, so
  every dotted branch (v1.2, 46.20) was unlandable behind an opaque error.
- No EXIT trap: any set -e abort between steps 2 and 6 stranded the scratch
  worktree and wedged all future lands of that branch. Trap added, disarmed
  at the publish boundary.
- Step 0 checked only for a leftover scratch DIRECTORY; a crash leaving only
  the branch made worktree-create refuse forever with no visible cause.
- AGENT_HASH_E extraction had no '|| true' — a receipt lacking hash_e killed
  the script silently and made its own fallback dead code.
- Version bump: inline python sys.exit(1) killed the caller before its error
  could run. Extracted to agency/tools/agency-version-next (NOT version-next,
  which already exists for the VERSION file's build identifier).
- NO_CHECKS was fatal on the first poll — i.e. on almost every real land.
  3-minute grace window added.
- mktemp -t is a BSD-ism; PR_NUM/PR_URL scraping could kill the script after
  publishing. Both fixed.

TRUST / SECURITY
- Every verifying and publishing tool (receipt-verify, diff-hash, pr-create,
  git-safe-commit, ...) was executed FROM the branch under review. A branch
  shipping its own receipt-verify passed its own gate. All now resolve from
  $TOOLS = the captain's checkout, with cwd in the scratch.
- --principal-approved was hardcoded on pr-merge, making branch-protection
  bypass the default merge mode. Now an explicit flag, also recorded in the
  receipt's hash_d_source.
- Validation steps run with GH_TOKEN/GITHUB_TOKEN/SSH_AUTH_SOCK scrubbed;
  their output is tailed to the transcript on failure.
- pr-submit's ${PRIORITY:+--priority "$PRIORITY"} word-split, allowing flag
  injection into dispatch create. Priority is validated at parse time.

DESIGN
- resolve-default-branch probed LOCAL refs first, so a stale local 'main' in
  a master-default clone made every consumer build a nonexistent origin/main
  — issue #107 through the local-refs door. Order is now remote-authoritative;
  local refs are the offline fallback. Conflict cases now tested.
- commit-precheck counted as a validation step while inspecting nothing (the
  scratch tree is clean), which suppressed the no-validation path and put a
  false step count into a signed receipt. Removed from the ladder.
- Zero validation steps now ABORTS (--allow-unvalidated to override) instead
  of signing a receipt for a gate that never ran.
- Fetch failure is fatal. post-merge-state is checked at preflight and no
  longer cleared when no release was cut.
- Dispatch recipient resolved against the agent registry, not guessed.

TESTS
- New: ci-rollup-verdict.bats (32) — the CI classifier extracted from a
  heredoc where every guard passed with PASS/FAIL swapped.
- New: agency-version-next.bats (19). pkg-manager.bats rewritten with PATH
  stubs (22, was skip-dependent). resolve-default-branch.bats +6 conflict
  cases. pr-captain-land-localfirst.bats 30 → 44, tautological guards
  replaced with real unit tests.
- scaffolding.bats now cleans up after itself: it was leaving
  agency/agents/testname in the real repo, reddening two other suites.

Full suite: 1398 pass / 323 fail — zero new failures vs main's baseline
(333), and 10 pre-existing failures fixed. All 25 agency/ <-> src/ mirror
pairs byte-identical.

## Commit: 58936fce

**Branch:** pr-lifecycle-v2
**Agent:** the-agency/jordan/pr-lifecycle-v2
**Message:** housekeeping/captain: devex/pr-lifecycle-v2: fix(pr-captain-land): QG fix cycle — 4-agent review findings

Fixes from the pre-PR quality gate (4 parallel reviewers on the local-first
rewrite). The reviewers found real defects, not nits.

CORRECTNESS
- LAND_SLUG collapsed only slashes while worktree-create rejects dots, so
  every dotted branch (v1.2, 46.20) was unlandable behind an opaque error.
- No EXIT trap: any set -e abort between steps 2 and 6 stranded the scratch
  worktree and wedged all future lands of that branch. Trap added, disarmed
  at the publish boundary.
- Step 0 checked only for a leftover scratch DIRECTORY; a crash leaving only
  the branch made worktree-create refuse forever with no visible cause.
- AGENT_HASH_E extraction had no '|| true' — a receipt lacking hash_e killed
  the script silently and made its own fallback dead code.
- Version bump: inline python sys.exit(1) killed the caller before its error
  could run. Extracted to agency/tools/agency-version-next (NOT version-next,
  which already exists for the VERSION file's build identifier).
- NO_CHECKS was fatal on the first poll — i.e. on almost every real land.
  3-minute grace window added.
- mktemp -t is a BSD-ism; PR_NUM/PR_URL scraping could kill the script after
  publishing. Both fixed.

TRUST / SECURITY
- Every verifying and publishing tool (receipt-verify, diff-hash, pr-create,
  git-safe-commit, ...) was executed FROM the branch under review. A branch
  shipping its own receipt-verify passed its own gate. All now resolve from
  $TOOLS = the captain's checkout, with cwd in the scratch.
- --principal-approved was hardcoded on pr-merge, making branch-protection
  bypass the default merge mode. Now an explicit flag, also recorded in the
  receipt's hash_d_source.
- Validation steps run with GH_TOKEN/GITHUB_TOKEN/SSH_AUTH_SOCK scrubbed;
  their output is tailed to the transcript on failure.
- pr-submit's ${PRIORITY:+--priority "$PRIORITY"} word-split, allowing flag
  injection into dispatch create. Priority is validated at parse time.

DESIGN
- resolve-default-branch probed LOCAL refs first, so a stale local 'main' in
  a master-default clone made every consumer build a nonexistent origin/main
  — issue #107 through the local-refs door. Order is now remote-authoritative;
  local refs are the offline fallback. Conflict cases now tested.
- commit-precheck counted as a validation step while inspecting nothing (the
  scratch tree is clean), which suppressed the no-validation path and put a
  false step count into a signed receipt. Removed from the ladder.
- Zero validation steps now ABORTS (--allow-unvalidated to override) instead
  of signing a receipt for a gate that never ran.
- Fetch failure is fatal. post-merge-state is checked at preflight and no
  longer cleared when no release was cut.
- Dispatch recipient resolved against the agent registry, not guessed.

TESTS
- New: ci-rollup-verdict.bats (32) — the CI classifier extracted from a
  heredoc where every guard passed with PASS/FAIL swapped.
- New: agency-version-next.bats (19). pkg-manager.bats rewritten with PATH
  stubs (22, was skip-dependent). resolve-default-branch.bats +6 conflict
  cases. pr-captain-land-localfirst.bats 30 → 44, tautological guards
  replaced with real unit tests.
- scaffolding.bats now cleans up after itself: it was leaving
  agency/agents/testname in the real repo, reddening two other suites.

Full suite: 1398 pass / 323 fail — zero new failures vs main's baseline
(333), and 10 pre-existing failures fixed. All 25 agency/ <-> src/ mirror
pairs byte-identical.

### Metadata
- commit_hash: 58936fce
- branch: pr-lifecycle-v2
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/captain-release/reference.md
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-land/examples.md
.claude/skills/pr-captain-land/reference.md
.claude/skills/pr-captain-land/scripts/pr-captain-land
.claude/skills/pr-submit/scripts/pr-submit
agency/tools/agency-version-next
agency/tools/ci-rollup-verdict
agency/tools/pkg-manager
agency/tools/resolve-default-branch
agency/tools/worktree-create
src/agency/tools/agency-version-next
src/agency/tools/ci-rollup-verdict
src/agency/tools/pkg-manager
src/agency/tools/resolve-default-branch
src/agency/tools/worktree-create
src/claude/skills/captain-release/reference.md
src/claude/skills/pr-captain-land/SKILL.md
src/claude/skills/pr-captain-land/examples.md
src/claude/skills/pr-captain-land/reference.md
```
