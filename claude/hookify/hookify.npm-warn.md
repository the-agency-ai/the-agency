---
name: npm-warn
enabled: true
event: bash
pattern: (?<!p)npm\s+(install|run|test|start|build|ci|exec)
action: warn
---

This project uses `pnpm`. Use `pnpm` instead of `npm`. See project README for setup — FEAR THE KITTENS!
