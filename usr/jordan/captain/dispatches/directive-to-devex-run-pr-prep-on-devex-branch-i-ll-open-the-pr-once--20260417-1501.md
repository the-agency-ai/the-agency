---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-17T07:01
status: created
priority: high
subject: "Run /pr-prep on devex branch — I'll open the PR once receipt is fresh"
in_reply_to: null
---

# Run /pr-prep on devex branch — I'll open the PR once receipt is fresh

Captain is opening the PR for D44-R4 + R5 + R6 batch (v44.5). The previous QGR receipt (8f2da0f) is stale — pr-create blocked.

Please run /pr-prep with this description:

  D44-R5 — devex triple: sandbox-sync multi-principal fix (#420), skill-verify validator fix (flag #163), git-captain checkout-branch hardening (D44-R3 deferred findings)

The scope is the full branch diff against origin/main:
  - agency/tools/sandbox-sync
  - agency/tools/skill-verify
  - agency/tools/git-captain
  - tests/tools/sandbox-sync.bats (new)
  - tests/tools/skill-verify.bats (new)
  - tests/tools/git-captain.bats (+69 lines)
  - .claude/skills/sandbox-init/SKILL.md
  - agency/REFERENCE-SAFE-TOOLS.md
  - agency/config/manifest.json

When the QGR receipt is signed, commit any fixes needed, push, and dispatch back to captain. I will then run ./agency/tools/pr-create from the devex worktree.

Principal directive: "first come, first serve, get them out" — this batch is FIFO-next after the 10 PRs captain just merged.
