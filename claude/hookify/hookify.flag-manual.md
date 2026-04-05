---
name: flag-manual
enabled: true
event: write
pattern: "flag-queue.jsonl"
action: warn
---

Use `flag <message>` to capture flags — it writes to the ISCP SQLite DB. The JSONL flag queue is legacy (v1). Direct writes to flag-queue.jsonl or the iscp.db are not supported. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
