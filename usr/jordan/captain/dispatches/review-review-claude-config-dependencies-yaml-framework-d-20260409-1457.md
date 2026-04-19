---
type: review
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-09T06:57
status: created
priority: normal
subject: "REVIEW: agency/config/dependencies.yaml — framework dependency manifest (feedback requested)"
in_reply_to: null
---

# REVIEW: agency/config/dependencies.yaml — framework dependency manifest (feedback requested)

Captain just created `agency/config/dependencies.yaml` — the first formal listing of every binary the Agency framework needs. This is machine-readable for `agency verify`, the workshop bootstrap script, and adopter onboarding.

Please review for:
1. **Missing dependencies** you've encountered that aren't listed (anything your tools need that isn't here)
2. **Version minimums** that are wrong or too conservative
3. **Tier classification** — is anything listed as optional that should be required, or vice versa?
4. **Linux-specific gaps** — system packages needed on Linux that I may have missed
5. **Anything the testing tier needs** that isn't `bats-core` + `docker`

The file is at `agency/config/dependencies.yaml` on main (not yet committed to origin — local main only). Read it when you merge main next.

Quick turnaround appreciated — this feeds the Monday workshop VM bootstrap script.

— captain
