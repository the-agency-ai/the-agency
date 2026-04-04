# A&D: Agent Workspace & Bootstrap Quality

**Date:** 2026-04-03
**Principal:** jordan
**Agent:** the-agency/jordan/captain
**PVR:** `agent-workspace-pvr-20260403.md`
**Status:** MAR Complete — Revised

## 1. Architecture Overview

This work upgrades existing tools — not a greenfield build. The core insight from DD1 is that **agent identity drives disambiguation**. Tools enforce naming conventions; agents self-select based on identity. No new infrastructure for agent discovery — the agent registration is the discovery mechanism.

```
Agent Registration (.claude/agents/{name}.md)
  ↓ directs startup reads
  ↓
Agent Identity (--agent flag)
  ↓ derives
  ↓
Workstream Assignment → Project Directory (usr/{principal}/{project}/)
  ↓ naming convention
  ↓
{agent}-handoff.md, {agent}-dispatch-*.md, dispatches/to: field
  ↓ tools enforce
  ↓
handoff tool, dispatch-create, workstream-create, agent-create
```

## 2. Component Designs

### 2.1 agent-create Updates (R1, R5)

**Current state:** `claude/tools/agent-create` (346 lines, v1.2.0). Scaffolds agent class directory and registration. Uses stale `claude/principals/` path. Does NOT scaffold `tools/` or `tmp/`.

**Changes:**

1. **Fix path:** `claude/principals/` → `usr/{principal}/` (use `_path-resolve`)
2. **Scaffold workspace dirs:** After creating registration, ensure `usr/{principal}/{project}/tools/` and `usr/{principal}/{project}/tmp/` exist (with `.gitignore` in `tmp/`)
3. **Write per-agent handoff template:** `usr/{principal}/{project}/{agent}-handoff.md` with TODO placeholders:

```markdown
# Handoff: {agent} — Bootstrap

---
type: agency-bootstrap
date: {date}
principal: {principal}
agent: {repo}/{principal}/{agent}
workstream: {workstream}
---

## Who You Are

TODO: What this agent owns and is responsible for.

## Your Workstream Peers

TODO: Who else works in this workstream, what they own.

## Current State

TODO: What's been done, what remains.

## Key Files

TODO: PVR, A&D, seeds, knowledge.

## Next Action

TODO: What to do first.
```

