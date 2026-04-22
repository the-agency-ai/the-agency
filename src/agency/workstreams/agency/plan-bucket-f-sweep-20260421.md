<!--
What Problem: Post-Phase-E residue sweep. The Great Rename (claude/ → agency/)
swept the tree at Phase 1 of plan v4, and Phase E (v46.12) narrowly swept the
skill-validation surface. An inventory on 2026-04-21 (captain-dispatched agent,
report in this plan's Appendix A) identified ~75 files / ~140 lines where the
pre-rename `claude/` prefix still appears on framework surfaces. Adopter-visible
docs, agent registrations, and principal bootloaders top the list. Bucket F
clears the residue as a dedicated release (R3 v46.14).

How & Why: Three-layer plan. Mechanical sweep via 5 parallel subagents (scopes
that are pure prefix/path-depth substitutions). Hand sweep by captain for the
3 scopes that need judgment (REFERENCE path-depth shifts, monofolk-ports error
messages, skill bodies). Verification layer runs ref-inventory-gen + custom
Bucket F grep audit + import-link-check before QG. Fix A from C#372 (pr-merge
advisory nag) rides along as a single small commit on the branch. QG, PR,
merge, release.

Why a plan file + MAR before execution: Phase-E-taught lesson. A sweep looks
mechanical until it hits a case where substitution would silently break.
MAR catches those before we're 3 PRs deep.

Written: 2026-04-21, after v46.13 merge (Bucket 0 shipped).
-->

---
status: draft-v1-awaiting-mar
workstream: agency
release: R3 v46.14
issue: the-agency#401 (Bucket F)
depends_on: Bucket 0 shipped (v46.13)
blocks: Bucket A (v46.16), PR #397 merge (v46.15)
---

# Bucket F — Post-Great-Rename Residue Sweep

