---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/designex
date: 2026-08-13T11:27
status: created
priority: normal
subject: "Decide + fix designsystem-add's dead template dependency (#254)"
in_reply_to: null
---

# Decide + fix designsystem-add's dead template dependency (#254)

designsystem-add points at agency/knowledge/design-systems/_template + writes to agency/knowledge/design-systems/ — but that whole tree was ARCHIVED to agency/workstreams/agency/history/flotsam/legacy-knowledge/design-systems/. So a real invocation fails 'Template directory not found'. Its new bats pass only because they supply a fixture template. This needs YOUR call (your pipeline): (a) re-point the tool to a live location under agency/workstreams/designex/ + move the template there, (b) restore the design-systems knowledge base to a live path, or (c) retire the tool if the design-systems concept was deliberately deprecated. Whatever you choose, update the tool + its bats + src mirror, QG, and /pr-submit. Landed v46.42 has the tool + tests but the production path is dead.
