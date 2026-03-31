# Agency Init & Update Design

**Source:** /discuss session, 2026-03-31
**Participants:** jordan (principal), captain (agent)
**Status:** Draft — pending review cycle

---

## Overview

`agency-init` and `agency-update` are the two entry points for installing and maintaining the Agency framework in any git repo. They follow the Rails model: template-driven generation at init time, rsync-style sync with conflict resolution at update time.

### Principles

- **Copy, don't symlink.** Framework files are copied into the target repo and committed. The project owns them.
- **Manifest-driven updates.** A manifest tracks what was installed, at what version, with what checksum. Updates compare against manifest to detect user modifications.
- **Three file tiers.** Every installed file has a tier (framework, config, scaffold) that governs update behavior.
- **Tools are tools.** No distinction by implementation language — bash, python, rust, compiled binary. All live in `claude/tools/`.

---

## Target Repo Structure

After `agency-init`, a bare repo looks like this:

```
my-project/
├── README.md                              # scaffold
├── CLAUDE.md                              # scaffold
│
├── .claude/                               # Claude Code's space
│   ├── settings.json                      # scaffold
│   ├── commands/
│   │   └── discuss.md                     # framework
│   └── skills/
│       ├── define/                        # framework
│       └── design/                        # framework
│
├── claude/                                # Agency framework
│   ├── README-THEAGENCY.md                # framework
│   ├── README-GETTINGSTARTED.md           # framework
│   ├── config/
│   │   ├── README.md                      # framework
│   │   ├── CLAUDE.md                      # framework
│   │   ├── agency.yaml                    # scaffold (generated with project values)
│   │   ├── agency-dependencies.yaml       # framework
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
│   │   ├── tool-telemetry.sh              # config
│   │   └── ghostty-status.sh              # config
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
│   │   ├── agency-verify                  # framework
│   │   ├── agency-whoami                  # framework
│   │   ├── code-review                    # framework
│   │   ├── commit-precheck                # framework
│   │   ├── git-commit                     # framework
│   │   ├── git-fetch                      # framework
│   │   ├── git-sync                       # framework
│   │   ├── git-tag                        # framework
│   │   ├── handoff                        # framework
│   │   ├── now                            # framework
│   │   ├── review-spawn                   # framework
│   │   ├── secret-vault                   # framework
│   │   ├── terminal-setup                 # framework
│   │   ├── terminal-setup-ghostty         # framework
│   │   ├── platform-setup                 # framework
│   │   ├── platform-setup-macos           # framework
│   │   ├── platform-setup-linux           # framework
│   │   ├── test-run                       # framework
│   │   ├── tool-create                    # framework
│   │   ├── worktree-create                # framework
│   │   ├── worktree-list                  # framework
│   │   └── worktree-delete                # framework
│   └── src/                               # --dev only
│       ├── README.md                      # framework
│       └── CLAUDE.md                      # framework
│
├── usr/                                   # agent INSTANCES (per-principal)
│   ├── README.md                          # scaffold
│   ├── CLAUDE.md                          # scaffold — explains class vs instance
│   └── {principal}/
│       ├── README.md                      # scaffold
│       ├── CLAUDE.md                      # scaffold
│       ├── claude/
│       │   ├── commands/
│       │   ├── hookify/
│       │   ├── hooks/
│       │   └── agents/
│       └── captain/                       # instance of captain class
│           ├── CLAUDE.md                  # scaffold
│           ├── handoff.md                 # scaffold
│           ├── dispatches/
│           ├── transcripts/
│           ├── history/
│
├── workstreams/                           # bodies of work
│   ├── README.md                          # scaffold
│   ├── CLAUDE.md                          # scaffold — explains workstream model
│   └── ops/                               # default workstream (coordination/maintenance)
│       ├── README.md                      # scaffold
│       ├── CLAUDE.md                      # scaffold
│       ├── seeds/
│       └── history/
```

### Directory Semantics

| Directory | Purpose | Audience |
|-----------|---------|----------|
| `.claude/` | Claude Code configuration (settings, commands, skills) | Claude Code |
| `claude/` | Agency framework (tools, agents, hooks, docs, config) | Agency |
| `usr/` | Agent instances — a principal's deployment of agent classes | Per-principal |
| `workstreams/` | Bodies of work with artifacts (PVR, A&D, Plan, QGR, Ref) | Per-workstream |

### Key Relationships

- **Agent class** (`claude/agents/tech-lead/agent.md`) — what the role IS
- **Agent instance** (`usr/jordan/devex/`) — who's filling the role, on what workstream
- **Workstream** (`workstreams/devex/`) — the body of work

Names can overlap. A workstream called `devex` can have an agent instance called `devex` (which is a tech-lead assigned to the devex workstream). The directory location disambiguates.

### README.md vs CLAUDE.md

Every directory gets both:
- **README.md** — for humans browsing the repo
- **CLAUDE.md** — for agents working in the repo

CLAUDE.md replaces the former KNOWLEDGE.md. Claude Code discovers CLAUDE.md files automatically via hierarchical reading.

### Workstream Artifacts

All artifacts are peers at the workstream root:

```
workstreams/devex/
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
usr/{principal}/{agent}/dispatches/
  dispatch-{slug}-YYYYMMDD.md
```

