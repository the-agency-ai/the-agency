# Agency Update v2 — Product Vision & Requirements

**Date:** 2026-04-02
**Status:** Approved — MAR round 1 (15 findings fixed) + monofolk review (7 findings fixed)
**Author:** the-agency/jordan/captain
**Predecessor:** `starter-sunset-pvr-20260401.md` (agency-update v1 — basic rsync + settings-merge)

## 1. Problem Statement

`agency update` exists and functions — it rsyncs framework files, merges settings, updates version metadata, and writes a handoff. But it has significant gaps that make it unsuitable for multi-principal repos and cross-repo workflows:

1. **No conflict detection.** If a user modified a framework file (customized a hook, edited an agent class), `agency update` silently overwrites it. The three-tier file strategy (framework/config/scaffold) was designed in the starter-sunset A&D but never implemented.

2. **Stale manifest.** File checksums are not recalculated during update. The manifest tracks files but can't distinguish "user modified this" from "framework changed this." Subsequent updates can't make smart decisions.

3. **No addressing integration.** The new Agent & Principal Addressing standard defines a richer `principals` structure in `agency.yaml` (display names, platform identity, address preferences). `agency update` doesn't know how to migrate existing flat `principals` entries to the new nested structure.

4. **No pre-flight validation.** No source integrity check, no dependency validation. A corrupt or incomplete source silently produces a broken installation.

5. **Manual verification.** User must run `agency verify` manually after update. The session-handoff hook doesn't react to `type: agency-update` handoffs to trigger verification.

6. **No update reporting.** No detailed change report, no artifact that records what changed and why. Historical tracking is poor.

**For whom:** Framework adopters running `agency update` on their projects, and framework maintainers evolving the-agency.

**Why now:** The addressing standard just landed in CLAUDE-THEAGENCY.md. Multi-principal support requires `agency.yaml` migration. The tier strategy must be implemented before anyone depends on customized framework files.

## 2. Target Users

- **Solo adopters** — run `agency update` on personal projects. Need conflict detection for customized hooks/agents.
- **Multi-principal teams** — need `agency.yaml` principal migration and per-principal addressing.
- **Framework maintainers** — need reliable update mechanics for the-agency itself.

## 3. Use Cases

### UC1: Clean Update (No Conflicts)

User has not modified any framework files. `agency update` syncs all framework files, merges settings, updates manifest with new checksums, writes update handoff. First session picks up update context via session-handoff hook.

### UC2: Update with User Modifications

User customized `agency/hooks/ref-injector.sh`. `agency update` detects the modification (manifest checksum mismatch), warns the user, and preserves their version. Reports what was skipped and why.

### UC3: Agency.yaml Migration

User's `agency.yaml` has flat `principals: { jdm: jordan }`. `agency update` detects the old format and migrates to nested structure with `name`, `display_name`, `platforms`. Uses sensible defaults for missing fields (titlecase name for display_name, empty for GitHub username). User fills in details post-migration.

### UC4: Pre-Flight Failure

Source repo is missing files or has an incomplete framework. `agency update` fails with actionable error before making any changes.

### UC5: Post-Update Session Context

After `agency update` writes a `type: agency-update` handoff, the first `claude` session reads it via session-handoff hook. The hook injects update context instructing the agent to run `agency verify`. This is best-effort — the hook provides context, the agent decides actions.

## 4. Functional Requirements

### 4.0 Prerequisites

**`agency init` must write per-file manifest checksums.** The current `_agency-init` does not generate a manifest in the target project. Without checksums from init, the first `agency update` has no baseline to compare against. This prerequisite must be completed before or alongside the update v2 work. A fallback: if `agency update` finds no manifest, it bootstraps one by computing checksums for all existing framework files (treating them all as untouched).

### 4.1 Three-Tier File Strategy

Implement the tier model from the starter-sunset A&D. **This replaces v1's unconditional rsync** — the current `_agency-update` rsyncs entire directories with `--delete`. The v2 approach is a manifest-driven file-by-file copy loop that checks tier and checksum before each file.

| Tier | On init | On update | Detection |
|------|---------|-----------|-----------|
| Framework | Copy from source | Always overwrite | File in source, checksum matches manifest = untouched |
| Config | Copy from source | Skip if user-modified; overwrite if untouched | Checksum differs from manifest = user-modified |
| Scaffold | Generate | Never overwrite (but may migrate schema — see 4.3) | File exists in target but not in source manifest |

