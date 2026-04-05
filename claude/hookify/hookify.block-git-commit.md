---
name: block-git-commit
enabled: true
event: bash
pattern: git commit
exclude_pattern: (git commit-tree|git commit --allow-empty-message)
action: block
---

**BLOCKED: Use `/git-commit` instead of bare `git commit`.**

The `git-commit` tool enforces QGR receipt checks and dispatches commit notifications to captain. Raw `git commit` bypasses both.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
