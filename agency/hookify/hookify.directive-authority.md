---
name: directive-authority
enabled: true
event: bash
pattern: "dispatch create.*--type directive"
action: warn
---

Only principals and captain may send `--type directive` dispatches. If you're not the captain or acting on principal direction, use `--type dispatch` instead. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
