# Reference: Receipt Infrastructure

Source A&D: `agency/workstreams/agency/receipt-infrastructure-ad-20260414.md`

---

## Naming Convention

```
{org}-{principal}-{agent}-{workstream}-{project}-{qgr|rgr}-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md
```

All fields are required. Full provenance in every filename — too much information is better than not enough.

**Examples:**
```
agency/workstreams/devex/qgr/the-agency-jordan-devex-devex-git-safe-qgr-pr-prep-20260414-1835-a1b2c3d.md
agency/workstreams/agency/rgr/the-agency-jordan-captain-agency-valueflow-rgr-plan-complete-20260414-1900-b2c3d4e.md
agency/workstreams/ops/qgr/monofolk-jordan-captain-ops-infra-qgr-phase-complete-20260414-1930-c3d4e5f.md
```

The `{hash_e_short}` field is the 7-char truncation of Hash E (the final artifact hash). Date comes before hash for chronological `ls` sort.

---

## Five-Hash Chain of Trust

| Hash | Name | What it captures | QGR (code) | RGR (methodology) |
|------|------|-----------------|------------|-------------------|
| **A** | Original | Artifact entering review | Code diff before QG | PVR/A&D/Plan document |
| **B** | Findings | Raw reviewer output | 4-agent review findings | MAR findings |
| **C** | Triage | Author disposition | Scorer + author three-bucket triage | Author three-bucket triage |
| **D** | Principal | 1B1 outcome | Principal discussion transcript | 1B1 transcript with principal |
| **E** | Final | Revised artifact | Code diff after all fixes | Revised document |

**Chain enforcement:** Hash C cannot be produced without Hash B existing. Hash E cannot be produced without Hash D. Each step gates the next. The receipt is proof the full lifecycle ran.

### Hash D Auto-Approve Rule

When no principal 1B1 occurs (soft gate):

- Hash D = Hash C
- Receipt field: `hash_d_source: "auto-approved — no principal 1B1"`
- No `hash_d_transcript` field is written

When a principal 1B1 does occur:

- Hash D = SHA-256 of the 1B1 transcript file
- Receipt field: `hash_d_source: "transcript"`
- Receipt field: `hash_d_transcript: {path/to/transcript.md}`

To audit all auto-approvals: grep `agency/workstreams/*/qgr/` for `hash_d_source: "auto-approved"`.

---

## Hash Computation

### Internal vs. Display

- **Internal / receipt storage:** Full SHA-256
- **Display / filename:** 7-char truncation

### `diff-hash` Invocations

```bash
./agency/tools/diff-hash                          # default: origin/main
./agency/tools/diff-hash --base origin/main       # explicit baseline
./agency/tools/diff-hash --base v39.1             # phase start tag
./agency/tools/diff-hash --base abc1234           # prior iteration commit
./agency/tools/diff-hash --file <path>            # single artifact file hash
./agency/tools/diff-hash --json                   # JSON output with full SHA-256
```

Each receipt records which base was used: `diff_base: origin/main`.

Skills pass the appropriate base automatically:
- `/iteration-complete` → `--base {prior-iteration-commit}`
- `/phase-complete` → `--base {phase-start-tag}`
- `/pr-prep` → `--base origin/main` (default)

For RGR methodology artifacts, hash the file content directly:
```bash
./agency/tools/diff-hash --file agency/workstreams/devex/git-safe-pvr-20260414.md
```

### Exclusion

`qgr/` and `rgr/` directories are excluded from ALL hash computations. Receipts do not appear in diffs and do not affect hash values.

---

## Stale Receipt Policy

**Hash match only. No time window.**

Hash E in the receipt matches the current artifact on disk → valid.
Hash E does not match → stale, blocked.

Time is irrelevant. The hash is the validity check.

---

## Receipt Format Spec

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

**Field notes:**
- `receipt_version: 1` from day one. Tools check version. Forward compatibility: unknown fields are ignored.
- `hash_d_transcript` is omitted when `hash_d_source` is `auto-approved`.
- `diff_base` records the exact baseline used in the `diff-hash` invocation.
- All `hash_*` fields store full SHA-256. The 7-char display appears only in the Chain of Trust section and the filename.

---

## Tool Reference

### `diff-hash`

Compute a deterministic hash with a parameterized base.

| Flag | Description |
|------|-------------|
| `--base <ref>` | Git ref for diff base (default: `origin/main`) |
| `--file <path>` | Hash a single file instead of a diff |
| `--json` | Output JSON with full SHA-256 and metadata |

### `receipt-sign`

Write a signed receipt with all five hashes.

Required flags:

| Flag | Description |
|------|-------------|
| `--type` | `qgr` or `rgr` |
| `--boundary` | Valueflow boundary (e.g., `iteration-complete`) |
| `--org` | Organization name |
| `--principal` | Principal identifier |
| `--agent` | Agent identifier |
| `--workstream` | Workstream name |
| `--project` | Project name |
| `--diff-base` | Baseline ref used for `diff-hash` |
| `--hash-a` through `--hash-e` | Full SHA-256 for each chain position |
| `--hash-d-source` | `transcript` or `auto-approved — no principal 1B1` |
| `--hash-d-transcript` | Path to transcript file (omit if auto-approved) |

### `receipt-verify`

Find and verify receipts for the current PR content.

| Invocation | Description |
|------------|-------------|
| `./agency/tools/receipt-verify --workstream <ws> --project <proj>` | Verify by workstream and project |
| `./agency/tools/receipt-verify --file <path>` | Verify a specific receipt file |

Matching algorithm:
1. Filter `agency/workstreams/{W}/qgr/` by filename pattern `*-{workstream}-{project}-*`
2. For each matching receipt, check Hash E against the current diff hash (QGR) or artifact hash (RGR)
3. Match → valid. No match → blocked.

Used in `pr-create`:
```bash
./agency/tools/receipt-verify || { echo "BLOCKED"; exit 1; }
```

---

## Valueflow Boundary Integration

| Boundary | Gate | Receipt type | Artifact hashed | `diff-hash` base |
|----------|------|-------------|----------------|-----------------|
| PVR complete | Review gate | RGR | PVR document | `--file <pvr-path>` |
| A&D complete | Review gate | RGR | A&D document | `--file <ad-path>` |
| Plan complete | Review gate | RGR | Plan document | `--file <plan-path>` |
| Iteration complete | Quality gate | QGR | Code diff | `--base {prior-iteration-commit}` |
| Phase complete | Quality gate | QGR | Code diff | `--base {phase-start-tag}` |
| PR/Release | Verify only | — | All receipts | `origin/main` |

A phase with 3 iterations produces 4 receipts: one QGR per iteration (each with its own base) plus one QGR for the phase boundary. `receipt-verify` at PR time finds all of them and checks each.

---

## Mixed PR Support

A PR may contain both code changes and updated methodology artifacts. `receipt-verify` handles this by running separate checks per artifact type:

1. **QGR check:** find receipt where Hash E matches the current code diff
2. **RGR check per artifact:** find receipt where Hash E matches each changed methodology document

All checks must pass. Any missing or mismatched receipt blocks the PR.

---

## Future Work (Flagged)

- `#102` — RG on QGR: `/captain-review` as a review gate on quality gate receipts
- `#103` — Universal artifact naming convention + multi-project per workstream
- `#104` — Receipt registry/DB for fast queries and cross-agency aggregation
