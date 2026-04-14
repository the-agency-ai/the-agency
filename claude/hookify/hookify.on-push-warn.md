---
name: on-push-warn
enabled: true
event: bash
pattern: 'git push (?!\.)'
action: warn
---

Push detected — only proceed if the principal explicitly asked. Use `/sync` for authorized pushes. See claude/docs/GIT-MERGE-NOT-REBASE.md — FEAR THE KITTENS!
