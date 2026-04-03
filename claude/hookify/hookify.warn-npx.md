---
name: warn-npx
enabled: true
event: bash
pattern: (?<!\bp)npx\s
action: warn
---

This project uses `pnpm`. Use `pnpx` instead of `npx`. See project README for setup — FEAR THE KITTENS!
