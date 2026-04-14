---
type: review
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T06:46
status: created
priority: normal
subject: "Starting task #11 (#168 agent-create dispatch loops)"
in_reply_to: 168
---

# Starting task #11 (#168 agent-create dispatch loops)

## Starting task #11 now

Bake the two canonical dispatch loops into agent-create scaffolding per #168.

## Approach

1. **Update agent-create tool/template** — generated CLAUDE-{AGENT}.md startup sequence includes step to arm both loops:
   - /loop 5m (silent-when-clean fast check)
   - /loop 30m (visible nag for stale dispatches)

2. **Sweep existing CLAUDE-*.md files** — add loop-arming step to iscp, devex, mdpal-cli, mdpal-app where missing (captain's already done)

3. **Update HANDOFF-BOOTSTRAP.md template** if it doesn't have the loops already

4. **BATS test** — verify agent-create generated output includes both loop prompts

Single commit, small scope. Redirect if needed.
