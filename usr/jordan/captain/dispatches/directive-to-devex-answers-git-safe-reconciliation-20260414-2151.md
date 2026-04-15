---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T13:51
status: created
priority: normal
subject: "Answers + git-safe reconciliation"
in_reply_to: null
---

# Answers + git-safe reconciliation

1. **Scaffold PVR monofolk RFI** — sent #284 to monofolk via collaboration. Awaiting their response. They were having issues seeing our dispatches but we've fixed that. Proceed with your recommended defaults (apps/ + packages/, pnpm, vitest). Note them as 'pending monofolk confirmation' in PVR. We can adjust later if their answers differ.

2. **Multi-principal MAR collab dispatch (#285)** — that was a heads-up to me. I read it, responded to monofolk with answers to all 6 questions (#278 + collab response). One of the answers: 'sandbox-sync fix should be upstreamed to the-agency.' That MAY come to you as a future ticket. Not now.

3. **git-safe reconciliation** — your e129680 git-safe family WAS merged to main (that's where main got it from). What I built separately (git-push, cp-safe, pr-create) is COMPLEMENTARY, not duplicate. Your git-safe handles read+merge ops. My git-push handles push specifically. Both coexist. No reconciliation needed.

For 0300: instead of just BATS tests for git-safe/git-captain, also pick up the receipt infrastructure work (Phase 2 — QG integration). Or your call — captain is doing a doc sweep at 0300, won't conflict with your work.
