---
name: session-start-mail
enabled: true
event: session-start
pattern: "iscp-check"
action: inform
---

When iscp-check reports unread dispatches or flags on SessionStart, **process them FIRST** before any other work. Read dispatches with `dispatch read <id>`, review flags with `flag list`. Unread mail takes priority. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
