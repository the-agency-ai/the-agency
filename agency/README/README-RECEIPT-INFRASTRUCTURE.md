# Receipt Infrastructure

## What It Is

Receipt infrastructure is the chain-of-trust backbone for quality gate and review gate results in TheAgency. Every time a gate runs — quality gate at iteration/phase boundaries, review gate on methodology artifacts — a signed receipt is produced proving the gate completed and capturing the full audit trail from original artifact through final revision.

Receipts are not notes or logs. They are cryptographic proof. Each receipt contains five hashes forming a chain from the artifact that entered review to the artifact that came out. If any step was skipped, the chain breaks.

## The Problem It Solves

Gates ran, but there was no enforcement. A quality gate could fire, produce findings, and then the PR could be created without any connection between "the gate ran on this code" and "this is the code in the PR." Receipts were written informally if at all — fragile markdown notes, no standard format, no hash verification, nothing blocking a PR with a stale or missing receipt.

The result: quality and review gates were advisory in practice even when they were meant to be mandatory. Receipt infrastructure makes them mandatory in a way that cannot be bypassed — the PR creation tool calls `receipt-verify` and blocks if no valid receipt matches the current diff.

## The Five-Hash Chain

Each receipt carries five hashes, labeled A through E:

- **A — Original artifact.** Hash of the code diff or methodology document entering review. Establishes what was actually reviewed.
- **B — Review findings.** Hash of the raw findings produced by reviewers. Proves the review happened and what it said.
- **C — Author triage.** Hash of the author's three-bucket disposition (disagree / autonomous / collaborative). Proves the author responded.
- **D — Principal outcome.** Hash of the 1B1 transcript with the principal. When no 1B1 occurs (soft gate), Hash D equals Hash C and is marked `auto-approved`. Auditable: grep for `hash_d == hash_c` to find all auto-approvals.
- **E — Final artifact.** Hash of the artifact after all revisions. This is what `receipt-verify` checks against the current state.

The chain is enforced sequentially. Hash C cannot be produced without Hash B. Hash E cannot be produced without Hash D. Each step gates the next.

## When to Use

Every Valueflow boundary produces a receipt:

- PVR complete → review gate → RGR
- A&D complete → review gate → RGR
- Plan complete → review gate → RGR
- Iteration complete → quality gate → QGR
- Phase complete → quality gate → QGR

At PR/release time, `receipt-verify` finds all receipts for the current workstream and project and checks that Hash E on each matches the current artifact. Missing or stale receipt → blocked.

## Tools

- **`diff-hash`** — compute a deterministic hash of the current diff or a single file, with parameterized baseline
- **`receipt-sign`** — write a signed receipt with all five hashes and full naming provenance
- **`receipt-verify`** — find and verify all receipts for the current PR content; supports mixed PRs with both code and methodology artifacts

## Where Receipts Live

Receipts are written to **per-workstream directories**:

```
agency/workstreams/{W}/qgr/    — quality gate receipts
agency/workstreams/{W}/rgr/    — review gate receipts
```

The filename carries full provenance:

```
{org}-{principal}-{agent}-{ws}-{proj}-{type}-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md
```

Receipt directories (`qgr/` and `rgr/`) are excluded from all hash computations so receipts never invalidate each other.

### Read Path (three-tier, backward compatible)

`receipt-verify` and `pr-create` search receipts in this order:

1. `agency/workstreams/*/qgr/` and `rgr/` (current — checked first)
2. `claude/receipts/` (legacy fallback)
3. `usr/**/qgr-*.md` (old-old fallback — sunsets when all migrated)

New receipts are always written to the per-workstream path via `receipt-sign`.
