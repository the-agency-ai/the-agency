---
name: secrets-warn
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: credentials|secrets|\.pem$|\.key$
---

Sensitive file detected — ensure no hardcoded secrets, file is in `.gitignore`, use `/secret` for secret management. See claude/docs/QUALITY-DISCIPLINE.md — FEAR THE KITTENS!
