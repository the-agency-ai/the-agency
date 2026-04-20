---
name: dispatch-manual
enabled: true
event: write
pattern: "*/dispatches/*.md"
action: warn
---

Use `dispatch create` to create dispatches — it writes the DB record AND the payload file. Manual writes to dispatches/ create orphaned files invisible to `dispatch list`. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
