---
type: escalation
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T01:01
status: created
priority: normal
subject: "Secret tool missing — tests/tools/secret.bats has 21 failures"
in_reply_to: null
---

# Secret tool missing — tests/tools/secret.bats has 21 failures

## Finding

agency/tools/secret does not exist on the devex branch (or master). However, tests/tools/secret.bats references it and has 31 tests — 21 of which fail with exit code 127 (command not found).

This predates DevEx work — discovered during Phase 1.1 universal test isolation, where all 37 BATS files were run.

## Impact

- 21 test failures in the suite that are silent unless you run the full battery
- The secret tool was either deleted, never implemented, or lives elsewhere

## Request

Captain: please investigate whether secret was deleted, moved, or never landed. Either restore the tool or remove the orphaned test file.
