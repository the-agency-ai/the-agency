# PROJECT: Workshop and Launch Preparation

**Created:** 2026-01-06
**Target:** Workshop Fri Jan 9 14:00 SGT
**Principal:** jordan
**Lead Agent:** housekeeping

---

## Timeline

| When | What |
|------|------|
| Tue Jan 6 | Planning complete, suspend at 95% |
| Wed Jan 7 | Suspended (planning/writing only) |
| Thu Jan 8 16:00 | Budget resets, execution sprint |
| Fri Jan 9 12:00 | Final prep complete |
| Fri Jan 9 14:00 | **Workshop** |

---

## Tier 1: Workshop Critical (Must Have by Fri 12:00)

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| 1.1 | Verify install.sh end-to-end | housekeeping | 🟡 | Tested locally, need fresh test |
| 1.2 | Test /welcome flow as participant | housekeeping | 🔴 | Full interview walkthrough |
| 1.3 | Verify AGENCY_TOKEN clone | housekeeping | 🔴 | Must work for private repo |
| 1.4 | Slides (~8-10) | jordan + opus | 🔴 | See structure below |
| 1.5 | Pre-work email finalized | jordan | 🟡 | Draft in WORKSHOP.md |
| 1.6 | Dry run full workshop flow | housekeeping | 🔴 | End-to-end timing |

### Slide Structure

1. What is The Agency? (2-3 slides)
   - Problem: single-agent bottleneck
   - Solution: multi-agent coordination
   - Proof: 8-day Project X teaser

2. How It Works (2-3 slides)
   - Principal → Agent model
   - Tools, not instructions
   - Choreography over orchestration

3. Demo/Install (1 slide)
   - The one command
   - What happens automatically

4. Hands-On (1 slide)
   - /welcome interview
   - Build something real

5. What's Next (1 slide)
   - Resources, community

---

## Tier 2: Book Critical (Must Have Before Publish)

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| 2.1 | init-agency tool | housekeeping | 🔴 | Chapter 4 references it |
| 2.2 | Starter repo accessible | jordan | 🔴 | Public or token-gated |
| 2.3 | Real Yak Shaving example | jordan | 🔴 | Chapter 1 placeholder |
| 2.4 | Real Broken Windows example | jordan | 🔴 | Chapter 1 placeholder |
| 2.5 | Verify install URLs | housekeeping | 🔴 | claude.ai/install.sh correct? |
| 2.6 | Verify pricing | housekeeping | 🔴 | Pro/Max prices current? |
| 2.7 | GitHub Discussions setup | jordan | 🔴 | Appendix C references it |
| 2.8 | Community infrastructure | jordan | 🔴 | Discord? |

---

## Tier 3: High Impact Framework

| # | Item | Owner | Status | Impact |
|---|------|-------|--------|--------|
| 3.1 | PROP-0015: CDP Web Capture | housekeeping | Draft | Unlocks modern web content |
| 3.2 | PROP-0017: Narrowcast Messages | housekeeping | Draft | Token efficiency at scale |
| 3.3 | PROP-0014: Knowledge Indexer | housekeeping | Referenced | Compounding knowledge |
| 3.4 | Troubleshooting Agent | TBD | 🔴 | Appendix C, support experience |

---

## Tier 4: Book Polish

| # | Item | Owner | Status | Notes |
|---|------|-------|--------|-------|
| 4.1 | Chapter 4 revisions | housekeeping | 🟡 Reviewed | Address feedback |
| 4.2 | Chapter 1 revisions | housekeeping | 🟡 Reviewed | Address feedback |
| 4.3 | Outline updates | housekeeping | 🟡 Reviewed | Address feedback |
| 4.4 | Chapter 10 Workbench scope | jordan | 🔴 | What modules in starter? |

---

## Execution Plan

### Before Thursday 16:00 (No Tokens)
- [ ] Draft slide outline (jordan)
- [ ] Write pre-work email final (jordan)
- [ ] List exact demo steps (jordan)

### Thursday 16:00 → Friday 12:00 Sprint

| Order | Task | Time | Owner |
|-------|------|------|-------|
| 1 | Verify AGENCY_TOKEN clone | 15 min | housekeeping |
| 2 | Full /welcome test | 30 min | housekeeping |
| 3 | Fix any issues | 1-2 hrs | housekeeping |
| 4 | Create slides | 1-2 hrs | jordan + opus |
| 5 | init-agency decision | 30 min | housekeeping |
| 6 | Dry run workshop | 30 min | housekeeping |
| 7 | Buffer for issues | 1 hr | — |

### Friday Morning Final Prep
- [ ] Smoke test install
- [ ] Slides ready
- [ ] Demo screen prepared
- [ ] Backup commands ready

---

## Success Criteria

**Workshop Success:**
- [ ] Participants can run one command and get to /welcome
- [ ] /welcome creates their first agent
- [ ] They build something in 10 minutes
- [ ] They leave knowing next steps

**Book Launch Ready:**
- [ ] Starter repo accessible
- [ ] All Chapter 4 commands work
- [ ] No placeholder examples remain
- [ ] URLs verified

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Install fails at workshop | Manual clone commands ready |
| Token doesn't work | Test Thursday first thing |
| /welcome confusing | Simplify if issues found |
| No Claude account | Pair with someone who has one |
| Run out of time Thu | Prioritize Tier 1 ruthlessly |

---

## Dependencies

```
Workshop Success
├── install.sh works (1.1)
├── /welcome works (1.2)
├── Token works (1.3)
├── Slides exist (1.4)
└── Pre-work sent (1.5)

Book Launch
├── Starter repo accessible (2.2)
├── init-agency exists (2.1)
├── URLs verified (2.5)
├── Examples real (2.3, 2.4)
└── Community ready (2.7, 2.8)
```

---

_Project tracking for workshop and launch preparation_
_Created 2026-01-06_
