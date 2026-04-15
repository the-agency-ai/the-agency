---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-14T19:12
status: created
priority: normal
subject: "RE #327: both items done — scaffold PVR updated + Phase 2 receipt verification passed with 2 findings"
in_reply_to: null
---

# RE #327: both items done — scaffold PVR updated + Phase 2 receipt verification passed with 2 findings

## Item 1: Scaffold PVR complete (5e81385)
Open questions → resolved decisions with captain-approved defaults:
- D1: apps/ + packages/ monorepo
- D2: pnpm
- D3: Vitest for both backend + frontend

Added Section 11 noting pending monofolk confirmation with fallback adjustments documented. PVR is A&D-ready.

## Item 2: Phase 2 receipt verification (2e5fec6)
End-to-end tested diff-hash → receipt-sign → receipt-verify chain with a real receipt:
- Hash A computed against main baseline ✓
- Hash B hashed findings JSON ✓
- Hash C hashed triage JSON ✓
- Hash D set to Hash C for auto-approved case ✓
- Hash E computed after clean (== Hash A since no fixes) ✓
- receipt-sign wrote to claude/receipts/ with correct naming ✓
- receipt-verify found and validated against committed state ✓

Receipt sample: claude/receipts/the-agency-jordan-devex-devex-receipt-phase2-verify-qgr-fed441a-20260415-0311.md

## Rough edges found

### 1. MINOR: diff-hash errors when run outside repo
When cwd is /tmp, diff-hash silently returns empty hash instead of an actionable error. The tool should either (a) resolve to the repo root (like other tools do via _path-resolve) or (b) fail loudly with 'not in a git repo' message. Observed during verification scripting.

### 2. MINOR: receipt-verify stale detection works on committed state only
Modifications to the working tree don't invalidate a receipt — only new commits do. This is correct per A&D ('hash match only, hash E matches what's on disk'), but the word 'disk' is ambiguous. Suggestion: clarify in A&D § 6 (Stale Receipt Policy) that 'on disk' means 'committed state (git diff against diff_base)', not 'working tree'. This matters for agent understanding — an agent could modify files between QG and verify and be surprised by a 'valid' receipt.

### Both are MINOR — no blockers

## Status
Queue clear. Awaiting direction.
