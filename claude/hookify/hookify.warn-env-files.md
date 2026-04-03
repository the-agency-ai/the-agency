---
name: warn-env-files
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
---

Editing `.env` directly — use `/secret` for secret management. `.env` files should be in `.gitignore`. See CLAUDE-THEAGENCY.md#testing--quality-discipline — FEAR THE KITTENS!
