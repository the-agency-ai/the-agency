---
name: agency-captain-release-notes
description: Captain-only. Generate a release-notes skeleton for the current captain to announce a window of PRs + releases to other captains/principals on the same repo. Auto-populates the mechanical parts (PR table, version window, frontmatter, filename); captain fills qualitative sections (TL;DR, shared changes, behavioral changes, flags, in-flight, coordination asks). Every PR is a release, and every window of releases deserves a note when multiple captains share a repo.
agency-skill-version: 2
when_to_use: Captain has landed a burst of PRs on the default branch and wants to broadcast what shipped to other captains/principals working the same repo. Typical cadence — once per session-burst, or daily. Also useful before session-end as a recap artifact.
argument-hint: "[--start-version vX.Y] [--end-version vX.Y] [--start-date ISO] [--end-date ISO] [--base <branch|all>] [--limit n] [--to <addr>] [--audience <string>] [--workstream <name>] [--captain <name|addr>] [--output <path>] [--dry-run] [--stdout]"
paths: []
required_reading:
  - agency/REFERENCE/REFERENCE-AGENT-ADDRESSING.md
  - agency/REFERENCE/REFERENCE-SAFE-TOOLS.md
---

# agency-captain-release-notes

Captain-only skill. Generates a release-notes skeleton addressed to other captains or principals on the same repo. Mechanical parts (PR table, version window, frontmatter, output path) are tool-generated; qualitative parts (narrative, shared changes, flags, in-flight) are captain-filled.

## Why this exists

When multiple captains (or captain + principal) work the same repo, "here's what I shipped since the last sync" is knowledge stored in `git log` + release tags + private handoffs. Cross-captain visibility requires manually walking `gh release list`, `gh pr list`, correlating by date, assembling a markdown file. Time-consuming, error-prone, drifts.

Captured 2026-04-23 when a captain wrote a release-notes file for cross-captain coord and it took ~15 minutes + a second round when the window expanded. Principal then asked: *"this should be a tool."* So it is.

The tool handles enumeration. The captain handles synthesis. Clean split.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

## Usage

```
/agency-captain-release-notes                                 # auto-detect everything
/agency-captain-release-notes --start-version v46.13          # explicit start
/agency-captain-release-notes --start-version v46.13 --end-version v46.33
/agency-captain-release-notes --to <repo>/<principal>/captain # narrow addressee
/agency-captain-release-notes --audience "any captain working on this repo"
/agency-captain-release-notes --base all                      # count every base branch
/agency-captain-release-notes --dry-run                       # preview without writing
/agency-captain-release-notes --stdout                        # print to stdout
```

### Arguments

- `--start-version <vX.Y>` — first release tag NOT already covered by a prior release-notes file. Auto-detected from the most recent prior file's `end_version` if omitted; falls back to `v0.0` + a 30-day date window when there is no prior file.
- `--end-version <vX.Y>` — most recent release to include. Auto-detected as the repo's latest release (selected on `isLatest`, not list order).
- `--start-date <ISO>` / `--end-date <ISO>` — alternative to version-based windowing (UTC timestamps). These win over the version-derived bounds.
- `--base <branch|all>` — base branch for PR enumeration. Default: the repo's default branch via `resolve-default-branch` (so `main` and `master` repos both work). `all` counts PRs merged into any base.
- `--limit <n>` — max PRs to scan (default 200). Release discovery uses its own larger limit, so narrowing this cannot break start-version date lookup.
- `--to <address>` — specific addressee. Default: broadcast (no specific `to:`, audience-only frontmatter).
- `--audience <string>` — human-readable audience description. Default: `"any captain or principal working on <project>"`.
- `--workstream <name>` — workstream directory name under `agency/workstreams/`. Default: the slugified `project.name` from `agency/config/agency.yaml` if that directory exists, else the repo name, else `agency`. (`project.name` is free text — the shipped default is literally `"My Project"` — so it is never used as a directory name unqualified.)
- `--captain <name|addr>` — captain identity for the filename and the frontmatter `from:`. Accepts `{principal}-{agent}` (split on the FIRST hyphen, so hyphenated agent slugs like `jordan-revive-release-notes` stay intact) or a full `{repo}/{principal}/{agent}` address. Default: resolved from `agency/tools/agent-identity`.
- `--output <path>` — explicit output file path. Mutually exclusive with `--stdout`. The tool refuses to write through a symlink.
- `--stdout` — print to stdout instead of writing.
- `--dry-run` — show what would be written.

