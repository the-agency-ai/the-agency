# Plan: Agent Workspace & Bootstrap Quality

**Date:** 2026-04-03
**Principal:** jordan
**Agent:** the-agency/jordan/captain
**PVR:** `agent-workspace-pvr-20260403.md`
**A&D:** `agent-workspace-ad-20260403.md`
**Status:** Draft

## Dependency Graph

```
Phase 1 (agent-create fixes) ──────┐
                                    │
Phase 2 (workstream-create) ────────┤ Core scaffolding
                                    │
Phase 3 (script discipline) ────────┘
                                    
Phase 4 (permissions + sync) ──────── Enablers

Phase 5 (tests) ───────────────────── Verification
```

Phases 1-2 are sequential (workstream-create depends on agent-create). Phase 3 is independent. Phase 4 is independent. Phase 5 depends on all prior phases.

---

## Phase 1: agent-create Modernization

Fix the tool that scaffolds agent workspaces. This is the single write path for registrations and workspace directories (A&D 2.1, MAR D3).

### 1.1: Fix Stale Paths

- Replace `claude/principals/*/` → `usr/{principal}/` in seed auto-detection (line ~275)
- Replace `claude/principals/*/` → `usr/{principal}/` in any other path references
- Remove `myclaude` reference from success output
- Source `_path-resolve` for `_validate_name` and path resolution

**Verify:** `grep -r 'claude/principals' claude/tools/agent-create` returns zero.

### 1.2: Scaffold tools/, tmp/, Bootstrap Handoff

- After creating agent registration, ensure `usr/{principal}/{project}/tools/` exists
- Ensure `usr/{principal}/{project}/tmp/` exists with `.gitignore` (`*` / `!.gitignore`)
- Write `usr/{principal}/{project}/{agent}-handoff.md` with TODO template (A&D 2.1 template)
- Validate agent name against slug regex (`^[a-z0-9][a-z0-9_-]{0,31}$`) before any path construction (MAR S2)
- Sanitize interpolation values: strip newlines and bare `---` sequences (MAR S1)

**Verify:** Run agent-create in test fixture, assert tools/, tmp/, {agent}-handoff.md exist.

### 1.3: Update Registration Template

- Registration template includes startup directives: read own handoff, read peers' handoffs, read role, act on startup
- Add TODO guard: if handoff contains `TODO:` placeholders, agent reports "Bootstrap handoff incomplete" (MAR D4)
- Registration uses the pattern from mdpal-cli.md as reference

**Verify:** Generated registration contains "read" directives and TODO guard.

---

## Phase 2: workstream-create Skill Upgrade

Upgrade the stub skill to a two-phase scaffold + guide flow (A&D 2.2, DD2).

### 2.1: Phase A — Deterministic Scaffold

- Parse args: `--name`, `--agent name[,class]` (repeatable), `--description`, `--worktree`, `--scaffold-only`
- Create `claude/workstreams/{name}/` (seeds/, reviews/, history/, KNOWLEDGE.md)
- Create `usr/{principal}/{name}/` (code-reviews/, dispatches/, transcripts/, history/, seeds/, tools/, tmp/)
- Call `agent-create` for each `--agent` flag (NOT inline registration writes — agent-create is the single path per MAR D3)
- Optionally create worktree (`--worktree` flag calls `worktree-create`)
- Commit scaffold

**Verify:** Scaffold creates all expected directories. agent-create is invoked (not bypassed). Registration files exist in `.claude/agents/`.

### 2.2: Phase B — Captain Instruction Output

- After scaffold, output a structured instruction to the captain:
  ```
  Scaffold complete for workstream '{name}' with agents: {agent1}, {agent2}.
  
  Bootstrap handoffs contain TODO placeholders. Run /discuss with these items:
  1. What is this workstream?
  2. What does {agent1} own?
  3. What does {agent2} own?
  4. What seeds do we have?
  5. What's the first action for each agent?
  
  Then update each {agent}-handoff.md with the resolved content.
  ```
- `--scaffold-only` skips this output
- Captain runs `/discuss`, fills in handoffs, commits

**Verify:** Skill output contains `/discuss` instruction with correct agent names. `--scaffold-only` suppresses it.

---

## Phase 3: Script Discipline

Hookify rule + telemetry for script persistence (A&D 2.5, 2.6).

### 3.1: Hookify Rule — Script Persistence Nudge

