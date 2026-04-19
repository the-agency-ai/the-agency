# Plan: Agent Workspace & Bootstrap Quality

**Date:** 2026-04-03
**Principal:** jordan
**Agent:** the-agency/jordan/captain
**PVR:** `agent-workspace-pvr-20260403.md`
**A&D:** `agent-workspace-ad-20260403.md`
**Status:** MAR Complete — Final

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

Phases 1-2 are sequential (workstream-create depends on agent-create). Phase 3 is independent but has a soft dependency on Phase 1's path layout (MAR D4 — validate patterns against final paths before commit). Phase 4 is independent. Phase 5 depends on all prior phases.

---

## Phase 1: agent-create Modernization

Fix the tool that scaffolds agent workspaces. This is the single write path for registrations and workspace directories (A&D 2.1, MAR D3).

### 1.1: Fix Stale Paths and Principal Resolution

- Replace `claude/principals/*/` → `usr/{principal}/` in seed auto-detection (line ~275)
- Replace `claude/principals/*/` → `usr/{principal}/` in any other path references
- Remove `myclaude` reference from success output
- Source `_path-resolve` for `_validate_name` and path resolution
- **MAR D5:** Resolve principal via `_path-resolve` using `$USER` → agency.yaml `name` field (same pattern as workstream-create Step 2). Do NOT use `$USER` raw as a path component.

**Verify:** `grep -r 'claude/principals' agency/tools/agent-create` returns zero. Principal resolved from agency.yaml, not `$USER`.

### 1.2: Scaffold tools/, tmp/, Bootstrap Handoff

- After creating agent registration, ensure `usr/{principal}/{project}/tools/` exists
- Ensure `usr/{principal}/{project}/tmp/` exists with `.gitignore` (`*` / `!.gitignore`)
- Write `usr/{principal}/{project}/{agent}-handoff.md` with TODO template (A&D 2.1 template)
- Validate agent name against slug regex (`^[a-z0-9][a-z0-9_-]{0,31}$`) before any path construction (MAR S2)
- Sanitize ALL interpolation values: strip newlines and bare `---` sequences from `{agent}`, `{principal}`, `{workstream}`, `{repo}` (MAR S1 — extended per plan MAR)

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
- **MAR D1:** Replace current Step 5 wholesale (it writes registrations inline). Remove `handoffs/` subdirectory convention — use flat `{agent}-handoff.md` files instead.
- Optionally create worktree (`--worktree` flag calls `worktree-create`)
- Commit scaffold

**Verify:** Scaffold creates all expected directories. agent-create is invoked (not bypassed). Registration files exist in `.claude/agents/`. No `handoffs/` directory created.

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

