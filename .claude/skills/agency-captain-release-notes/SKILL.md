---
name: agency-captain-release-notes
description: Captain-only. Generate a release-notes skeleton for the current captain to announce a window of PRs + releases to other captains/principals on the same repo. Auto-populates the mechanical parts (PR table, version window, frontmatter, filename); captain fills qualitative sections (TL;DR, shared changes, behavioral changes, flags, in-flight, coordination asks). Every PR is a release, and every window of releases deserves a note when multiple captains share a repo.
agency-skill-version: 2
when_to_use: Captain has landed a burst of PRs on master and wants to broadcast what shipped to other captains/principals working the same repo. Typical cadence — once per session-burst, or daily. Also useful before session-end as a recap artifact.
argument-hint: "[--start-version vX.Y] [--end-version vX.Y] [--to <addr>] [--audience <string>] [--workstream <name>] [--dry-run] [--stdout]"
paths: []
required_reading:
  - agency/REFERENCE/REFERENCE-AGENT-ADDRESSING.md
  - agency/REFERENCE/REFERENCE-SAFE-TOOLS.md
---

# agency-captain-release-notes

Captain-only skill. Generates a release-notes skeleton addressed to other captains or principals on the same repo. Mechanical parts (PR table, version window, frontmatter, output path) are tool-generated; qualitative parts (narrative, shared changes, flags, in-flight) are captain-filled.

**Name pattern:** `agency-` (framework-level skill, upstreamed from the-agency), `captain-` (captain-only scope), `release-notes` (noun).

## Why this exists

When multiple captains (or captain + principal) work the same repo, "here's what I shipped since the last sync" is knowledge stored in `git log` + release tags + private handoffs. Cross-captain visibility requires manually walking `gh release list`, `gh pr list`, correlating by date, assembling a markdown file. Time-consuming, error-prone, drifts.

Captured 2026-04-23 when a captain wrote a release-notes file for cross-captain coord and it took ~15 minutes + a second round when the window expanded. Principal then asked: *"this should be a tool."* So it is.

The tool handles enumeration. The captain handles synthesis. Clean split.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

## Usage

```
/agency-captain-release-notes                                 # auto-detect everything
/agency-captain-release-notes --start-version v3.2            # explicit start
/agency-captain-release-notes --start-version v3.2 --end-version v3.31
/agency-captain-release-notes --to monofolk/peter/captain     # narrow addressee
/agency-captain-release-notes --audience "any captain working on monofolk"
/agency-captain-release-notes --dry-run                       # preview without writing
/agency-captain-release-notes --stdout                        # print to stdout
```

### Arguments

- `--start-version <vX.Y>` — first release tag NOT already covered by a prior release-notes file. Auto-detected from most recent prior file's `end_version` if omitted.
- `--end-version <vX.Y>` — most recent release to include. Auto-detected as the latest tag on master if omitted.
- `--start-date <ISO>` / `--end-date <ISO>` — alternative to version-based windowing (UTC timestamps).
- `--to <address>` — specific addressee. Default: broadcast (no specific `to:`, audience-only frontmatter).
- `--audience <string>` — human-readable audience description. Default: `"any captain or principal working on <project>"`.
- `--workstream <name>` — workstream directory name under `agency/workstreams/`. Default: project name from `agency/config/agency.yaml`.
- `--captain <name>` — captain name for filename + frontmatter. Default: resolved from `agency-identity` (`{principal}-{agent}`).
- `--output <path>` — explicit output file path.
- `--stdout` — print to stdout instead of writing.
- `--dry-run` — show what would be written.

## Preconditions

1. `gh` CLI installed (tool queries GitHub for PRs + releases).
2. Captain is on master or any branch (tool does not care — it queries `gh` not the local branch state).
3. Repo has at least one release tag (for auto-detection). Not required if `--end-version` passed explicitly.

## Flow / Steps

### Step 1: Generate skeleton

```bash
./agency/tools/agency-captain-release-notes [...args]
```

Tool writes to `agency/workstreams/<workstream>/release-notes/release-notes-<YYYYMMDD>-<captain>-<vStart>-<vEnd>.md`.

Skeleton has:
- YAML frontmatter (from / audience / to / window / prs_landed_count / generated_by)
- Header block (from / audience / window)
- TL;DR placeholder
- **PRs landed table** — auto-populated from `gh pr list`
- Cross-repo / shared-package changes placeholder
- Master behavioral changes placeholder
- Open items / flags placeholder
- In-flight (not yet PR'd) placeholder
- Coordination requests placeholder
- Signoff

### Step 2: Fill qualitative sections

The captain edits the file in place. Each placeholder section has an HTML-comment guidance block telling the captain what belongs there.

Focus areas:
- **TL;DR** — one paragraph executive summary of what shipped this window
- **Cross-repo / shared-package changes** — new or changed shared paths (packages/, tools/, config/) that other captains' agents consume downstream
- **Master behavioral changes** — things downstream branches pick up on next merge (process conventions, receipt patterns, infrastructure)
- **Open items / flags** — filed framework flags + known issues + workarounds
- **In-flight** — what's accumulating in captain's branches so others don't duplicate
- **Coordination requests** — questions / asks for other captains

### Step 3: Commit

Commit via `/coord-commit` (release notes are a pure coord artifact — no QG gate). Or `/git-safe-commit --no-work-item` directly.

### Step 4: Optional dispatch

If the note is narrowly addressed (`--to <addr>`), dispatch a pointer to the addressee so their monitor flags it:

```bash
./agency/tools/dispatch create --to <addr> --type coord --subject "Release notes published: <vStart>-<vEnd>" --body "<file path>"
```

For broadcast audiences, skip — the file on master is discoverable.

## Failure modes

- **No releases exist**: tool errors on `--end-version` auto-detection. Pass `--end-version` explicitly.
- **No prior release-notes file**: `--start-version` auto-detection falls back to `v0.0`. Captain should pass `--start-version` explicitly to anchor the window.
- **`gh` not installed / not authenticated**: tool dies. Install + `gh auth login` first.
- **`gh pr list` returns empty**: the window's PRs may all be closed (not merged) or the date-bound filter may be off. Check `--start-date` / `--end-date`.

## What this does NOT do

- **Does not commit.** Tool writes a file; captain commits via `/coord-commit`.
- **Does not push.** Release notes typically land as coord artifacts on master, not via PR.
- **Does not dispatch.** Optional Step 4 is captain's call.
- **Does not fill qualitative sections.** Tool only handles the mechanical parts. Synthesis is the captain's job.
- **Does not enforce filename convention.** Default convention is `release-notes-{YYYYMMDD}-{captain}-{vStart}-{vEnd}.md`; `--output` overrides.

## Captain-only — three-layer defense

1. `paths: []` — no file-path auto-activation.
2. Name contains `captain-` — scope visible in skill listing.
3. Tool runs as the invoking agent regardless, but the skill's audience context + auto-captain-detection via `agent-identity` means non-captain use is semantically awkward (output would carry the wrong captain name). Non-captain use isn't structurally blocked — the convention is softly enforced.

## Status

`active` (v1.0.0, shipped 2026-04-23 as an upstream from monofolk v3.3-v3.31 release-notes convention-capture).

## Related

- `/coord-commit` — how captain commits the filled release notes
- `/git-safe-commit` — underlying commit tool
- `/dispatch` — optional Step 4 addressee pointer
- `agency/tools/agency-captain-release-notes` — the tool this skill wraps
- `REFERENCE-AGENT-ADDRESSING.md` — addressee format for `--to`
- the-agency adopter issue tracking upstream integration — TBD

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
