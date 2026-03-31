# Agency Init & Update Design

**Source:** /discuss session, 2026-03-31
**Participants:** jordan (principal), captain (agent)
**Status:** Revised — post multi-agent review (design, code, security)
**Review:** 3 CRITICAL, 7 MAJOR, 8 MINOR findings addressed in this revision

---

## Overview

`agency-init` and `agency-update` are the two entry points for installing and maintaining the Agency framework in any git repo. They follow the Rails model: template-driven generation at init time, rsync-style sync with conflict resolution at update time.

### Preconditions

The target must be a git repo before agency-init runs. The expected sequence:

- **Bare repo:** `git init` → `claude init` → `agency-init`
- **Existing repo:** `claude init` (if needed) → `agency-init`

agency-init validates that git is initialized. It does not create the repo.

### Principles

- **Copy, don't symlink.** Framework files are copied into the target repo and committed. The project owns them.
- **Manifest-driven updates.** A manifest tracks what was installed, at what version, with what checksum. Updates compare against manifest to detect user modifications.
- **Three file tiers.** Every installed file has a tier (framework, config, scaffold) that governs update behavior.
- **Tools are tools.** No distinction by implementation language — bash, python, rust, compiled binary. All live in `claude/tools/`.
- **Single namespace.** Everything Agency-related lives under `claude/`. One top-level directory. Good neighbor in someone else's repo.
- **Git is the safety net.** Updates don't auto-commit. `git checkout -- claude/` is the rollback. No custom staging or backup mechanism needed.

### Trust Model

**v1:** The user trusts the source they point agency-init/update at. Source is a local filesystem path (clone of the-agency repo, AGENCY_SOURCE env var, or auto-detected). No cryptographic verification of source integrity. This is the same trust model as Rails generators and gstack.

**Post-v1 (public release):** Source authentication via signed checksums (CHECKSUMS.sha256 signed by release process) or GPG-signed manifests. Decision deferred to the public release milestone.

---

## Target Repo Structure

After `agency-init`, a bare repo looks like this. Everything Agency-related is under `claude/`.

