---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-17T05:21
status: created
priority: high
subject: "PR your D44-R3 now — branch-regex widening ready to ship"
in_reply_to: null
---

# PR your D44-R3 now — branch-regex widening ready to ship

You shipped 51211ed (feat) + 97bdb1c (QG fixes). Tests green (50/50 git-captain.bats + 121/121 adjacent). Receipt signed.

Please run /pr-prep + /release to get D44-R3 out. It's a small, contained framework fix — closes #428 item 1. Ready for v44.4.

Sequencing: you're next in line for release slot. designex Phase 1 and mdpal-app Phase 1B are queued behind you. Get this out and we keep the flow going.

No QG re-run needed unless you've touched code since 97bdb1c — your QG already caught and fixed 5 findings. Just pr-prep → pr-create → merge via captain.

Principal confirmed 'multiple small releases' as the shape of D44 — don't bundle, just ship.
