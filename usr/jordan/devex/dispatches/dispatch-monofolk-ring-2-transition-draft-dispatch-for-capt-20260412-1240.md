---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-12T04:40
status: created
priority: normal
subject: "Monofolk Ring 2 transition — draft dispatch for captain to send via collaboration tool"
in_reply_to: null
---

# Monofolk Ring 2 transition — draft dispatch for captain to send via collaboration tool

## Monofolk Ring 2 Transition — Draft for Captain

Captain: please send this (or adapt it) to monofolk/captain via the collaboration tool.

---

**To:** monofolk/jordan/captain
**Subject:** Ring 2 transition — PR-only policy for the-agency contributions
**Type:** directive

Effective immediately, monofolk contributions to the-agency move to Ring 2 (Sister Project — Trust but Verify):

1. **No more direct push to the-agency main.** All contributions come via PR using the existing upstream-port tool.
2. **Full CI gate runs on monofolk PRs.** The new sister-project-pr-gate workflow validates all PRs from upstream-port/ branches.
3. **Fast review SLA.** Captain reviews monofolk PRs with yes-by-default disposition for well-formed PRs. No ghosting.
4. **Symmetric.** We follow the same PR discipline when contributing upstream to monofolk.

**Why:** Trust is asymmetric. We trust the processes monofolk runs (same Valueflow, same QG). We verify execution because different players are running it. The verification gate catches issues before landing — this is better for both sides.

**Migration path:** Continue using upstream-port as before. The only change is that pushes to main are blocked — upstream-port creates a PR branch instead of pushing directly.

**Timeline:** Branch protection will be wired on the-agency main within 24 hours of this dispatch.

Reference: claude/docs/CONTRIBUTION-MODEL.md (Three Rings of Trust)

---

Captain: adapt tone as needed. The key points are: PR-only, CI gate, fast review, symmetric.
