# Agency Update v2 + Addressing Tooling — Architecture & Design

**Date:** 2026-04-02
**Status:** Draft (MAR findings incorporated 2026-04-02)
**Author:** the-agency/jordan/captain
**PVR:** `agency-update-pvr-20260402.md`

## 1. System Overview

Two bodies of work converge: (1) making `agency update` smarter with tier-based file management and manifest checksums, and (2) building the addressing standard tooling that agency-update, dispatches, and handoffs all need. One A&D because they share infrastructure.

```
Before:  agency-update does blind rsync
         dispatch-create writes bare "jordan/captain"
         handoff has no agent field
         _path-resolve can't parse nested principals

After:   agency-update uses manifest checksums + tier strategy
         dispatch-create writes "the-agency/jordan/captain" (fully qualified)
         handoff carries agent address
         _address-parse is the canonical parsing library
         agency-init scaffolds project directories + works before claude init
```

## 2. Architecture

### 2.1 Component Map

```
                    ┌──────────────────────┐
                    │    agency.yaml        │
                    │  (nested principals,  │
                    │   remotes, repo)      │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │   _address-parse     │  ← NEW: canonical library
                    │  parse, resolve,     │
                    │  format, validate    │
                    └──┬──────┬────────┬───┘
                       │      │        │
              ┌────────▼┐ ┌──▼─────┐ ┌▼──────────┐
              │dispatch- │ │handoff │ │_agency-   │
              │create    │ │        │ │update     │
              │(rewrite) │ │(+agent)│ │(v2)       │
              └──────────┘ └────────┘ └───────────┘
                                           │
                    ┌──────────────────────┤
                    │                      │
              ┌─────▼──────┐  ┌───────────▼──────────┐
              │ manifest   │  │ settings-merge        │
              │ (checksums,│  │ (section-level:       │
              │  tiers)    │  │  hooks=fw, perms=user)│
              └────────────┘  └──────────────────────┘
```

### 2.2 `_address-parse` Library

**Location:** `claude/tools/lib/_address-parse`

The canonical address parsing library. All tools source this instead of reimplementing. Sourced like `_log-helper` and `_path-resolve` — sets up functions, no side effects.

**Functions:**

```bash
# Parse address into components. Sets ADDR_ORG, ADDR_REPO, ADDR_PRINCIPAL, ADDR_AGENT.
# Input: any form (bare, principal-scoped, fully qualified, org-qualified)
# Segment count: 1=bare, 2=principal/agent, 3=repo/principal/agent, 4=org/repo/principal/agent
address_parse <addr>

# Resolve short forms to fully qualified using local context.
# Bare "captain" → "the-agency/jordan/captain"
# Reads repo from git remote -v, principal from agency.yaml.
# Sets ADDR_REPO, ADDR_PRINCIPAL, ADDR_AGENT (all resolved).
address_resolve <addr>

# Produce fully qualified string: "repo/principal/agent"
address_format <repo> <principal> <agent>

# Validate a single component. Rejects: /, .., null bytes, reserved names.
# --level org: [A-Za-z0-9-]+ (case-preserved)
# --level repo|principal|agent: [a-z0-9][a-z0-9_-]* (lowercase, max 32 chars)
# Reserved names (principal/agent level): _, system, shared, all, default
address_validate_component <name> [--level org|repo|principal|agent]
```

**Repo detection:** `_address_detect_repo()` — parse `git remote -v` for origin URL, extract org and repo name. Handles GitHub (`github.com:org/repo.git`, `github.com/org/repo`), GitLab (nested groups → leaf name only). Override via `repo:` section in agency.yaml.

**Principal resolution:** `_address_detect_principal()` — find `$USER` key in agency.yaml `principals:` section, return its `name` field. Falls back to `default` key. Handles both flat (`jdm: jordan`) and nested (`jdm: { name: jordan, ... }`) formats for backward compatibility.

**Org name detection:** For the 3-segment ambiguity warning ("first segment matches known org"), derive known org names from: (1) `remotes:` section in agency.yaml URLs, (2) `git remote -v` URLs. No separate `orgs:` list needed.

**Error handling:**
- Unknown repo: hard fail with `"Cannot detect repo from git remote. Set repo.name in agency.yaml."`
- Unknown principal: hard fail with `"No principals entry for $USER in agency.yaml. Run agency init."`
- Unknown agent: warn only (agent may not be registered yet)
- Invalid component: hard fail with specific rejection reason

### 2.3 `dispatch-create` Rewrite

