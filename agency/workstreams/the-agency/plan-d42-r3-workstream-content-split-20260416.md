---
title: "D42-R3 — Workstream Content Split + Structural Overhaul"
slug: d42-r3-workstream-content-split-structural-overhaul
path: docs/plans/20260416-d42-r3-workstream-content-split-structural-overhaul.md
date: 2026-04-16
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
tags: [Infra]
---

# D42-R3 — Workstream Content Split + Structural Overhaul

## Context

Monofolk's second principal (Peter Gao) exposed fundamental friction: workstream artifacts (PVR, A&D, plans, seeds, research, transcripts, receipts) accumulate in `usr/{P}/{A}/` with no shared visibility. A second principal joining a workstream can't see the first principal's source of truth. Issue #121 + #130 + #122.

Monofolk/captain posted a ratified spec. Captain ran a MAR (4 agents), then a 1B1 with the principal resolving each finding. This revised spec incorporates all 1B1 decisions.

## Revised Spec: REFERENCE-WORKSTREAM-CONTENT-SPLIT

### Core Rule

> If the artifact is about the workstream, it lives in the workstream.
> If the artifact is about the agent's personal state, it lives in the agent's sandbox.

**Litmus test:** if a second principal joined this workstream tomorrow, would they need to read `usr/{P}/{A}/` to understand the workstream? If yes, those artifacts belong in `claude/workstreams/{W}/`.

---

### Directory Structure — `claude/workstreams/{W}/`

Shared workstream space. Visible to every principal's agent working this workstream.

```
claude/workstreams/{W}/
  CLAUDE-{W}.md                          # workstream CLAUDE.md (shared class doc)
  KNOWLEDGE.md                           # accumulated patterns + decisions
  pvr-{W}-{slug}-{YYYYMMDD}.md           # current PVR(s) — flat at root
  ad-{W}-{slug}-{YYYYMMDD}.md            # current A&D(s) — flat at root
  plan-{W}-{slug}-{YYYYMMDD}.md          # current plan(s) — flat at root
  seed-{W}-{topic}-{YYYYMMDD}.md         # seed proposals — flat at root
  qgr/                                   # quality gate receipts (NEW)
  rgr/                                   # release gate receipts (NEW)
  drafts/{P}-{A}/                        # WIP before ratification
  research/                              # MARFI outputs, investigations
  transcripts/                           # 1B1 records, summaries, verbatim
  history/                               # superseded current versions
  history/flotsam/                       # uncategorized archive
```

**Current versions at root, accumulation in subdirs.** PVR, A&D, plan, seed files are flat at root for discoverability. Everything that accumulates goes in typed subdirs.

**When `{W}` equals `{slug}`** (single-project workstream), the name doubles: `pvr-folio-folio-20260416.md`. Accepted for mechanical consistency.

---

### Directory Structure — `usr/{P}/{A}/`

Personal agent state. Only this agent instance's working state.

```
usr/{P}/{A}/
  {A}-handoff.md                         # session handoff
  CLAUDE-{A}.md                          # personal overlay on class doc
  tmp/                                   # scratch (gitignored)
  tools/                                 # personal scripts
  history/                               # personal archive
  history/flotsam/                       # uncategorized personal items
```

**What's NOT here anymore:**
- `dispatches/` — all dispatches are DB-only via ISCP (legacy git payloads → `history/flotsam/`)
- `code-reviews/` — QGRs cover reviews (goes to per-workstream `qgr/`)
- `transcripts/` — workstream discussions go to shared `claude/workstreams/{W}/transcripts/`
- `seeds/` — workstream seeds go to shared workstream root
- `plans/` — workstream plans go to shared workstream root

---

### Directory Structure — `usr/{P}/`

Principal sandbox root. Contains ONLY agent directories.

```
usr/
  {P}/                                   # principal sandbox
    {A}/                                 # per-agent personal state (see above)
```

