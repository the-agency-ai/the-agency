---
type: pvr
project: documentation-sweep
workstream: agency
date: 2026-04-15
status: draft
---

# PVR: Documentation Sweep — Day 40 Changes + REFERENCE- Refactor

## Problem

Significant framework changes landed D40 without corresponding documentation updates. New agents and adopters will be confused or misled by stale docs. Specifically:

**Day 40 changes needing documentation:**
1. **Safe tools family** — git-safe, git-captain, git-safe-commit (renamed from git-commit), git-push, cp-safe, pr-create
2. **Receipt infrastructure** — diff-hash, receipt-sign, receipt-verify, claude/receipts/, five-hash chain
3. **Session lifecycle** — /session-end (commit everything), /session-compact (new), session-preflight
4. **PR enforcement** — pr-create, /release (renamed from /ship), block-raw-pr-create hookify, version bump in manifest
5. **Hookify enforcement fix** — blocks now actually block (decision:block + exit 2)
6. **Valueflow stream model** — work stream → delivery stream → value stream
7. **Branch protection** — LIVE on main (requires PR approval + smoke test)
8. **Dispatch service seed** — ISCP workstream, cloud-hosted agent messaging

**Naming refactor:** `claude/docs/*.md` → `claude/REFERENCE-*.md`

## Target Audience

- New agents reading the bootloader
- Existing agents picking up main after the D40 changes
- Adopters (Peter Gao onboarding, monofolk, future)
- Principals reading methodology docs

## Use Cases

1. **Agent startup** — reads CLAUDE-THEAGENCY.md, needs accurate tool list and safe tool guidance
2. **Principal learning** — reads README-GETTINGSTARTED, needs accurate setup flow
3. **Adopter onboarding** — reads README-THEAGENCY, needs accurate feature overview
4. **Skill invocation** — ref-injector loads REFERENCE-* docs, needs them at predictable paths
5. **First release** — new adopter needs step-by-step guide through the PR/release process

## Functional Requirements

1. Update CLAUDE-THEAGENCY.md with all D40 tool/skill additions
2. Update README-ENFORCEMENT.md with new hookify rules (block-raw-push, block-raw-cp, block-raw-pr-create, hookify fix)
3. Update README-THEAGENCY.md with safe tools, receipt infrastructure, Valueflow streams
4. Update README-GETTINGSTARTED.md with new setup flow
5. Create REFERENCE-RECEIPT-INFRASTRUCTURE.md (spec)
6. Create README-RECEIPT-INFRASTRUCTURE.md (overview)
7. Create REFERENCE-SAFE-TOOLS.md (spec)
8. Create README-SAFE-TOOLS.md (overview)
9. Create YOUR-FIRST-RELEASE.md (step-by-step guide)
10. Rename claude/docs/*.md → claude/REFERENCE-*.md
11. Update every reference to claude/docs/ across skills, hookify, ref-injector, READMEs
12. Update skill descriptions that reference old skill/tool names

## Non-Functional Requirements

- Consistency: all docs follow the same structure and tone
- Accuracy: every claim in a doc must be verifiable against code
- Discoverability: key information is in CLAUDE-THEAGENCY.md bootloader (short) with detail in REFERENCE- docs
- Audit trail: RGR receipt produced for the documentation work

## Constraints

- Must stage all PRs for morning review (no admin merge)
- Must follow full Valueflow: plan → MAR → refine → execute → MAR → RGR
- Cannot change behavior — docs only
- Must use safe tools (git-safe, git-safe-commit, pr-create)

## Success Criteria

- All 8 Day 40 changes documented
- All claude/docs/*.md renamed to claude/REFERENCE-*.md with references updated
- New docs (RECEIPT-INFRASTRUCTURE, SAFE-TOOLS, YOUR-FIRST-RELEASE) created
- No broken references (grep for old paths returns nothing)
- PR staged with RGR receipt
- Principal reviews in morning, merges if good

## Non-Goals

- No behavior changes (docs only)
- No new tools or skills
- No monofolk Ring 2 dispatch (separate discussion)
- No receipt infrastructure Phase 2 (DevEx handling)

## Open Questions

None — all resolved in last night's 1B1.
