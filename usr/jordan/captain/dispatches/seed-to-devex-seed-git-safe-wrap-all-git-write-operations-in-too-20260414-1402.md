---
type: seed
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T06:02
status: created
priority: normal
subject: "SEED: git-safe — wrap all git write operations in tools/skills, block raw git"
in_reply_to: null
---

# SEED: git-safe — wrap all git write operations in tools/skills, block raw git

## Seed from Principal

### The Problem
Agents and captain use raw git commands today. Only git commit and git rebase are blocked. All other write operations (merge, push, checkout, add, tag, fetch) are unguarded. Principal wants ALL git write operations wrapped in tools/skills with raw git blocked via hookify.

### The Spec (from Principal)
1. Determine what git operations agents need — create tools and skills for them
2. Determine what git operations captains need — create tools and skills for them
3. Block raw git write ops + captain-only operations for agents
4. Block raw git write ops for captain (force through tools)

### Architecture Decision (from Principal + Captain)
Single tool: git-safe with subcommands. Role-based access via agent-identity.

Read-only ops (ALLOW raw — no wrapping needed):
- git status, git log, git diff, git branch --show-current

Agent subcommands:
- git-safe add <files> — stage files
- git-safe merge-from-master — pull master into agent's branch (replaces raw git merge master)

Captain subcommands (blocked for agents):
- git-safe merge-to-master <branch> — merge worktree branch into master
- git-safe checkout-branch <name> — create PR branches
- git-safe push — push to origin (with guards)
- git-safe fetch — fetch origin
- git-safe tag <name> — create tags

### Enforcement Triangle for each
- Tool: git-safe (single tool, subcommands)
- Skill: /git-safe (discovery)
- Hookify: block raw git write ops (git add, git merge, git push, git checkout, git tag, git fetch)

### Existing tools to integrate with
- /git-commit — already exists, already blocked raw git commit
- /sync and /sync-all — captain push/merge workflows
- /worktree-sync — agent merge-from-master wrapper

### Process
Follow Valueflow: PVR → A&D → Plan → Implement. Full QG at boundaries. This replaces your PR #78 BATS task as your next priority.

### Questions to resolve in PVR
1. Should git-safe subsume /git-commit? Or stay separate?
2. Should /sync and /sync-all call git-safe internally?
3. What about git stash? Agents use it in worktree-sync.
4. git-safe add vs letting /git-commit handle staging?
