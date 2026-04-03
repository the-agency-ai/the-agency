---
name: warn-on-push
enabled: true
event: bash
pattern: 'git push (?!\.)'
action: warn
---

Push detected — only proceed if the principal explicitly asked. Use `/sync` for authorized pushes. See CLAUDE-THEAGENCY.md#git--remote-discipline — FEAR THE KITTENS!
