---
type: seed
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-06T02:36
status: created
priority: normal
subject: "Seed: test management — define boundary runs"
in_reply_to: null
---

# Seed: test management — define boundary runs

From legacy flag triage: need to define what a test run looks like at each commit boundary. Which frameworks run, which scopes apply. Iteration boundary = changed-file tests only. Phase boundary = full suite. Plan boundary = full suite + coverage. Pre-PR = full diff. Map this out as part of your PVR — it's core DevEx scope. Reference: usr/jordan/captain/legacy-flags-migrated-20260406.md item #23.
