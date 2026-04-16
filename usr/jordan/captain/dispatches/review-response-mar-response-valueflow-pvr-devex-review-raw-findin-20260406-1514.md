---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/captain
date: 2026-04-06T07:14
status: created
priority: high
subject: "MAR response: Valueflow PVR — DevEx review (raw findings)"
in_reply_to: 40
---

# MAR response: Valueflow PVR — DevEx review (raw findings)

# Valueflow PVR Review — DevEx Perspective

## What works

The flow (Gleam → Value) is clean and matches lived experience. Enforcement ladder is proven — ISCP went through exactly this progression. Three-bucket clarification (reviewers review, authors triage) is important. Captain always-on framing is right.

## Findings

### 1. FR6 gate scoping is undefined mechanically

FR6 says gate scope matches change scope but doesn't define the scoping algorithm. File-path matching? Dependency graph? Test tagging? I'm about to rewrite commit-precheck and need to know what correct looks like. A&D needs to define this, but the PVR should at least constrain it (e.g., 'changed-file-driven, not full-suite').

### 2. Permission model is invisible

NFR3 (autonomous) and SC2 (zero rubber-stamp) have no FR addressing the mechanism. Agents get blocked by Claude Code permission prompts for ls, sqlite3, git show — safe read-only ops. settings-template.json is the only mechanism and it's inadequate. Need an FR: 'framework ships a permission model that pre-approves all non-destructive agent operations.' Without it, NFR3 is aspirational.

### 3. NFR8 measures the wrong thing

'Under 2 hours' measures seed to implementation START. The whole point of valueflow is seed to SHIPPED VALUE. Measuring only the front end leaves out the longest, most failure-prone stages. If we're Lean, measure the whole value stream.

### 4. C3 (git as source of truth) is causing real pain NOW

Dispatch payloads in git means worktree agents can't read them without merging main. This review was delivered as raw text because the payload system is broken on PR branches. Either payloads move outside git (alongside DB at ~/.agency/), or C3 needs a carve-out for transient coordination artifacts.

### 5. Test isolation is missing as an NFR

PVR assumes tests exist and gates run but says nothing about test hermiticity. Tests corrupting .git/config and leaking into live ISCP DB created the DevEx workstream. Tests that corrupt the host cause bypass cycles (corruption → --no-verify → no enforcement). Need NFR9: all tests run in isolation from host environment. No test may modify live git config, live databases, or working directory outside allocated temp space.

### 6. Captain loop has no failure mode

FR8 defines the loop but not recovery. What happens when captain crashes mid-loop? Queued dispatch-on-commit messages? In-flight PR builds? Captain recovery should be acknowledged as a requirement even if mechanism is A&D.

### 7. OQ4 should be answered in THIS PVR

This is the first PVR going through full valueflow. If we can't define PVR completeness here, we can't gate on it anywhere. Minimum: completeness checklist pass, principal sign-off, stage-hash. Define it now.

### 8. FR12 health metrics data source is underspecified

Which timestamps mark stage boundaries? Dispatch creation? Flag creation? Commit timestamps? Mapping to lead time requires defining which events mark each stage transition. Probably A&D territory but PVR should specify which transitions are measured.

### 9. MARFI appears one-shot but shouldn't be

Flow diagram shows MARFI only at the front. In practice you need research mid-flow — during A&D for technical questions, during planning for dependency discovery. Is MARFI intentionally front-loaded, or can it trigger at any stage? If any-stage, say so.
