---
type: architecture-design
project: git-safe
workstream: devex
date: 2026-04-14
status: draft
pvr: claude/workstreams/devex/git-safe-pvr-20260414.md
---

# A&D: git-safe + git-captain + git-safe-commit rename

## 1. Architecture Overview

Three components form the git-safe family:

```
┌─────────────────────────────────────────────────────┐
│                 Agent / Captain                       │
│                                                       │
│  Bash("git status")  ──→  BLOCKED by hookify          │
│  Bash("git push")    ──→  BLOCKED by hookify          │
│                                                       │
│  /git-safe status    ──→  git-safe tool ──→ git       │
│  /git-safe add X     ──→  git-safe tool ──→ git       │
│  /git-captain push   ──→  git-captain tool ──→ git    │
│  /git-safe-commit    ──→  git-safe-commit tool ──→ git│
│                                                       │
│  /worktree-sync      ──→  (internal git via tool)     │
│  /sync, /sync-all    ──→  (internal git via tool)     │
└─────────────────────────────────────────────────────┘
```

**Key design decision:** Hookify fires on PreToolUse (Bash tool invocations from agents). It does NOT fire on git commands inside framework tools. This means framework tools (worktree-sync, git-safe, git-captain) can call raw git internally — the block only prevents agents from bypassing the tools.

## 2. Tool Design

### DD-1: git-safe (claude/tools/git-safe)

Bash script with subcommands. Passthrough wrapper for safe git operations.

```
git-safe status [args]         → git status [args]
git-safe log [args]            → git log [args]
git-safe diff [args]           → git diff [args]
git-safe branch                → git branch --show-current
git-safe add <file> [file...]  → git add <file> [file...]
git-safe merge-from-master     → git merge main (or master)
git-safe --help                → usage
git-safe --version             → version
```

Guards:
- `git-safe add` BLOCKS `-A`, `--all`, `.` — requires explicit file paths
- `git-safe merge-from-master` auto-detects main vs master branch name
- Read-only subcommands pass args through directly (thin wrapper)

### DD-2: git-captain (claude/tools/git-captain)

Bash script with subcommands. Captain-only git operations.

```
git-captain merge-to-master <branch>  → git merge <branch> --no-ff (on main)
git-captain checkout-branch <name>    → git checkout -b <name>
git-captain push [args]               → git push [args]
git-captain fetch                     → git fetch origin
git-captain tag <name> [-m <msg>]     → git tag -a <name> [-m <msg>]
git-captain --help                    → usage
git-captain --version                 → version
```

Guards:
- `merge-to-master` verifies current branch IS main/master before merging
- `checkout-branch` validates branch name format
- `push` blocks push to main without --force-with-lease (existing hookify guard, now in-tool)
- No role-checking in the tool itself — hookify blocks agents from invoking it

### DD-3: git-safe-commit (renamed from git-safe-commit)

Existing tool at `claude/tools/git-safe-commit` → renamed to `claude/tools/git-safe-commit`.
Existing skill at `.claude/skills/git-safe-commit/` → renamed to `.claude/skills/git-safe-commit/`.

No functional changes — pure rename for naming consistency.

## 3. Hookify Rules

### DD-4: New rule — hookify.raw-git-block.md

```yaml
name: raw-git-block
enabled: true
event: bash
pattern: ^git\s+
exclude_pattern: git-safe|git-captain|git-safe-commit
action: block
```

Message:
```
BLOCKED: Raw git is not allowed. Use the git-safe family:
- /git-safe status, log, diff, branch, add, merge-from-master
- /git-safe-commit (commit with QG awareness)
- /git-captain (captain only: push, fetch, tag, merge-to-master, checkout-branch)
```

This single rule replaces these existing rules:
- `hookify.git-safe-commit-block.md` (→ subsumed)
- `hookify.git-add-and-commit-block.md` (→ subsumed)
- `hookify.raw-rebase-block.md` (→ subsumed)
- `hookify.reset-to-origin-block.md` (→ subsumed)
- `hookify.force-push-main-block.md` (→ subsumed)
- `hookify.force-push-any-block.md` (→ subsumed)
- `hookify.no-push-main.md` (→ subsumed)
- `hookify.destructive-git-warn.md` (→ subsumed)
- `hookify.raw-git-merge-master-block.md` (→ subsumed)

All 9 replaced by one rule: block ALL raw git.

### DD-5: New rule — hookify.git-captain-agent-block.md

```yaml
name: git-captain-agent-block
enabled: true
event: bash
pattern: git-captain
action: block
```

Message: "BLOCKED: git-captain is captain-only. Agents use /git-safe for git operations."

Only applies to agent sessions (not captain). Detection: `agent-identity` resolves the current agent — if not captain, block.

**Design question resolved:** Hookify rules don't currently have role-based filtering. Simplest approach: git-captain is NOT in agent tool lists in settings.json. Agents can't invoke it because it's not in their allowed tools. The hookify rule is belt-and-suspenders.

## 4. Skills

### DD-6: /git-safe skill

