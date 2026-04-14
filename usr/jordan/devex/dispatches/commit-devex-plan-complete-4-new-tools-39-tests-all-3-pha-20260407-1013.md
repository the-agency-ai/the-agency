---
type: commit
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T02:13
status: created
priority: normal
subject: "DevEx plan complete — 4 new tools, 39 tests, all 3 phases shipped"
in_reply_to: null
---

# DevEx plan complete — 4 new tools, 39 tests, all 3 phases shipped

## DevEx Plan Complete

All 10 iterations across 3 phases shipped on the devex branch. Ready for /sync-all and PR prep.

### New tools
- `test-scoper` — convention-based file→test mapping
- `test-full-suite` — Docker + in-process fallback (T3)
- `enforcement-audit` — validates enforcement.yaml registry
- `context-budget-lint` — @-import chain token estimation

### Key changes
- `commit-precheck` v3: classify→scope→run, 60s budget, docs fast path
- `settings-template.json`: cleaned + expanded permissions (no destructive ops)
- `enforcement.yaml`: 19 capabilities registered, all passing audit
- `docker-test.sh`: extended from 7 to 36 BATS files
- 39 new BATS tests across 4 test files

### Commits on devex branch
- `aa04513` Phase 1.2+1.3: test-scoper + commit-precheck rewrite
- `c2b6bf2` Phase 1.4: tests (25)
- `3ad7993` Phase 2: Docker full suite + test-full-suite
- `435dad1` Phase 3.1-3.3: permissions, enforcement, context budget
- `b976409` Phase 3.4: tests (14)

### Pre-existing issues noted (not regressions)
- setup-agency tool missing (tests reference it)
- platform-setup refs to deleted mac-setup/linux-setup tools
- jsonschema not installed (findings-consolidate)