**Plan version:** draft-v1 (2026-04-21, awaiting MAR)
**Release target:** R3 v46.14
**Issue:** [the-agency#401](https://github.com/the-agency-ai/the-agency/issues/401)
**Parent plan:** `plan-abc-stabilization-20260421.md` (v3.2)

## Problem

The Great Rename (plan v4 Phase 1) moved `claude/` → `agency/` at the repo root. Phase E (v46.12) swept the skill-validation surface narrowly. An inventory run on 2026-04-21 (full report in Appendix A) identified residue across 13 framework surfaces:

| # | Scope | Files | Hits | Severity |
|---|---|---:|---:|---|
| 1 | `agency/README-*.md` (getting-started, framework overview) | 2 | 8 | **HIGH** |
| 2 | `agency/REFERENCE/REFERENCE-*.md` (customer ref docs) | 15 | 34 | **HIGH** + path-depth change |
| 3 | `agency/README/*.md` (ENFORCEMENT, SAFE-TOOLS) | 2 | 3 | **HIGH** |
| 4 | `agency/config/**` | 0 | 0 | CLEAN |
| 5 | `agency/agents/**` (class defs) | 2 | 3 | MEDIUM |
| 6 | `agency/tools/**` | 2 | 3 | LOW (intentional) |
| 7 | `src/apps/**` (monofolk-ports error messages) | 6 | 11 | MEDIUM |
| 8 | `.claude/agents/**` (agent registrations) | 9 | 24 | **HIGH** |
| 9 | `.claude/skills/**/SKILL.md` (frontmatter + body) | 16 | 24 | **HIGH** |
| 10 | `agency/hookify/**` (footer refs) | 15 | 15 | MEDIUM |
| 11 | `agency/hooks/**` | 1 | 1 | LOW (intentional) |
| 12 | `usr/jordan/*/CLAUDE*.md` (principal bootloaders) | 3 | 11 | **HIGH** |
| 13 | Root bootloaders (`CLAUDE.md`, `CLAUDE-THEAGENCY.md`) | 2 | 3 | **HIGH** |

**Total actionable:** ~75 files, ~140 lines.

**Not just prefix substitution:** References to `claude/REFERENCE-FOO.md` must become `agency/REFERENCE/REFERENCE-FOO.md` — the REFERENCE subdir is a path-depth change, not only a prefix swap. Mechanical sed on the prefix alone would leave the path wrong.

## Out-of-scope findings (filed, not executed here)

Inventory surfaced 4 adjacent structural issues that aren't rename residue. File as issues; handle post-Bucket-F:

1. **Starter-pack canonical location** — docs reference `claude/starter-packs/<type>/`; actual location appears to be `src/spec-provider/starter-packs/`. Affects REFERENCE-PRINCIPAL-GUIDE, REFERENCE-CONCEPTS, REFERENCE-SECRETS, monofolk-ports scaffolding, /service-add, /ui-add. **Needs decision** on canonical path before sweeping.
2. **Broken pointer** — `agency/README-GETTINGSTARTED.md:169` references `claude/YOUR-FIRST-RELEASE.md` which doesn't exist anywhere. Orphan, not a rename miss.
3. **MCP tsx path** — `REFERENCE-CONCEPTS.md:253` hardcodes `claude/claude-desktop/agency-server/index.ts`; actual is `src/integrations/claude-desktop/agency-server/index.ts`. Load-bearing example.
4. **Missing bootloaders** — 6 of 9 principals lack `CLAUDE-<agent>.md` fragments (designex, mdpal-cli, mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark). Structural gap; not rename.
5. **`src/tools-developer/`** (15 files) has `claude/` residue — outside the 11-scope list but parallel to `agency/tools/`. Some files (e.g. `git-rename-tree`, `agency-verify-v46`) may intentionally reference `claude/` for backwards-compat. **Audit before sweeping.**

All 5 filed as follow-up issues during Phase 0 (below).

## Phase structure

### Phase 0: Preflight — scope confirmation + tooling checks

1. **Confirm intentional references.** Three files explicitly reference `claude/` on purpose (import-link-check, plan-capture tool, plan-capture hook). Add them to an `.bucket-f-allowlist` or equivalent so sweep tooling skips them.
2. **Sanity-check scope 5 (src/tools-developer)** — inspect each of the 15 files; decide scope-in (sweep) or scope-out (intentional backwards-compat). Document in this plan before Phase 1.
3. **File 5 follow-up GitHub issues** for the out-of-scope findings above (starter-pack canonical, broken YOUR-FIRST-RELEASE pointer, MCP tsx path, missing bootloaders, tools-developer audit).
4. **Confirm `ref-inventory-gen` + `import-link-check` are functional** — both are post-Phase-E tools; re-run against main to baseline. Snapshot output to `agency/workstreams/agency/research/bucket-f-pre-sweep-baseline-20260421.md`.

**Gate 0 exit:** allowlist committed; scope 5 decided; 5 follow-up issues filed; baseline inventory snapshot committed.

### Phase 1: Mechanical sweep — 5 parallel subagents

Five subagents run in worktree isolation, each with a scoped manifest. Output is structured patch applied serially by captain.

| Subagent | Scope | Substitution complexity |
|---|---|---|
| **F-A** | Scope 1 + 3 + 13 — customer-facing top-level docs (README-GETTINGSTARTED, README-THEAGENCY, README/ENFORCEMENT, README/SAFE-TOOLS, repo-root CLAUDE.md, CLAUDE-THEAGENCY.md) | HIGH — path-depth changes; ASCII trees need rewrite not just replace |
| **F-B** | Scope 8 — `.claude/agents/**` (all 9 agent registrations) | LOW — consistent `claude/agents/`, `claude/workstreams/`, `claude/REFERENCE-*.md` patterns |
| **F-C** | Scope 10 — `agency/hookify/**` footer refs (15 rules) | LOW — one-line footer pattern |
| **F-D** | Scope 12 — `usr/jordan/*/CLAUDE*.md` (captain, devex, iscp bootloaders; 11 hits including tool paths) | MEDIUM — mix of doc refs + load-bearing tool paths (`./claude/tools/...` → `./agency/tools/...`) |
| **F-E** | Scope 5 + 6-intentional-exempt + 11-intentional-exempt — `agency/agents/**` (3 hits) + confirm the 3 exempt files are annotated | LOW — few hits; includes writing an "intentional reference" comment at each exempt site |

**Each subagent output:** structured patch with before/after hunks, count of hits resolved, list of any path-depth changes that required rewriting (not just replacement). Captain reviews each patch before applying.

**Gate 1 exit:** all 5 subagent patches applied to branch; `ref-inventory-gen --scope agency/README,agency/README,CLAUDE.md,agency/CLAUDE-THEAGENCY.md,.claude/agents,agency/hookify,agency/agents,usr/jordan` returns zero unresolved `claude/` refs across scopes 1, 3, 5, 8, 10, 12, 13.

### Phase 2: Hand sweep — 3 scopes captain owns

Scopes that need human judgment. Not parallelizable.

#### Phase 2.1 — Scope 2: REFERENCE docs (15 files, 34 hits)

Path-depth change: `claude/REFERENCE-FOO.md` → `agency/REFERENCE/REFERENCE-FOO.md`. Additionally:

- `REFERENCE-REPO-STRUCTURE.md:14-17` — ASCII tree uses `claude/` as the top-level dir. **Rewrite the description**, not just substitution; it describes the old structure.
- `REFERENCE-SKILL-AUTHORING.md:79-80, 104-105` — example `required_reading:` frontmatter that authors copy. **Update to current convention** (including the subdir shift).
- `REFERENCE-SKILL-CONVENTIONS.md:26` — normative guidance: `"If truly no REFERENCE doc applies, the closest-fit candidate is claude/REFERENCE-REPO-STRUCTURE.md"` — substitute + verify the cross-ref is still the closest-fit candidate.
- `REFERENCE-PRINCIPAL-GUIDE.md:134-139` + `REFERENCE-CONCEPTS.md:253, 272, 279` — starter-pack paths. **Defer** pending the canonical-starter-pack-path follow-up issue. Add a `TODO(bucket-f-followup-starter-packs)` comment at each site; don't change the path.
- `REFERENCE-CLAUDE-COVERAGE-CHECKLIST.md` (9 hits) — table format cross-refs. Mechanical for 9; verify no doc-name drift (e.g. was "REFERENCE-FOO" also renamed?).

**Gate 2.1 exit:** 34 hits resolved; 6 deferred hits marked with TODO comments pointing to the follow-up issue.

#### Phase 2.2 — Scope 7: src/apps (6 files, 11 hits)

Mostly `monofolk-ports` TS source — docstrings, help text, error messages. Error messages will fire at runtime if triggered, so accuracy matters.

- `service-add.ts`, `ui-add.ts`, `validators.ts`, `topology-patch.ts` — swap `claude/` → correct path. Starter-pack hits (3) are deferred pending the canonical-path issue; leave TODO.
- `mdslidepal-web/src/types.ts:2` and `test-smoke-workshop.md:90` — doc-style references; mechanical.
- **Additionally:** `src/apps/mdpal-app/claude/agents/unknown/backups/...` — the enclosing path includes `claude/`. Confirm whether this is pre-rename framework debris (rename to `agency/agents/...`) or app-local intentional structure (leave, annotate). Inspect first commit history; decide before sweeping.

**Gate 2.2 exit:** 11 hits resolved or TODO'd; directory rename decision made on `src/apps/mdpal-app/claude/agents/`.

#### Phase 2.3 — Scope 9: .claude/skills bodies + frontmatter (16 files, 24 hits)

Mix of `required_reading:` frontmatter (3 skills) and SKILL.md body refs (13 skills).

- Frontmatter sweep is validated by ref-injector; any path typo fails loudly at skill invocation. Low risk.
- Body refs include example code blocks (captain-sync-all/examples.md shows example git output with `claude/REFERENCE-SKILLS-INDEX.md`). Update to reflect current tree.
- `pr-captain-merge/SKILL.md:162`, `pr-captain-merge/examples.md:125`, `pr-submit/scripts/README.md:43` — doc-style refs; mechanical.
- `sandbox-init/SKILL.md:47` — normative: `"sandbox root — NOT under a 'claude/' subdirectory"`. **Keep but reword** — explaining the negative is legit; the wording should match current convention (reference `.claude/` or `agency/` appropriately).

**Gate 2.3 exit:** 24 hits resolved; ref-injector verifies all 16 skills still invoke cleanly (no broken `required_reading:` refs).

### Phase 3: Fix A ride-along (C#372)

One tool edit (`agency/tools/pr-merge`) — post-merge advisory nag:

```
✓ Merged PR #<N>
>>> NEXT STEP REQUIRED: /pr-captain-post-merge <N> <<<
    (cuts the release tag — CI will go red on main if you skip this)
```

Plus: auto-emit a flag "post-merge-pending PR #<N>" at merge time so `/flag-triage` surfaces the pending action even if captain closes the terminal.

**Scope:** 1 file, ~15 lines. Advisory text only. Zero risk.

**Why in Bucket F:** Fix A is 15 minutes of work; carving its own release (R6) wastes a release cycle. It's a captain-hygiene improvement; rides along in Bucket F's coord commits.

**Gate 3 exit:** pr-merge nag text fires after successful merge; flag auto-emitted on merge.

### Phase 4: Verification

1. Re-run `ref-inventory-gen --post --strict` — expect zero unknown paths.
2. Re-run `import-link-check` — expect clean.
3. Run `agency/tools/agency-verify-v46 --customer` — expect exit 0.
4. Run full BATS: `bats src/tests/tools/` — expect green.
5. **Custom Bucket F grep audit** — a one-shot grep for `[[:space:]`''\"\\(\\[]claude/[^.]` across the scopes above (excluding allowlisted files). Any non-zero output = a miss. Document in plan revision.
6. **Agent registration smoke test** — spawn one agent class (e.g. reviewer-code) and confirm it loads; catches broken registration paths.

**Gate 4 exit:** all 6 checks clean.

### Phase 5: QG + PR + merge + release

1. `/pr-prep` — full QG, parallel reviewer agents, RGR receipt.
2. `/sync` — push branch.
3. `/pr-create` — PR title `fix(bucket-f): post-Great-Rename residue sweep (#401) + pr-merge advisory nag (#372 Fix A) → v46.14`.
4. Principal approval.
5. `/pr-captain-merge <N> --principal-approved`.
6. `/pr-captain-post-merge` — cuts v46.14 release.

**Gate 5 exit:** v46.14 shipped on GitHub.

## MAR — Reviewers + focus

Propose 3 reviewers. Each reads this draft plus Appendix A (the inventory).

| Reviewer | Focus |
|---|---|
| **reviewer-design** | Is the phase split right? Is the 5-subagent/hand-sweep divide sound? Does Fix A belong here? |
| **reviewer-scope** (general-purpose with "scope creep" framing) | Are the 5 out-of-scope findings correctly scoped out, or should any fold back in? Is the scope-5 (src/tools-developer) decision structured correctly? |
| **reviewer-code** | Phase 2 hand-sweep scopes — are the judgment criteria clear? Are the TODO markers for the deferred starter-pack items structured enough for the follow-up to pick them up? |

Each returns structured findings (no 3-bucket self-sort). Captain triages into ACCEPT or REJECT (per the Bucket 0 discipline; no DEFER).

## Risk assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Mechanical sweep misses path-depth change on REFERENCE docs | M | H (breaks ref-injector validation) | Phase 2.1 is hand sweep specifically for this; ref-injector catches at Phase 4 |
| Subagent patches conflict with each other | L | M (serial application halts) | Each scope is disjoint; captain reviews + applies serially |
| Starter-pack path decision blocks Bucket F | L | M | TODO markers in place; don't block; handle in follow-up issue |
| `src/apps/mdpal-app/claude/agents/` is actually app-local and we rename it | M | M (breaks mdpal-app dev loop) | Phase 2.2 requires explicit decision before sweeping; consult mdpal-app owner |
| Fix A ride-along delays merge due to QG findings on pr-merge | L | L (revert or split) | Keep in separate commit; if QG flags, split into R6 as originally planned |
| Missing bootloaders (6 principals) cause confusion post-merge | L | L | They were missing before; filed as issue; not worse than current state |

## Subagent delegation points

| Phase | Subagent type | Parallel? | Isolation |
|---|---|---|---|
| Phase 0.3 — file 5 follow-up issues | general-purpose (sequential `gh issue create`) | no | no |
| Phase 1 — 5 parallel mechanical sweep agents (F-A..E) | general-purpose × 5 | **yes** | dedicated `.agency/worktrees-bucket-f/` or serialized patches |
| Phase 4.6 — agent registration smoke test | general-purpose (spawn + confirm) | no | ephemeral test worktree |

## Verification

- `ref-inventory-gen --post --strict` → zero unknown paths
- `import-link-check` → clean
- `agency-verify-v46 --customer` → exit 0
- `bats src/tests/tools/` → green
- Custom Bucket F grep audit → zero hits outside allowlist
- Agent registration smoke test → reviewer-code loads cleanly

## Release sequencing impact

If Bucket F executes cleanly, plan v3.2's release table needs one row adjusted:

| Old (plan v3.2) | New (with Fix A in F) |
|---|---|
| R3 v46.14 — Bucket F | R3 v46.14 — Bucket F + C#372 Fix A |
| R6 v46.17 — C#372 full fix | R6 v46.17 — C#372 Fix B (pending-post-merge state file) + Fix D (auto-release GH Action) |

Parent plan (`plan-abc-stabilization-20260421.md` v3.2) gets a revision log entry noting Fix A rode along in F.

## Critical files

- This plan: `agency/workstreams/agency/plan-bucket-f-sweep-20260421.md`
- Inventory report: Appendix A (below)
- C#372 diagnosis: `agency/workstreams/agency/research/c372-diagnosis-20260421.md` (to be written from agent output)
- Parent plan: `agency/workstreams/agency/plan-abc-stabilization-20260421.md` (v3.2)
- Issue: https://github.com/the-agency-ai/the-agency/issues/401

## Appendix A — Inventory report (2026-04-21 subagent output)

*Preserved verbatim from the inventory agent's output. Full per-file findings follow.*

[Condensed to top-level summary here; full per-scope findings saved separately at `agency/workstreams/agency/research/bucket-f-inventory-20260421.md` during Phase 0.]

| # | Scope | File count | Files w/ residue | Hits | Severity |
|---|---|---:|---:|---:|---|
| 1 | `agency/README-*.md` | 2 | 2 | 8 | HIGH |
| 2 | `agency/REFERENCE/REFERENCE-*.md` | 46 | 15 | 34 | HIGH + path-depth |
| 3 | `agency/README/*.md` | 3 | 2 | 3 | HIGH |
| 4 | `agency/config/**` | 9 | 0 | 0 | CLEAN |
| 5 | `agency/agents/**` | 31 | 2 | 3 | MEDIUM |
| 6 | `agency/tools/**` | 134 | 2 | 3 | LOW (intentional) |
| 7 | `src/apps/**` | 207 | 6 | 11 | MEDIUM |
| 8 | `.claude/agents/**` | 9 | 9 | 24 | HIGH |
| 9 | `.claude/skills/**/SKILL.md` | 114 | 16 | 24 | HIGH |
| 10 | `agency/hookify/**` | 41 | 15 | 15 | MEDIUM |
| 11 | `agency/hooks/**` | 9 | 1 | 1 | LOW (intentional) |
| 12 | `usr/jordan/*/CLAUDE*.md` | 3 | 3 | 11 | HIGH |
| 13 | Root bootloaders | 2 | 2 | 3 | HIGH |

Plus 5 out-of-scope findings (starter-pack canonical, broken YOUR-FIRST-RELEASE pointer, MCP tsx path, missing bootloaders, src/tools-developer audit) — filed as follow-up issues in Phase 0.3.

---

*Draft v1. Awaiting MAR.*
