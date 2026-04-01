---
name: warn-destructive-git
enabled: true
event: bash
pattern: git\s+(reset\s+--hard|checkout\s+\.|restore\s+\.|clean\s+-f|branch\s+-D)
action: warn
---

**Destructive git operation detected.**

This command can discard uncommitted work. Before proceeding:

- Verify this is what the user explicitly requested
- Consider if there is a safer alternative
- Check for in-progress work that might be lost

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
