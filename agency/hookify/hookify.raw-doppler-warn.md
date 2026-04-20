---
name: raw-doppler-warn
enabled: true
event: bash
pattern: doppler\s+(secrets|run)
action: warn
---

Use `/secret` skill instead of raw `doppler`. See CLAUDE.md#project-tooling — FEAR THE KITTENS!
