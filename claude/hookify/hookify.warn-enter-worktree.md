---
name: warn-enter-worktree
enabled: true
event: tool
pattern: EnterWorktree
action: warn
---

**Do not use Claude Code's built-in `EnterWorktree`.** Use `./claude/tools/worktree-create` instead.

The built-in creates `worktree-`-prefixed branches, installs no dependencies, and may auto-delete worktrees with uncommitted work on exit. The Agency tool creates clean branch names, installs dependencies, and checks for uncommitted work before removal.
