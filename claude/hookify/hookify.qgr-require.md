---
name: qgr-require
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

Ensure a QGR exists for this commit — `/git-commit` checks for a matching receipt. See CLAUDE-THEAGENCY.md#quality-gate-protocol — FEAR THE KITTENS!
