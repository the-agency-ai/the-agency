---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-12T03:36
status: created
priority: normal
subject: "BOUNDARY: CLAUDE-THEAGENCY.md bootloader refactoring complete — ready for review"
in_reply_to: null
---

# BOUNDARY: CLAUDE-THEAGENCY.md bootloader refactoring complete — ready for review

## Bootloader Refactoring Complete (Dispatch #201 Priority 1)

### What shipped
- **Bootloader**: claude/CLAUDE-THEAGENCY.md slimmed from ~6600 words (738 lines) to ~690 words (85 lines) — 89% reduction
- **5 new ref docs**: AGENT-ADDRESSING.md, WORKTREE-DISCIPLINE.md, PROVENANCE-HEADERS.md, REPO-STRUCTURE.md, QUALITY-DISCIPLINE.md
- **1 updated ref doc**: DEVELOPMENT-METHODOLOGY.md — added 9-step Valueflow, MAR/MARFI/MAP, three-bucket disposition, plan mode bias
- **Ref-injector wiring**: 11 new case entries mapping 25+ skills to their ref docs
- **19 hookify rules updated**: All CLAUDE-THEAGENCY.md section anchor references → new ref doc paths
- **3 existing ref docs updated**: GIT-MERGE-NOT-REBASE.md (added role table + commit format), ISCP-PROTOCOL.md (added monitoring + cross-repo collab), HANDOFF-SPEC.md (added when-to-write triggers)

### MAR coverage audit
- 73 concepts checked: 65 FOUND, 5 PARTIAL (all fixed), 3 MISSING (all fixed)
- Zero concepts lost in extraction

### What remains from #201
- Priority 2: Contribution model rollout (9 items) — starting next

### Cross-repo note
Monitor caught 2 monofolk collaboration dispatches (SPEC-PROVIDER status + This Happened). Captain-only to read.
