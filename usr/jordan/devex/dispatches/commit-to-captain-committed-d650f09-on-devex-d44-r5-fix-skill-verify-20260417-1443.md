---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-17T06:43
status: created
priority: normal
subject: "Committed d650f09 on devex: D44-R5: fix: skill-verify validator matches current skill convention (flag #163)

The validator required every SKILL.md to include an `allowed-tools:` frontmatter
field. But per flag #62 / flag #63 (devex dispatch #171), `allowed-tools:` was
intentionally removed from every shipping skill: restricting to specific
subcommand patterns silently blocked agents on permission prompts they could
not see. Every SKILL.md now documents this rationale in its header comment,
yet the validator continued rejecting all 59 skills, which blocked
`/quality-gate` Step 0 precondition on every run.

**Fix:** validator now requires a well-formed frontmatter block with a non-
empty `description:` field — and treats `allowed-tools:` as optional. Both
pre- and post-flag-#62/#63 skills validate cleanly.

**Also:** `skill-verify` now honors an explicit `AGENCY_PROJECT_ROOT` env
var. Previously `_path-resolve` (sourced by the script) recomputed the
project root from its own script location, silently overwriting any
operator-set override. This made it impossible to test the validator against
a fixture `.claude/skills/` directory.

**Tests:** new tests/tools/skill-verify.bats — 11 tests covering:
- happy path (description-only frontmatter, no allowed-tools) ✓ accepts
- backward compat (description + allowed-tools) ✓ accepts
- rejects no frontmatter, empty description, missing description, empty file
- reports missing SKILL.md
- --quiet flag, --help flag
- LIVE sanity: all 59 shipping framework skills validate (would have caught
  the original regression)

Fixes flag #163."
in_reply_to: null
---

# Committed d650f09 on devex: D44-R5: fix: skill-verify validator matches current skill convention (flag #163)

The validator required every SKILL.md to include an `allowed-tools:` frontmatter
field. But per flag #62 / flag #63 (devex dispatch #171), `allowed-tools:` was
intentionally removed from every shipping skill: restricting to specific
subcommand patterns silently blocked agents on permission prompts they could
not see. Every SKILL.md now documents this rationale in its header comment,
yet the validator continued rejecting all 59 skills, which blocked
`/quality-gate` Step 0 precondition on every run.

**Fix:** validator now requires a well-formed frontmatter block with a non-
empty `description:` field — and treats `allowed-tools:` as optional. Both
pre- and post-flag-#62/#63 skills validate cleanly.

**Also:** `skill-verify` now honors an explicit `AGENCY_PROJECT_ROOT` env
var. Previously `_path-resolve` (sourced by the script) recomputed the
project root from its own script location, silently overwriting any
operator-set override. This made it impossible to test the validator against
a fixture `.claude/skills/` directory.

**Tests:** new tests/tools/skill-verify.bats — 11 tests covering:
- happy path (description-only frontmatter, no allowed-tools) ✓ accepts
- backward compat (description + allowed-tools) ✓ accepts
- rejects no frontmatter, empty description, missing description, empty file
- reports missing SKILL.md
- --quiet flag, --help flag
- LIVE sanity: all 59 shipping framework skills validate (would have caught
  the original regression)

Fixes flag #163.

## Commit: d650f09

**Branch:** devex
**Agent:** the-agency/jordan/devex
**Message:** housekeeping/captain: D44-R5: fix: skill-verify validator matches current skill convention (flag #163)

The validator required every SKILL.md to include an `allowed-tools:` frontmatter
field. But per flag #62 / flag #63 (devex dispatch #171), `allowed-tools:` was
intentionally removed from every shipping skill: restricting to specific
subcommand patterns silently blocked agents on permission prompts they could
not see. Every SKILL.md now documents this rationale in its header comment,
yet the validator continued rejecting all 59 skills, which blocked
`/quality-gate` Step 0 precondition on every run.

**Fix:** validator now requires a well-formed frontmatter block with a non-
empty `description:` field — and treats `allowed-tools:` as optional. Both
pre- and post-flag-#62/#63 skills validate cleanly.

**Also:** `skill-verify` now honors an explicit `AGENCY_PROJECT_ROOT` env
var. Previously `_path-resolve` (sourced by the script) recomputed the
project root from its own script location, silently overwriting any
operator-set override. This made it impossible to test the validator against
a fixture `.claude/skills/` directory.

**Tests:** new tests/tools/skill-verify.bats — 11 tests covering:
- happy path (description-only frontmatter, no allowed-tools) ✓ accepts
- backward compat (description + allowed-tools) ✓ accepts
- rejects no frontmatter, empty description, missing description, empty file
- reports missing SKILL.md
- --quiet flag, --help flag
- LIVE sanity: all 59 shipping framework skills validate (would have caught
  the original regression)

Fixes flag #163.

### Metadata
- commit_hash: d650f09
- branch: devex
- files_changed: 3
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/skill-verify
tests/tools/skill-verify.bats
usr/jordan/devex/dispatches/commit-to-captain-committed-94e2667-on-devex-d44-r4-feat-sandbox-syn-20260417-1438.md
```
