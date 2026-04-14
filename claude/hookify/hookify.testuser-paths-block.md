---
name: testuser-paths-block
enabled: true
event: bash
pattern: usr/testuser
action: block
---

STOP. You are writing to `usr/testuser/` — this means `AGENCY_PRINCIPAL=testuser` leaked from the BATS test suite into your shell environment. Run `unset AGENCY_PRINCIPAL` and retry. The flag tool (and any tool using `_path-resolve`) will resolve to the wrong principal until this is cleared.

See `claude/docs/AGENT-ADDRESSING.md` — principal resolution uses `agency.yaml`, not raw env vars.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
