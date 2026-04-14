---
type: pvr
project: git-safe
workstream: devex
date: 2026-04-14
status: draft
seeds:
  - dispatch #238 (git-safe seed)
  - dispatch #239 (correction: two tools)
  - dispatch #240 (correction: ALL git wrapped)
---

# PVR: git-safe + git-captain — Wrapped Git Operations

## 1. Problem Statement

Agents use raw git commands today. Only `git commit` and `git rebase` are blocked by hookify. All other operations — including destructive ones like `git reset --soft`, `git checkout`, `git push` — are unguarded. This caused a data-loss incident (Day 35: agent ran `git reset --soft` destroying 35 commits of history, recovered only via reflog).

**For whom:** All agents and captain sessions in TheAgency.
**Why now:** The Day 35 incident proved that prose documentation ("don't squash") is insufficient. Mechanical enforcement is required.

## 2. Target Users

| User | Role | Gets |
|------|------|------|
| Worktree agents (devex, iscp, mdpal-*, etc.) | Feature implementation | `git-safe` only |
| Captain | Coordination, PR lifecycle, push | `git-safe` + `git-captain` |

## 3. Use Cases

### Agent use cases (git-safe)
- Stage files before commit: `git-safe add <files>`
- Check working tree status: `git-safe status`
- View commit history: `git-safe log`
- View changes: `git-safe diff`
- Check current branch: `git-safe branch`
- Merge master into worktree: `git-safe merge-from-master`

### Captain use cases (git-captain)
- Merge worktree branch into master: `git-captain merge-to-master <branch>`
- Create PR branches: `git-captain checkout-branch <name>`
- Push to origin: `git-captain push`
- Fetch from origin: `git-captain fetch`
- Create tags: `git-captain tag <name>`

## 4. Functional Requirements

### FR1: git-safe tool
Single tool with subcommands. Available to all agents and captain.

| Subcommand | Maps to | Guards |
|------------|---------|--------|
| `git-safe status` | `git status` | None (read-only) |
| `git-safe log [args]` | `git log [args]` | None (read-only) |
| `git-safe diff [args]` | `git diff [args]` | None (read-only) |
| `git-safe branch` | `git branch --show-current` | None (read-only) |
| `git-safe add <files>` | `git add <files>` | Block `git add -A` (must be explicit) |
| `git-safe merge-from-master` | `git merge main` | Only merges main/master, nothing else |

### FR2: git-captain tool
Single tool with subcommands. Available to captain only. Hookify blocks agents from invoking it.

| Subcommand | Maps to | Guards |
|------------|---------|--------|
| `git-captain merge-to-master <branch>` | `git merge <branch> --no-ff` (on main) | Must be on main branch |
| `git-captain checkout-branch <name>` | `git checkout -b <name>` | Name validation |
| `git-captain push [args]` | `git push [args]` | Block push to main without --force-with-lease |
| `git-captain fetch` | `git fetch origin` | None |
| `git-captain tag <name>` | `git tag -a <name>` | Name validation |

### FR3: Hookify enforcement
Block ALL raw `git` invocations via a single hookify rule. The block message points to `git-safe` and `git-captain`.

Pattern: `^git\s+` (any git subcommand).
Exceptions: none. All git goes through the tools.

### FR4: Existing tool migration
All existing tools that use raw git internally must be updated to call `git-safe` or `git-captain` subcommands instead. Key tools:
- `worktree-sync` → `git-safe merge-from-master`
- `git-commit` → `git-safe add` (already uses git add internally)
- `collaboration` → `git-captain push`
- `upstream-port` → `git-captain checkout-branch`, `git-safe add`, `git-captain push`
- `nit-add`, `nit-resolve` → `git-safe add`
- `pr-build` → `git-captain checkout-branch`, `git-captain merge-to-master`
- `lib/_agency-init` → `git-safe add`

### FR5: Skills
- `/git-safe` skill — discovery for agent git operations
- `/git-captain` skill — discovery for captain git operations

### FR6: Pass-through for tools
Tools in `claude/tools/` that call git internally should NOT be blocked by hookify. The hookify rule should only fire on Bash tool calls from agents, not on internal tool execution. This is already how hookify works (PreToolUse on Bash, not on internal subprocesses).

## 5. Non-Functional Requirements

- **Performance:** Zero overhead for read-only operations (thin wrappers)
- **Compatibility:** Must not break existing worktree-sync, git-commit, /sync, /sync-all flows
- **Idempotent:** Running the same command twice produces the same result
- **Error messages:** Actionable — tell the user what to do instead

## 6. Constraints

- Must ship on the devex branch (standard worktree workflow)
- Hookify rule must not block git operations INSIDE existing tools (only direct Bash tool calls)
- git-safe and git-captain are Bash scripts in `claude/tools/`
- Must handle both `main` and `master` branch names
- Must work in worktrees and main checkout

## 7. Success Criteria

1. No agent can run raw `git` commands — hookify blocks with actionable message
2. All existing tools pass their BATS tests after migration
3. git-safe covers all read + agent-write operations
4. git-captain covers all captain-only operations
5. Agent cannot invoke git-captain (hookify blocks)

## 8. Non-Goals

- **Not replacing /sync or /sync-all** — those are higher-level workflows that will call git-captain internally
- **Not replacing /git-commit** — that's a higher-level workflow with QGR enforcement
- **Not wrapping git in hooks** — hooks are internal (PreToolUse fires on Bash, not subprocesses)
- **Not changing the merge-not-rebase policy** — that's already enforced

## 9. Open Questions

1. **git stash** — worktree-sync uses `git stash`/`git stash pop`. Should this be in git-safe? Or left as internal to worktree-sync?
2. **git-safe add -A** — should we block `git add -A` / `git add .` to prevent accidental staging of secrets? Or just warn?
3. **Should git-safe subsume /git-commit?** — Principal question from dispatch #238. Recommendation: NO — /git-commit is a higher-level workflow (QGR enforcement, dispatch-on-commit). git-safe add is the low-level staging.