**Location:** `claude/tools/dispatch-create` (currently 76 lines → ~120 lines)

**Current:** Writes bare `From: jordan/captain`, no structured frontmatter.

**New frontmatter:**
```yaml
---
status: created
created: 2026-04-02T15:45
created_by: the-agency/jordan/captain    # fully qualified, auto-computed
to: monofolk/jordan/captain              # validated address
priority: normal
subject: "descriptive subject line"
in_reply_to: dispatch-filename.md        # filename only, for replies
read_by: null
read_at: null
resolved_at: null
---
```

**Changes:**
- `created_by:` auto-computed via `address_resolve` + `address_format`. Not user-supplied. Sources `_address-parse`.
- `--to <address>` flag — required. Validated via `address_validate_component` per segment.
- `--subject <text>` flag — required.
- `--reply-to <filename>` flag — optional. Sets `in_reply_to:`.
- `--priority <normal|high|low>` flag — optional, default `normal`.
- Agent name detection: default `captain`, but check `$CLAUDE_AGENT_NAME` env var if available (future: Claude Code may expose this).
- File naming: `dispatch-{slug}-YYYYMMDD-HHMM.md` (slug from subject, auto-timestamped).

**No `--from` flag.** Sender identity is computed from trusted local sources, not self-asserted. This is a trust model decision.

### 2.4 `handoff` Tool Update

**Location:** `claude/tools/handoff` (currently 282 lines → ~300 lines)

**Add `agent` field to frontmatter:**
```yaml
---
type: session
date: 2026-04-02 09:05
agent: the-agency/jordan/captain    # NEW: fully qualified
branch: main
trigger: session-end
---
```

**Changes:**
- Source `_address-parse` library.
- Compute `agent:` via `address_resolve` on session start. Agent name derived from branch-to-agent mapping (existing logic: main/master → captain, worktree branches → branch slug).
- Write `agent:` to frontmatter on every `handoff write`.
- `handoff read` — no change (raw output, consumers parse).
- Backward compatible: missing `agent` field still parses. Existing handoffs remain valid.

### 2.5 `_path-resolve` Updates

**Location:** `claude/tools/lib/_path-resolve` (currently 123 lines)

**Add `_validate_name()`:**
```bash
_validate_name() {
    local name="$1"
    local level="${2:-principal}"  # principal|agent|repo

    # Reject empty
    [[ -z "$name" ]] && { echo "Name cannot be empty" >&2; return 1; }
    # Reject path traversal
    [[ "$name" == *".."* || "$name" == *"/"* ]] && { echo "Name contains path traversal" >&2; return 1; }
    # Reject null bytes
    [[ "$name" == *$'\0'* ]] && { echo "Name contains null byte" >&2; return 1; }
    # Reject too long
    [[ ${#name} -gt 32 ]] && { echo "Name exceeds 32 characters" >&2; return 1; }
    # Pattern check
    [[ "$name" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { echo "Name must match [a-z0-9][a-z0-9_-]*" >&2; return 1; }
    # Reject reserved
    case "$name" in
        _|system|shared|all|default) echo "Name '$name' is reserved" >&2; return 1 ;;
    esac
    return 0
}
```

Applied in every function that constructs filesystem paths from names.

**Update `_pr_yaml_get` for nested principals:** The current parser handles flat `key: value` under a section. For the new nested `principals:` structure, add a nested-aware parser:

```bash
# For principals section: key is system username, value is nested object
# Returns the 'name' field from the nested object
_pr_yaml_get_principal_name() {
    local username="$1"
    local yaml_file="$2"
    # Try nested format first: "  username:\n    name: value"
    local name
    name=$(sed -n "/^  ${username}:/,/^  [a-z]/{ /^    name:/{ s/^    name: *//; s/ *$//; p; } }" "$yaml_file")
    if [[ -n "$name" ]]; then
        echo "$name"
        return 0
    fi
    # Fall back to flat format: "  username: value"
    _pr_yaml_get "principals" "$username" "$yaml_file"
}
```

### 2.6 `_agency-update` v2 Rewrite

**Location:** `claude/tools/lib/_agency-update` (currently 339 lines → ~600 lines)

**Replace rsync with manifest-driven file loop.** This is the core architectural change.

**Update flow:**

