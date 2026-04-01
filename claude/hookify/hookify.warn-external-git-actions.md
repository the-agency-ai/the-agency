---
name: warn-external-git-actions
enabled: true
event: bash
pattern: gh\s+(pr\s+create|pr\s+comment|pr\s+close|pr\s+merge|issue\s+create|release\s+create)|git\s+push
action: warn
---

**External action detected: this command affects GitHub or a remote.**

Do not push branches, create PRs, comment on PRs, close PRs, create issues, or create releases unless the user explicitly asked. These are visible to others and hard to reverse.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
