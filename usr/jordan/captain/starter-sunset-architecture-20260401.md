# Starter Sunset — Architecture & Design

**Date:** 2026-04-01
**Status:** Complete
**Author:** captain
**PVR:** `starter-sunset-pvr-20260401.md`

## 1. System Overview

Replace the dual-distribution model (the-agency-starter repo + agency-init tool) with a single `agency` CLI that handles init, update, verify, identity, and feedback. Sunset the starter repo, evolve starter packs into skills, and add handoff type support for bootstrap/update flows.

```
Before:  agency-init + agency-update + agency-verify + agency-whoami + agency-feedback
         + the-agency-starter repo + starter-release tool + 5 sync tools + 2 workflows + 13 tests

After:   agency init|update|verify|whoami|feedback
         (one script, subcommand dispatch, no starter repo)
```

## 2. Architecture

### 2.1 The `agency` CLI

Single bash script at `agency/tools/agency`. Subcommand dispatch pattern (like `git init`, `rails new`).

```bash
#!/usr/bin/env bash
# agency — The Agency CLI
# Usage: agency <command> [options]

set -euo pipefail
AGENCY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$AGENCY_DIR/tools/lib/_log-helper" 2>/dev/null || true

# Capture subcommand args into array for sourced files to read
shift_and_capture() { shift; AGENCY_ARGS=("$@"); }

case "${1:-}" in
  init)     shift; AGENCY_ARGS=("$@"); source "$AGENCY_DIR/tools/lib/_agency-init" ;;
  update)   shift; AGENCY_ARGS=("$@"); source "$AGENCY_DIR/tools/lib/_agency-update" ;;
  verify)   shift; AGENCY_ARGS=("$@"); source "$AGENCY_DIR/tools/lib/_agency-verify" ;;
  whoami)   shift; AGENCY_ARGS=("$@"); source "$AGENCY_DIR/tools/lib/_agency-whoami" ;;
  feedback) shift; AGENCY_ARGS=("$@"); source "$AGENCY_DIR/tools/lib/_agency-feedback" ;;
  version)  _agency_version ;;
  help|"")  _agency_help ;;
  *)        echo "Unknown command: $1" >&2; _agency_help; exit 1 ;;
esac
```

**Key decisions:**

