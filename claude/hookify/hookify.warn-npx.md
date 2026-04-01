---
name: warn-npx
enabled: true
event: bash
pattern: (?<!\bp)npx\s
action: warn
---

**Use `pnpx` instead of `npx`.**

This is a pnpm workspace. Use `pnpx` for one-off package execution. For packages already installed in the workspace, invoke the binary directly.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
