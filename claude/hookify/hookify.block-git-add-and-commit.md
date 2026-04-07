---
name: block-git-add-and-commit
enabled: true
event: bash
pattern: git\s+add\b.*&&.*git\s+commit
action: block
---

**BLOCKED: `git add ... && git commit ...` bypasses /git-commit skill.**

The `/git-commit` skill (and the `claude/tools/git-commit` tool it wraps)
enforces:
- QGR receipt check before commit
- Commit notification dispatch to captain
- Workstream/agent prefix in the message
- Proper trailers (Co-Authored-By, etc.)

The compound `git add && git commit` form dodges all of this. The `block-git-commit`
hookify rule already blocks bare `git commit`, but its HEREDOC exclude pattern
lets the compound HEREDOC form sneak through. This rule closes that gap.

**The right way:**

1. Stage files with `git add` as a separate Bash call
2. Run `/git-commit` (the skill) — it does the commit + dispatch + telemetry

Or, for simple cases:

```bash
./claude/tools/git-commit "Phase X.Y: short description" --no-work-item
```

(No compound. Two separate steps. Real telemetry.)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
