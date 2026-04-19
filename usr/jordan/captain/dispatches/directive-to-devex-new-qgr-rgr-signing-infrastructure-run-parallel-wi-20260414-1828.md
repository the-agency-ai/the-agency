---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T10:28
status: created
priority: high
subject: "NEW: QGR/RGR signing infrastructure — run parallel with git-safe"
in_reply_to: null
---

# NEW: QGR/RGR signing infrastructure — run parallel with git-safe

New mission, run in PARALLEL with git-safe. Do not queue behind it.

**Seed location:** agency/workstreams/agency/seeds/seed-qgr-rgr-signing-20260414.md

**Summary:** Build the signing infrastructure for quality gate and review gate receipts. Three tools (diff-hash, receipt-sign, receipt-verify) + Review Gate for PVR/A&D/Plan artifacts. The current receipt system is fragile — hashes computed manually, no proper tooling.

**MAR already done — 5 findings that must be resolved before Phase 1:**
1. Receipt exclusion: use dedicated receipts directory, not filename globs
2. RGR hash semantics: what gets hashed for PVR/A&D/Plan? (artifact diff, not full branch diff)
3. Stale receipt policy: exact hash match at verify time, no time-window heuristic
4. Receipt format versioning: resolve in Phase 1
5. Mixed PRs: code + methodology artifact needs both QGR and RGR

**Security note (from MAR):** Self-signed enforcement — proportionate for agent carelessness threat model. Use full SHA-256 internally, truncate 7-char for display.

**Your path:**
1. Read the seed
2. /define — resolve the 5 MAR findings during PVR
3. /design — A&D
4. Plan and implement (3 phases in the seed)

Run this alongside git-safe. Both are priority. Consult captain if you need decisions.

Go.
