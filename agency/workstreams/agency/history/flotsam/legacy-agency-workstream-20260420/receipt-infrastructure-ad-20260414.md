---
type: architecture-design
project: receipt-infrastructure
workstream: agency
date: 2026-04-14
status: reviewed
seed: claude/workstreams/agency/seeds/seed-qgr-rgr-signing-20260414.md
resolved-by: captain/principal 1B1 — Day 40
mar: 2 rounds (initial + 3-item 1B1 resolution)
transcript: usr/jordan/captain/transcripts/design-transcript-20260414.md
---

# A&D: Receipt Infrastructure — QGR/RGR Signing + Valueflow Boundary Enforcement

## 1. Scope

This is the enforcement backbone for the entire Valueflow methodology. Every boundary where work crosses a gate produces a signed receipt proving the gate ran.

**Stream model:**
- **Work stream** — agent-level work, produces commits. Gates: `/iteration-complete`, `/phase-complete`
- **Delivery stream** — work streams converge into PRs/releases. Gates: `/release`, `pr-create`
- **Value stream** — builds/deployments ship to the world. Gates: `/deploy`

Transitions: Commits → QG/RG gate → PRs → PR gate → Builds/Deployments

## 2. Receipt Location

**`claude/receipts/`** — flat directory, framework-level. One place for all receipts across all agents, all workstreams, all agencies.

No subdirectories. The filename IS the hierarchy. `diff-hash` excludes this directory from all hash computations.

## 3. Receipt Naming Convention

```
{org}-{principal}-{agent}-{workstream}-{project}-{qgr|rgr}-{hash}-{YYYYMMDD-HHMM}.md
```

Full provenance in every filename. Too much information is better than not enough.

Examples:
```
claude/receipts/the-agency-jordan-devex-devex-git-safe-qgr-a1b2c3d-20260414-1835.md
claude/receipts/the-agency-jordan-captain-agency-valueflow-rgr-b2c3d4e-20260414-1900.md
claude/receipts/monofolk-jordan-captain-ops-infra-qgr-c3d4e5f-20260414-1930.md
```

## 4. Five-Hash Chain of Trust

Every receipt contains five hashes forming an audit chain. Each hash is a gate — missing a hash means a step was skipped.

| Hash | What it captures | Artifact |
|------|-----------------|----------|
| **Hash A** | Original artifact INTO review | Source document or code diff |
| **Hash B** | Raw review findings | What reviewers said |
| **Hash C** | Author's disposition/triage | Three-bucket: disagree/autonomous/collaborative |
| **Hash D** | 1B1 with principal outcome | Hash of the transcript (or = Hash C if auto-approved) |
| **Hash E** | Final revised artifact | Document or code after all revisions |

### Chain enforcement
Cannot produce Hash C without Hash B existing. Cannot produce Hash E without Hash D. Each step gates the next. The receipt is proof the full lifecycle ran.

### Hash D specifics

**When principal 1B1 occurs:** Hash D is a hash of the 1B1 transcript file. The receipt includes `hash_d_transcript: {path}` so the discussion can be inspected.

**When auto-approved (soft gate):** Hash D = Hash C. The receipt records `hash_d_source: "auto-approved — no principal 1B1"`. Auditable — grep for `hash_d == hash_c` to find all auto-approvals.

### Chain for QGR (code)
- A: code diff hash before QG
- B: 4-agent review findings hash
- C: scorer + author triage hash
- D: principal discussion transcript hash (or = C if auto-approved)
- E: final code diff hash after fixes

### Chain for RGR (methodology artifacts)
- A: original PVR/A&D/Plan document hash
- B: MAR findings hash
- C: author three-bucket triage hash
- D: 1B1 discussion with principal transcript hash
- E: final revised document hash

## 5. Hash Computation

### `diff-hash` tool

Parameterized baseline — not always origin/main:

```
./claude/tools/diff-hash                          # default: origin/main
./claude/tools/diff-hash --base origin/main       # explicit
./claude/tools/diff-hash --base v39.1             # phase start tag
./claude/tools/diff-hash --base abc1234           # prior iteration commit
./claude/tools/diff-hash --file <path>            # single artifact file hash
./claude/tools/diff-hash --json                   # JSON with full SHA-256
```

Skills pass the appropriate base:
- `/iteration-complete` → `--base {prior-iteration-commit}`
- `/phase-complete` → `--base {phase-start-tag}`
- `/pr-prep` → `--base origin/main` (default)

