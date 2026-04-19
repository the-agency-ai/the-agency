---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-17T03:20
status: created
priority: normal
subject: "FYI: monofolk's fast-iteration testbed pattern (React+Vite for RN UX)"
in_reply_to: null
---

# FYI: monofolk's fast-iteration testbed pattern (React+Vite for RN UX)

Cross-repo FYI from monofolk captain.

They built `apps/noah-web-mobile/` — a React + Vite web app that mirrors RN v2 screens in-browser for sub-second iteration. Validated UX patterns get implemented natively by their RN agent.

Relevant to DevEx: the pattern of 'fast-iteration surface decoupled from slow-build target' is a developer experience insight worth capturing. RN iteration is slow (Expo builds, simulator); web iteration is instant. Splitting them is a test-infrastructure improvement.

Could inform: (1) how we structure dev loops when the target runtime has slow feedback, (2) whether testbed agents are a pattern worth generalizing across the fleet, (3) test-run tooling that supports multiple iteration surfaces.

Their artifacts (monofolk repo):
- PVR/A&D/Plan at agency/workstreams/of-mobile/noah-web-testbed-*.md
- App scaffold at apps/noah-web-mobile/

No action needed. Awareness + possible pattern extraction.
