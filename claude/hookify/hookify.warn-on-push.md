---
name: warn-on-push
enabled: true
event: bash
pattern: 'git push (?!\.)'
action: warn
---

You are about to push to a remote. Pushing is a deliberate, user-initiated action — never a side effect.

Before proceeding, confirm:

1. The principal explicitly asked for this push
2. You are NOT pushing to main or master (use PRs instead)
3. You are using `/sync` (the only command authorized to push) or have explicit permission

If any of these are not true, stop and ask the principal.
