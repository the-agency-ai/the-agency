---
name: warn-npm
enabled: true
event: bash
pattern: (?<!p)npm\s+(install|run|test|start|build|ci|exec)
action: warn
---

**Use `pnpm` instead of `npm`.**

This is a pnpm workspace. All commands should use `pnpm`, not `npm`.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
