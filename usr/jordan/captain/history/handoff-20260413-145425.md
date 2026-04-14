---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-12
trigger: session-end
---

## Resume — Day 37 (continued from marathon session)

### IMMEDIATE: Execute deck revision from 3 Granola review passes

Jordan did three Granola-recorded slide review passes. The third is most comprehensive. Instructions: Feed transcript + slides to MAR, build TODO list, consolidate, plan mode, execute.

**Current deck:** `claude/workstreams/mdslidepal/workshop-deck.md` (77 slides, v10)
**Serve:** `cd .claude/worktrees/mdslidepal-web/apps/mdslidepal-web && node dist/bin/mdslidepal.js serve /path/to/workshop-deck.md --port 8001`
**Screenshot:** `cd /tmp && node screenshot-slides.js`

### TODO LIST — Consolidated from 3 Granola passes

**Slide fixes:**
- **3**: Companies on separate lines. SV/SG on second lines. Smart Nation Fellow standalone. Advisors standalone.
- **4**: SVG boxes still overlapping arrows — Create UP, Apply RIGHT, Learn DOWN, Improve LEFT
- **16**: Add footnote defining "principal" (human in human-agent collaboration)
- **18**: Add "Act happens fast with agents. Gated by OOD/Delegate."
- **20**: "Many considered too expensive to scale" (not "without scale")
- **21**: "effectively infinitely" / "They're free." own line / "You can have all three" own line
- **25**: End with "They valued safety. They went to build safety." (drop quote)
- **28**: 4 Ds cross-reference to paper + Anthropic Academy
- **35**: "how to do things" not "what to do." CLAUDE.md=policy → tools/skills → hooks/enforcement. Bring Enforcement Triangle here.
- **36**: Elements is "hodgepodge" — rework from agency README. Proper definitions.
- **43**: Per-phase slides with artifacts (PVR, A&D, Plan). QG + QGR. Remove "From The Agency Group AI."
- **46**: Conflate: bug filed + agent fixed it autonomously
- **67**: Strike "For Educators" → "For Everyone." ODA double meaning.
- **70**: "All built with Claude Code. / All built with Valueflow. / All open source."

**Structural:**
- NEW "What is a Principal?" slide before "What is an Agent"
- Move Quality Gates + Enforcement Triangle INTO Valueflow walkthrough
- Link Enforcement Triangle to continuous improvement / Deming / OODA
- DROP "Case Study: Yesterday"
- Move HX/AX EARLIER
- "enables Valueflow" not "implements"
- After Independent Build: recap Valueflow loop
- Capitalize: Principal (P), Agency (A), Captain (C)
- Guided Build: map to Valueflow phases with artifacts
- "How Slides Were Made": not all today — several days, walks, dictation
- Acknowledgments: Abel, Weiling, Phyllis, Anthropic
- Markdown lingua franca stays in What's Next (not earlier)

### What shipped Day 37

- Release D37-R1 (PR #79): critical agency-update fix + Over protocol + contribution model + 8 feedback filings + mdslidepal workstream + Figma research + DesignEx + workshop deck v10
- GitHub: #52 closed, #51 closed, #80 filed+closed. #74/#58/#50 open.
- Monofolk: PR #77 merged, #78 open, 3 contrib branches clean, multiple dispatches
- Feedback: 8 filed (#46531-#46860)

### Fleet state

- **DevEx**: Dispatch #223 just arrived (workshop repo LIVE + CODE_OF_CONDUCT). Check it!
- **DesignEx**: PVR drafted, MAR complete, running autonomously
- **mdslidepal-web**: Built, serving deck, SmartyPants working
- **mdslidepal-mac**: Phase 1 in progress
- **Monofolk**: D37-R1 notified, safe to update

### Workshop Monday 13 April

- 09:00 start, Republic Polytechnic, 20+ lecturers + IMDA observers
- AV gear purchased (lav mic + DJI camera)
- Deck: 77 slides (v10), Plan B operational
- Workshop repo: DevEx handling (dispatch #221/#222/#223)
- Blocking: workshop repo + bootstrap script + Vercel deploy test

### Protocols

- Over/Over-and-Out in CLAUDE-CAPTAIN.md + CLAUDE-THEAGENCY.md
- Soft/hard gate execution model
- Granola ingestion tool at usr/jordan/captain/tools/granola-ingest
- Playwright slide review workflow

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