Create `claude/hookify/hookify.warn-script-persistence.md`:
- Triggers on `Write` tool calls to `*.sh` or `*.py` outside `usr/*/tools/` and `claude/tools/`
- Warns: save to `usr/{principal}/{project}/tools/` with `# Why did I write this script:` header
- Explicitly documents scope limitations (no extension, heredoc, tmp — it's a nudge, not a gate per MAR S4)
- Ends with the attack kittens trademark

**Verify:** Rule file exists, contains correct matcher pattern, documents limitations.

### 3.2: Telemetry — Agent Script Detection

Modify `claude/hooks/tool-telemetry.sh`:
- In the Bash branch, check if command path matches `usr/*/tools/*` or `*/usr/*/tools/*`
- If match, add `"source": "agent-script", "script_path": "<relative>"` to JSONL entry
- ~10 lines of change

**Verify:** Run a script from `usr/test/project/tools/test.sh`, check telemetry JSONL contains `agent-script` source.

---

## Phase 4: Permissions & Worktree Sync

Enable standard operations without prompts (A&D 2.7, 2.4).

### 4.1: Permission Additions

Update `claude/config/settings-template.json`:
- Add `Bash(unzip -d usr/*:*)`
- Add `Bash(tar -xf * -C usr/*:*)`
- Verify Read/Glob permissions present: `usr/**`, `claude/**`, `.claude/**`

Update `.claude/settings.json` (this repo):
- Same additions

Run `settings-merge` to propagate.

**Verify:** `jq '.permissions.allow' .claude/settings.json | grep unzip` shows scoped permission.

### 4.2: Unzip Safety Script

Create `claude/tools/safe-extract`:
- Wrapper around unzip/tar that validates archive contents first
- `unzip -l <archive>` piped through `grep '\.\.'` — reject if `../` found (MAR S3)
- Only extracts to `usr/` paths
- Pre-approved in settings.json: `Bash(./claude/tools/safe-extract*)`

**Verify:** Archive with `../` entry is rejected. Clean archive extracts to `usr/*/seeds/`.

### 4.3: Worktree Sync Enhancement

Update `.claude/skills/worktree-sync/SKILL.md`:
- After merge, log diff stats for `claude/`, `.claude/`, `CLAUDE.md` changes
- Mention checking for new dispatches after sync
- Verify `claude/tools/worktree-sync` exists and has `_log-helper` integration

Add permission if missing: `Bash(./claude/tools/worktree-sync*)` to settings-template.json.

**Verify:** Skill mentions dispatch check. Tool permission present.

---

## Phase 5: Tests & Verification

All tests for the work done in Phases 1-4.

### 5.1: agent-create Tests

Create or extend `tests/tools/agent-create.bats`:
- agent-create scaffolds `tools/`, `tmp/`, `.gitignore` in sandbox
- agent-create writes `{agent}-handoff.md` with required frontmatter
- agent-create validates agent name (rejects invalid, path traversal)
- agent-create registration contains startup read directives
- agent-create registration contains TODO guard
- No `claude/principals/` references in tool output

### 5.2: session-handoff Tests

Create `tests/tools/session-handoff.bats`:
- `main` branch resolves to captain directory
- `master` branch resolves to captain directory
- Feature branch resolves to branch-slug directory
- `agency-bootstrap` type gets bootstrap context prefix
- `agency-update` type gets update context prefix
- Default type passes through handoff content

### 5.3: Integration Test — Bootstrap Flow

Add to `tests/tools/agent-bootstrap.bats`:
- Init fixture repo → run agent-create → assert registration + handoff exist
- Invoke session-handoff.sh with fixture → assert systemMessage contains handoff content
- Handoff with TODO placeholders → assert agent would detect incomplete bootstrap

### 5.4: settings-merge Permission Assertions

Extend `tests/tools/settings-merge.bats`:
- After merge, `Bash(unzip -d usr/*:*)` present
- `Bash(unzip:*)` wildcard NOT present
- `Read(usr/**)` present
- `Glob(usr/**)` present

### 5.5: safe-extract Tests

Create `tests/tools/safe-extract.bats`:
- Clean archive extracts to `usr/` path
- Archive with `../` entry rejected
- Archive targeting non-usr/ path rejected

### 5.6: Final Verification

Full sweep:
- `bats tests/tools/` — all tests pass
- `bash -n` on all modified shell tools
- `jq . .claude/settings.json > /dev/null` — valid JSON
- `jq . claude/config/settings-template.json > /dev/null` — valid JSON
- No `claude/principals/` references in framework code
- All hookify rules end with attack kittens trademark

---

## Phase Summary

| Phase | What | Effort | Depends On |
|-------|------|--------|------------|
| 1 | agent-create modernization | Medium | — |
| 2 | workstream-create upgrade | Medium | Phase 1 |
| 3 | Script discipline (hookify + telemetry) | Low | — |
| 4 | Permissions + worktree sync + safe-extract | Low | — |
| 5 | Tests & verification | Medium | Phases 1-4 |
