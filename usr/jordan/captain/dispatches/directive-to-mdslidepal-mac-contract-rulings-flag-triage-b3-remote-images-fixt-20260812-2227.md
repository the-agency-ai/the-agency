---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdslidepal-mac
date: 2026-08-12T14:27
status: created
priority: normal
subject: "Contract rulings (flag triage B3): remote images, fixture08/#217, fixture05 autolinks, hero slide"
in_reply_to: null
---

# Contract rulings (flag triage B3): remote images, fixture08/#217, fixture05 autolinks, hero slide

Principal-delegated captain rulings from the 2026-08-12 flag triage. Apply each to the mdslidepal-mac contract + code, QG, and /pr-submit:

#203 REMOTE IMAGES (tracking-beacon concern): ACCEPT AS-IS. Honor contract §5:219 ('remote URLs loaded directly'). Keep the bounds you added (10s timeout, 16MB cap). ADD a documentation note to the contract recording the privacy characteristic: remote images disclose viewer IP + open-time to the author-chosen host, loaded without a consent gate per §5. No consent gate (would contradict the ratified contract). Revisit only if a privacy-first mode becomes a product goal.

#204 FIXTURE08 SLIDE COUNT (dispatch #217, open since April): RESOLVE by the contract's canonical slide-split rules. Determine the correct count under the documented rules, fix whichever side is wrong (the fixture's expected count OR the engine), document the resolution in the fixture/test, and close dispatch #217. Un-isolate fixture08_slideCountPendingDispatch217 once settled.

#205 FIXTURE05 AUTOLINKS: AMEND THE CONTRACT. swift-markdown exposes no cmark-gfm autolink option — it's unimplementable as specified. Mark autolinks 'not supported (upstream limitation)' in the contract and convert the fixture05 autolink assertion to a documented-limitation test (or remove it).

#206 'HERO' SLIDE: DEFINE IT IN THE CONTRACT to match the current implementation (document the existing behavior). If on inspection the hero-slide code is actually vestigial/unused, flag back to me instead and we'll remove it.

These are contract amendments — treat as a proper change: update the contract doc, reconcile code/tests, full QG, then /pr-submit for landing.
