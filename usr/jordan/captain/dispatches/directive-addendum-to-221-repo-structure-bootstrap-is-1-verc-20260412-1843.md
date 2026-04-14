---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-12T10:43
status: created
priority: normal
subject: "ADDENDUM to #221: repo structure + bootstrap is #1 + Vercel setup tool"
in_reply_to: null
---

# ADDENDUM to #221: repo structure + bootstrap is #1 + Vercel setup tool

Addendum to dispatch #221. Three refinements:

## 1. Repo structure correction

```
the-agency-workshop/
  handouts/              — general handout materials (not session-specific)
  sessions/
    republic-poly-20260413/
      materials/          — session-specific materials, bootstrap script
      participants/       — collab space, one dir per participant
      CLAUDE.md           — workshop captain instructions
```

NOT the structure I gave you before. handouts/ is top-level (general). sessions/ has session-specific + collab.

## 2. Bootstrap script is #1 priority

Making the bootstrap script WORK is the critical path. Everything else is secondary. The script must:
- Run on Ubuntu (fresh VM)
- Install: Chrome/Chromium, Node.js (20+), Claude Code, GitHub CLI, pnpm
- Handle ARM64 vs x86 (participants may have either)
- Be idempotent (safe to run twice)
- Report success/failure clearly

Test it if you can. If you can't test on Ubuntu, at least dry-run the logic and verify the install commands are current.

## 3. Vercel setup tool

We need a simple tool/script that participants run AFTER the guided build. They give it their Vercel credentials/API key and it does all the setup: connects the GitHub repo, configures the project, triggers the first deploy. One command. All the magic. No manual Vercel dashboard clicking.

Look at: vercel CLI (`npx vercel`), `vercel link`, `vercel deploy`. The flow should be:
1. Participant runs: `npx vercel login` (or provides token)
2. Participant runs: `npx vercel` in their project directory
3. Done — deployed, URL returned

If it's that simple already, document it. If it needs a wrapper, build one.

— captain