**Tier assignment:** Stored in `agency/config/manifest.json` per file. Each file entry has `hash`, `tier`, and `version` fields. The existing `modified` field is dropped — modification is now computed on-the-fly by comparing the current file hash against the manifest hash.

```json
"agency/hooks/ref-injector.sh": {
  "hash": "abc123...",
  "tier": "config",
  "version": "2.0.0"
}
```

**Tier classification rules (per-file, with directory defaults):**
- `framework` (always overwrite) — agents/, docs/, hookify/, templates/, tools/lib/*, CLAUDE-THEAGENCY.md, README-THEAGENCY.md
- `config` (preserve if modified) — hooks/, tools/ (top-level executables). Individual files may be overridden to `framework` tier in the manifest if they should never be customized (e.g., `tools/lib/_log-helper`).
- `scaffold` (never overwrite, may migrate) — usr/, workstreams/, agency.yaml
- `settings.json` is a **special case** — not purely any tier. It requires section-level merge: hooks section is framework-managed (update with framework), permissions section is user-managed (preserve), plugins section is user-managed (preserve). Handled by `settings-merge`, not by the tier system directly.

**Manifest migration:** When `agency update` v2 encounters a v1 manifest (entries without `tier` field), it infers tier from the path-based classification rules above and writes the enriched manifest. This is a one-time inference on the first v2 update.

**Registry.json relationship:** `registry.json` defines `protected_paths` (always scaffold) and `components` (logical groupings). Tier classification is informed by but not derived from registry — the manifest is the single source of truth for per-file tier.

### 4.2 Manifest-Driven Updates

**Checksum algorithm:** SHA-256 via `shasum -a 256 "$file" | cut -d' ' -f1`. This works on both macOS and Linux. Do not use `sha256sum` alone — non-standard path on macOS.

On every `agency update`:

1. Read manifest checksums for all tracked files
2. Compute current SHA-256 checksums of target files
3. Compare:
   - **Target matches manifest** → file untouched since last update → safe to overwrite (framework tier) or overwrite (config tier, since untouched)
   - **Target differs from manifest** → user modified → framework tier: overwrite with warning; config tier: preserve user version, log skip; scaffold tier: never touch
   - **File in source but not in manifest** → new file → copy and add to manifest
   - **File in manifest but not in source** → file removed upstream → warn, don't delete. `agency update --prune` deletes these files. Default is warn-only for safety.
4. Update manifest with new checksums after sync

**Manifest bootstrap (no prior manifest):** When `agency update` runs against a target with no manifest (or a v1 manifest without checksums), it must be **conservative**: treat all config-tier files as user-modified (skip, don't overwrite). Only framework-tier files are safe to overwrite without baseline. This prevents the first v2 update from silently clobbering customized hooks. The bootstrap computes checksums for all existing files and writes the manifest — subsequent updates have a baseline.

### 4.3 Agency.yaml Migration

`agency.yaml` is scaffold tier (never overwritten) but subject to schema migration. Detect old format and migrate. Three known formats in the wild:

1. **Flat** (the-agency original): `principals: { jdm: jordan }`
2. **Root-level singular** (monofolk current): `principal: jordan` + `principal_name: "..."` + `principal_email: "..."` + `principal_github: "..."`
3. **Nested** (target): `principals: { jdm: { name: jordan, display_name: "Jordan Dea-Mattson", ... } }`

Migration steps:
1. Detect format by structural markers (presence of `principals:` vs `principal:` vs nested object)
2. For flat: `jdm: jordan` → `jdm: { name: jordan, display_name: "Jordan" }`
3. For root-level: extract `principal`, `principal_name`, `principal_email`, `principal_github` → build nested structure under `principals:` keyed by `$USER`
4. Default `display_name` to titlecase of `name` if not derivable from source format
5. Default `address.informal` to `display_name`
6. Leave `platforms.github` empty unless derivable from `principal_github` field
7. Preserve all other agency.yaml sections untouched

**Non-interactive.** No prompts during migration. Defaults are applied, and the update report lists what was defaulted so the user can refine. The tool architecture (bash scripts invoked by Claude Code) does not support interactive stdin.

**Migration versioning:** Detect-and-migrate. No explicit schema version field. Each migration checks for the presence/absence of specific YAML structures. Migrations are idempotent — running the same migration twice produces the same result. New migrations are added as the schema evolves, each with its own detection heuristic.

### 4.4 Pre-Flight Validation

Before making any changes:

1. Source exists and is a valid Agency framework source (has `agency/CLAUDE-THEAGENCY.md` — the definitive framework marker)
2. Source has all required directories (agents/, docs/, hooks/, tools/)
3. Target is initialized (has `agency/config/agency.yaml`)
4. Target has clean git state for framework files (warn if uncommitted changes in `claude/`)
5. Display "from version → to version" and list of changes before applying

**No version compatibility check.** The "always forward" constraint (from starter-sunset PVR) means compatibility is implicit — every update moves to the current source version. If a breaking change requires migration, the migration is bundled in the update (see 4.3).

### 4.5 Post-Update Actions

1. `agency update` runs `sandbox-sync` as a final step — new skills and hookify rules from the update are symlinked into `.claude/` immediately, not deferred to next session
2. `agency update` writes handoff with `type: agency-update`
3. `session-handoff.sh` detects the type and injects update context
4. The injected context instructs the agent to run `agency verify --verbose` as first action
5. This is best-effort — hooks inject system messages, not tool calls. The agent reads the context and decides actions.
6. **Worktree staleness:** After update, worktree copies of settings.json are stale until next `/session-resume` (which runs worktree-sync). Document this explicitly — it's a known window.

### 4.6 Update Reporting

After update, generate a summary at `usr/{principal}/{agent}/update-report-YYYYMMDD-HHMM.md`. Agent name resolved from context (not hardcoded to `captain`). Principal resolved via `agency whoami` (reading from agency.yaml). If principal cannot be resolved (corrupt agency.yaml), the report is written to `claude/config/last-update-report.md` as fallback.

Contents:
- Source version → target version (if no `framework:` block in agency.yaml, report "version unknown → {new version}")
- Files added, updated, skipped (with reasons for skips)
- Config files preserved (user-modified, with paths)
- Agency.yaml migrations applied (with defaults used)
- Next steps

### 4.7 Dry Run

`agency update --dry-run` displays what would change without modifying any files:
- Files that would be added, updated, skipped, or pruned
- Agency.yaml migrations that would be applied
- Settings that would be merged
- No interactive prompts during dry-run

## 5. Non-Functional Requirements

- **Zero data loss.** Never delete or overwrite user-modified config files without explicit `--prune` flag.
- **Idempotent.** Running `agency update` twice with same source produces same result.
- **Offline.** Works from local clone, no network required.
- **Fast.** Update of a typical project completes in under 5 seconds.
- **macOS + Linux.** Platform-aware sed/stat/checksum commands (`shasum -a 256` for checksums).

## 6. Constraints

- Must be backward-compatible with current agency.yaml format (flat principals)
- Must not break existing handoff lifecycle
- Manifest schema changes must be additive (old manifests still readable — missing `tier` inferred from path)
- No interactive prompts (tool runs in Claude Code Bash environment)
- Git is the rollback mechanism — no framework-level undo

## 7. Success Criteria

- Three-tier file strategy implemented and tested
- Manifest checksums computed on every init and update
- User-modified config files preserved during update (verified by BATS test)
- Agency.yaml flat→nested migration works without data loss (verified by BATS test)
- Pre-flight validation catches incomplete source (verified by BATS test)
- Session-handoff hook injects update context for `type: agency-update` handoffs
- Update report generated with actionable content
- `agency update --dry-run` previews all changes without modifying files
- Update of `test/test-agency-project/` fixture completes in under 5 seconds
- All BATS tests pass (existing + new)

## 8. Non-Goals

- No remote update (download from GitHub/registry) — local clone only
- No rollback mechanism beyond `git checkout`
- No interactive conflict resolution (merge tool) — just preserve user version
- No multi-version support (always update to source version)
- No version compatibility checks — always forward, migrations bundled in update
- No partial update (`agency update --only <component>`) — always full sync

## 9. Relationship to Other Work

- **Addressing standard** — drives UC3 (agency.yaml migration)
- **ISCP/IACP** — update must preserve dispatch/handoff addressing in new format
- **Enforcement triangle** — update must sync new hookify rules and wire enforcement
- **Monofolk contributions** — update must handle new skills/tools from upstream ports

## 10. Resolved Questions

1. **Config tier granularity:** Per-file tier assignment stored in manifest, with directory-level defaults from classification rules. Individual files can override their directory's default tier. This allows `tools/lib/_log-helper` to be `framework` tier even though `tools/` defaults to `config`.

2. **Migration versioning:** Detect-and-migrate. No explicit schema version field. Each migration checks for structural markers. Migrations are idempotent.

3. **Partial update:** Deferred to non-goals. Always full sync for now. The manifest-driven approach naturally enables partial update in the future since each file has a component/tier tag.