`.claude/skills/git-safe/SKILL.md` — discovery for agent git operations. Lists all subcommands with examples. Ref-injector wires it to inject GIT-MERGE-NOT-REBASE.md for merge-from-master.

### DD-7: /git-captain skill  

`.claude/skills/git-captain/SKILL.md` — discovery for captain git operations. Only available to captain. Lists all subcommands.

### DD-8: /git-safe-commit skill (rename)

`.claude/skills/git-safe-commit/SKILL.md` — renamed from git-safe-commit. Same content, updated name references.

## 5. Existing Tool Migration

Tools that currently use raw git must call git-safe/git-captain internally:

| Tool | Current raw git | Migrates to |
|------|----------------|-------------|
| `worktree-sync` | `git merge main`, `git stash` | Keep raw (internal — hookify doesn't fire) |
| `git-safe-commit` (née git-safe-commit) | `git add`, `git commit` | Keep raw (internal) |
| `collaboration` | `git add`, `git commit`, `git push` | Keep raw (internal) |
| `upstream-port` | `git checkout`, `git add`, `git commit`, `git push` | Keep raw (internal) |
| `pr-build` | `git checkout -b`, `git merge --no-ff` | Keep raw (internal) |
| `nit-add` | `git add`, `git commit` | Keep raw (internal) |
| `lib/_agency-init` | `git add`, `git commit` | Keep raw (internal) |

**Key insight:** Framework tools don't need migration. Hookify fires on Bash tool calls from agents, not on subprocesses inside framework tools. The tools already use git correctly — they just call it directly. The protection is at the agent boundary, not inside tools.

## 6. Rename Scope (git-safe-commit → git-safe-commit)

### Files to rename/move
- `claude/tools/git-safe-commit` → `claude/tools/git-safe-commit`
- `.claude/skills/git-safe-commit/SKILL.md` → `.claude/skills/git-safe-commit/SKILL.md`
- `claude/hookify/hookify.git-safe-commit-block.md` → removed (subsumed by raw-git-block)

### References to update (181 files, 100+ occurrences)
Categories:
- **Skills:** 11 files reference `/git-safe-commit`
- **Hookify:** 3 rules reference git-safe-commit
- **Tools:** 6 tools reference git-safe-commit
- **Hooks:** ref-injector.sh has `git-safe-commit|ship)` case
- **Config:** enforcement.yaml (3 entries), agency.yaml (1)
- **Docs:** 20+ reference docs
- **Tests:** git-operations.bats (40+ test references)
- **READMEs:** 5 files
- **CLAUDE.md:** 2 references in bootloader
- **Templates:** 2 files
- **Workstream docs:** 15+ files (plans, A&Ds, seeds, reviews)

### Rename strategy
1. `git mv` for file/directory renames
2. `sed` find-and-replace for content references
3. Three patterns to replace:
   - `/git-safe-commit` → `/git-safe-commit` (skill invocations)
   - `claude/tools/git-safe-commit` → `claude/tools/git-safe-commit` (tool paths)
   - `git-safe-commit` → `git-safe-commit` (bare name references, careful not to match `raw git commit`)

## 7. Trade-offs

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Single tool vs two tools | Two (git-safe + git-captain) | Single with role checks | Cleaner separation, no role-checking logic |
| Wrap reads too | Yes — all git wrapped | Reads stay raw | Principal decision: zero raw git |
| New hookify rule approach | One catch-all rule | Keep individual rules | Simpler, no gaps |
| Internal tool migration | Don't migrate | Migrate tools to call git-safe | Hookify only fires on agent Bash calls, not internal subprocesses |

## 8. Failure Modes

- **Agent tries raw git** → hookify blocks with actionable message pointing to git-safe
- **Agent tries git-captain** → not in allowed tools + hookify belt-and-suspenders
- **git-safe add -A** → blocked by the tool itself with message about explicit paths
- **git-safe merge-from-master on main** → safe (merges main into main = no-op)
- **Rename missed a reference** → old `/git-safe-commit` invocation fails (skill not found) with clear error

## 9. Testing Strategy

- **git-safe:** BATS tests for each subcommand (status, log, diff, branch, add, merge-from-master)
- **git-captain:** BATS tests for each subcommand
- **git-safe-commit:** Existing git-operations.bats tests, renamed
- **Hookify:** Test that raw git is blocked (modify existing hookify tests)
- **Rename verification:** grep for any remaining `"/git-safe-commit"` or `tools/git-safe-commit` references

## 10. A&D Completeness

```
1. Architecture Overview     ✓ Complete
2. Tool Design               ✓ Complete (DD-1, DD-2, DD-3)
3. Hookify Rules             ✓ Complete (DD-4, DD-5)
4. Skills                    ✓ Complete (DD-6, DD-7, DD-8)
5. Migration Strategy        ✓ Complete (no migration needed)
6. Rename Scope              ✓ Complete (181 files mapped)
7. Trade-offs                ✓ Complete
8. Failure Modes             ✓ Complete
9. Testing Strategy          ✓ Complete
10. Open Questions           0 remaining

Score: 10/10 complete
```
