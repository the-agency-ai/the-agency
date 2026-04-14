---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-13
trigger: session-end
---

## Resume — Day 38 (Workshop Day)

### What happened this session

**Workshop deck: v10 → v17 in one session.** 7 committed versions, 3 MAR rounds, 80+ individual changes.

**Deck is at v17** (`f8e3750`), 90+ slides, committed and serving on port 8001.

Key structural changes across v10→v17:
- OODA throughout (NOT ODA — Principal IS the OOD, Act = Delegation)
- Proper OODA loop SVG (circular, colored arcs, readable labels)
- Enforcement Triangle SVG (Direction/Discovery/Compliance triangle)
- Session Lifecycle SVG (Resume→Dialogue→Execute→Compact→End loop)
- "Claude Code Concepts" section: Agents+Subagents, Commands/Skills/Tools, Events/Hooks
- Direction→Discovery→Compliance→Triangle enforcement sequence
- Valueflow stages with artifacts (Seed→Define, Design→Plan, Implement→Ship→Value)
- QG expanded to 8 stages
- Agency concepts: Processes/Artifacts/Patterns/Collaboration (4 slides)
- Quality philosophy: "We fix things. We don't work around them."
- "Context Is Everything" slide with Attention paper reference
- My Home Network anecdote (content TBD — Jordan tells it live)
- Guided Tour, Setup, Checklist slides for Part 4
- Acknowledgments: Abel, Weiling, Phyllis, Anthropic
- Contact: jdm@devopspm.com, GitHub: jordandm

### Workshop status

- **Workshop:** 13 April 2026, 09:00, Republic Polytechnic
- **Deck:** v17, committed, ready
- **Workshop repo:** https://github.com/the-agency-ai/the-agency-workshop — LIVE
- **Bootstrap:** `curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-workshop/main/sessions/republic-poly-20260413/materials/bootstrap.sh | bash`
- **Risk:** No end-to-end Ubuntu VM test confirmed

### Commits this session

- `2aad5b3` v11 — MAR + 30 revisions + OODA fix + concepts (83 slides)
- `8391634` v12 — QG 8 stages, quality philosophy, repo structure, MAR loop (86 slides)
- `fcbda87` v13 — structural review: pacing fixes (85 slides)
- `a285f30` v14 — OODA graphics, reorder concepts, Agency elements
- `c322b97` v15 — Boyd restored, Direction/Discovery/Compliance sequence
- `9c480b5` v16 — OODA readable, Enforcement Triangle SVG, Agency reorg
- `62b9be5` — OODA loop SVG fix (readable text)
- `4db0eb1` — OODA loop proper circle
- `f8e3750` v17 — CC Concepts header, two-line titles, Valueflow refresh

### Fleet state

- **DevEx:** Workshop repo delivered (dispatch #223). CODE_OF_CONDUCT shipped.
- **DesignEx:** Running autonomously
- **mdslidepal-web:** Serving deck, SmartyPants working
- **mdslidepal-mac:** Phase 1 in progress
- **Monofolk:** D37-R1 notified

### What's next (post-workshop)

- Workshop debrief + lessons learned
- DevEx PR build (#201 items complete, 6 commits ready)
- Monofolk Ring 2 transition dispatch
- CI rework (smoke-ubuntu + fork-pr-full-qg)
- Deck post-mortem: what worked, what didn't, what to change for next time

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