Current model: markdown files, agents prompted to read them. Future: ISCP (dispatch #3) designs proper inter-agent communication.

---

## File Classification

Three tiers govern update behavior:

| Tier | On init | On update | Description |
|------|---------|-----------|-------------|
| **framework** | Copy from source | Always overwrite | Framework-owned files. Users should not modify. |
| **config** | Copy from source | Overwrite if untouched (hash matches manifest). Skip + warn if user modified. | Framework-provided defaults that users may customize. |
| **scaffold** | Generate or copy | Never touch | Project-specific files generated at init time. User owns completely. |

### Tier Assignment by Path

```
framework:
  - claude/tools/**
  - claude/tools/lib/**
  - claude/docs/**
  - claude/agents/*/agent.md
  - claude/templates/**
  - claude/config/agency-dependencies.yaml
  - claude/README-*.md
  - claude/*/README.md (framework directories)
  - claude/*/CLAUDE.md (framework directories)
  - .claude/commands/**
  - .claude/skills/**

config:
  - claude/hooks/**
  - claude/hookify/*.md (shipped rules only)

scaffold:
  - CLAUDE.md
  - README.md
  - claude/config/agency.yaml
  - .claude/settings.json
  - usr/**
  - workstreams/**
```

Tier is assigned by directory pattern, not per-file lists. Add a tool to `claude/tools/` in the source — it's automatically framework tier. Add a hook to `claude/hooks/` — automatically config tier.

Update only touches files tracked in the manifest. User-added files in any directory are never deleted.

### Known Limitation: Config Merge

`.claude/settings.json` and `claude/config/agency.yaml` are scaffold — never overwritten. When a new Agency version ships new hooks or config keys, users don't get them automatically. Agency-update surfaces this in its summary ("new hooks available, add manually"). A merge strategy is deferred to a future version.

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

- **Per-file hash** — SHA-256 of file contents at install/update time
- **Per-file tier** — drives update behavior
- **No `modified` boolean** — computed at update time by comparing current file hash to manifest hash
- **Source tracking** — repo, commit, version of what was installed
- **Options** — remember what flags were used (for re-running)

---

## agency-init Flow

```
agency-init <target> [--principal <name>] [--project <name>] [--dev]
```

1. **Validate** — target is a git repo (or offer to `git init`). Agency source exists (AGENCY_SOURCE env var or auto-detect).
2. **Check not initialized** — if `claude/config/manifest.json` exists, abort with "use agency-update".
3. **Resolve defaults** — principal from `whoami`, project from directory name, timezone from system.
4. **Copy framework files** — all framework tier files from source to target.
5. **Copy config files** — all config tier files from source to target.
6. **Generate scaffold files** — CLAUDE.md (from template + project name), README.md, agency.yaml (from args), .claude/settings.json (with hooks + permissions), usr/{principal}/ directory tree, workstreams/ops/ directory tree. All README.md and CLAUDE.md files for scaffold directories.
7. **If `--dev`** — copy `claude/src/` with source code, tests, build scripts.
8. **Write manifest** — hash every installed file, record tier, source commit, options.
9. **Commit** — scoped to Agency files only (not `git add -A`).
10. **Print next steps** — launch instructions, captain bootstrap prompt.

---

## agency-update Flow

```
agency-update [--source <path>]
```

1. **Read manifest** — load `claude/config/manifest.json`. If missing, abort ("not an Agency project, use agency-init").
2. **Resolve source** — AGENCY_SOURCE env var, --source flag, or saved source path from manifest.
3. **For each file in the new source:**
   - **Framework tier** — overwrite always.
   - **Config tier** — hash current local file. If hash matches manifest → overwrite (user hasn't touched it). If hash differs → skip, add to conflict list.
   - **Scaffold tier** — skip always.
   - **New file** (not in manifest) — copy, add to manifest with appropriate tier.
4. **Removed files** (in manifest but not in new source) — warn as deprecated. Do not delete.
5. **Update manifest** — new hashes, new source commit, updated_at timestamp.
6. **Print summary:**
   ```
   agency-update complete
     Updated: 14 files (framework)
     Updated: 3 files (config, untouched)
     Skipped: 2 files (config, user-modified)
     Added:   4 files (new in this version)
     Deprecated: 1 file (removed upstream)
   ```
7. **No auto-commit** — user reviews changes and commits when ready.

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
- Rewrite `.github/workflows/test.yml` to run bats tests directly
- Fix `.github/workflows/starter-verify.yml` stale tool paths
- Remove agency-service from manifest components

---

## `--dev` Flag

Default install ships runnable tools only. `--dev` adds:

- `claude/src/` — source code for compiled tools, apps, services
- `tests/` — test suites (bats, etc.)
- Build scripts and dev tooling

Today all tools are bash scripts, so `--dev` adds tests only. As compiled artifacts ship (mdpal, mockandmark, future services), their source goes in `claude/src/`.

---

## Open Items (Deferred)

- **Config merge strategy** — how to deliver new hooks/config keys to scaffold files
- **Starter-packs** — what they look like, how they're shipped
- **ISCP** — proper inter-agent communication (dispatch #3)
- **Test management** — multi-framework test tracking and boundary run definitions
- **Human-to-agent findings** — reporting mechanism for principals
