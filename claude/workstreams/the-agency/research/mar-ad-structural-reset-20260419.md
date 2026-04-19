---
type: mar-triage
workstream: the-agency
slug: ad-structural-reset
artifact: ad-the-agency-structural-reset-20260419.md
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
reviewers: [reviewer-architect, reviewer-operations, reviewer-verification, reviewer-risk]
overall_verdict: approve-with-changes (4/4 reviewers aligned)
---

# MAR Triage — A&D: Structural Reset (v46.0)

4 reviewers + captain triage. All reviewers returned `approve-with-changes` — architecture and design sound; operational execution gaps need binding commitments in Plan before execution.

## Collaborate (captain-autonomous resolution)

Per principal's "only stop if collaborate" directive, captain resolves both autonomously:

### R-7 — Principal countersign on gates

**Captain decision:** NO — captain gates autonomously, principal approves at PR review only. Rationale: principal is shipping-focused; per-gate countersign adds latency. Gate receipts are committed + inspectable at PR review. Principal can abort the merge if any gate artifact is suspect.

### R-10 — Cross-repo ack required before merge from 9 worktree agents + monofolk

**Captain decision:** NO — dispatch post-merge, not pre-merge. Rationale: only monofolk is a real adopter; 9 worktree agents are the-agency's own fleet and will rebase per standard post-merge flow. Pre-merge ack would stall indefinitely. Mitigations: strong release notes with migration runbook, `v45.3-pre-reset` tag pushed to origin as a rollback anchor, monofolk notified via cross-repo dispatch AT merge with clear "read the migration guide before update."

## Accept (fold into Plan)

### HIGH severity — binding commitments

| ID | Reviewer | Finding | Plan action |
|---|---|---|---|
| F4 / R-4 | architect, risk | Subagent scope overlap (A+D both touch hookify; subagent C/B files intersect) | Plan: explicit per-subagent file-list manifests (globs rejected). Canonical split by file-glob, not topic. Post-fan-out: `git diff --stat` per subagent branch detects overlap; any out-of-scope edit rejects. |
| F-OPS-02 | operations | Runtime disjointness not enforced | Plan: ship `subagent-scope-check.sh` that verifies each subagent's file list is subset of their manifest before captain merges the work |
| F-OPS-06 | operations | Release notes timing race | Plan: release notes drafted Phase 0, completed before Phase 6; Phase 6 MUST be IN the PR before PR-open, not before merge. Gate 6 blocks PR creation. |
| F-OPS-09 | operations | Mid-flight resume marker missing | Plan: `usr/jordan/captain/reset-baseline-20260419/PHASE-CURSOR.txt` updated at each gate pass. `/session-resume` and handoff tool read cursor. Dispatch to self at each gate. |
| V2 | verification | Scan scope holes (.gitignore, tests, usr/, apps/, package.json) | Plan: expand `ref-inventory-gen` scope; explicit excludes only — everything else scanned |
| V3 | verification | Gate check automation | Plan: write `gate-check-{0..6}.sh` scripts; each gate is a script that exits 0/nonzero |
| V6 | verification | Per-worktree rollback missing | Plan: each worktree tags `pre-v46-rebase` BEFORE rebase; smoke-failure triggers rollback to tag |
| V8 | verification | `agency update --migrate` untested | Plan: §5.7 Migration validation — checkout v45.3 tag in `/tmp/v45-snapshot/`, run `agency update --migrate`, run monofolk smoke, assert green |
| V10 | verification | No post-merge smoke | Plan: Gate 7 — captain on master post-merge runs full battery; red = revert-merge before fleet rebase dispatch |
| R-1 | risk | Archive-before-delete enforcement | Plan: `agency-archive-then-delete` wrapper tool (or pre-delete hookify rule) — refuses `git rm`/`rm -rf` inside `agency/` unless flotsam path with matching stem exists OR `--confirmed-zero-value=<rationale>` |
| R-2 | risk | DB extraction integrity | Plan: (a) `PRAGMA integrity_check` pre-dump; (b) round-trip validation post-dump (load into :memory:, `.tables`); (c) sha256 source + dump; MANIFEST.txt in flotsam dir |
| R-8 | risk | Dynamic ref verification | Plan: post-sweep, full `bats tests/` re-run + every hookify rule fires + `agency-health` in clean shell; ENOENT on any `claude/...` path = miss |
| R-12 | risk | Supply-chain subagent sweep | Plan: pre-Phase-4 file-tree hash manifest of `agency/hooks/`, `agency/tools/`, `.claude/`. Post-Phase-4.5 NEW-file diff shows ZERO additions in these dirs (sweep is edits-only). Line-count delta heuristic rejects non-path-substitution edits. |

### MEDIUM severity — fold into Plan

