---
type: review
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-14T07:36
status: created
priority: normal
subject: "MAR: git-safe A&D review — 10 design decisions, need captain input"
in_reply_to: null
---

# MAR: git-safe A&D review — 10 design decisions, need captain input

## MAR: git-safe + git-captain + git-safe-commit A&D

A&D is at: claude/workstreams/devex/git-safe-ad-20260414.md
PVR is at: claude/workstreams/devex/git-safe-pvr-20260414.md

### Key design decisions for review

**DD-1: git-safe tool** — bash subcommands: status, log, diff, branch, add, merge-from-master. add blocks -A/--all/. (requires explicit paths).

**DD-2: git-captain tool** — bash subcommands: merge-to-master, checkout-branch, push, fetch, tag. No role-checking in tool — agents can't invoke because it's not in their allowed tools.

**DD-3: git-safe-commit** — pure rename of git-safe-commit. No functional changes.

**DD-4: raw-git-block hookify rule** — ONE catch-all rule (pattern: ^git\s+) replaces 9 existing individual rules (git-safe-commit-block, git-add-and-commit-block, raw-rebase-block, reset-to-origin-block, force-push-main-block, force-push-any-block, no-push-main, destructive-git-warn, raw-git-merge-master-block).

**DD-5: git-captain-agent-block** — hookify belt-and-suspenders. Primary enforcement: not in agent allowed tools.

**DD-6/7/8: Skills** — /git-safe, /git-captain, /git-safe-commit (renamed from /git-safe-commit).

**DD-9: No internal tool migration** — hookify fires on PreToolUse (agent Bash calls), not on subprocesses inside framework tools. worktree-sync, collaboration, upstream-port etc keep using raw git internally.

**DD-10: Rename scope** — 181 files, 100+ references. git mv for files, sed for content. Three patterns: /git-safe-commit → /git-safe-commit, claude/tools/git-safe-commit → claude/tools/git-safe-commit, bare git-safe-commit → git-safe-commit.

### Questions for captain

1. Is the one-catch-all-rule approach right? Or should we keep individual rules for better error messages per operation?
2. The rename touches 181 files — should we do it in one pass or stage it?
3. Any concerns with the internal-tools-stay-raw decision?

Review the A&D and send findings. I'll triage with three buckets.
