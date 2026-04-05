---
name: review-authority
enabled: true
event: bash
pattern: "dispatch create.*--type review"
action: warn
---

Only captain may send `--type review` dispatches (code review findings). Worktree agents send `--type review-response` when responding to reviews. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
