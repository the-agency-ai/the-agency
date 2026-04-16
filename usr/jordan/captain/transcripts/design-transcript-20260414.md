# Design Transcript — Day 40: Receipt Infrastructure + Valueflow Streams

**Date:** 2026-04-14
**Mode:** Design discussion
**Participants:** Jordan (principal), Captain (agent)
**Protocol:** 1B1 with Over

---

## Backfill: Earlier Session Decisions

### Session lifecycle skills
**Decision:** `/session-end` commits everything (no asking), idempotent. `/session-compact` new skill for mid-session context refresh. Both end with directive: "Safe to `/compact` and/or `/exit`."

### Safe tools pattern
**Decision:** Block raw commands that cross boundaries. Enforcement triangle: tool + skill + hookify.
- `git push` → `git-push` tool (blocks main)
- `cp` → `cp-safe` tool (blocks cross-worktree)
- `gh pr create` → `pr-create` tool (requires QGR + version bump)
- `/ship` renamed to `/release`

### PR = Release
**Decision:** Every PR is a release. Version bumped in manifest.json, GitHub release created on merge. Enforcement in `pr-create` (QGR + version check) and `/post-merge` (creates GitHub release).

### Dispatch service
**Decision:** Cloud-hosted agent messaging. Single hub. 4-segment addressing: `{org}/{repo}/{principal}/{agent}`. Fewer segments = more local. JSON envelope + markdown body. BSL license with 3-year Apache 2.0 conversion. Seeded to ISCP workstream.

### git-safe family
**Decision:** git-safe (all agents), git-captain (captain only), git-safe-commit (renamed from git-commit). One catch-all hookify rule with escalation path. Internal tools stay raw. DevEx implementing autonomously.

---

## Receipt Infrastructure 1B1

### Item 1: Receipt location
**Decision:** `claude/receipts/` — flat directory, framework-level. No subdirectories. Filename IS the hierarchy.

### Item 2: Receipt naming
**Decision:** Full provenance: `{org}-{principal}-{agent}-{workstream}-{project}-{qgr|rgr}-{hash}-{YYYYMMDD-HHMM}.md`

### Item 3: RGR hash semantics — five-hash chain
**Discussion:** Jordan proposed progressive hashing. Evolved through discussion:
- Started with "hash the artifact file"
- Jordan: "hash the original AND the findings"
- Jordan: "hash the disposition before principal discussion"
- Jordan: "and after principal discussion as well"

**Decision:** Five-hash chain of trust:
1. Hash A — original artifact into review
2. Hash B — raw review findings
3. Hash C — author's disposition/triage (before principal)
4. Hash D — outcome of 1B1 with principal
5. Hash E — final revised artifact

Each hash gates the next. Missing a hash = skipped a step. Enforces the full MAR lifecycle.

### Item 4: Stale receipt policy
**Decision:** Hash match only. No time window. Hash E matches disk = valid. Doesn't match = stale. Time is irrelevant.

### Item 5: Receipt format versioning
**Decision:** `receipt_version: 1` in frontmatter from day one.

### Item 6: Mixed PRs
**Decision:** Allowed. PR with code + PVR needs both QGR and RGR. `receipt-verify` checks for each artifact type present.

### Item 7: RG on QGR (flagged for future)
**Discussion:** Jordan asked "what if we want to force an MAR review of the QGR?"
**Decision:** Flag for future (#102). The QGR is an artifact that could go through RG. `/captain-review` becomes an RG on the QGR.

### Item 8: Universal artifact naming (flagged for future)
**Discussion:** Jordan: proper naming with full provenance for ALL artifacts, not just receipts.
**Decision:** Flag for future (#103). Same pattern as receipts: `{org}-{principal}-{agent}-{workstream}-{project}-{artifact-type}-{YYYYMMDD}.md`

---

## Valueflow Stream Terminology

**Discussion:** Jordan proposed three levels of flow.
**Decision:**
- **Work stream** — agent-level work, produces commits
- **Delivery stream** — work streams converge into PRs/releases
- **Value stream** — builds/deployments that ship to the world

Transitions:
- Commits → QG/RG gate → PRs → PR gate → Builds/Deployments
- `/iteration-complete`, `/phase-complete` = work stream gates
- `/release`, `pr-create` = delivery stream gates
- `/deploy` = value stream gate

---

## Ownership
**Decision:** Captain owns receipt infrastructure. DevEx reviews (MAR), does not build. Captain implements.

---

## MAR Findings 1B1

### Item 1: Hash D solo path
**Decision:** Hash D = Hash C when auto-approved (no principal 1B1). Receipt records `hash_d_source: "auto-approved"`. Auditable — grep for hash_d == hash_c finds all auto-approvals.

### Item 2: receipt-verify matching algorithm
**Discussion:** Jordan: "if there is a principal 1B1, it is a hash of the transcript"
**Decision:** Match on workstream + project + Hash E. Hash D = hash of 1B1 transcript file. Receipt includes `hash_d_transcript` path. Mixed PRs: receipt-verify runs once per artifact type, all must match.
**Action:** Jordan: "Do we want to eventually also store receipts in a DB or registry?" → Flagged #104 for future.

### Item 3: Diff baseline parameterization
**Discussion:** Jordan: "and if we have multiple loops, we have multiple receipts"
**Decision:** `diff-hash --base` parameterized (origin/main, tag, commit). Each iteration/phase gets its own receipt. They accumulate. PR has all of them. Receipt records `diff_base`.

---

## Stream Terminology (resolved during session)

**Decision:**
- Work stream = agent commits
- Delivery stream = PRs/releases
- Value stream = builds/deployments

Jordan: "Workstreams Commits become Delivery Stream PR become Value Stream builds/deployments"

---

## Ownership

**Decision:** Captain owns receipt infrastructure implementation. DevEx reviews via MAR only.

---

*All items resolved. A&D updated. MAR requested from DevEx.*