| ID | Reviewer | Finding | Plan action |
|---|---|---|---|
| F2 | architect | Phase 3 bundles multi-profile ops | Split into Phase 3a (archive moves via git mv), 3b (data extraction), 3c (rm confirmed-dead). Own gate each. |
| F3 | architect | Gate 3.5 lacks personal-state validation | Add checks: `legacy-captain-workstream-20260419/` non-empty + dialogue-transcript in active transcripts |
| F5 | architect | Subagent @import constraint | Subagent briefs: "do not invoke skills requiring @import resolution; read only files in your scope" |
| F6 | architect | `.claude/commands/` ownership | Declare §0.7: subagent B owns `.claude/commands/*.md` rewrites alongside skills |
| F7 / V5 | architect, verification | Canary expansion | Expand to 8+ canaries: 1 binary (logo SVG), 1 deep-nested, 1 unusual-name if found; confirm no symlinks in `claude/` pre-move |
| F8 | architect | Per-subagent commit boundaries | Phase 4 uses 5 commits (one per subagent) so per-subagent revert is possible without whole-phase rollback |
| F10 | architect | Hookify canary test design | Plan: `hookify-rule-canary` tool; per-rule canary-trigger; Gate 5 blocks on tool existence |
| F-OPS-01 | operations | Time budget | Rebaseline to 120 min with explicit reserves; pre-write subagent briefs |
| F-OPS-03 | operations | Gate check manual vs scripted | Same as V3 — write `gate-check.sh` scripts |
| F-OPS-04 | operations | Phase 3 partial-failure recovery | Phase 3 as one atomic commit — stage all archive+delete ops, verify tree, then one commit. Failure pre-commit = `git checkout -- .` + restart |
| F-OPS-07 | operations | Subagent fan-in model | Each subagent returns receipt (`subagent-{A..E}-receipt.md` with files touched, ref-leakage count, test result). Captain blocks on 5/5 receipts before Phase 4.5 |
| V1 | verification | Baseline checksum completeness | Add content-inventory.sha256 (every tracked file), skill count, hookify rule count, test count, settings.json + CLAUDE.md checksums |
| V4 | verification | Captain smoke gaps | Extend battery: skill-validate.bats, hookify dynamic rule-fire canary, commit-precheck on post-reset file, ISCP tool battery, ref-injector live test, bats tests/ parity check vs Phase 0 |
| V7 | verification | Monofolk smoke shallowness | Add content-hash validation (resolved hook sha256 matches v46.0 manifest); hook-fire round-trip test |
| V9 | verification | Allowlist rationale requirement | `agency/tools/ref-sweep-allowlist.txt` — glob-or-path + rationale per line; ref-inventory-gen warns on unlisted hits; gate blocks if rationale missing |
| R-3 | risk | Audit log reconciliation | Post-reset script compares audit log against commits on reset branch; zero delta required |
| R-5 | risk | CLAUDE.md @import mid-reset contradiction | Captain decision: OPTION (B) — subagent briefs forbid reading CLAUDE.md / invoking skills that trigger @import resolution. Subagent scope is ONLY their declared file list. |
| R-6 | risk | `--migrate-back` fallback | Implement `--migrate-back` + BATS test before merge. Ship manual-revert runbook in release notes as guaranteed fallback. |

### LOW severity — fold into Plan

| ID | Reviewer | Finding | Plan action |
|---|---|---|---|
| F1 | architect | Phase count inconsistency | Fix "partitioned into 9 numbered phases (0–6, with 3.5 and 4.5 as split sub-phases)" |
| F9 | architect | Audit log committed to repo | Commit audit log to `agency/workstreams/the-agency/history/reset-audit-20260419.log` as Phase 6 deliverable |
| F11 | architect | logs/ disposition | §7 Content audit adds logs/ default: archive-to-flotsam |
| F-OPS-05 | operations | Push tag to origin | Phase 0 gate requires `git-captain push-tag v45.3-pre-reset` before any move |
| F-OPS-08 | operations | Audit log JSONL | Format: JSONL — `{"ts":...,"cmd":...,"exit":0,"phase":...,"rationale":...}` |
| F-OPS-10 | operations | Phase 3.5 literal commands | Plan produces literal `git mv` command list, not rule table |
| R-9 | risk | History preservation on all files | Post-Phase-1 scripted pass: `git log --follow` on all renamed files; count delete+add; zero tolerance |
| R-11 | risk | Historical path-string helper | Document pattern in release notes: search history subtrees for `claude/` patterns |

## Reject

None — all findings accepted.

## Overall verdict

**Approve-with-changes confirmed. A&D proceeds to Plan with all findings folded in as binding operational commitments.**

Plan must deliver:
- File-list manifests for 5 subagents (disjoint, explicit)
- 7 gate-check.sh scripts
- ref-inventory-gen tool design
- ref-sweep-allowlist.txt format + seed entries
- agency-archive-then-delete wrapper (or hookify rule)
- hookify-rule-canary tool design
- subagent-scope-check.sh
- Per-subagent receipt template
- Phase cursor format
- v45.3 snapshot migration test design
- Canary file list (8+)
- Release notes skeleton filled in
- Monofolk smoke battery as script