**Internal:** Full SHA-256. **Display/filename:** 7-char truncation.

**Exclusion:** `claude/receipts/` excluded from ALL hash computations.

The receipt records which base was used: `diff_base: origin/main`.

### For methodology artifacts (RGR)
Hash the artifact file content directly:
```
./claude/tools/diff-hash --file claude/workstreams/devex/git-safe-pvr-20260414.md
```

## 6. Stale Receipt Policy

**Hash match only. No time window.**

Hash E matches what's on disk = valid. Doesn't match = stale. Time is irrelevant. The hash IS the validity check.

## 7. Multiple Receipts

Each gate boundary produces its own receipt. They accumulate.

A phase with 3 iterations produces 4 receipts:
- Iteration 1 QGR (base: start of phase)
- Iteration 2 QGR (base: iteration 1)
- Iteration 3 QGR (base: iteration 2)
- Phase complete QGR (base: start of phase)

`receipt-verify` at PR time finds ALL of them. The audit trail shows every gate that fired during development.

## 8. Receipt Matching Algorithm (`receipt-verify`)

1. Parse the current branch for workstream and project context
2. Filter `claude/receipts/` by filename: `*-{workstream}-{project}-*`
3. For each matching receipt, check Hash E against current diff hash (for QGR) or artifact hash (for RGR)
4. Match → valid. No match → blocked.

For mixed PRs (code + methodology artifact):
- Run once for QGR: find receipt where Hash E matches code diff
- Run once for RGR per changed artifact: find receipt where Hash E matches artifact hash
- ALL must match. Missing any → blocked.

## 9. Receipt Format

```markdown
---
receipt_version: 1
type: qgr | rgr
boundary: iteration-complete | phase-complete | plan-complete | pvr | ad | pr-prep
org: the-agency
principal: jordan
agent: devex
workstream: devex
project: git-safe
diff_base: origin/main
hash_a: <sha256-full>
hash_b: <sha256-full>
hash_c: <sha256-full>
hash_d: <sha256-full>
hash_d_source: "transcript" | "auto-approved — no principal 1B1"
hash_d_transcript: usr/jordan/captain/transcripts/design-transcript-20260414.md
hash_e: <sha256-full>
date: 2026-04-14T18:35
---

# Receipt: {boundary} — {project}

## Chain of Trust
- A (original): {7-char} — {description}
- B (findings): {7-char} — {count} findings from {count} reviewers
- C (triage): {7-char} — {count} accepted, {count} rejected, {count} deferred
- D (principal): {7-char} — {transcript path or "auto-approved"}
- E (final): {7-char} — {final state description}

## Review Summary
{narrative}
```

`receipt_version: 1` from day one. Tools check version. Forward compatibility: ignore unknown fields.

## 10. Valueflow Boundary Integration

| Boundary | Gate | Receipt | Artifact | Base |
|----------|------|---------|----------|------|
| PVR complete | RG | RGR | PVR document | file hash |
| A&D complete | RG | RGR | A&D document | file hash |
| Plan complete | RG | RGR | Plan document | file hash |
| Iteration complete | QG | QGR | Code diff | prior iteration |
| Phase complete | QG | QGR | Code diff | phase start |
| PR/Release | verify | — | All receipts | origin/main |

## 11. Tools

### `diff-hash`
Compute deterministic hash with parameterized base.

### `receipt-sign`
Write signed receipt with all five hashes.

### `receipt-verify`
Find and verify receipts for current PR content. Checks all artifact types present.

### Updated `pr-create`
```bash
./claude/tools/receipt-verify || { echo "BLOCKED"; exit 1; }
```

## 12. Implementation Phases

### Phase 1: Core tools
- `diff-hash` (parameterized base, file mode, JSON output)
- `receipt-sign` (five-hash chain, full naming convention)
- `receipt-verify` (matching algorithm, mixed PR support)
- `claude/receipts/` directory
- BATS tests
- Update `pr-create`

### Phase 2: QG integration
- Update `/quality-gate` to produce five-hash chain
- Update `/iteration-complete`, `/phase-complete`
- Update `/pr-prep`, `/release`

### Phase 3: RG for methodology artifacts
- Build `/review-gate` skill
- Update `/define`, `/design`, `/plan-complete`
- Mixed PR verification

## 13. Flagged for Future

- #102: RG on QGR — review the review (`/captain-review` as RG on QGR)
- #103: Universal artifact naming convention + multi-project per workstream
- #104: Receipt registry/DB for fast queries and cross-agency aggregation
