---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-08-12T14:09
status: created
priority: normal
subject: "Backlog (flag triage): mdpal create --content unbounded argv (E2BIG)"
in_reply_to: null
---

# Backlog (flag triage): mdpal create --content unbounded argv (E2BIG)

From 2026-08-12 flag triage (#211): 'mdpal create --content' passes the whole document via argv with no size gate, while every other mutation path uses a 16 KiB stdin threshold — large files can hit E2BIG. Add a CLI-side --content-stdin with the same threshold. mdpal-app depends on this.
