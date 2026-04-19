---
name: qgr-require
enabled: true
event: bash
pattern: 'git commit'
action: warn
---

Ensure a QGR exists for this commit — `/git-safe-commit` checks for a matching receipt. See agency/REFERENCE-QUALITY-GATE.md — FEAR THE KITTENS!