No loose files, no README, no shared content at the principal level.

---

### Directory Structure — `.claude/agents/{P}/{A}.md`

Agent registrations are principal-scoped.

```
.claude/agents/
  {P}/
    {A}.md                               # principal-scoped registration
```

**Invocation:** `claude --agent {P}/{A}` (e.g., `claude --agent jordan/captain`)

Each registration contains:
- `@import` of class doc: `@claude/agents/{class}/agent.md`
- `@import` of workstream CLAUDE: `@claude/workstreams/{W}/CLAUDE-{W}.md`
- `@import` of personal overlay: `@usr/{P}/{A}/CLAUDE-{A}.md`
- Startup steps (handoff read, dispatch check, etc.)

**`agent-bootstrap` retired.** Principal resolution is structural (path-based), not runtime. No shared-parent fallback — agents get shared context from the workstream CLAUDE doc, not sibling agent files.

---

### Directory Structure — `claude/` (framework)

```
claude/
  CLAUDE-THEAGENCY.md                    # repo-level bootloader
  REFERENCE-*.md                         # reference docs
  README-*.md                            # framework readmes
  config/                                # manifest.json, agency.yaml, settings-template.json
  agents/                                # class definitions (captain/, tech-lead/)
  hooks/                                 # PreToolUse/SessionStart hooks
  hookify/                               # behavioral enforcement rules
  tools/                                 # framework tools + lib/
  templates/                             # scaffolding templates
  data/                                  # SQLite DBs (ISCP, telemetry)
  receipts/                              # LEGACY — old receipts, dual-read during transition
  workstreams/                           # per-workstream shared spaces (see above)
```

---

### Receipt Naming (revised)

**Old:** `{org}-{principal}-{agent}-{workstream}-{project}-qgr-{hash}-{YYYYMMDD-HHMM}.md`

**New:** `{org}-{principal}-{agent}-{workstream}-{project}-{type}-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md`

Changes:
- `{type}` (qgr/rgr) and `{boundary}` (pr-prep/iteration-complete/phase-complete/plan-complete) added to filename
- Hash moved to end
- Date before hash = chronological `ls` sort

**Write path:** `claude/workstreams/{W}/qgr/` or `claude/workstreams/{W}/rgr/`

**Read path (dual-read during transition):**
1. `claude/workstreams/{W}/qgr/` and `rgr/` (new, checked first)
2. `claude/receipts/` (legacy fallback)
3. `usr/**/qgr-*.md` (old-old fallback, sunsets when all migrated)

---

### Receipt Frontmatter

```yaml
---
type: qgr
boundary: phase-complete
workstream: folio
project: folio-cms
principal: jordan
agent: monofolk/jordan/folio
date: 2026-04-16
hash_a: <full SHA-256>
hash_b: <full SHA-256>
hash_c: <full SHA-256>
hash_d: <full SHA-256>
hash_e: <full SHA-256>
hash_d_source: "auto-approved — no principal 1B1"
diff_base: origin/main
summary: "Phase 1: types and parser"
---
```

---

### Shared Artifact Frontmatter

Every shared artifact carries YAML frontmatter:

```yaml
---
type: pvr                              # pvr | ad | plan | seed | research | summary | transcript
workstream: folio
project: folio-cms                     # if project-scoped; omit if workstream-level
principal: jordan                      # who authored
agent: monofolk/jordan/folio           # fully qualified
date: 2026-04-16
slug: folio-cms                        # for PVR/A&D/plan
topic: headless-cms-comparison         # for seed/research/transcript
source: claude-code                    # for transcripts: granola | claude-code | manual
---
```

---

### Draft → Ratified Flow

1. Agent writes draft at `claude/workstreams/{W}/drafts/{P}-{A}/{type}-draft-{W}-{slug}-{YYYYMMDD}.md`
2. 1B1 review or principal approval
3. Move to workstream root as `{type}-{W}-{slug}-{YYYYMMDD}.md` (drops `{P}-{A}` attribution — now shared canon)
4. Superseded drafts → `history/`

