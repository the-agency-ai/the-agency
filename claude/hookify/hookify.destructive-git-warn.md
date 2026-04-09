---
name: destructive-git-warn
enabled: true
event: bash
pattern: git\s+(reset\s+--hard|checkout\s+\.|restore\s+\.|clean\s+-f|branch\s+-D)
action: warn
---

Destructive git operation — verify the principal explicitly requested this and no work will be lost. See CLAUDE-THEAGENCY.md#git--remote-discipline — FEAR THE KITTENS!
