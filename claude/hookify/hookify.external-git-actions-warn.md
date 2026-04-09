---
name: external-git-actions-warn
enabled: true
event: bash
pattern: gh\s+(pr\s+create|pr\s+comment|pr\s+close|pr\s+merge|issue\s+create|release\s+create)|git\s+push
action: warn
---

External action — this affects GitHub or a remote. Only proceed if the principal explicitly asked. See CLAUDE-THEAGENCY.md#git--remote-discipline — FEAR THE KITTENS!
