---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-17T06:38
status: created
priority: normal
subject: "Committed 94e2667 on devex: D44-R4: feat: sandbox-sync 2 bug fixes (closes #420)

Two bugs reported by monofolk MAR, both blocking multi-principal agency setups:

**Bug 1 — Engineer detection alphabetical fallback.**
Previously when $USER didn't match any usr/<name>/ directory, sandbox-sync fell
back to the first-alphabetical sandbox dir (gave 'jordan' to Peter in multi-
principal setups). Now resolves via `claude/config/agency.yaml` using $USER
as the key into the `principals:` block (the schema-supported approach).
Refuses with a clear error if no mapping and no usr/$USER/ sandbox exists —
no silent alphabetical fallback.

Resolution order:
  1. $PRINCIPAL env var (explicit override)
  2. agency.yaml `principals.$USER.name`
  3. `usr/$USER/` bootstrap fallback (for sandboxes named after the system user
     but not yet registered in agency.yaml)
  4. Refuse with actionable error

**Bug 2 — Path mismatch commands/ vs claude/commands/.**
sandbox-sync reads from `usr/<name>/commands/`, `usr/<name>/hookify/`, etc.
(no `claude/` prefix). sandbox-init skill previously documented
`usr/<name>/claude/commands/` — inconsistent with reality and with monofolk's
recommendation. Per captain directive #420, monofolk's recommended convention
(commands/ with no prefix) is correct. Updated the sandbox-init skill to match:

  usr/<name>/
    commands/ hooks/ hookify/ agents/   # no 'claude/' prefix
    CLAUDE.md settings.local.json       # at sandbox root
    scripts/ tools/ README.md

**Tests:** new tests/tools/sandbox-sync.bats — 11 tests covering the
engineer-detection resolution order (6 cases) and the post-D44-R4 path
conventions (3 cases) plus basic idempotency + --quiet behavior.

Fixes #420 item 1 (engineer detection) and #420 item 2 (path alignment).
Does not retrofit the other sandbox-* skills (sandbox-create, sandbox-try,
etc.) which still reference `usr/*/claude/commands/` — those are a separate
alignment pass, flagged for follow-up."
in_reply_to: null
---

# Committed 94e2667 on devex: D44-R4: feat: sandbox-sync 2 bug fixes (closes #420)

Two bugs reported by monofolk MAR, both blocking multi-principal agency setups:

**Bug 1 — Engineer detection alphabetical fallback.**
Previously when $USER didn't match any usr/<name>/ directory, sandbox-sync fell
back to the first-alphabetical sandbox dir (gave 'jordan' to Peter in multi-
principal setups). Now resolves via `claude/config/agency.yaml` using $USER
as the key into the `principals:` block (the schema-supported approach).
Refuses with a clear error if no mapping and no usr/$USER/ sandbox exists —
no silent alphabetical fallback.

Resolution order:
  1. $PRINCIPAL env var (explicit override)
  2. agency.yaml `principals.$USER.name`
  3. `usr/$USER/` bootstrap fallback (for sandboxes named after the system user
     but not yet registered in agency.yaml)
  4. Refuse with actionable error

**Bug 2 — Path mismatch commands/ vs claude/commands/.**
sandbox-sync reads from `usr/<name>/commands/`, `usr/<name>/hookify/`, etc.
(no `claude/` prefix). sandbox-init skill previously documented
`usr/<name>/claude/commands/` — inconsistent with reality and with monofolk's
recommendation. Per captain directive #420, monofolk's recommended convention
(commands/ with no prefix) is correct. Updated the sandbox-init skill to match:

  usr/<name>/
    commands/ hooks/ hookify/ agents/   # no 'claude/' prefix
    CLAUDE.md settings.local.json       # at sandbox root
    scripts/ tools/ README.md

**Tests:** new tests/tools/sandbox-sync.bats — 11 tests covering the
engineer-detection resolution order (6 cases) and the post-D44-R4 path
conventions (3 cases) plus basic idempotency + --quiet behavior.

Fixes #420 item 1 (engineer detection) and #420 item 2 (path alignment).
Does not retrofit the other sandbox-* skills (sandbox-create, sandbox-try,
etc.) which still reference `usr/*/claude/commands/` — those are a separate
alignment pass, flagged for follow-up.

## Commit: 94e2667

**Branch:** devex
**Agent:** the-agency/jordan/devex
**Message:** housekeeping/captain: D44-R4: feat: sandbox-sync 2 bug fixes (closes #420)

Two bugs reported by monofolk MAR, both blocking multi-principal agency setups:

**Bug 1 — Engineer detection alphabetical fallback.**
Previously when $USER didn't match any usr/<name>/ directory, sandbox-sync fell
back to the first-alphabetical sandbox dir (gave 'jordan' to Peter in multi-
principal setups). Now resolves via `claude/config/agency.yaml` using $USER
as the key into the `principals:` block (the schema-supported approach).
Refuses with a clear error if no mapping and no usr/$USER/ sandbox exists —
no silent alphabetical fallback.

Resolution order:
  1. $PRINCIPAL env var (explicit override)
  2. agency.yaml `principals.$USER.name`
  3. `usr/$USER/` bootstrap fallback (for sandboxes named after the system user
     but not yet registered in agency.yaml)
  4. Refuse with actionable error

**Bug 2 — Path mismatch commands/ vs claude/commands/.**
sandbox-sync reads from `usr/<name>/commands/`, `usr/<name>/hookify/`, etc.
(no `claude/` prefix). sandbox-init skill previously documented
`usr/<name>/claude/commands/` — inconsistent with reality and with monofolk's
recommendation. Per captain directive #420, monofolk's recommended convention
(commands/ with no prefix) is correct. Updated the sandbox-init skill to match:

  usr/<name>/
    commands/ hooks/ hookify/ agents/   # no 'claude/' prefix
    CLAUDE.md settings.local.json       # at sandbox root
    scripts/ tools/ README.md

**Tests:** new tests/tools/sandbox-sync.bats — 11 tests covering the
engineer-detection resolution order (6 cases) and the post-D44-R4 path
conventions (3 cases) plus basic idempotency + --quiet behavior.

Fixes #420 item 1 (engineer detection) and #420 item 2 (path alignment).
Does not retrofit the other sandbox-* skills (sandbox-create, sandbox-try,
etc.) which still reference `usr/*/claude/commands/` — those are a separate
alignment pass, flagged for follow-up.

### Metadata
- commit_hash: 94e2667
- branch: devex
- files_changed: 5
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/sandbox-init/SKILL.md
claude/tools/sandbox-sync
tests/tools/sandbox-sync.bats
usr/jordan/devex/dispatches/commit-to-captain-committed-2f2dd02-on-devex-d44-r3-add-qgr-receipt--20260417-1324.md
usr/jordan/devex/dispatches/dispatch-to-captain-d44-r3-pr-ready-for-merge-pr-182-20260417-1325.md
```
