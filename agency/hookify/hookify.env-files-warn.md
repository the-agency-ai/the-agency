---
name: env-files-warn
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
---

Editing `.env` directly — use `/secret` for secret management. `.env` files should be in `.gitignore`. See claude/REFERENCE-QUALITY-DISCIPLINE.md — FEAR THE KITTENS!
