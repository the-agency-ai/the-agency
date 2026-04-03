---
name: warn-secrets
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: credentials|secrets|\.pem$|\.key$
---

Sensitive file detected — ensure no hardcoded secrets, file is in `.gitignore`, use `/secret` for secret management. See CLAUDE-THEAGENCY.md#testing--quality-discipline — FEAR THE KITTENS!