Edits to ratified artifacts: normal git flow with meaningful commit messages.

---

### Current → History Flow

When a current artifact is superseded:
1. Copy current to `history/` with `{HHMM}` added: `pvr-{W}-{slug}-{YYYYMMDD}.md` → `history/pvr-{W}-{slug}-{YYYYMMDD}-{HHMM}.md`
2. Write new current at root: `pvr-{W}-{slug}-{NEW_YYYYMMDD}.md`

---

### PII Handling

PII is blocked at ingestion, not by path-scoping. Transcripts from all sources (including Granola with external parties) go to `claude/workstreams/{W}/transcripts/`. A PII redaction gate should be built as a separate tool — not part of this spec.

---

### Migration Strategy

**New stuff flows to new locations immediately.** Old stuff migrates after.

- Old `usr/{P}/{A}/dispatches/` contents → `claude/workstreams/{W}/history/flotsam/`
- Old `usr/{P}/{A}/qgr-*` files → `claude/workstreams/{W}/qgr/` (rename to new convention)
- Old `usr/{P}/{A}/transcripts/` → `claude/workstreams/{W}/transcripts/`
- Old `claude/receipts/` → per-workstream `qgr/`/`rgr/` (after tools updated)
- Old `claude/principals/` → `history/flotsam/` (entire tree is legacy)
- Old `.claude/agents/{A}.md` → `.claude/agents/{P}/{A}.md`

