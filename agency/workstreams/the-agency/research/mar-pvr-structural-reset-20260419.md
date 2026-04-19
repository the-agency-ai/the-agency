---
type: mar-triage
workstream: the-agency
slug: pvr-structural-reset
artifact: pvr-the-agency-structural-reset-20260419.md
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
reviewers: [reviewer-product, reviewer-architect, reviewer-risk, reviewer-verification]
overall_verdict: approve-with-changes (4/4 reviewers aligned)
---

# MAR Triage — PVR: Structural Reset (v46.0)

4 reviewers + captain triage. All reviewers returned `approve-with-changes` — structural soundness confirmed, improvements needed.

## Accept (fold into A&D)

### Critical / High (binding commitments before execution)

| ID | Reviewer | Finding | Action in A&D |
|---|---|---|---|
| A2 | reviewer-architect | `src/` split deferred but agency/ implicitly commits to being installed-tree; PVR silent | A&D declares: `agency/` = installed tree; future `src/` (per #337) = source tree |
| A4 | reviewer-architect | Reference sweep strategy absent — PVR has table, no mechanism | A&D specifies: per-category sweep unit, scripted grep verification gate, subagent fan-out scope |
| R1 | reviewer-risk | `bug.db`/`bugs.db` delete without extraction | A&D requires: `sqlite3 .dump` export to `history/flotsam/legacy-bug-dbs-20260419/` before rm |
| R2 | reviewer-risk | docs/ + reviews/ delete without archive-first rule | A&D promotes to binding: "every deletion preceded by archive-to-flotsam unless principal 1B1 confirms zero value" |
| R3 | reviewer-risk | Ref sweep aspirational not mechanical (CRITICAL) | A&D: post-sweep grep produces zero hits outside explicit allowlist; blocks merge |
| R4 | reviewer-risk | Hookify rules may have path-encoded matching; silently no-op post-rename | A&D: enumerate hookify rules, validate each fires post-reset against canary test |
| R5 | reviewer-risk | Hook bypass window unbounded during reset | A&D: `AGENCY_ALLOW_RAW=1` per-command only (never session env); captain-only; audit log every raw invocation |
| V1 | reviewer-verification | SC #12 undefined "non-historical paths" | A&D: explicit allowlist file (e.g., `.agency/ref-sweep-exclude.txt`); scripted test |
| V5 | reviewer-verification | No pre-reset baseline capture | A&D: before move #1, snapshot `agency-health --json`, bats output, file inventory, grep count to `usr/jordan/captain/reset-baseline-20260419/` |
| V6 | reviewer-verification | No phase gates | A&D: 4 gates (Great Rename / Subdir / Cruft / Ref sweep), each with its own receipt artifact |
| V7 | reviewer-verification | No captain smoke battery | A&D: post-reset battery — /handoff read, /dispatch list, /flag list, /agency-health, /session-resume --dry-run, one skill with required_reading |
| V8 | reviewer-verification | No monofolk smoke battery | A&D: adopter-side checklist in release notes — agency update exit 0, hook paths resolve, @imports resolve, dispatch round-trip |
| V9 | reviewer-verification | Ref-sweep inventory artifact missing | A&D: scripted `ref-inventory.txt` generator, pre + post snapshots, diff empty modulo allowlist |

### Medium

| ID | Reviewer | Finding | Action in A&D |
|---|---|---|---|
| P1 | reviewer-product | Bootstrap paradox framing buried | Add sentence: "paradox remains open post-v46.0 by design" |
| P2 | reviewer-product | the-agency-group audience not addressed | Explicit deferral note in §2 |
| P3 | reviewer-product | Adopter migration OR-clause unresolved | Decision: manual migration via release notes + optional `agency update --migrate` helper |
| P5 | reviewer-product | SC #12 hedged "non-historical paths" | Same as V1 |
| P6 | reviewer-product | Static @import link-check missing | SC: "link-check tool reports zero broken @ imports and required_reading paths" |
| P7 | reviewer-product | usr/ + v2 skill non-goals silent | Add: "no changes to usr/ content beyond @import path rewrites"; "no v2 skill bundle conversions" |
| A1 | reviewer-architect | `agency/config/` shape not called out | A&D: `agency/config/` preserved as-is; reserves future `install-manifest.yaml` home |
| A3 | reviewer-architect | `.claude/` vs `agency/` ownership boundary | A&D: "`.claude/` = Anthropic-owned discovery; `agency/` = framework-owned. Cross-refs flow `.claude/` → `agency/`, never reverse" |
| A5 | reviewer-architect | workstream/captain/ triage by content-type before merge | A&D: personal state → `usr/jordan/captain/history/flotsam/`; shared artifacts → `the-agency/history/legacy-captain-workstream-20260419/` |
| A6 | reviewer-architect | Rollback scope under-detailed | A&D: (i) tag captures pre-reset, (ii) adopter-side = agency update --version v45.3 + settings.json revert, (iii) mid-flight abort = hard reset (all-or-nothing by design), (iv) rename detection validated per phase commit |
| R6 | reviewer-risk | CLAUDE.md @import ordering fragility | A&D: CLAUDE.md @import rewrite is LAST step; no subagents spawn before that step completes |
| R7 | reviewer-risk | monofolk `--migrate` should be mandatory | A&D: `agency update` v45.x→v46.0 requires `--migrate` flag; version-gate it |
| R8 | reviewer-risk | Pre-reset receipt path-strings won't resolve post-rename | A&D: add `HISTORICAL-PATH-NOTE.md` in each receipts/archive dir explaining the rename boundary |
| R9 | reviewer-risk | Rollback under non-atomic merge | A&D: enforce single-PR single-merge; if reset can't fit one PR, abort + redesign |
| R10 | reviewer-risk | Rename-then-sweep ordering | A&D: rename is pure move (no content edit); sweep separate commit; `git log --follow` validated on 5 canary files before merge |
| V2 | reviewer-verification | agency-health scoping (master vs worktrees) | A&D: SC #11 scoped to master-only; SC #11b added for "each worktree reports green after rebase" |
| V3 | reviewer-verification | `agency init` + `agency update --migrate` SCs missing | A&D: explicit SCs |
| V10 | reviewer-verification | Dynamic string-concat refs | A&D: grep for `["']claude/` and `claude/$` patterns |

### Low (captured; fine to address in A&D or Plan)

| ID | Reviewer | Finding | Action |
|---|---|---|---|
| P4 | reviewer-product | "Active worktree mid-reset" use case | Add Use Case 3.6: existing handoffs resolve under new paths |
| P9 | reviewer-product | Q8, Q9 content-audit items | Move to A&D content-inventory checklist |
| A7 | reviewer-architect | Nested @import resolution validation | A&D validation gate |
| V4 | reviewer-verification | Release-notes quality test | A&D: release notes include working examples for 3 breaking paths |
| V11 | reviewer-verification | ref-injector bats resolution test | A&D: new bats test for required_reading path validity |
| V12 | reviewer-verification | Fleet-wide worktree post-reset smoke | A&D: dispatch template "post-reset worktree smoke" with 60s check battery |

## Collaborate (principal decision)

### P8 — Branching strategy + PR #294 interaction

**Reviewer finding:** Q1 + Q2 are delivery-blocking; principal should decide before A&D starts.

**Captain autonomous decision (per principal's "only stop if collaborate" directive):**
- **New branch:** `v46.0-structural-reset` off `contrib/claude-tools-worktree-sync` HEAD
- **Merge order:** PR #294 merges first (already prepped); v46.0 reset PR follows
- **Rationale:** PR #294 already covers substantial scope; adding structural reset makes review impossible. Separate PR = clearer review + clearer rollback + clearer release notes.

**Noted for principal review:** if principal prefers monolithic PR #294 mega-scope instead, captain will restructure in A&D iteration.

## Reject

None — all findings accepted or deferred.

## Overall verdict

**Approve-with-changes confirmed. PVR proceeds to A&D with the findings above folded in.**

Critical gates for A&D: A2, A4, R1, R2, R3, R5, V5, V6, V7, V8, V9 — these are binding commitments, not suggestions.
