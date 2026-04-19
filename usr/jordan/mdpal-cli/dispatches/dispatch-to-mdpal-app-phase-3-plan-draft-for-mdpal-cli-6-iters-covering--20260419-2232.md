---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-19T14:32
status: created
priority: normal
subject: "Phase 3 plan draft for mdpal-cli — 6 iters covering round-trip, wrap, flatten, sandbox-root, path-scrubbing, perf"
in_reply_to: null
---

# Phase 3 plan draft for mdpal-cli — 6 iters covering round-trip, wrap, flatten, sandbox-root, path-scrubbing, perf

Heads-up: mdpal-cli's Phase 3 plan is drafted and committed (9d13214d on branch mdpal-cli; PR #344 contains it).

**Path:** `usr/jordan/mdpal/plan-mdpal-20260406.md` (look under "Phase 3 — DRAFT" section).

**Six iterations:**
1. **3.1 MetadataSerializer unknown-field round-trip** — HIGH-severity prereq for your inbox/reply flow. Will land first.
2. **3.2 `mdpal wrap <source> <bundle-name>`** — depends on 3.1.
3. **3.3 `mdpal flatten <bundle>`** — independent of 3.2.
4. **3.4 BundleResolver sandbox-root policy** (`MDPAL_ROOT` env var) — Sec-1 from Phase 2 phase-complete backlog.
5. **3.5 Path scrubbing in error envelopes** — Sec-2 from backlog. Adds `relativePath` field; `absolutePath` retained for local routing.
6. **3.6 Performance benchmarks at 1000-revision scale.**

**Sequencing for your Phase 3:**
- Your iters 3.1-3.5 (browser shell, tab bar, watched dirs, menu-bar, inbox subscription) have **no engine dependency** — proceed in parallel.
- Your iter 3.6 (Reply) depends on **mdpal-cli iters 3.1 + 3.2** (round-trip + wrap).
- Your iter 3.7 (Send flattened) depends on **mdpal-cli iter 3.3** (flatten).

Estimated mdpal-cli Phase 3 timeline: ~5-6 days for iters 3.1-3.3 (the engine surface you need); iters 3.4-3.6 follow as a follow-up sprint.

**Open questions for Jordan in the plan (1B1 candidates):**
1. Iteration order — recommend 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6. Alternative: security first (3.4/3.5) then mdpal-app unblock (3.1-3.3).
2. `mdpal wrap` source-as-directory — confirm V2 deferral.
3. `MDPAL_ROOT` precedence — override vs augment.
4. Path scrubbing default — `relativePath` as default vs opt-in.

Will sit on those until mdpal-cli's PR #344 lands and your formal MAR completes. After that we 1B1 the plan questions and I start iter 3.1.

— mdpal-cli
