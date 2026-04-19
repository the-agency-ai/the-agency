---
type: seed
project: qgr-rgr-signing
workstream: agency
date: 2026-04-14
origin: captain session — enforcement infrastructure gaps discovered during D40-R1/R2
---

# Seed: QGR/RGR Signing Infrastructure

## Problem

The current QGR (Quality Gate Report) receipt system has gaps:
1. **Hash computation is fragile** — computed manually, changes when ANY code changes (including the QGR file itself)
2. **No RGR** (Review Gate Report) — PVR, A&D, and Plan go through MAR but produce no verifiable receipt
3. **pr-create hash verification is a workaround** — hacked together in one session, not properly designed
4. **No tooling** — hash computation, receipt writing, and verification are manual steps in skills

## Vision

A complete signing infrastructure where:
- Every gate (QG or RG) produces a signed receipt
- `pr-create` verifies the receipt matches the current code
- The chain of trust is: review runs → hash computed → receipt signed → tool verifies

## Components Needed

### 1. `diff-hash` tool
Computes a deterministic hash of the diff between current branch and origin/main, **excluding receipt files** (qgr-*.md, rgr-*.md). This is the stable "code fingerprint" that doesn't change when receipts are added.

```
./agency/tools/diff-hash              # prints 7-char hash
./agency/tools/diff-hash --json       # prints JSON with hash, file list, exclusions
```

### 2. `receipt-sign` tool
Writes a signed QGR or RGR receipt file with the correct hash. Single tool for both gate types.

```
./agency/tools/receipt-sign --type qgr --boundary pr-prep --scope "D40-R2 description"
./agency/tools/receipt-sign --type rgr --boundary pvr --scope "mdpal PVR v2"
```

Does:
1. Computes diff-hash
2. Generates timestamp
3. Writes receipt file at correct path with correct naming convention
4. Reports: "Receipt written: {path} (hash: {hash})"

### 3. `receipt-verify` tool
Verifies a receipt matches the current code. Used by `pr-create` and potentially by CI.

```
./agency/tools/receipt-verify          # finds newest receipt, verifies hash
./agency/tools/receipt-verify --file <path>   # verifies specific receipt
```

Returns exit 0 if valid, exit 1 if stale/missing/mismatched.

### 4. Updated `pr-create`
Calls `receipt-verify` instead of inline hash logic. Much simpler:

```bash
./agency/tools/receipt-verify || { echo "BLOCKED: no valid receipt"; exit 1; }
```

### 5. RG (Review Gate) for methodology artifacts

| Artifact | Gate | Review method | Receipt type |
|----------|------|---------------|-------------|
| Code | QG | 4 parallel agents + scorer + fix | QGR |
| PVR | RG | MAR + triage + revision | RGR |
| A&D | RG | MAR + triage + revision | RGR |
| Plan | RG | MAR + triage + revision | RGR |

RG follows the same pattern as QG but adapted:
- MAR instead of 4-agent parallel review
- Triage instead of scorer
- Completeness check instead of test suite
- Receipt includes: hash, MAR round count, findings count, completeness score

### 6. Updated skills

| Skill | Change |
|-------|--------|
| `/quality-gate` | Uses `receipt-sign --type qgr` instead of manual QGR writing |
| `/pr-prep` | Calls `receipt-verify` before creating PR |
| `/release` | Calls `receipt-verify` before creating PR |
| `/iteration-complete` | Uses `receipt-sign --type qgr` |
| `/phase-complete` | Uses `receipt-sign --type qgr` |
| `/define` | Produces RGR via `receipt-sign --type rgr --boundary pvr` |
| `/design` | Produces RGR via `receipt-sign --type rgr --boundary ad` |
| `/plan-complete` | Produces RGR via `receipt-sign --type rgr --boundary plan` |

## Implementation Plan

### Phase 1: Core tools (diff-hash, receipt-sign, receipt-verify)
- Build the 3 tools
- BATS tests for each
- Update pr-create to use receipt-verify

### Phase 2: QG integration
- Update /quality-gate to use receipt-sign
- Update /iteration-complete, /phase-complete
- Update /pr-prep, /release

### Phase 3: RG for methodology artifacts
- Build /review-gate skill (parallel to /quality-gate)
- Update /define, /design, /plan-complete to produce RGR
- pr-create accepts QGR or RGR

## Open Questions

1. Should receipt-verify check ONLY the newest receipt, or should it accept any valid receipt within the time window?
2. Should we version the receipt format for forward compatibility?
3. Should CI also verify receipts (defense in depth)?
