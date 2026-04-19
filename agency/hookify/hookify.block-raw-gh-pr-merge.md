---
name: block-raw-gh-pr-merge
enabled: true
event: bash
pattern: 'gh pr merge'
action: block
---

🚫 BLOCKED: Raw `gh pr merge` is not allowed. Use `./claude/tools/pr-merge` (or `/pr-merge` skill) instead.

Why: `gh pr merge` defaults nudge toward `--squash` (banned — same family as rebase, rewrites history). Captain shipped 4 squash merges on Day 41 by reaching for raw `gh pr merge`. The framework's principle is "merge, never rebase, never squash."

The safe wrapper:
- ALWAYS uses true merge commit (`--merge`)
- Refuses `--squash` and `--rebase` flags explicitly
- Defers to branch protection by default
- Requires `--principal-approved` flag (not raw `--admin`) to bypass
- Logs every override

Usage:
  ./claude/tools/pr-merge <PR>                       # standard merge
  ./claude/tools/pr-merge <PR> --principal-approved  # captain attestation that principal verbally approved override
  ./claude/tools/pr-merge <PR> --delete-branch       # also delete remote branch

Skill: /pr-merge

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