- **Subcommand logic lives in `agency/tools/lib/_agency-*` files.** The main script is a thin dispatcher. Each subcommand file is sourced (not exec'd) so it shares the parent's environment (AGENCY_DIR, log helper, etc.).
- **Arguments via `AGENCY_ARGS` array.** Unlike existing lib files (`_log-helper`, `_path-resolve`) which set up environment by side effect, `_agency-*` files receive arguments via the `AGENCY_ARGS` bash array — not via `source script "$@"`, which is fragile across Bash versions. Subcommand files read `"${AGENCY_ARGS[@]}"` for their positional parameters.
- **`set -euo pipefail` is inherited.** All sourced subcommand files execute under strict mode. Every `_agency-*` file must be written with this awareness — use `${VAR:-}` for optional variables, and handle expected non-zero exits explicitly.
- **`${BASH_SOURCE[0]}` for path resolution.** Not `$0`, which breaks when invoked via symlink.
- **Naming convention:** Underscore prefix (`_agency-init`) marks these as internal — not directly invocable tools. Same pattern as `_log-helper`, `_path-resolve`. But unlike those (which export environment), `_agency-*` files execute a complete action. This is an intentional extension of the pattern.
- **Telemetry:** Each `_agency-*` subcommand file uses `log_start`/`log_end` for its own telemetry entry (e.g., `log_start "agency-init" "${AGENCY_ARGS[@]}"`).
- **Clean break.** Delete old `agency-*` tools immediately. No thin wrappers. Two projects, we control both.

### 2.2 Subcommand Design

#### `agency init [--principal name] [--project name] [--timezone tz]`

Absorbs current `agency-init` logic with these changes:

1. **Precondition checks** (new):
   ```
   .git/ exists?            → if not: "Run git init first" and exit
   .claude/ exists?         → if not: "Run claude init first" (creates .claude/ and settings.json)
   On main/master branch?   → if not: "Switch to main/master before running agency init" and exit
   Already initialized?     → if agency/config/agency.yaml exists: "Already initialized" and exit
   ```
   The initialization check uses `agency.yaml` (not `handoff.md`) because it's a framework file created by init that users don't normally delete. The branch check ensures the bootstrap handoff lands at `usr/{principal}/captain/handoff.md` where `session-handoff.sh` will find it (the hook maps main/master → captain).

2. **Principal prompt** (existing, improved):
   - `--principal name` flag or interactive prompt
   - Validate: lowercase, alphanumeric + hyphens, no spaces
   - Map to system username in agency.yaml principals section

3. **Framework copy** (existing — current agency-init logic):
   - Agents, hooks, tools, docs, hookify, templates, skills, commands
   - CLAUDE.md from template with @import
   - .claude/settings.json via settings-merge (array union, not overwrite)
   - agency.yaml with principal config

4. **Bootstrap handoff** (new):
   ```
   usr/{principal}/captain/handoff.md
   ```
   Written with `type: agency-bootstrap` frontmatter. Content designed to trigger onboarding behavior when the agent reads it on first session start. See Section 2.4.

5. **Initial commit** (existing):
   - `git add` framework files
   - Commit: "agency init: initialize Agency 2.0 framework"

#### `agency update`

New implementation replacing the deprecated shim.

**Flow:**
1. **Detect source** — find the agency framework source. Options in order:
   - `$AGENCY_SOURCE` env var (explicit path)
   - Sibling directory: `../the-agency/` (common dev layout)
   - Error if neither found
2. **Sync framework files** — rsync from source, respecting protected paths from registry.json:
   - Copy: agents/, hooks/, tools/, docs/, hookify/, templates/, skills/, commands/
   - Skip: usr/ (principal sandboxes), workstreams/ (project-specific), config/agency.yaml (project config)
   - Merge: .claude/settings.json via settings-merge (array union)
3. **Update manifest** — bump version, update file hashes
4. **Write update handoff** — uses the handoff tool (archive-then-write pattern):
   ```bash
   # Archive existing handoff to history/
   bash agency/tools/handoff archive
   # Write new handoff with update type
   bash agency/tools/handoff write --type agency-update --trigger agency-update
   ```
   The handoff tool archives the existing session handoff to `history/`, then the agent writes the new handoff with update content:
   ```markdown
   ---
   type: agency-update
   date: 2026-04-01 14:30
   from_commit: abc123
   to_commit: def456
   ---
   ## Agency Update
   Updated framework from abc123 to def456.
   ### Changes
   - 3 skills added: foo, bar, baz
   - 2 tools updated: git-safe-commit, handoff
   - 1 hook added: new-hook.sh
   ### Previous session state
   [Summary of what the previous handoff contained — key context the agent needs to continue work]
   ```
   The update handoff includes a summary of the previous session state so the agent has both contexts. The full previous handoff is preserved in `history/` if the agent needs detail.

**Design decision: source detection, not download.** `agency update` works from a local clone of the-agency. No package registry, no HTTP fetch, no version resolution. You `git pull` the-agency repo, then run `agency update` in your project. Simple. The source repo IS the package registry. This is a developer-only workflow for now — a future distribution model (brew, tarball, etc.) may be needed for broader adoption.

#### `agency verify [--verbose]`

Absorbs current `agency-verify` logic. Checks:
- agency.yaml exists and readable
- Required directories exist (claude/config, claude/agents, claude/docs, claude/hooks, .claude/skills)
- Provider tools exist and executable
- Settings.json valid JSON
- Skill count matches expectations
- No orphaned references (tools referenced by skills that don't exist)

#### `agency whoami`

Absorbs current `agency-whoami`. Returns principal name from agency.yaml mapping.

#### `agency feedback "title" "description"`

Absorbs current `agency-feedback`. Creates GitHub issue or local fallback. Update target repo from `the-agency-starter` to `the-agency`.

### 2.3 Handoff Type System

Extend the handoff tool and skill to support typed handoffs via YAML frontmatter.

**Types:**

| Type | Written by | Read by | Triggers |
|------|-----------|---------|----------|
| `session` | Agent (SessionEnd, PreCompact, boundary commands) | session-handoff.sh hook | Normal session restore |
| `agency-bootstrap` | `agency init` | session-handoff.sh hook | Onboarding behavior |
| `agency-update` | `agency update` | session-handoff.sh hook | Update verification |

**Handoff format with type:**

```markdown
---
type: session
date: 2026-04-01 14:30
branch: main
trigger: SessionEnd
---

## Current State
...
```

**Strict on write, forgiving on read:**
- Write: handoff tool always includes `type` in frontmatter
- Read: missing type = `session` (default). The session-handoff.sh hook and any agent reading a handoff treats missing type as session. This means old handoffs (pre-type-support) work without migration.

**Changes to handoff tool (`agency/tools/handoff`):**

1. `handoff write` — add `--type <type>` flag. Default: `session`. The tool writes YAML frontmatter with the type.
2. `handoff read` — no change (it already outputs raw content; consumers parse the frontmatter).
3. `handoff archive` — no change (archives the file as-is, type preserved).

**Changes to session-handoff.sh hook:**

Currently injects handoff content as systemMessage on SessionStart. Add type awareness:

```bash
# Parse type from frontmatter (default: session)
type=$(sed -n '/^---$/,/^---$/{ /^type:/{ s/^type: *//; p; } }' "$handoff_path")
type="${type:-session}"

case "$type" in
  agency-bootstrap)
    # Inject with onboarding context
    prefix="This is a fresh Agency installation. The bootstrap handoff below was written by agency init. Help the user get oriented — verify the install, walk through first steps. The user can break out at any time."
    ;;
  agency-update)
    # Inject with update context
    prefix="The Agency framework was just updated. The handoff below contains both the update summary and the previous session state. Review what changed, verify nothing broke, then continue normal work."
    ;;
  session|*)
    # Normal restore (current behavior)
    prefix=""
    ;;
esac
```

The `sed` frontmatter parser is simple and may fail on edge cases (BOM, Windows line endings, `---` horizontal rules in body). The `type="${type:-session}"` default handles all parse failures gracefully — forgiving on read. If parsing fails, you get a normal session restore, which is always safe.

The hook prepends a short system context line based on type, then includes the full handoff content. The agent reads the type context and naturally adjusts behavior — no separate onboarding skill needed for the trigger mechanism. The handoff content itself does the work.

### 2.4 Bootstrap Handoff Content

What `agency init` writes to `usr/{principal}/captain/handoff.md`. Counts and version are computed dynamically at init time (not hardcoded in a template):

```markdown
---
type: agency-bootstrap
date: 2026-04-01 14:30
principal: jordan
---

## Welcome to The Agency

This project was just initialized with The Agency framework (v2.0.0).

### What's installed
- {skill_count} skills, {command_count} commands, {agent_count} agent classes, {hook_count} hooks
- Quality gate protocol, code review lifecycle, development methodology
- Principal sandbox at usr/{principal}/captain/

### First steps
1. Verify the installation: `agency verify`
2. Explore available skills: type `/` to see skill list
3. Start a discussion about your project: `/discuss`
4. When ready to build: `/define` to create a PVR

### Your environment
- Principal: {principal}
- Project: {project_name}
- Config: agency/config/agency.yaml

### How to get help
- `/agency-help` — quick reference
- `/agency-welcome` — guided tour
- `/agency-tutorial` — interactive walkthrough
- `agency/README-THEAGENCY.md` — full documentation
```

The `{...}` placeholders are computed by `_agency-init` at runtime (e.g., `skill_count=$(find .claude/skills -mindepth 1 -maxdepth 1 -type d | wc -l)`). This avoids drift between the template and reality.

This content IS the onboarding. The session-handoff.sh hook injects it with the `agency-bootstrap` type prefix, and the agent naturally provides an onboarding experience. When the user does their first real work and the handoff rotates to history, the bootstrap is preserved as `history/handoff-{timestamp}.md`.

### 2.5 Starter Repo Sunset

**What gets removed:**

| Artifact | Location | Action |
|----------|----------|--------|
| Starter repo contents | `archive-the-agency-starter/` | Already archived, commit then delete after verification |
| Starter test fixture | `test/the-agency-starter/` | Delete (embedded git repo) |
| Starter tools | `agency/tools/starter-*` | Delete: starter-test, starter-verify, starter-compare, starter-cleanup, starter-update, starter-release |
| Starter docs | `claude/docs/STARTER-PACK-INTEGRATION.md`, `STARTER-RELEASE-PROCESS.md` | Delete |
| Repo relationship doc | `claude/docs/REPO-RELATIONSHIP.md` | Delete |
| Starter workflows | `.github/workflows/starter-release.yml` | Already deleted |
| | `.github/workflows/starter-verify.yml` | Rename to `verify.yml` (done — now framework-focused) |
| Starter BATS tests | `tests/tools/starter-release.bats` | Delete |
| registry.json fields | `starter_version`, starter component | Remove |
| manifest.json fields | `project.starter_version` | Remove |
| agency-feedback target | `jordandm/the-agency-starter` | Update to `the-agency` |

**What stays:**

| Artifact | Location | Reason |
|----------|----------|--------|
| `test/test-agency-project/` | Test fixture | Validates agency-init output |
| `claude/starter-packs/` | Platform knowledge | Evolves into skill content (DevEx work) |
| Historical references | Dispatches, transcripts | Records of what was |

**GitHub the-agency-starter repo:**
- Update README to redirect: "This repo is archived. See [the-agency](link) for the current framework."
- Archive via GitHub settings (read-only)

### 2.6 Starter Packs Evolution

Starter packs stay in `claude/starter-packs/` as **platform knowledge** — reference material that feeds the generalized `/environment-setup` skill. They are NOT deleted as part of this work.

The evolution path (handled by DevEx service composition work, not this plan):
1. Current static docs (README, SETUP, VERIFY, etc.) become structured knowledge
2. `/environment-setup` skill reads relevant pack knowledge based on detected project type
3. Skill follows assess → do → guide → verify pattern
4. Provider setup portions (credentials, tokens) move to `/provider-setup` skills

This A&D acknowledges the path but does NOT design the skill — that's the DevEx agent's domain.

### 2.7 Tool Migration Path

```
Current                    → Transition                → Final
─────────────────────────────────────────────────────────────────
agency/tools/agency-init   → thin wrapper calling       → deleted
                              agency init (deprecation
                              warning)
agency/tools/agency-update → already deprecated shim    → deleted
agency/tools/agency-verify → thin wrapper               → deleted
agency/tools/agency-whoami → thin wrapper               → deleted
agency/tools/agency-feedback → thin wrapper             → deleted
agency/tools/agency        → NEW: main CLI script       → permanent
agency/tools/lib/_agency-* → NEW: subcommand logic      → permanent
```

**Clean break decision:** Given two projects in the installed base and we control both — skip the thin-wrapper transition. Delete old tools, ship `agency`. Update settings.json permissions to reference `agency` instead of individual `agency-*` tools.

**Permissions update in settings.json:**

```json
// Before (5 entries):
"Bash(./agency/tools/agency-init *)",
"Bash(./agency/tools/agency-update *)",
"Bash(./agency/tools/agency-verify *)",
"Bash(./agency/tools/agency-whoami *)",
"Bash(./agency/tools/agency-feedback *)",

// After (2 entries — no-arg and with-arg):
"Bash(./agency/tools/agency)",
"Bash(./agency/tools/agency *)",
```

Two entries: `agency` (no args, for help/version) and `agency *` (with subcommand). Claude Code matches the glob against the full command string — `agency *` matches `agency init --principal foo` but not bare `agency`.

### 2.8 Version Tracking

No semver, no version pinning, no rollback. But we track what's installed for diagnostics and update diffs.

**agency.yaml gets a `framework` section:**

```yaml
framework:
  version: "2.0.0"         # human-readable, bumped manually in the-agency repo
  installed_at: "2026-04-01T14:30:00+08:00"
  updated_at: "2026-04-01T14:30:00+08:00"
  source_commit: "abc123"  # git rev-parse HEAD of the-agency at install/update time
```

`agency init` writes it. `agency update` updates it. `agency verify` reads it. `agency version` reads `framework.version` and `framework.source_commit` for display. The source commit uniquely identifies the exact framework state — the version string is for humans. Note: if the-agency has uncommitted changes when `agency init`/`update` runs, the commit hash won't represent the actual copied state. This is inherent to the "source repo as registry" model and acceptable at current scale.

**manifest.json simplification:**
- Remove `starter_version`
- Keep file hashes for drift detection (useful for `agency verify` to warn about modified framework files)
- The `source_commit` + `version` in agency.yaml replaces version tracking

**registry.json simplification:**
- Lift `protected_paths` to a top-level array (currently nested per-component, requiring aggregation). The update flow needs a single flat list of paths to exclude from rsync.
- Remove `starter_version`, `install_hooks`
- Keep component list for reference

### 2.9 File Layout (Final State)

```
agency/tools/
  agency                    # CLI entry point (new)
  lib/
    _agency-init            # init subcommand logic (extracted from agency-init)
    _agency-update          # update subcommand logic (new)
    _agency-verify          # verify subcommand logic (extracted from agency-verify)
    _agency-whoami          # whoami subcommand logic (extracted from agency-whoami)
    _agency-feedback        # feedback subcommand logic (extracted from agency-feedback)
    _log-helper             # existing
    _path-resolve           # existing
    _provider-resolve       # existing
  handoff                   # updated: --type flag support
  git-safe-commit                # existing
  settings-merge            # existing
  ...                       # other tools unchanged
```

## 3. Design Decisions

### DD-1: Single script, sourced subcommands

The `agency` CLI is one bash script that sources subcommand files from `lib/`. Not a dispatcher that exec's separate scripts. This means:
- Shared environment (AGENCY_DIR, log helper, common functions)
- Single permission entry in settings.json
- Subcommand files can share helper functions defined in the main script
- Testable: each `_agency-*` file can be sourced in tests with mocked environment

### DD-2: No transition wrappers — clean break

Delete old `agency-*` tools immediately. Don't maintain thin wrappers. Two projects, we control both, update them simultaneously.

### DD-3: Source detection over download

`agency update` finds the-agency source locally, not via HTTP. The source repo is the package registry. Simple, offline-capable, no version resolution complexity.

### DD-4: Handoff type via frontmatter, not filename

Types go in YAML frontmatter, not encoded in filenames. The handoff tool always writes the same path (`handoff.md`); the type field changes. This preserves the existing path resolution and archival logic.

### DD-5: Bootstrap content IS onboarding

No separate onboarding skill trigger or marker file. The bootstrap handoff content, combined with the `agency-bootstrap` type prefix from session-handoff.sh, naturally triggers onboarding behavior. The agent reads "this is a fresh install, here's what's available" and responds accordingly.

### DD-6: Update archives then writes new handoff

`agency update` uses the handoff tool's archive-then-write pattern — the same pattern every other handoff write uses. The existing session handoff is archived to `history/`, then a new handoff of type `agency-update` is written. The update handoff includes a summary of the previous session state so the agent has continuity. The full previous handoff is preserved in `history/` if detail is needed. This follows "always use the handoff tool" — no raw file manipulation, no double-frontmatter corruption risk.

### DD-7: Source commit as version

`git rev-parse HEAD` of the-agency repo at install/update time is the version. No semver, no version file, no release tags needed. The commit hash uniquely identifies the framework state. Human-readable? Run `git log --oneline -1 <hash>` against the-agency repo.

### DD-8: registry.json simplification

registry.json currently tracks components with versions, dependencies, protected paths, and install hooks. With the starter model dead:
- Keep: component list, protected paths (lifted to top-level array — see Section 2.8)
- Remove: starter_version, install_hooks (agency init handles this directly)
- Simplify: dependency tracking not needed (agency init copies everything atomically)

### DD-9: Bash 3.2 compatibility

macOS ships Bash 3.2. Off-limits features: associative arrays (`declare -A`), `|&` pipe stderr, `;&` case fall-through, `coproc`, `mapfile`/`readarray`, `${var,,}` lowercase operator. Process substitution (`<()`) works on 3.2 but not when sourced in some contexts — avoid in `_agency-*` files. Use `tr '[:upper:]' '[:lower:]'` instead of `${var,,}`.

## 4. Constraints and Risks

**Constraints:**
- macOS first-class, Linux next, Windows/PowerShell KIV
- Bash 3.2+ (macOS default — no bash 4 features like associative arrays)
- No network dependency at runtime
- Claude Code 2.1.88+ minimum

**Risks:**

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking monofolk during transition | High | Update monofolk immediately after framework changes. We control both. |
| Handoff type breaks existing sessions | Medium | Forgiving on read: missing type = session. No migration needed. |
| Settings.json permission change breaks in-flight sessions | Low | User restarts Claude session to pick up new settings. |
| `agency update` source detection fails | Medium | Clear error message with instructions. `$AGENCY_SOURCE` env var as explicit override. |

## 5. Open Questions

1. **`test/the-agency-starter/` removal** — This is an embedded git repo (submodule or nested .git). What's the cleanest way to remove it? `git rm` if submodule, `rm -rf` if just a nested repo with .git/ in .gitignore.
2. **Starter packs timeline** — When does `/environment-setup` actually get built? The DevEx service composition A&D is in review. This A&D defers to that work but doesn't set a deadline.

---

## Appendix: Review Findings and Resolutions

Three-agent review (PVR alignment, technical soundness, existing patterns fit). All findings resolved in revision.

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | M | Idempotency check fragile (`handoff.md` vs `agency.yaml`) | Fixed: check `agency.yaml` existence (Section 2.2) |
| 2 | M | "Onboarding skill" PVR terminology vs A&D "no skill" | Fixed: PVR success criteria updated to match A&D design |
| 3 | M | `source` with args is novel pattern for lib files | Fixed: `AGENCY_ARGS` array, documented in DD-1 (Section 2.1) |
| 4 | M | Prepend-to-handoff corrupts YAML frontmatter | Fixed: archive-then-write via handoff tool (DD-6, Section 2.2) |
| 5 | M | Prepend bypasses handoff tool | Resolved by #4 |
| 6 | M | Permission glob `agency *` doesn't match no-arg case | Fixed: two entries — `agency` and `agency *` (Section 2.7) |
| 7 | M | Source detection dev-only, fragile for future users | Fixed: acknowledged as constraint in Section 2.2 |
| 8 | M | Bootstrap handoff invisible if init runs on non-main branch | Fixed: branch precondition check (Section 2.2) |
| 9 | M | Registry protected_paths aggregation unspecified | Fixed: lift to top-level array (Section 2.8) |
| 10 | m | `starter-verify.yml` not in sunset table | Fixed: added to Section 2.5 |
| 11 | m | Bootstrap content hardcodes version/counts | Fixed: computed at init time (Section 2.4) |
| 12 | m | Missing `_log-helper` integration in subcommands | Fixed: documented in DD-1 (Section 2.1) |
| 13 | m | `agency.yaml` framework section vs `agency version` disconnect | Fixed: added `version` key (Section 2.8) |
| 14 | m | `sed` frontmatter parser brittle | Fixed: noted forgiving-read handles failures (Section 2.3) |
