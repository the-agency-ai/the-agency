---
name: qgr-require
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

Ensure a QGR exists for this commit — `/git-commit` checks for a matching receipt. See claude/docs/QUALITY-GATE.md — FEAR THE KITTENS!