```
1. Pre-flight validation
   ├── Source exists and has claude/CLAUDE-THEAGENCY.md
   ├── Source has required directories
   ├── Target is initialized (has agency.yaml)
   └── Warn if uncommitted changes in claude/

2. Load or bootstrap manifest
   ├── If manifest exists with tiers → use it
   ├── If manifest exists without tiers → infer from path, enrich
   └── If no manifest → bootstrap (compute checksums, config tier = user-modified)

3. Build file delta
   For each file in source framework:
   ├── Compute source SHA-256
   ├── Compute target SHA-256 (if exists)
   ├── Look up manifest entry (hash, tier)
   └── Decide action:
       ├── framework tier → always copy
       ├── config tier + untouched → copy
       ├── config tier + modified → skip, log
       ├── new file → copy, add to manifest
       └── removed upstream → warn (or delete if --prune)

4. Apply file delta
   ├── Copy files (respecting decisions)
   ├── Handle settings.json via settings-merge (section-level)
   └── Handle agency.yaml via migration (detect-and-migrate)

5. Agency.yaml migration
   ├── Detect format (flat / root-level / nested)
   ├── Migrate to nested principals structure
   └── Add remotes, repo sections if missing

6. Update manifest
   ├── Write new checksums for all synced files
   ├── Set tier for new files
   └── Bump framework_version, updated_at

7. Post-update actions
   ├── Run sandbox-sync (activate new skills/hookify)
   ├── Write update handoff (type: agency-update, agent: fully qualified)
   └── Generate update report

8. Output summary
   ├── Files: +N added, ~N updated, -N removed, !N skipped (user-modified)
   ├── Migrations applied
   └── Next steps
```

**Checksum function (cross-platform):**
```bash
_compute_checksum() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    else
        echo "ERROR: No SHA-256 tool available" >&2
        return 1
    fi
}
```

**Manifest bootstrap conservatism:** When no prior manifest exists, treat config-tier files as user-modified (skip). Only framework-tier files are safe to overwrite without baseline. This prevents the first v2 update from clobbering customized hooks.

### 2.7 `settings-merge` Upgrade

**Location:** `claude/tools/settings-merge` (currently 73 lines → ~100 lines)

**Current:** Array union on `permissions.allow`, shallow merge for everything else.

**New:** Section-level merge strategy:

| Section | Strategy | Rationale |
|---------|----------|-----------|
| `hooks` | **Framework-managed** — replace from template | Hooks must stay in sync with framework. New hooks, updated commands. |
| `permissions.allow` | **User-managed** — array union (add new, keep existing) | Permissions accumulate per-session. Never wipe. |
| `enabledPlugins` | **User-managed** — preserve | User choice. |
| Everything else | **Shallow merge** — add missing keys, don't overwrite | Safe default. |

```bash
MERGED=$(jq -s '
  .[0] as $target | .[1] as $template |
  $target * {
    hooks: $template.hooks,
    permissions: {
      allow: (($target.permissions.allow // []) + ($template.permissions.allow // []) | unique)
    }
  }
' "$TARGET" "$TEMPLATE")
```

The key change: `hooks: $template.hooks` replaces instead of merging. This ensures new hooks from framework updates are picked up, and removed hooks are cleaned out.

### 2.8 `agency-init` Updates

**Location:** `claude/tools/lib/_agency-init` (currently 530 lines → ~560 lines)

**Changes:**

1. **Write per-file manifest.** After copying all framework files, compute SHA-256 for each and write to `claude/config/manifest.json` with `tier` field. This gives `agency update` v2 a baseline.

2. **Scaffold project directory.** Already fixed: creates `usr/{principal}/{project}/` with code-reviews, dispatches, transcripts, history. (Committed at `6a5a104`.)

3. **Accept unborn HEAD.** Already fixed: `git init` with no commits is valid. (Committed at `ea6fc0e`.)

4. **New agency.yaml structure.** Write nested principals format from the start:
   ```yaml
   principals:
     {$USER}:
       name: {principal}
       display_name: "{Principal}"
     default:
       name: unknown
   ```

5. **Document new flow.** Update help text and README-GETTINGSTARTED.md: `git init → agency init → claude`. No `claude init` required first.

### 2.9 Agency.yaml Schema Migration

Three formats in the wild, one target:

```
Format 1 (flat):           principals: { jdm: jordan }
Format 2 (root-level):     principal: jordan + principal_name: "..." + principal_github: "..."
Format 3 (nested/target):  principals: { jdm: { name: jordan, display_name: "..." } }
```

**Detection heuristics (idempotent):**

Detection is scoped to the `principals:` section only — a bare `name:` elsewhere in the file must not trigger nested detection. Extract the principals block first, then classify.