```
my-project/
├── README.md                              # scaffold
├── CLAUDE.md                              # scaffold
│
├── .claude/                               # Claude Code's space
│   ├── settings.json                      # scaffold
│   ├── worktrees/                         # gitignored — transient worktree copies
│   ├── commands/
│   │   └── discuss.md                     # framework
│   └── skills/
│       ├── define/                        # framework
│       └── design/                        # framework
│
├── claude/                                # Agency framework — single namespace
│   ├── README-THEAGENCY.md                # framework
│   ├── README-GETTINGSTARTED.md           # framework
│   ├── config/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── agency.yaml                    # scaffold (generated with project values)
│   │   ├── agency-dependencies.yaml       # framework
│   │   ├── settings-template.json         # framework — canonical permissions/hooks
│   │   └── manifest.json                  # managed by init/update
│   ├── agents/                            # agent CLASS definitions
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework — explains these are role defs
│   │   ├── captain/
│   │   │   └── agent.md                   # framework
│   │   ├── project-manager/
│   │   │   └── agent.md                   # framework
│   │   ├── cos/
│   │   │   └── agent.md                   # framework
│   │   ├── reviewer-code/
│   │   │   └── agent.md                   # framework
│   │   ├── reviewer-design/
│   │   │   └── agent.md                   # framework
│   │   ├── reviewer-security/
│   │   │   └── agent.md                   # framework
│   │   ├── reviewer-test/
│   │   │   └── agent.md                   # framework
│   │   └── reviewer-scorer/
│   │       └── agent.md                   # framework
│   ├── docs/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── QUALITY-GATE.md                # framework
│   │   ├── DEVELOPMENT-METHODOLOGY.md     # framework
│   │   ├── CODE-REVIEW-LIFECYCLE.md       # framework
│   │   ├── FEEDBACK-FORMAT.md             # framework
│   │   ├── PR-LIFECYCLE.md                # framework
│   │   └── TELEMETRY.md                   # framework
│   ├── hooks/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── ref-injector.sh                # config
│   │   ├── session-handoff.sh             # config
│   │   ├── quality-check.sh               # config
│   │   ├── plan-capture.sh                # config
│   │   ├── branch-freshness.sh            # config
│   │   └── tool-telemetry.sh              # config
│   ├── hookify/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   └── *.md                           # config (shipped rules)
│   ├── templates/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── principal-v2/                  # framework
│   │   ├── CLAUDE-USER.md                 # framework
│   │   ├── CLAUDE-PROJECT.md              # framework
│   │   └── PROVIDER.sh                    # framework
│   ├── tools/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── lib/
│   │   │   ├── _log-helper               # framework
│   │   │   ├── _path-resolve             # framework
│   │   │   └── _provider-resolve         # framework
│   │   ├── agency-init                    # framework
│   │   ├── agency-update                  # framework
│   │   ├── agency-verify                  # framework
│   │   ├── agency-whoami                  # framework
│   │   ├── code-review                    # framework
│   │   ├── commit-precheck                # framework
│   │   ├── dependencies-check             # framework
│   │   ├── dependencies-install           # framework
│   │   ├── git-commit                     # framework
│   │   ├── git-fetch                      # framework
│   │   ├── git-sync                       # framework
│   │   ├── git-tag                        # framework
│   │   ├── handoff                        # framework
│   │   ├── now                            # framework
│   │   ├── review-spawn                   # framework
│   │   ├── secret-vault                   # framework
│   │   ├── settings-merge                 # framework
│   │   ├── terminal-setup                 # framework
│   │   ├── terminal-setup-ghostty         # framework
│   │   ├── platform-setup                 # framework
│   │   ├── platform-setup-macos           # framework
│   │   ├── platform-setup-linux           # framework
│   │   ├── telemetry                      # framework
│   │   ├── test-run                       # framework
│   │   ├── tool-create                    # framework
│   │   ├── worktree-create                # framework
│   │   ├── worktree-list                  # framework
│   │   └── worktree-delete                # framework
│   ├── usr/                               # agent INSTANCES (per-principal)
│   │   ├── README.md                      # scaffold
│   │   ├── CLAUDE.md                      # scaffold — explains class vs instance
│   │   └── {principal}/
│   │       ├── README.md                  # scaffold
│   │       ├── CLAUDE.md                  # scaffold
│   │       ├── claude/
│   │       │   ├── commands/
│   │       │   ├── hookify/
│   │       │   ├── hooks/
│   │       │   └── agents/
│   │       └── captain/                   # instance of captain class
│   │           ├── CLAUDE.md              # scaffold
│   │           ├── handoff.md             # scaffold
│   │           ├── dispatches/
│   │           ├── transcripts/
│   │           └── history/
│   ├── workstreams/                       # bodies of work
│   │   ├── README.md                      # scaffold
│   │   ├── CLAUDE.md                      # scaffold — explains workstream model
│   │   └── ops/                           # default workstream (coordination/maintenance)
│   │       ├── README.md                  # scaffold
│   │       ├── CLAUDE.md                  # scaffold
│   │       ├── seeds/
│   │       └── history/
│   └── src/                               # --dev only
│       ├── README.md                      # framework
│       └── CLAUDE.md                      # framework
```

### Directory Semantics

| Directory | Purpose | Audience |
|-----------|---------|----------|
| `.claude/` | Claude Code configuration (settings, commands, skills, worktrees) | Claude Code |
| `claude/` | Agency framework — everything Agency-related | Agency |
| `claude/agents/` | Agent class definitions — what a role IS | Framework |
| `claude/usr/` | Agent instances — a principal's deployment of agent classes | Per-principal |
| `claude/workstreams/` | Bodies of work with artifacts (PVR, A&D, Plan, QGR, Ref) | Per-workstream |

### Key Relationships

- **Agent class** (`claude/agents/tech-lead/agent.md`) — what the role IS
- **Agent instance** (`claude/usr/jordan/devex/`) — who's filling the role, on what workstream
- **Workstream** (`claude/workstreams/devex/`) — the body of work

Names can overlap. A workstream called `devex` can have an agent instance called `devex` (which is a tech-lead assigned to the devex workstream). The directory location disambiguates.

### README.md vs CLAUDE.md

Every directory gets both:
- **README.md** — for humans browsing the repo
- **CLAUDE.md** — for agents working in the repo