Create `agency/hookify/hookify.warn-script-persistence.md`:
- Triggers on `Write` tool calls to `*.sh` or `*.py` outside `usr/*/tools/` and `claude/tools/`
- Warns: save to `usr/{principal}/{project}/tools/` with `# Why did I write this script:` header
- Explicitly documents scope limitations (no extension, heredoc, tmp — it's a nudge, not a gate per MAR S4)
- Ends with the attack kittens trademark

**Verify:** Rule file exists, contains correct matcher pattern, documents limitations.

### 3.2: Telemetry — Agent Script Detection

Modify `agency/hooks/tool-telemetry.sh`:
- In the Bash branch, check if command path matches `usr/*/tools/*` or `*/usr/*/tools/*`
- If match, add `"source": "agent-script", "script_path": "<relative>"` to JSONL entry
- ~10 lines of change

**Verify:** Run a script from `usr/test/project/tools/test.sh`, check telemetry JSONL contains `agent-script` source.

---

## Phase 4: Permissions & Worktree Sync

Enable standard operations without prompts (A&D 2.7, 2.4).

### 4.1: Permission Additions

Update `agency/config/settings-template.json`:
- Add `Bash(unzip -d usr/*:*)`
- Add `Bash(tar -xf * -C usr/*:*)`
- Verify Read/Glob permissions present: `usr/**`, `claude/**`, `.claude/**`

Update `.claude/settings.json` (this repo):
- Same additions

Run `settings-merge` to propagate.

**Verify:** `jq '.permissions.allow' .claude/settings.json | grep unzip` shows scoped permission.

### 4.2: Unzip Safety Script

Create `agency/tools/safe-extract`:
- **Unzip only** for now (MAR S3 — tar symlink attacks need separate validation, deferred)
- `unzip -l <archive>` piped through `grep '\.\.'` — reject if `../` found in any entry path
- Also check for symlink entries in zip (`unzip -l` output, flag entries with `l` attribute)
- Only extracts to `usr/` paths
- Pre-approved in settings.json: `Bash(./agency/tools/safe-extract*)`
- Remove `Bash(tar -xf * -C usr/*:*)` from permissions until tar-specific validation is written

**Verify:** Archive with `../` entry is rejected. Archive with symlink entry is rejected. Clean archive extracts to `usr/*/seeds/`.

### 4.3: Worktree Sync Enhancement

Update `.claude/skills/worktree-sync/SKILL.md`:
- After merge, log diff stats for `claude/`, `.claude/`, `CLAUDE.md` changes
- Mention checking for new dispatches after sync
- Verify `agency/tools/worktree-sync` exists and has `_log-helper` integration

Add permission if missing: `Bash(./agency/tools/worktree-sync*)` to settings-template.json.

**Verify:** Skill mentions dispatch check. Tool permission present.

---

## Phase 5: Tests & Verification

All tests for the work done in Phases 1-4.

### 5.1: agent-create Tests

Create or extend `tests/tools/agent-create.bats`:
- agent-create scaffolds `tools/`, `tmp/`, `.gitignore` in sandbox
- agent-create writes `{agent}-handoff.md` with required frontmatter
- agent-create validates agent name — rejection tests for each class (MAR T1):
  - 32+ character name → rejected
  - Uppercase name → rejected
  - Path traversal (`../evil`) → rejected
  - Reserved names (`system`, `shared`) → rejected
- agent-create registration contains startup read directives
- agent-create registration contains TODO guard
- agent-create resolves principal from agency.yaml, not raw `$USER` (MAR D5)
- No `claude/principals/` references in tool output

**Fixture:** BATS fixture must have a valid git repo with agency.yaml initialized before agent-create runs.

### 5.2: session-handoff Tests

Create `tests/tools/session-handoff.bats`:
- **Test the hook script directly** (`agency/hooks/session-handoff.sh`), not the handoff tool (MAR T2)
- Stub git environment for branch detection
- `main` branch resolves to captain directory
- `master` branch resolves to captain directory
- Feature branch resolves to branch-slug directory
- `agency-bootstrap` type gets bootstrap context prefix
- `agency-update` type gets update context prefix
- Default type passes through handoff content

### 5.3: Bootstrap Flow Tests (split per MAR T3)

**5.3a: File-level assertions (BATS)** — `tests/tools/agent-bootstrap.bats`:
- Init fixture repo → run agent-create → assert registration + handoff files exist
- Registration file contains startup read directives
- Registration file contains TODO guard pattern
- Handoff file contains required frontmatter fields
- Invoke `session-handoff.sh` with fixture → assert JSON output is non-empty

**5.3b: Harness injection (manual smoke test)** — documented, not automated:
- Launch claude in fixture with bootstrap handoff → verify agent reads handoff without prompting
- Cannot be tested in BATS (harness behavior not observable from shell)

### 5.4: settings-merge Permission Assertions

Extend `tests/tools/settings-merge.bats`:
- After merge, `Bash(unzip -d usr/*:*)` present
- `Bash(unzip:*)` wildcard NOT present
- `Read(usr/**)` present
- `Glob(usr/**)` present
- **Idempotency** (MAR T5): merge twice, assert unzip permission appears exactly once (no duplication)

### 5.5: safe-extract Tests

Create `tests/tools/safe-extract.bats`:
- Clean archive extracts to `usr/` path
- Archive with `../` entry rejected
- Archive with symlink entry rejected (MAR S3 — plan MAR)
- Archive targeting non-usr/ path rejected

### 5.6: worktree-sync Tests (MAR D3/T4)

Add to existing `tests/tools/worktree.bats` or create new:
- `agency/tools/worktree-sync` exists and is executable
- `--dry-run` exits 0 and makes no git state changes
- Skill file mentions dispatch check after sync

### 5.7: workstream-create Tests

Create `tests/tools/workstream-create.bats`:
- `--scaffold-only` flag: no `/discuss` instruction in output, scaffold files exist (MAR T-new)
- Without `--scaffold-only`: output contains `/discuss` instruction with agent names
- Scaffold calls agent-create (registrations exist in `.claude/agents/`)
- No `handoffs/` subdirectory created (MAR D1)

### 5.8: Final Verification

Full sweep:
- `bats tests/tools/` — all tests pass
- `bash -n` on all modified shell tools
- `jq . .claude/settings.json > /dev/null` — valid JSON
- `jq . agency/config/settings-template.json > /dev/null` — valid JSON
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

---

## Plan MAR Findings (2026-04-03)

### Security

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| S1 | Low | Sanitize all interpolated fields, not just agent | Extended in 1.2 to cover {workstream}, {principal}, {repo} |
| S2 | Medium | Path traversal via agent name — adequately addressed | Confirmed slug regex excludes `/`, `.`, `..` |
| S3 | Medium | safe-extract: tar symlink attacks not covered | Restricted to unzip only. Tar deferred. Added symlink check. |
| S-new | Low | Phase B instruction should include full paths | Added full `usr/{principal}/{name}/{agent}-handoff.md` to instruction |

### Design

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| D1 | High | workstream-create Step 5 must be replaced wholesale | Noted in 2.1 — replace, not append. Remove handoffs/ convention. |
| D2 | Medium | Hookify rule input format untestable | Document limitation. Defer test. |
| D3 | Medium | Phase 5 missing worktree-sync test | Added 5.6 |
| D4 | Low | Phase 3 soft-depends on Phase 1 paths | Noted in dependency graph |
| D5 | Low | agent-create principal resolution unspecified | Added to 1.1 — resolve via _path-resolve |

### Test Coverage

| ID | Severity | Finding | Resolution |
|----|----------|---------|------------|
| T1 | High | Name validation needs boundary tests | Added rejection classes to 5.1 |
| T2 | High | session-handoff tests must call hook, not tool | Noted in 5.2 |
| T3 | Medium | Integration test can't assert systemMessage in BATS | Split into 5.3a (BATS) and 5.3b (manual smoke) |
| T4 | Low | worktree-sync test absent | Added 5.6 |
| T5 | Medium | settings-merge idempotency untested | Added to 5.4 |
| T-new | — | --scaffold-only flag untested | Added 5.7 |