```bash
_detect_yaml_format() {
    local yaml="$1"
    # Check for root-level singular (no principals: section)
    if grep -q "^principal:" "$yaml" 2>/dev/null; then
        echo "root-level"
        return
    fi
    # Must have principals: section for flat or nested
    if ! grep -q "^principals:" "$yaml" 2>/dev/null; then
        echo "unknown"
        return
    fi
    # Extract principals block (from "principals:" to next top-level key)
    local block
    block=$(sed -n '/^principals:/,/^[a-z]/{/^principals:/d;/^[a-z]/d;p;}' "$yaml")
    # Check for nested (target format) — has "    name:" within principals block
    if echo "$block" | grep -q "^    name:"; then
        echo "nested"
    else
        echo "flat"
    fi
}
```

**Migration functions:**

- `_migrate_flat_to_nested()` — parse flat `key: value` pairs under `principals:`, restructure to nested with defaults. Handle `default:` entry specially: migrate `default: unknown` to `default: { name: unknown }` (preserves the fallback semantics without inventing display_name).
- `_migrate_rootlevel_to_nested()` — extract `principal`, `principal_name`, `principal_email`, `principal_github` from root, build nested structure under `principals:` keyed by `$USER`
- `_migrate_add_sections()` — add `remotes:` and `repo:` sections if missing (with comments)

**Safety:** Before any migration, create a backup: `cp agency.yaml agency.yaml.pre-migration`. On migration failure, restore from backup and hard-fail with the error. Remove backup on success.

Each migration is idempotent — running it on already-migrated YAML produces no changes.

## 3. Design Decisions

### DD-1: `_address-parse` as Phase 1

Build `_address-parse` first. All other tools depend on it. dispatch-create and handoff cannot write fully qualified addresses without it. Monofolk's F5 recommendation confirmed this priority.

### DD-2: File-by-file loop, not rsync

The three-tier strategy requires per-file decisions (check tier, compare checksum, decide action). rsync operates on directories and can't make per-file tier decisions. The replacement is a bash loop over the source manifest, calling `_compute_checksum` and comparing against the target manifest. Performance impact is negligible — file counts are in the hundreds, not thousands.

### DD-3: Settings.json hooks replacement

Hooks section in settings.json is framework-managed — `settings-merge` replaces it wholesale from the template. This is the monofolk F1 finding: hooks must stay in sync with the framework. Permissions are user-managed — array union, never wipe. This split resolves the settings.json tier problem without inventing a new tier.

### DD-4: Conservative manifest bootstrap

When `agency update` v2 encounters a target with no manifest (or v1 manifest without checksums), it treats config-tier files as user-modified (skip). Only framework-tier files are overwritten. This prevents the first v2 update from clobbering customized hooks. Monofolk F6 finding.

### DD-5: Init before claude init

`agency init` creates `.claude/` itself. The flow is `git init → agency init → claude`. Tested and confirmed working on presence-detect project. `claude init` is optional — Claude Code gracefully picks up existing `.claude/`. Docs need updating.

### DD-6: Non-interactive migration

Agency.yaml migration uses sensible defaults, not prompts. `display_name` defaults to titlecase of `name`. GitHub username left empty. The tool runs in Claude Code's Bash environment where interactive stdin is unavailable. Users refine post-migration.

### DD-7: Sender identity is computed, not self-asserted

`dispatch-create` has no `--from` flag. The `created_by:` field is computed from `_address-parse` (repo from git, principal from agency.yaml, agent from context). This is a trust model decision — dispatches are signed by their origin, not by what the sender claims to be.

### DD-8: Cross-repo commit protocol

Formalized per monofolk dispatch: communication artifacts (dispatches, handoffs, session state) push to main. Executable code (tools, skills, hooks, agents) requires PR. The bright-line test: "Does this change how an agent behaves? PR. Communication? Push to main." To be added to CLAUDE-THEAGENCY.md.

## 4. Test Strategy

### New: `tests/tools/address-parse.bats`

- Parse all 4 input forms (1, 2, 3, 4 segments)
- Resolve bare → fully qualified (mock git remote, mock agency.yaml)
- Reject: empty, slashes, `..`, null bytes, reserved names, too long, uppercase in non-org
- Org names preserve case
- Detect repo from git remote -v (GitHub SSH, GitHub HTTPS, GitLab)
- Detect principal from nested agency.yaml
- Detect principal from flat agency.yaml (backward compat)
- 3-segment ambiguity warning when first segment matches known org

### New: `tests/tools/dispatch-create.bats`

- Creates file at correct path with correct filename format
- `created_by:` is fully qualified
- `created_by:` is auto-computed (not user-supplied)
- `--to` is validated
- `--subject` is required
- `in_reply_to` is filename-only
- Frontmatter has all required fields