4. **Update registration template** to include startup directives (read handoff, read peers' handoffs, read role, act on startup)
5. **Remove stale references:** `myclaude`, `claude/principals/`

**Decision:** agent-create stays a tool (not a skill). The guided discussion (DD2) is the captain's job — the captain invokes `/agent-create` as part of the guided `/workstream-create` skill, or standalone when adding an agent to an existing workstream.

**MAR D3 resolution:** agent-create is the **single write path** for `.claude/agents/` registrations and workspace scaffolding. workstream-create calls agent-create for each `--agent` flag — it does NOT write registrations directly.

**MAR D5 resolution:** Fix stale `claude/principals/` path → `usr/{principal}/`. Remove myclaude reference. These are must-fix during implementation.

**MAR S2 resolution:** Validate `--agent` name against slug regex (`^[a-z0-9][a-z0-9_-]{0,31}$`) before any path construction. Hard-fail on invalid names.

### 2.2 workstream-create Skill Upgrade (R1, R4, R5, DD2)

**Current state:** `.claude/skills/workstream-create/SKILL.md` (123 lines). Creates workstream dir, sandbox dir, agent registrations. Does NOT create worktrees, does NOT write bootstrap handoffs with substance, does NOT guide the principal.

**Design: Two-phase skill**

**Phase A — Scaffold (deterministic):**
1. Parse args: `--name`, `--agent name[,class]` (repeatable for multi-agent), `--description`
2. Call existing scaffold logic (workstream dir, sandbox dir, agent registrations)
3. Add: `tools/`, `tmp/` (with `.gitignore`), `seeds/`
4. For each agent: write `{agent}-handoff.md` template with TODOs
5. Optionally create worktree (`--worktree` flag, calls `worktree-create`)
6. Commit scaffold

**Phase B — Guide (interactive, DD2, revised per MAR D1):**

Phase A completes deterministically. The skill's final output instructs the captain:

> "Scaffold complete. Now run `/discuss` with these items to fill in the bootstrap handoffs:
> 1. What is this workstream?
> 2. What does {agent} own? (for each agent)
> 3. What seeds do we have?
> 4. What's the first action for {agent}?"

The captain invokes `/discuss` as a separate step — NOT a programmatic invocation from within the skill. This is honest about the execution model, testable, and doesn't silently degrade.

**MAR D4 resolution:** The agent registration template includes a guard: if the handoff contains `TODO:` placeholders, the agent reports "Bootstrap handoff incomplete — needs captain to run /discuss for workstream {name}" before proceeding. Fail loud, not silent.

**Key constraint:** `--scaffold-only` flag skips the Phase B instruction output (for automation and testing).

### 2.3 Handoff Tool Updates (R5, DD1)

**Current state:** `claude/tools/handoff` writes to `{project}/handoff.md`. Archives to `history/`.

**Changes:**

**MAR D2 resolution:** The handoff tool stays **branch-scoped** for the session lifecycle (write, archive, read). Bootstrap handoffs are a different concern — written once by agent-create at scaffold time. No `--agent` flag on the handoff tool.

Per-agent bootstrap handoffs (`{agent}-handoff.md`) are:
- **Written by:** agent-create (tool) during scaffolding
- **Populated by:** captain during Phase B guided discussion
- **Read by:** agent on startup (directed by registration)
- **Updated by:** agent via explicit Write tool call (not handoff tool)

This keeps the handoff tool simple and branch-scoped. Bootstrap handoffs don't need archive-rotate.

**No changes to session-handoff.sh hook.** Per DD1, the hook stays branch-scoped. Per-agent handoff reads are directed by the agent registration.

### 2.4 merge-main / worktree-sync (R6, DD3)

**Current state:** `.claude/skills/worktree-sync/SKILL.md` (43 lines) already wraps `claude/tools/worktree-sync`. Merges master, copies settings, runs sandbox-sync, reports changed files/dispatches/CLAUDE.md.

**Assessment:** This IS the merge-main capability. No new tool needed per D4.

**Changes:**

1. **Verify tool exists:** `claude/tools/worktree-sync` — confirm it works, has `_log-helper` integration
2. **Add permission:** `Bash(./claude/tools/worktree-sync*)` to settings-template.json (if not already)
3. **Enhance logging:** After merge, log diff stats for `claude/`, `.claude/`, `CLAUDE.md` to handoff (observability per DD3)
4. **Skill update:** Ensure worktree-sync skill mentions reading new dispatches after sync

**No blocking gate.** Defense in depth: QG+MAR on main and PR.

### 2.5 Script Discipline (R2, D3, S4)

**Enforcement strategy:** Detect positive behavior, not block negative.

**Components:**

1. **Hookify rule:** `hookify.warn-script-persistence.md` — on `Write` tool calls to `*.sh` or `*.py` files, if the path is NOT under `usr/*/tools/` or `claude/tools/`, warn:
   > "Scripts should be saved to `usr/{principal}/{project}/tools/` with a `# Why did I write this script:` header. See Script Discipline in CLAUDE-THEAGENCY.md."

   This catches the Write, not the inline Bash heredoc — but it's the best pre-execution signal available.

2. **Header convention enforcement:** tool-telemetry.sh (or a new post-Write hook) checks if scripts written to `usr/*/tools/` have the required header. Warn if missing.

3. **Integrity check (S4):** When an agent runs a script from `tools/`, the Bash hook can compare the file's current hash against the hash logged in the header comment. Warn on mismatch. Low-friction: warning, not block.

### 2.6 Ad-Hoc Tool Telemetry (R3)

**Current state:** `claude/hooks/tool-telemetry.sh` logs all tool invocations. For Bash, logs only the binary name (first token).

**Changes:**

1. In the Bash branch, check if the command path matches `usr/*/tools/*` or `*/usr/*/tools/*`
2. If match, add `"source": "agent-script", "script_path": "<relative path>"` to the JSONL entry
3. Periodic mining script (captain tool): scan telemetry JSONL for script paths that appear across multiple sessions → candidates for promotion to `claude/tools/`

**Minimal change** — ~10 lines in tool-telemetry.sh.

### 2.7 Permission Completeness (R7, S3)

**Changes to settings-template.json:**

```json
"Bash(unzip -d usr/*:*)",
"Bash(tar -xf * -C usr/*:*)"
```

**MAR S3 resolution:** Destination-flag scoping alone doesn't prevent zip slip (archives can embed `../` in entry paths). Two-step defense:
1. Restrict archive sourcing to `usr/*/tmp/` (downloaded archives land in scratch first)
2. Pre-extract validation: `unzip -l <archive> | grep '\.\.'` — reject if `../` found in any entry path
3. Document the validation requirement in the permission comment

No `Bash(unzip:*)` or `Bash(unzip -d ./*:*)` wildcard.

Also verify these are present (added earlier this session):
```json
"Read(usr/**)",
"Read(claude/**)",
"Read(.claude/**)",
"Glob(usr/**)",
"Glob(claude/**)",
"Glob(.claude/**)"
```

### 2.8 Session-Handoff Hook — No Changes (DD1)

The hook stays branch-scoped. It maps branch slug → project directory → `handoff.md`. Per DD1, per-agent handoff discovery is the agent registration's responsibility, not the hook's.

The `main`/`master` → `captain` fix already shipped this session.

## 3. What's NOT In Scope

- **R8 (/ command audit):** P3, separate work item
- **R9 (transcript review):** P3, captain does this asynchronously
- **New dispatch tools:** Flagged separately (flag #11 — dispatch read/list across worktrees)
- **Cross-repo collaboration tooling:** Addressed by existing `_address-parse` + dispatch system
- **`$CLAUDE_AGENT` environment variable:** Not available in hooks. Not needed per DD1.

## 4. Risk Areas

1. **agent-create path migration** (`claude/principals/` → `usr/`): May break projects on old paths. Need backward-compat check or migration warning.
2. **workstream-create Phase B (guided):** `/discuss` invocation from within a skill is untested. May need the skill to explicitly hand off to `/discuss` rather than invoking it programmatically.
3. **Hookify rule for script persistence:** Write tool calls don't always include the full path in a predictable format. May need to parse the `file_path` parameter from hook input.
4. **Telemetry JSONL size:** Adding script paths to every Bash invocation increases log volume. Mitigated: only when path matches `usr/*/tools/*`.

## 5. Files to Modify

| File | Change | Section |
|------|--------|---------|
| `claude/tools/agent-create` | Fix paths, scaffold tools/tmp, handoff template, registration template | 2.1 |
| `.claude/skills/workstream-create/SKILL.md` | Two-phase: scaffold + guided discussion | 2.2 |
| `claude/tools/handoff` | `--agent` flag for per-agent handoffs | 2.3 |
| `.claude/skills/worktree-sync/SKILL.md` | Enhanced logging, dispatch mention | 2.4 |
| `claude/tools/worktree-sync` | Post-merge diff logging (if tool exists) | 2.4 |
| `claude/hookify/hookify.warn-script-persistence.md` | NEW — warn on scripts not saved to tools/ | 2.5 |
| `claude/hooks/tool-telemetry.sh` | Detect `usr/*/tools/*` runs, add source field | 2.6 |
| `claude/config/settings-template.json` | Add unzip/tar permissions scoped to usr/ | 2.7 |
| `.claude/settings.json` | Same permission additions | 2.7 |

## 6. A&D MAR Findings (2026-04-03)

### Security (S1-S4)

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| S1 | Low | YAML structural injection via unsanitized interpolation | Sanitize name fields — strip newlines, bare `---`. Inline in 2.1. |
| S2 | Medium | Path traversal via `--agent` on agent-create | Validate slug regex before path construction. Inline in 2.1. |
| S3 | Medium | Zip slip not prevented by destination-flag scoping | Pre-extract `unzip -l` path check + restrict sourcing to `usr/*/tmp/`. Inline in 2.7. |
| S4 | Low | Hookify rule has trivial bypass (no extension, heredoc, tmp) | Document as nudge not gate. Pair with telemetry. Inline in 2.5. |

### Design (D1-D5)

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| D1 | High | Phase B `/discuss` invocation from skill is unproven | Reframed: skill outputs instruction, captain invokes separately. Inline in 2.2. |
| D2 | Medium | `--agent` flag mixes two resolution models in handoff tool | Dropped. Bootstrap handoffs written by agent-create, not handoff tool. Inline in 2.3. |
| D3 | Medium | agent-create / workstream-create overlapping scope | agent-create is single write path. workstream-create calls it. Inline in 2.1. |
| D4 | Low | TODO handoffs fail silently if Phase B skipped | Registration template detects TODO placeholders, reports to captain. Inline in 2.2. |
| D5 | Low | agent-create stale paths (claude/principals/, myclaude) | Must-fix during implementation. Inline in 2.1. |

### Test Coverage (T1-T5)

| ID | Severity | Finding | Test Needed |
|----|----------|---------|-------------|
| T1 | High | No tests for tools/tmp scaffolding | BATS: agent-create scaffolds tools/, tmp/, .gitignore, {agent}-handoff.md |
| T2 | High | No tests for session-handoff branch→captain | BATS: main→captain mapping, type-aware injection |
| T3 | Medium | No integration test for init→scaffold→startup | BATS: init fixture, agent-create, assert registration + handoff discoverable |
| T4 | Low | No merge-main/worktree-sync test | BATS: tool exists, --dry-run, post-merge logging |
| T5 | Medium | No permission assertions in settings-merge | BATS: assert unzip scoped present, wildcard absent |