Migration uses `git-safe mv` (#130) once built.

---

### Repo-Level Workstream

Every repo has a repo-level workstream owned by the captain:
- For the-agency: `claude/workstreams/the-agency/`
- For monofolk: `claude/workstreams/monofolk/`

Captain plans, cross-cutting research, framework QGRs/RGRs, principal session transcripts — all go here. Same structure as domain workstreams.

---

### Ordering Constraints (from MAR)

These operations MUST happen in this order:
1. **Update `agent-create`** to write `.claude/agents/{P}/{A}.md` — before any new agents
2. **Rewrite all 9 existing registrations** from flat to `{P}/{A}.md` with `@import` model — before retiring agent-bootstrap
3. **Retire `agent-bootstrap`** — after all registrations rewritten
4. **Update `multi-principal.bats`** — retire agent-bootstrap regression anchor, add new `{P}/{A}.md` tests
5. **Update `receipt-sign` write path** — before any new QG runs
6. **Update `receipt-verify` + `pr-create` + `diff-hash`** — atomically with receipt-sign (all four in same commit)
7. **Update `_agency-init`** scaffold — before any new `agency init` runs
8. **Ship `git-safe mv`** — before migration begins

---

### Tooling Impact Summary

| Tool/Skill | Change | Phase |
|---|---|---|
| `receipt-sign` | Write to `claude/workstreams/{W}/qgr/` or `rgr/`; new filename format; requires `--workstream` for path | 1 |
| `receipt-verify` | Dual-read: new workstream path first, `claude/receipts/` fallback, update third-tier glob for new naming | 1 |
| `pr-create` | Separate `find` call — add `claude/workstreams/*/qgr/` to search (NOT just receipt-verify fix) | 1 |
| `diff-hash` | Add exclusions for `claude/workstreams/*/qgr/**` and `claude/workstreams/*/rgr/**` | 1 |
| `agent-create` | Write `.claude/agents/{P}/{A}.md` instead of `.claude/agents/{A}.md` | 1 |
| `agent-bootstrap` | Retire AFTER all registrations rewritten | 1 |
| `multi-principal.bats` | Retire agent-bootstrap tests, add `{P}/{A}.md` structure tests | 1 |
| `workstream-create` | Scaffold new subdirs (qgr/, rgr/, drafts/, research/, transcripts/, history/flotsam/) | 1 |
| `workstream-create` | Drop old subdirs from `usr/{P}/{A}/` scaffold (dispatches/, code-reviews/, seeds/) | 1 |
| `_agency-init` | Update usr/ scaffold to new slim structure | 1 |
| `git-safe` | Add `mv` subcommand (#130) | 1 |
| `git-safe` | Add `unstage` subcommand (D42 safety gap) | 1 |
| `git-safe` | Add `restore` subcommand (D42 safety gap) | 1 |
| `/define` | Write PVR to `claude/workstreams/{W}/` root | 2 |
| `/design` | Write A&D to `claude/workstreams/{W}/` root | 2 |
| `/transcript` | Write to `claude/workstreams/{W}/transcripts/` | 2 |
| `/quality-gate` | Update receipt output path reference | 2 |
| 9 existing `.claude/agents/*.md` | Rewrite to `.claude/agents/{P}/{A}.md` with `@import` model | 1 |
| REFERENCE-REPO-STRUCTURE.md | Update directory tree | 2 |
| REFERENCE-RECEIPT-INFRASTRUCTURE.md | Update receipt paths + naming | 2 |
| REFERENCE-QUALITY-GATE.md | Update receipt output paths | 2 |
| REFERENCE-WORKSTREAM-CONTENT-SPLIT.md | NEW — this spec as a reference doc | 1 |
| CLAUDE-THEAGENCY.md | Add reference doc pointer | 2 |
| CLAUDE.md | Add content placement pointer | 2 |

---

### Legacy Cleanup (separate pass after Phase 2)

| Current Location | Destination | Notes |
|---|---|---|
| `claude/principals/` | `history/flotsam/` | v1 principal system, fully replaced by `usr/` + `agency.yaml` |
| `claude/principals/jordan/resources/secrets/*.env` | **DELETE** | Security: .env files in git |
| `claude/plans/` | `claude/workstreams/the-agency/history/flotsam/` | Legacy plans |
| `claude/proposals/` | `claude/workstreams/the-agency/history/flotsam/` | Legacy proposals |
| `claude/reviews/` | `claude/workstreams/the-agency/history/flotsam/` | Legacy reviews |
| `claude/knowledge/` | Per-workstream `KNOWLEDGE.md` | Legacy knowledge |
| `claude/workstreams/test; rm -rf /` | **DELETE** | Injection test artifact |
| Old `claude/workstreams/{W}/seeds/` subdir | Seeds move to root | Files stay, subdir kept for backward compat |
| Old `claude/workstreams/{W}/reviews/` subdir | Replaced by `qgr/` | Migrate contents |

---

### What This Spec Does NOT Cover

- **Version decouple (#122):** `agency_version` vs `project.version` — separate release
- **PII redaction tool:** build separately, not part of content split
- **Permission scoping:** future hardening, not blocking
- **Workstream deletion/archival:** define when needed (no current use case)

---

## Implementation Plan

### Phase 1: Infrastructure (one release — D42-R3)

All tools + scaffold + registrations updated atomically. This is the big bang.

**Files to modify:**

| File | Change |
|---|---|
| `claude/tools/receipt-sign` | New write path (`claude/workstreams/{W}/qgr/` or `rgr/`), new filename format |
| `claude/tools/receipt-verify` | Dual-read (new path → `claude/receipts/` → `usr/`), update glob patterns for new naming |
| `claude/tools/pr-create` | Add `claude/workstreams/*/qgr/` to find calls |
| `claude/tools/diff-hash` | Add `:(exclude,glob)claude/workstreams/*/qgr/**` and `:(exclude,glob)claude/workstreams/*/rgr/**` |
| `claude/tools/agent-create` | Write to `.claude/agents/{P}/{A}.md`, resolve principal |
| `claude/tools/git-safe` | Add `mv`, `unstage`, `restore` subcommands |
| `claude/tools/lib/_agency-init` | Update usr/ scaffold (drop dispatches, code-reviews, seeds) |
| `.claude/skills/workstream-create/SKILL.md` | New workstream subdirs, slim usr/ scaffold |
| `.claude/agents/jordan/captain.md` | New principal-scoped registration (migrate from flat) |
| `.claude/agents/jordan/devex.md` | Same |
| `.claude/agents/jordan/designex.md` | Same |
| `.claude/agents/jordan/iscp.md` | Same |
| `.claude/agents/jordan/mdpal-cli.md` | Same |
| `.claude/agents/jordan/mdpal-app.md` | Same |
| `.claude/agents/jordan/mdslidepal-web.md` | Same |
| `.claude/agents/jordan/mdslidepal-mac.md` | Same |
| `.claude/agents/jordan/mock-and-mark.md` | Same |
| `claude/tools/agent-bootstrap` | Retire (delete or stub with error message) |
| `tests/tools/multi-principal.bats` | Retire agent-bootstrap tests, add {P}/{A}.md tests |
| `claude/REFERENCE-WORKSTREAM-CONTENT-SPLIT.md` | NEW — this spec shipped as reference doc |
| `claude/config/manifest.json` | Version bump 42.2 → 42.3 |

### Phase 2: Skill Output Paths + Documentation (one release — D42-R4)

Update skills to write to new locations. Update all reference docs.

**Files to modify:**

| File | Change |
|---|---|
| `.claude/skills/define/SKILL.md` | PVR output → `claude/workstreams/{W}/` |
| `.claude/skills/design/SKILL.md` | A&D output → `claude/workstreams/{W}/` |
| `.claude/skills/transcript/SKILL.md` | Transcript output → `claude/workstreams/{W}/transcripts/` |
| `.claude/skills/quality-gate/SKILL.md` | Receipt path references |
| `claude/REFERENCE-REPO-STRUCTURE.md` | Full directory tree update |
| `claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md` | Receipt paths + naming update |
| `claude/REFERENCE-QUALITY-GATE.md` | Receipt output path update |
| `claude/CLAUDE-THEAGENCY.md` | Add reference doc pointer |
| `CLAUDE.md` | Add content placement pointer |

### Phase 3: Migration (separate release — D42-R5 or later)

Requires `git-safe mv` (from Phase 1). Move existing artifacts to new locations.

- Old receipts from `claude/receipts/` → per-workstream `qgr/`/`rgr/`
- Old usr/ artifacts → shared workstream paths
- Legacy `claude/principals/` → flotsam
- Security: delete `.env` files from `claude/principals/jordan/resources/secrets/`
- Delete `claude/workstreams/test; rm -rf /`

---

## Verification

### Phase 1 verification
1. `bats tests/tools/multi-principal.bats` — new tests pass, old agent-bootstrap tests removed
2. `bats tests/schemas/hookify-rules.bats` — schema passes
3. `claude --agent jordan/captain` — resolves correctly from `.claude/agents/jordan/captain.md`
4. `./claude/tools/receipt-sign --workstream agency ...` — writes to `claude/workstreams/agency/qgr/`
5. `./claude/tools/receipt-verify` — finds receipt at new path
6. `./claude/tools/pr-create` — finds receipt at new path
7. `./claude/tools/diff-hash` — excludes new receipt paths
8. `./claude/tools/git-safe mv src dest` — atomic move works
9. `./claude/tools/git-safe unstage file` — clears staged file
10. Fresh `agency init --from-github` on test repo — produces new slim usr/ scaffold

### Phase 2 verification
1. `/define` on test workstream — PVR written to `claude/workstreams/{W}/`
2. `/transcript` — written to `claude/workstreams/{W}/transcripts/`
3. All REFERENCE docs updated and internally consistent

### Phase 3 verification
1. No files remain in `claude/receipts/` (all migrated or in flotsam)
2. No .env files in repo
3. `claude/principals/` removed
4. `git status` clean after migration
