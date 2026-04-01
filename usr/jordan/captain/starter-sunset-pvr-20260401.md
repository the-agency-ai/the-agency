# Starter Sunset — Product Vision & Requirements

**Date:** 2026-04-01
**Status:** Reviewed
**Author:** captain

## 1. Problem Statement

The Agency currently has two distribution mechanisms:

- **the-agency-starter** — a separate GitHub repo that ships a curated snapshot of the framework. Maintained via `starter-release` (a manual sync+clean process with 5 dedicated tools, 2 GitHub workflows, and 13 integration tests).
- **agency-init** — a tool that copies framework files directly from the source repo into a target project.

With `agency-init` now handling full installation (37 skills, 9 commands, agents, hooks, docs, templates), the-agency-starter repo is redundant as a distribution vehicle. Maintaining two paths creates sync drift, release overhead, and confusion about which is canonical.

Separately, **starter packs** (`claude/starter-packs/node-base`, `react-app`, `vercel`, etc.) are static template directories. They should evolve into skills — discoverable, composable, and invocable as part of a generalized environment setup pattern.

**For whom:** Framework maintainers (reduced maintenance burden) and adopters (single, clear onboarding path).

**Why now:** agency-init just reached feature parity. The starter repo is now pure overhead.

## 2. Target Users

- **Framework adopters** — run `agency init` on their projects
- **Framework maintainers** — evolve the-agency itself
- **Skill authors** — create skills (including project-type overlays that used to be "starter packs")

## 3. Use Cases

### Happy Path Flow

1. `git init`
2. `claude init` (creates `.claude/`)
3. `agency init` (copies framework, asks for principal name, creates `usr/{principal}/captain/`, writes bootstrap handoff)
4. `claude` (first launch — SessionStart hook reads bootstrap handoff)
5. Onboarding skill activates automatically (user can break out) — verifies install, configures principal, orients user
6. User is ready

### Use Cases

1. **New project setup:** `agency init` on a bare repo (post `git init` + `claude init`). Preconditions enforced — block if either hasn't been run. Bootstrap handoff triggers onboarding on first `claude` launch.
2. **Existing project update:** `agency update` syncs framework to latest. Prepends update info to existing handoff (doesn't replace it). First captain session picks it up and runs verification.
3. **Tech stack overlay:** `/environment-setup` skill assesses the project, does what it can autonomously, guides user through human-required steps, verifies the result. Platform-specific knowledge (evolved from starter packs) feeds the skill. **Deferred — being sorted out with DevEx agent.**
4. **Author a starter pack skill:** Create platform knowledge that feeds the generalized setup skill.

### Handoff Types

| Type | Written by | Triggers |
|------|-----------|----------|
| `session` | Agent at session end | Normal restore |
| `agency-bootstrap` | `agency init` | Onboarding skill |
| `agency-update` | `agency update` | Update verification skill |

The bootstrap handoff content IS the onboarding trigger — no separate marker file. The agent reads it and naturally flows into onboarding. On `agency update`, update info is prepended to the existing handoff so the agent gets both "what changed" and "where you left off."

The handoff tool and skill need to be updated to support the `type` frontmatter.

## 4. Functional Requirements

### 4.1 CLI Consolidation

Single `agency` script as the entry point with subcommands:

```
agency init [--principal name]     # initialize new project
agency update                      # sync to latest framework
agency verify                      # health check
agency whoami                      # show principal
agency feedback                    # submit feedback
```

Current `agency-*` tools (`agency-init`, `agency-update`, `agency-verify`, `agency-whoami`, `agency-feedback`) get absorbed into the single script. The logic lives in `agency`, not in separate tools behind a dispatcher.

### 4.2 Starter Repo Sunset

- Archive the-agency-starter contents to `archive-the-agency-starter/` (done)
- Remove `test/the-agency-starter/` submodule
- Remove starter-specific tools: `starter-test`, `starter-verify`, `starter-compare`, `starter-cleanup`, `starter-update`, `starter-release`
- Remove starter-specific docs: `STARTER-PACK-INTEGRATION.md`, `STARTER-RELEASE-PROCESS.md`
- Update or remove `REPO-RELATIONSHIP.md`
- Remove GitHub workflows: `starter-release.yml`, `starter-verify.yml`
- Remove `starter_version` from `registry.json` and `manifest.json`
- Remove BATS tests: `tests/tools/starter-release.bats`
- Archive the-agency-starter GitHub repo — update README to redirect followers to the-agency as the new home

### 4.3 Starter Packs as Skills

Starter packs evolve into platform knowledge that feeds a generalized `/environment-setup` skill:

- **Pattern:** Assess → Do → Guide → Verify
- The skill detects the project state, does what it can autonomously, guides the user through human-required steps (account creation, OAuth, DNS), and verifies the result
- Current `claude/starter-packs/{name}/` content becomes one input to this knowledge
- Platform setup work is in progress with the DevEx agent — will be passed over

### 4.4 agency update

- Real implementation behind `agency update` (replaces deprecated shim)
- Syncs framework files from source repo
- Merges settings via `settings-merge` (array union, preserves local config)
- Prepends update summary to existing `handoff.md` (doesn't replace)
- Writes handoff block with `type: agency-update`
- First captain session picks up the update context and runs verification
- Always moves forward — no rollback, no version pinning

### 4.5 Onboarding

- `agency init` creates `usr/{principal}/captain/handoff.md` with `type: agency-bootstrap`
- Bootstrap handoff content triggers onboarding behavior on first `claude` launch
- Onboarding is automatic but user can break out at any time
- Onboarding skill verifies install, walks through first steps
- When complete, normal handoff lifecycle takes over (bootstrap rotates to history)

### 4.6 Handoff Type Support

- Update handoff tool and `/handoff` skill to support `type` frontmatter
- Types for now: `session`, `agency-bootstrap`
- `agency-update` type added when agency update is built
- Additional types (agent-bootstrap, etc.) come later

## 5. Non-Functional Requirements

- **Platform support:** macOS first-class, Linux next, Windows/PowerShell KIV (keep in view)
- **Idempotency:** `agency init` on an already-initialized project warns and exits
- **No network dependency at runtime:** `agency init` and `agency update` work from a local clone
- **Claude Code 2.1.88+** — minimum version, floats up with new releases

## 6. Constraints

- **Claude Code 2.1.88+** (floats up with releases)
- **Scripts can be any language** — bash, python, TypeScript, whatever fits
- **macOS first-class, Linux next, Windows/PowerShell KIV**
- **Declared dependencies** — manifest with check-and-guide pattern (assess what's installed, tell user what's missing, give install command)
- **`test/test-agency-project/`** stays as a test fixture

## 7. Success Criteria

- `agency init` on a bare `git init` + `claude init` repo produces a working Agency project
- `agency update` syncs to latest, prepends to handoff, first session runs verification
- Zero references to `the-agency-starter` in framework code (historical records excluded)
- Starter packs evolved into platform knowledge for `/environment-setup`
- Starter-specific tools, docs, workflows, and tests removed
- Single `agency` script replaces all `agency-*` tools
- Onboarding skill triggers automatically on first launch post-init
- All BATS tests pass
- Platform setup work from DevEx agent integrated

## 8. Non-Goals

- No version pinning, rollback, or downgrade — always forward
- No non-git project support
- No starter pack dependency resolution ("react-app requires node-base")

## 9. Open Questions

1. **`/environment-setup` UX and architecture** — deferred to platform setup work with DevEx agent
