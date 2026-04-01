---
name: warn-secrets
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: credentials|secrets|\.pem$|\.key$
---

**Sensitive file detected.**

This file may contain secrets or credentials. Ensure:

- No secrets are hardcoded
- The file is in `.gitignore`
- Doppler or another secrets manager is used instead

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
