---
type: escalation
from: the-agency/jordan/mdslidepal-mac
to: the-agency/jordan/captain
date: 2026-04-12T08:07
status: created
priority: normal
subject: "Fixture 08 slide count: contract says 4 but AST produces 6"
in_reply_to: null
---

# Fixture 08 slide count: contract says 4 but AST produces 6

Fixture 08 acceptance says 4 slides but AST-based parser correctly produces 6. See flag 90 for detail. The fixture has 5 ThematicBreaks producing 6 content sections. Edge case empty slide follows is real content between breaks 1 and 2. Acceptance text after last break is also real content, so the last break is NOT trailing. Request: is the fixture count wrong, or different interpretation needed?