### Update: `tests/tools/agency-init.bats`

- Fresh repo (unborn HEAD) accepted
- Project directory scaffolded (`usr/{principal}/{project}/` with subdirs)
- Manifest written with per-file checksums and tiers
- Agency.yaml uses nested principals format
- New flow: works without prior `claude init`

### Update: `tests/tools/agency-update.bats` (new file, split from agency-init.bats)

- Clean update (no modifications): all framework files updated
- Update with user-modified hook: hook preserved, logged as skipped
- Manifest bootstrap: config-tier files treated as user-modified when no prior manifest
- Agency.yaml migration: flat → nested
- Agency.yaml migration: root-level → nested
- Agency.yaml migration: already nested (idempotent)
- Settings.json: hooks replaced, permissions preserved
- `--dry-run` shows preview without changes
- `--prune` removes files absent from source
- Sandbox-sync runs post-update
- Update report generated

### Update: `tests/tools/handoff-types.bats`

- `agent` field present in new handoffs
- `agent` field is fully qualified
- Missing `agent` field still parses (backward compat)

### Live testing

The principal has expressed intent to test `agency init` and `agency update` on real projects. The presence-detect project is the first live init test (completed). Agency update will be tested by running `agency update` on presence-detect after building v2.

## 5. Migration Path

1. Build `_address-parse` (no external dependencies — pure library)
2. Add `_validate_name()` to `_path-resolve`
3. Update `agency-init` — nested principals, manifest with checksums, project dir scaffolding
4. Update `dispatch-create` — fully qualified addresses, new frontmatter
5. Update `handoff` — agent field
6. Upgrade `settings-merge` — section-level strategy
7. Rewrite `_agency-update` — manifest-driven file loop, tier strategy, migrations
8. Update `session-handoff.sh` — compat check for agent field
9. Tests for all of the above
10. Update docs — init flow, cross-repo protocol, addressing standard references

Steps 1-2 are blocking. Steps 3-5 can parallelize. Steps 6-7 depend on 1-2. Step 8 is independent. Step 9 runs throughout. Step 10 at the end.

## 6. Risks

1. **YAML parsing in bash.** The nested principals structure pushes bash YAML parsing to its limits. `_pr_yaml_get` and the migration functions use sed/grep heuristics. Risk: edge cases in quoting, Unicode display names, multi-line values. Mitigation: comprehensive BATS tests with edge-case YAML files. If bash parsing proves fragile, consider a Python helper for YAML operations.

2. **Manifest file growth.** Every framework file gets a manifest entry. At ~145 files, the manifest is ~200 lines of JSON. Not a concern now, but worth monitoring if file count grows significantly.

3. **Settings.json hooks replacement.** Replacing hooks wholesale means user hook customizations are lost. Mitigation: hooks are framework-managed by design. Users who need custom hooks should add them via sandbox (local symlinks, not settings.json edits). Document this.

4. **Migration idempotency.** The detect-and-migrate approach requires each migration to be safe to run multiple times. Testing is the mitigation — every migration gets an idempotency test.

5. **Bootstrap handoff cost.** The presence-detect test showed $0.37 for bootstrap — the agent explored everything instead of using the handoff context. Not in scope for this A&D, but noted: the bootstrap handoff content and session-handoff hook prefix need to be more directive to prevent unnecessary exploration.

6. **`_address-parse` as SPOF.** Every address-aware tool sources this library. A bug in `_address-parse` breaks dispatch-create, handoff, and agency-update simultaneously. Mitigation: comprehensive BATS tests as Phase 1 gate. The library is pure functions with no side effects, so bugs are containable and testable.

7. **Bash 3.2 YAML parsing.** macOS ships bash 3.2 which lacks associative arrays. All YAML parsing uses sed/grep heuristics on the plain text file, not data structures. This works for our flat/nested structure but cannot handle arbitrary YAML (quoted strings with colons, multi-line values, anchors). Mitigation: agency.yaml is our format — we control what gets written. Tests cover the specific formats we emit. If complexity grows, add a Python YAML helper.

8. **Manifest corruption.** If manifest.json is corrupted (invalid JSON, partial write), `agency update` loses its baseline. Mitigation: validate manifest JSON before trusting it (`jq . manifest.json > /dev/null`). On parse failure, treat as "no manifest" (bootstrap mode with conservative defaults). Write manifest atomically: write to `.manifest.json.tmp`, then `mv` to `manifest.json`.
