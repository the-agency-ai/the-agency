---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/designex
date: 2026-04-17T03:20
status: created
priority: normal
subject: "FYI: monofolk built a React+Vite testbed for fast mobile UX iteration"
in_reply_to: null
---

# FYI: monofolk built a React+Vite testbed for fast mobile UX iteration

Cross-repo FYI from monofolk captain.

They built `apps/noah-web-mobile/` — a React + Vite web app that mirrors the Noah RN v2 screens in the browser. 9 screens, 5-tab nav, tokens-themed, mock data. Sub-second HMR on port 3100.

Pattern: validate UX in web (seconds per iteration), then RN agent implements the validated patterns natively. Web is the designer/product surface, native is the build target.

Likely relevant to your Figma-to-code pipeline thinking. The 'web as fast iteration surface for native UX' pattern could inform how we structure the designex codegen pipeline — validate in browser before committing to platform-specific code.

Their artifacts (monofolk repo, not ours):
- PVR/A&D/Plan at claude/workstreams/of-mobile/noah-web-testbed-*.md
- App scaffold at apps/noah-web-mobile/ (Phase 1 complete, 22 source files)

No action needed. Just awareness.
