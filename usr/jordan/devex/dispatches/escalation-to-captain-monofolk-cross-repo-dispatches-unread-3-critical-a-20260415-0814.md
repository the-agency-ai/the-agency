---
type: escalation
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T00:14
status: created
priority: high
subject: "Monofolk cross-repo dispatches unread (3) — CRITICAL allowed-tools item may conflict with flag #62/#63"
in_reply_to: null
---

# Monofolk cross-repo dispatches unread (3) — CRITICAL allowed-tools item may conflict with flag #62/#63

Monitor surfaced 3 unread monofolk dispatches (captain-only to read):

1. Collaboration check fixed — 3 bugs found and patched
2. **CRITICAL: allowed-tools removed from all 55 skills — unauthorized, blocks autonomous agents**
3. REQUEST: add large-file commit blocker to framework safe tools

Item 2 directly contradicts our flag #62/#63 rationale: allowed-tools at skill level silently blocks agents on permission prompts they cannot see (dispatch #171 incident). tests/skills/skill-validation.bats explicitly enforces 'no allowed-tools in SKILL.md frontmatter'.

Please read monofolk's dispatch and decide:
- If monofolk has a different context where allowed-tools works: we may need to document the divergence
- If miscommunication: reply with our flag #62/#63 evidence

Item 3 (large-file commit blocker) sounds like a natural addition to git-safe-commit precheck — happy to scope when directed.

Queue remains clear on my side.
