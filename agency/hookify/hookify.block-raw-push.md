---
name: block-raw-push
enabled: true
event: bash
pattern: 'git push'
action: block
---

BLOCKED: Raw git push is not allowed. All pushes go through skills:
- `/sync` — push current branch to origin (the ONLY push command)
- `/collaboration push <repo>` — push cross-repo dispatches

Every change reaches origin through a PR. Never push directly to main.

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