CLAUDE.md replaces the former KNOWLEDGE.md. Claude Code discovers CLAUDE.md files automatically via hierarchical reading. Existing KNOWLEDGE.md files should be renamed to CLAUDE.md during migration.

### Workstream Artifacts

All artifacts are peers at the workstream root:

```
claude/workstreams/devex/
  devex-pvr-YYYYMMDD.md          # Product Vision & Requirements
  devex-ad-YYYYMMDD.md           # Architecture & Design
  devex-plan-YYYYMMDD.md         # Plan (phases, iterations)
  devex-ref-YYYYMMDD.md          # Reference (final docs)
  devex-qgr-{scope}-YYYYMMDD.md  # Quality Gate Reports
  seeds/                          # input materials
  history/                        # archived artifact versions
```

No `bugs/` directory. A bug is a finding in a QGR, which becomes a work item in the plan. QGRs are workstream artifacts, not dispatches.

### Dispatches

Any agent can dispatch to any agent. Dispatches live in the receiving agent's instance:

```
claude/usr/{principal}/{agent}/dispatches/
  dispatch-{slug}-YYYYMMDD.md
```

Current model: markdown files, agents prompted to read them. Future: ISCP (dispatch #3) designs proper inter-agent communication.

### Worktrees

Worktrees live at `.claude/worktrees/{name}/` (gitignored). They are Claude Code's concern — transient, not committed. The Agency worktree tools (`worktree-create`, `worktree-list`, `worktree-delete`) manage this location.

**Known issue (ISS-012):** Some repos have worktrees in both `.claude/worktrees/` and `.git/worktrees/`. The tooling must be consolidated to use a single location.

---

## File Classification

Three tiers govern update behavior:

| Tier | On init | On update | Description |
|------|---------|-----------|-------------|
| **framework** | Copy from source | Always overwrite | Framework-owned files. Users should not modify. |
| **config** | Copy from source | Overwrite if untouched (hash matches manifest). Skip + warn if user modified. | Framework-provided defaults that users may customize. |
| **scaffold** | Generate or copy | Never touch | Project-specific files generated at init time. User owns completely. |

### Tier Assignment by Path

Tier is assigned by directory pattern, not per-file lists. Add a tool to `claude/tools/` in the source — it's automatically framework tier. Add a hook to `claude/hooks/` — automatically config tier.

**Precedence rule:** More specific patterns win. `claude/usr/**` (scaffold) takes precedence over `claude/*/CLAUDE.md` (framework) because `claude/usr/` is explicitly listed as scaffold.

```
framework:
  - claude/tools/**
  - claude/tools/lib/**
  - claude/docs/**
  - claude/agents/*/agent.md
  - claude/agents/*/README.md
  - claude/agents/*/CLAUDE.md
  - claude/templates/**
  - claude/config/agency-dependencies.yaml
  - claude/config/settings-template.json
  - claude/README-*.md
  - .claude/commands/**
  - .claude/skills/**

config:
  - claude/hooks/** (excluding README.md, CLAUDE.md which are framework)
  - claude/hookify/*.md (shipped rules only — distinguished by presence in manifest)

scaffold:
  - CLAUDE.md (repo root)
  - README.md (repo root)
  - claude/config/agency.yaml
  - .claude/settings.json
  - claude/usr/**
  - claude/workstreams/**
```

**Distinguishing shipped vs user hookify rules:** A hookify rule is "shipped" if it exists in the source at init/update time and is tracked in the manifest. User-added rules in `claude/hookify/` are not in the manifest and are never touched.

**Deleted config-tier files:** If a user deletes a config-tier file that is in the manifest, agency-update treats the missing file as a user modification (intentional deletion) and skips it. The update summary warns: "Skipped (deleted by user): claude/hooks/foo.sh".

Update only touches files tracked in the manifest. User-added files in any directory are never deleted.

### Settings Merge

`.claude/settings.json` is scaffold — never overwritten by agency-update. New tools and hooks from updates require permission entries that the user doesn't have yet.

**Solution:** `claude/config/settings-template.json` is a framework-tier file (always current). The `settings-merge` tool diffs the template against the user's `.claude/settings.json` and adds missing permission entries and hook entries. It never removes or modifies existing entries.

- **agency-update summary prompts:** "Run `./claude/tools/settings-merge` to pick up new permissions and hooks."
- **If `.claude/settings.json` is malformed:** `settings-merge` prints the exact JSON fragments to add manually instead of attempting a merge.
- **`claude/config/agency.yaml`** follows the same pattern — scaffold, never overwritten, manual merge for new config keys.

---

## Manifest Schema (v2)

Lives at `claude/config/manifest.json`.

```json
{
  "schema_version": "2.0",
  "installed_at": "2026-04-01T10:00:00Z",
  "updated_at": "2026-04-01T10:00:00Z",
  "source": {
    "repo": "the-agency-ai/the-agency",
    "path": "/Users/jordan/code/the-agency",
    "commit": "944c5c8",
    "version": "2.0.0"
  },
  "options": {
    "dev": false,
    "principal": "jordan"
  },
  "files": {
    "claude/tools/git-commit": {
      "hash": "sha256:abc123...",
      "tier": "framework",
      "installed_version": "2.0.0"
    },
    "claude/hooks/ref-injector.sh": {
      "hash": "sha256:def456...",
      "tier": "config",
      "installed_version": "2.0.0"
    },
    "CLAUDE.md": {
      "hash": "sha256:ghi789...",
      "tier": "scaffold",
      "installed_version": "2.0.0"
    }
  }
}
```

- **Per-file hash** — SHA-256 of file contents at install/update time. Hash prefix (`sha256:`) required for forward-compatibility with algorithm migration.
- **Per-file tier** — drives update behavior
- **No `modified` boolean** — computed at update time by comparing current file hash to manifest hash
- **Source tracking** — repo slug, local filesystem path, commit, version
- **Options** — remember what flags were used (for re-running with `--dev`)
- **Schema version validation** — agency-update refuses to process a manifest with an unrecognized `schema_version`. Prevents older tooling from corrupting a newer manifest.

---

## agency-init Flow

```
agency-init <target> [--principal <name>] [--project <name>] [--dev]
```

1. **Validate** — target is a git repo (abort if not — do not offer to create). Agency source exists (AGENCY_SOURCE env var or auto-detect from script location).
2. **Check not initialized** — if `claude/config/manifest.json` exists, abort with "use agency-update".
3. **Resolve defaults** — principal from `whoami` (lowercased, validated: `^[a-z][a-z0-9-]*$`), project from directory name, timezone from system.
4. **Copy framework files** — all framework tier files from source to target.
5. **Copy config files** — all config tier files from source to target.
6. **Generate scaffold files** — CLAUDE.md (from template + project name), README.md, agency.yaml (from args), .claude/settings.json (from settings-template.json), claude/usr/{principal}/ directory tree, claude/workstreams/ops/ directory tree. All README.md and CLAUDE.md files for scaffold directories.
7. **If `--dev`** — copy `claude/src/` with source code, tests, build scripts. Dev files are tracked in the manifest with their tier and `options.dev` is set to true.
8. **Set permissions** — `chmod +x` only on files copied by agency-init (explicit list from manifest, not glob).
9. **Write manifest** — hash every installed file, record tier, source commit/path, options.
10. **Commit** — stage only files tracked in the manifest (explicit `git add` per file, not `git add -A`).
11. **Print next steps** — launch instructions, captain bootstrap prompt, reminder to run `settings-merge` if customizing.

---

## agency-update Flow

```
agency-update [--source <path>] [--dry-run]
```

1. **Read manifest** — load `claude/config/manifest.json`. If missing, abort ("not an Agency project, use agency-init"). If `schema_version` is unrecognized, abort with version mismatch error.
2. **Resolve source** — `--source` flag first, then AGENCY_SOURCE env var, then `source.path` from manifest. Validate that the resolved path exists and contains `claude/config/agency-dependencies.yaml`.
3. **If `--dry-run`** — perform all comparisons and print the summary (step 7) without writing any files. Exit.
4. **For each file in the new source:**
   - **Framework tier** — overwrite always.
   - **Config tier** — hash current local file. If file missing → skip, warn as "deleted by user". If hash matches manifest → overwrite (user hasn't touched it). If hash differs → skip, add to conflict list.
   - **Scaffold tier** — skip always.
   - **New file** (not in manifest) — copy, add to manifest with appropriate tier.
5. **Removed files** (in manifest but not in new source) — warn as deprecated. Do not delete.
6. **Set permissions** — `chmod +x` only on files written in this update (explicit list, not glob).
7. **Update manifest** — new hashes, new source commit/path, updated_at timestamp.
8. **Print summary:**
   ```
   agency-update complete (git is your undo — review changes before committing)
     Updated: 14 files (framework)
     Updated: 3 files (config, untouched)
     Skipped: 2 files (config, user-modified)
     Skipped: 1 file (config, deleted by user)
     Added:   4 files (new in this version)
     Deprecated: 1 file (removed upstream)

   Run ./claude/tools/settings-merge to pick up new permissions and hooks.
   ```
9. **No auto-commit** — user reviews changes with `git diff` and commits when ready. Rollback: `git checkout -- claude/`.

---

## agency-service Deprecation

The `source/services/agency-service/` directory and its 10 embedded services are deprecated.

| Service | Decision | Replacement |
|---------|----------|-------------|
| test-service | FUTURE | `test-run` tool + bats (interim). Test management system needed later. |
| log-service | REPLACED | JSONL telemetry via `_log-helper` |
| secret-service | REPLACED | `secret-vault` tool |
| request-service | KILL | Dead |
| bug-service | FUTURE | Bugs are QGR findings (interim). Human-to-agent finding reports needed later. |
| idea-service | KILL | Dead |
| observation-service | KILL | Dead |
| dispatch-service | FUTURE | File-based dispatches (interim). ISCP designs proper replacement. |
| messages-service | FUTURE | File-based dispatches (interim). ISCP designs proper replacement. |
| product-service | KILL | Dead |

Actions:
- Delete `source/services/agency-service/` entirely
- Rewrite `.github/workflows/test.yml` to install bats and run `bats tests/` directly (no service startup, no health checks, no HTTP API)
- Fix `.github/workflows/starter-verify.yml`: update `tools/myclaude` → `claude/tools/agency-verify` (or remove if myclaude was a starter-only artifact), update `source/services/agency-service` references → remove, update `tools/` → `claude/tools/` paths
- Remove agency-service from manifest components

---

## `--dev` Flag

Default install ships runnable tools only. `--dev` adds:

- `claude/src/` — source code for compiled tools, apps, services
- `tests/` — test suites (bats, etc.)
- Build scripts and dev tooling

Today all tools are bash scripts, so `--dev` adds tests only. As compiled artifacts ship (mdpal, mockandmark, future services), their source goes in `claude/src/`.

`agency-update` respects the `options.dev` flag from the manifest. If a repo was initialized with `--dev`, updates include dev files. To add dev files to an existing non-dev install, run `agency-init --dev` (which detects the existing manifest and offers to upgrade rather than aborting).

---

## KNOWLEDGE.md Migration

KNOWLEDGE.md is replaced by CLAUDE.md. Existing repos may have KNOWLEDGE.md files that agents no longer read by default (Claude Code auto-discovers CLAUDE.md, not KNOWLEDGE.md).

**agency-init:** Does not create KNOWLEDGE.md. Only creates CLAUDE.md.

**agency-update:** Detects KNOWLEDGE.md files that have no corresponding CLAUDE.md. Warns in the update summary: "Found KNOWLEDGE.md without CLAUDE.md — rename recommended: {path}". Does not rename automatically (user may have both intentionally).

---

## Open Items (Deferred)

- **Source authentication** — signed checksums or GPG for public release (v1 trusts the source)
- **Starter-packs** — what they look like, how they're shipped
- **ISCP** — proper inter-agent communication (dispatch #3)
- **Test management** — multi-framework test tracking and boundary run definitions
- **Human-to-agent findings** — reporting mechanism for principals
- **Worktree consolidation (ISS-012)** — resolve worktrees appearing in both `.claude/worktrees/` and `.git/worktrees/`
- **Terminal-specific hooks** — ghostty-status.sh should be conditional on `terminal.provider` config, not shipped to all users