## Preconditions

1. `gh` available — the tool prefers the framework wrapper `agency/tools/gh` (token injection + telemetry) and falls back to bare `gh` on PATH.
2. `jq` installed — used for all release/PR JSON shaping.
3. Captain may be on any branch — the tool queries `gh`, not local branch state.
4. Repo has at least one release (for `--end-version` auto-detection). Not required if `--end-version` is passed explicitly.

## Flow / Steps

### Step 1: Generate skeleton

```bash
./agency/tools/agency-captain-release-notes [...args]
```

Tool writes to `agency/workstreams/<workstream>/release-notes/release-notes-<YYYYMMDD>-<captain>-<vStart>-<vEnd>.md`.

Skeleton has:
- YAML frontmatter, in emitted order: `from`, `to` (only when `--to` is passed), `audience`, `date`, `window` (incl. `base_branch`), `prs_landed_count`, `generated_by`
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
./agency/tools/dispatch create --to <addr> --type dispatch --subject "Release notes published: <vStart>-<vEnd>" --body "<file path>"
```

`dispatch` is the general-purpose type; the valid set is defined by `VALID_TYPES` in `agency/tools/dispatch`. There is no `coord` type — passing one is a hard error.

For broadcast audiences, skip — the file on the default branch is discoverable.

## Failure modes

- **No releases exist**: tool errors on `--end-version` auto-detection. Pass `--end-version` explicitly.
- **No prior release-notes file**: `--start-version` falls back to `v0.0` and the date window opens 30 days back. Pass `--start-version` explicitly to anchor the window.
- **`gh` not installed / not authenticated**: tool dies with an install pointer. `jq` missing dies the same way rather than silently reporting 0 PRs.
- **Zero PRs in window**: the tool warns and emits a placeholder table row. Check `--base` (a repo whose PRs land on a non-default base needs `--base all`) and the date bounds.
- **Wrong workstream directory**: auto-resolution prefers a directory that already exists; if no candidate matches it warns and falls back to the slugified project name, which `mkdir -p` then creates. Pass `--workstream` explicitly to control it.
- **Inverted window**: if the resolved start is not before the resolved end, the tool refuses rather than emitting a document that claims a range it did not cover. Set `--start-date` / `--end-date` explicitly.

## What this does NOT do

- **Does not commit.** Tool writes a file; captain commits via `/coord-commit`.
- **Does not push.** Release notes typically land as coord artifacts, not via PR.
- **Does not dispatch.** Optional Step 4 is captain's call.
- **Does not fill qualitative sections.** Tool only handles the mechanical parts. Synthesis is the captain's job.
- **Does not enforce filename convention.** Default convention is `release-notes-{YYYYMMDD}-{captain}-{vStart}-{vEnd}.md`; `--output` overrides.

## Captain-only — three-layer defense

1. `paths: []` — no file-path auto-activation.
2. Name contains `captain-` — scope visible in skill listing.
3. Tool runs as the invoking agent regardless, but the skill's audience context + auto-captain-detection via `agent-identity` means non-captain use is semantically awkward (output would carry the wrong captain name). Non-captain use isn't structurally blocked — the convention is softly enforced.

## Status

`active` (v1.2.0). Shipped 2026-04-23 as an upstream from an adopter repo's v3.3-v3.31 release-notes convention-capture; revived and re-validated against v46.33 on 2026-08-12 (PR #426 lineage).

## Related

- `/coord-commit` — how captain commits the filled release notes
- `/git-safe-commit` — underlying commit tool
- `/dispatch` — optional Step 4 addressee pointer
- `agency/tools/agency-captain-release-notes` — the tool this skill wraps
- `agency/tools/resolve-default-branch` — supplies the default `--base`
- `REFERENCE-AGENT-ADDRESSING.md` — addressee format for `--to`

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
