---
name: block-force-push-main
enabled: true
event: bash
pattern: git\s+push\s+(?=.*(\s-f\b|--force(?!-with-lease)))(?=.*(main|master))
action: block
---

**Force push to main/master is blocked.**

Force pushing to the main branch can overwrite upstream work. Use a feature branch or `--force-with-lease` on non-main branches instead.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
