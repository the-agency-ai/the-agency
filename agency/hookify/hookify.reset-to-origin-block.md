---
name: reset-to-origin-block
enabled: true
event: bash
pattern: git\s+reset\s+--hard\s+origin
action: block
---

**BLOCKED: `git reset --hard origin/*` destroys local work.**

This command drops all local commits not on origin — including installed framework files, worktree merges, and coordination artifacts. Use merge-based sync instead.

Use instead:
- `/sync-all` — merges origin/master safely (never resets)
- `git merge origin/master` — if you need to pull origin's changes manually

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
