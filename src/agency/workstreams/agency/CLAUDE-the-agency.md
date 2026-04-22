# The-Agency Workstream

The **meta-workstream** that develops the-agency framework itself.

## Purpose

Everything that is "the-agency as a product" — its platform tools, developer tools, agent classes, hookify rules, skills, reference docs, templates, release process — ships from here. This is the framework-dev workstream for the framework itself.

## Scope

- Framework release lifecycle (version bumps, release notes, migration runbooks)
- Platform + developer tool development (`agency/tools/` + `src/tools-developer/`)
- Hookify rules authoring (`agency/hookify/`)
- Skill + command authoring (`.claude/skills/`, `.claude/commands/`)
- Reference + README doc maintenance (`agency/REFERENCE/`, `agency/README/`)
- Agent class definition authoring (`agency/agents/`)
- Cross-workstream coordination (dispatches routing, ISCP protocol)
- Build pipeline (post-v46.2: `src/tools-platform/build` + manifest.json generation)
- Release cadence infrastructure (daily cron, release-skip files, Release-D{N}-R{n}-{date}.md)
- Adopter migration (andrew-demo, monofolk interop)

## Agents

- **captain** (`usr/jordan/captain/`) — primary workstream lead; owns release cuts, plan authoring, MAR coordination, PR review, cross-repo collaboration
- Reviewer subagents — invoked during quality gates (reviewer-code, reviewer-security, reviewer-design, reviewer-test, reviewer-scorer)
- Multi-principal note: additional principals (e.g., matt) collaborate here via `usr/{principal}/captain/` sandboxes; `drafts/{P}-captain/` in workstream root keeps WIP attributed

## Artifacts at workstream root

- `CLAUDE-the-agency.md` — this doc
- `pvr-the-agency-{slug}-{YYYYMMDD}.md` — current PVRs (1 per active slug)
- `ad-the-agency-{slug}-{YYYYMMDD}.md` — current A&Ds
- `plan-the-agency-{slug}-{YYYYMMDD}.md` — current plans
- `seed-the-agency-{topic}-{YYYYMMDD}.md` — current seeds

## Accumulating subdirs

- `releases/` — per-release records: `Release-D{N}-R{n}-{YYYYMMDD}.md` (shipped) or `Release-Skip-{YYYYMMDD}.md` (skipped), trust-chain preservation
- `qgr/` — Quality Gate Receipts (implementation boundaries: iteration/phase/plan-execution/pr-prep)
- `rgr/` — Review Gate Receipts (document reviews: seed/PVR/A&D/plan)
- `research/` — MAR triages, investigations, worknotes
- `transcripts/` — per-day dialogue transcripts (1B1 records, decision chains)
- `drafts/{P}-captain/` — superseded draft versions per principal
- `history/flotsam/` — legacy subsystem archives (legacy-agency-workstream, legacy-principals, legacy-receipts, etc.)

## Principals + adopters

- **Jordan** (`usr/jordan/captain/`) — primary framework author
- **Adopters:**
  - `monofolk` — cross-repo via `collaboration-monofolk` bridge (foreign-org)
  - `andrew-demo` — local adopter repo used for migration testing

## Relationship to `src/` and `agency/`

- `agency/` — dual-tracked installable framework (ships to customers on `agency init`)
- `src/` — framework-dev-only content (sources + developer tools + archives; never shipped)
- `src/tools-platform/` (v46.2+) — platform tool sources that build into `agency/tools/`
- `src/tools-developer/` — developer-only tools, never built, never shipped
- `src/apps/` — app workstream source trees (mdpal, mdslidepal, mock-and-mark) with their own build toolchains
- This workstream (`agency/workstreams/the-agency/`) owns the release + coordination process that spans both

## Versioning

Releases use `D.R` format:
- D = Day counter (calendar day from reference start)
- R = Release number within that day (resets daily, increments per cut)
- Example: Day 46, Release 1 = `v46.1` (shipped 2026-04-20 as AgencyV3 foundation)
- Symbolic tag `agency-v3` marks the installer threshold release

Per-artifact versions live in YAML frontmatter; `agency/config/manifest.json` is the derived index.

## Release cadence (v46.2+)

- Daily cron at 2300 SGT (15:00 UTC)
- Empty days skip (nothing shipped)
- Override A: manual mid-day cut (captain + principal 1B1)
- Override B: skip next scheduled cut (commit `Release-Skip-{YYYYMMDD}.md` to `releases/`)

Full release-history dir: `releases/` (both `Release-D{N}-R{n}-*.md` and `Release-Skip-*.md` files co-located; audit-browseable via `ls`)

## Cross-references

- Plan: `plan-the-agency-structural-reset-20260419.md` (plan v4, historical) + `plan-the-agency-structural-reset-v5-20260420.md` (v5, via `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`)
- PVR: `pvr-the-agency-structural-reset-20260419.md`
- A&D: `ad-the-agency-structural-reset-20260419.md`
- Latest release: `releases/Release-D46-R1-20260420.md`
