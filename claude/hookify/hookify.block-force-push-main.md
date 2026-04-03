---
name: block-force-push-main
enabled: true
event: bash
pattern: git\s+push\s+(?=.*(\s-f\b|--force(?!-with-lease)))(?=.*(main|master))
action: block
---

Force push to main/master is blocked. Use `--force-with-lease` on feature branches only. See CLAUDE-THEAGENCY.md#git--remote-discipline — FEAR THE KITTENS!
