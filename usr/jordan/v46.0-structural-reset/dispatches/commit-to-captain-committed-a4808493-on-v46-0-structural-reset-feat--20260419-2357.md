---
type: commit
from: the-agency/jordan/v46.0-structural-reset
to: the-agency/jordan/captain
date: 2026-04-19T15:57
status: created
priority: normal
subject: "Committed a4808493 on v46.0-structural-reset: feat(v46.0): Phase 0 partial — tools 4-8 (agency-sweep, import-link-check, subagent triplet)

Tools 4-8 (all with BATS tests):

Tool 4: agency-sweep
  - Path-substitution engine for Phase 4 reference rewrite
  - --dry-run default, --apply, --output-patch (valid unified diff)
  - Manifest-driven allowed + rejected substitutions
  - Cascade-prevention: post-substitution text not re-scanned
  - First-match-wins by manifest order
  - Allowlist-aware: matched lines skip substitution
  - BATS: 17 tests (min 16 per Plan v4)

Tool 5: import-link-check
  - Verifies @import and required_reading: targets resolve to on-disk files
  - Handles inline form, YAML list form, HTML comment form
  - Scopes: .claude/, agency/, claude/, CLAUDE.md (extensible via --scope)
  - --json machine output; exit 1 on any orphan
  - BATS: 11 tests (min 10)

Tool 6: subagent-scope-check
  - Verifies subagent branch stayed within manifest files: globs
  - Non-emptiness assertion (unless expected_changes: 0 declared)
  - BATS: 7 tests (min 6)

Tool 7: subagent-diff-verify
  - Line-level reconstruction: apply manifest substitutions to (-) line,
    assert equals (+) line
  - Rejects whitespace-only changes, binary changes, free-text edits
  - Test fixture path exempt
  - BATS: 11 tests (min 10)

Tool 8: subagent-overlap-check
  - Pairwise manifest overlap detection with ownership_priority tie-break
  - Reports winner/loser per overlap; --json for machine consumption
  - BATS: 6 tests (min 5)

Running total: 8/20 Phase 0b tools complete with BATS green. Plan v4 Principle 8
(tool-with-BATS-before-invocation) maintained. Continuing with audit-log
pair + hookify-rule-canary + agency-* tools next."
in_reply_to: null
---

# Committed a4808493 on v46.0-structural-reset: feat(v46.0): Phase 0 partial — tools 4-8 (agency-sweep, import-link-check, subagent triplet)

Tools 4-8 (all with BATS tests):

Tool 4: agency-sweep
  - Path-substitution engine for Phase 4 reference rewrite
  - --dry-run default, --apply, --output-patch (valid unified diff)
  - Manifest-driven allowed + rejected substitutions
  - Cascade-prevention: post-substitution text not re-scanned
  - First-match-wins by manifest order
  - Allowlist-aware: matched lines skip substitution
  - BATS: 17 tests (min 16 per Plan v4)

Tool 5: import-link-check
  - Verifies @import and required_reading: targets resolve to on-disk files
  - Handles inline form, YAML list form, HTML comment form
  - Scopes: .claude/, agency/, claude/, CLAUDE.md (extensible via --scope)
  - --json machine output; exit 1 on any orphan
  - BATS: 11 tests (min 10)

Tool 6: subagent-scope-check
  - Verifies subagent branch stayed within manifest files: globs
  - Non-emptiness assertion (unless expected_changes: 0 declared)
  - BATS: 7 tests (min 6)

Tool 7: subagent-diff-verify
  - Line-level reconstruction: apply manifest substitutions to (-) line,
    assert equals (+) line
  - Rejects whitespace-only changes, binary changes, free-text edits
  - Test fixture path exempt
  - BATS: 11 tests (min 10)

Tool 8: subagent-overlap-check
  - Pairwise manifest overlap detection with ownership_priority tie-break
  - Reports winner/loser per overlap; --json for machine consumption
  - BATS: 6 tests (min 5)

Running total: 8/20 Phase 0b tools complete with BATS green. Plan v4 Principle 8
(tool-with-BATS-before-invocation) maintained. Continuing with audit-log
pair + hookify-rule-canary + agency-* tools next.

## Commit: a4808493

**Branch:** v46.0-structural-reset
**Agent:** the-agency/jordan/v46.0-structural-reset
**Message:** housekeeping/captain: feat(v46.0): Phase 0 partial — tools 4-8 (agency-sweep, import-link-check, subagent triplet)

Tools 4-8 (all with BATS tests):

Tool 4: agency-sweep
  - Path-substitution engine for Phase 4 reference rewrite
  - --dry-run default, --apply, --output-patch (valid unified diff)
  - Manifest-driven allowed + rejected substitutions
  - Cascade-prevention: post-substitution text not re-scanned
  - First-match-wins by manifest order
  - Allowlist-aware: matched lines skip substitution
  - BATS: 17 tests (min 16 per Plan v4)

Tool 5: import-link-check
  - Verifies @import and required_reading: targets resolve to on-disk files
  - Handles inline form, YAML list form, HTML comment form
  - Scopes: .claude/, agency/, claude/, CLAUDE.md (extensible via --scope)
  - --json machine output; exit 1 on any orphan
  - BATS: 11 tests (min 10)

Tool 6: subagent-scope-check
  - Verifies subagent branch stayed within manifest files: globs
  - Non-emptiness assertion (unless expected_changes: 0 declared)
  - BATS: 7 tests (min 6)

Tool 7: subagent-diff-verify
  - Line-level reconstruction: apply manifest substitutions to (-) line,
    assert equals (+) line
  - Rejects whitespace-only changes, binary changes, free-text edits
  - Test fixture path exempt
  - BATS: 11 tests (min 10)

Tool 8: subagent-overlap-check
  - Pairwise manifest overlap detection with ownership_priority tie-break
  - Reports winner/loser per overlap; --json for machine consumption
  - BATS: 6 tests (min 5)

Running total: 8/20 Phase 0b tools complete with BATS green. Plan v4 Principle 8
(tool-with-BATS-before-invocation) maintained. Continuing with audit-log
pair + hookify-rule-canary + agency-* tools next.

### Metadata
- commit_hash: a4808493
- branch: v46.0-structural-reset
- files_changed: 15
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/agency-sweep
agency/tools/import-link-check
agency/tools/secret-test-help
agency/tools/subagent-diff-verify
agency/tools/subagent-overlap-check
agency/tools/subagent-scope-check
tests/tools/agency-sweep.bats
tests/tools/import-link-check.bats
tests/tools/subagent-diff-verify.bats
tests/tools/subagent-overlap-check.bats
tests/tools/subagent-scope-check.bats
usr/jordan/captain/reset-baseline-20260419/bats-baseline.txt
usr/jordan/captain/reset-baseline-20260419/ref-inventory-pre.txt
usr/jordan/captain/reset-baseline-20260419/sensitive-dirs-sha256.txt
usr/jordan/v46.0-structural-reset/dispatches/commit-to-captain-committed-0401f768-on-v46-0-structural-reset-feat--20260419-2344.md
```
