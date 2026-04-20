# THE-AGENCY-BOOK-WORKING-NOTE-0022

**Date:** 2026-01-06 15:45 SGT
**Participants:** jordan (principal), housekeeping (agent)
**Subject:** Week Planning — Usage Limits and Workshop Prep

---

## Constraints

### Usage Status (as of Tue Jan 6 15:34)
- **Weekly usage:** 89% consumed
- **Reset:** Thursday Jan 8 ~16:00 SGT
- **Suspend threshold:** 95% (Jordan's policy)
- **Remaining budget:** ~6% before suspension

### Timeline
| When | Status |
|------|--------|
| **Tue Jan 6 now** | ~6% remaining |
| **Wed Jan 7** | Likely suspended |
| **Thu Jan 8 until 16:00** | Suspended |
| **Thu Jan 8 16:00** | Fresh weekly budget |
| **Fri Jan 9 14:00** | Workshop |

### Available Work Time
- **Before suspension:** Maybe 1-2 hours today
- **After reset:** Thu 16:00 → Fri 14:00 = **~22 hours** of fresh budget

---

## Work Prioritization

### Must Complete Before Workshop (Fri 14:00)

| Priority | Task | Status | Notes |
|----------|------|--------|-------|
| P0 | Test install.sh end-to-end | ✅ Done | Tested today |
| P0 | /welcome command works | ✅ Exists | Need to verify |
| P0 | Repo accessible via token | 🟡 Verify | Test AGENCY_TOKEN flow |
| P0 | WORKSHOP.md facilitator guide | ✅ Done | Created today |

### Should Complete Before Workshop

| Priority | Task | Status | Notes |
|----------|------|--------|-------|
| P1 | Book Chapter 4 updates | 🔴 Pending | Based on review feedback |
| P1 | Verify all 40 tools work | 🟡 Partial | Spot-check critical ones |
| P1 | Test /welcome interview flow | 🔴 Pending | Run through full interview |
| P1 | Pre-work email finalized | 🟡 Draft exists | Edit for production |

### Nice to Have

| Priority | Task | Status | Notes |
|----------|------|--------|-------|
| P2 | PROP-0015 CDP web capture | 🔴 Pending | Future tool |
| P2 | PROP-0017 Narrowcast messages | 🔴 Draft | Future enhancement |
| P2 | Book Chapter 1 revisions | 🔴 Pending | Based on review |
| P2 | Real examples for placeholders | 🔴 Jordan | Yak shaving, broken windows |

---

## Thursday Sprint Plan (16:00 → Workshop)

### Hour 1-2: Verification (Thu 16:00-18:00)
- [ ] Fresh test of full install flow
- [ ] Run through /welcome interview as participant
- [ ] Verify AGENCY_TOKEN works with private repo
- [ ] Check all critical tools respond correctly

### Hour 3-4: Polish (Thu 18:00-20:00)
- [ ] Fix any issues found in verification
- [ ] Update pre-work email for production
- [ ] Final WORKSHOP.md review

### Hour 5+: Documentation (Thu evening if needed)
- [ ] Chapter 4 updates based on actual flow
- [ ] Capture any last-minute learnings

### Friday Morning: Final Prep
- [ ] Quick smoke test
- [ ] Prepare screen for demo
- [ ] Have backup commands ready

---

## Today's Remaining Work (Before 95%)

With ~6% budget remaining, focus on:

1. **Commit everything done today** ✅
2. **Create this planning doc** ✅
3. **PROP-0017 for narrowcast** ✅
4. **Session backup** — Preserve context for Thursday

### What NOT to do today:
- Large explorations
- New feature development
- Extensive testing (save for fresh budget)

---

## Session Handoff Notes

When resuming Thursday 16:00+:

### Context
- Workshop is Friday 14:00
- All philosophy docs created (PROP-0016, WORKING-NOTE-0020, -0021)
- install.sh tested and working
- WORKSHOP.md created
- Book reviews done (outline, Ch1, Ch4)
- Working notes consolidated in the-agency repo

### Immediate Actions
1. Run `./tools/welcomeback`
2. Check this note (WORKING-NOTE-0022) for sprint plan
3. Start with verification sprint
4. Focus on workshop readiness

### Files to Reference
- `the-agency-starter/WORKSHOP.md` — facilitator guide
- `the-agency-starter/install.sh` — the one command
- `.claude/commands/welcome.md` — interview flow
- `WORKING-NOTE-0018` — publication blockers
- `WORKING-NOTE-0019` — workshop install flow

---

## Decisions Made Today

| Decision | Rationale |
|----------|-----------|
| One-command install | Reduces workshop friction to minimum |
| Auto-install Claude Code | Participants shouldn't need pre-work for tools |
| Auto-launch myclaude | Gets them into agent session immediately |
| /welcome for interview | Separates mechanical install from conversational onboarding |
| Philosophy documentation | Right Way = Fast Way is core, needed to be explicit |
| Narrowcast as future | Good idea but not needed for workshop |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Install fails at workshop | Have manual commands ready |
| Token doesn't work | Test Thursday, have backup |
| /welcome is confusing | Review and simplify if needed |
| Participants don't have Claude account | Pair them with someone who does |
| Run out of time Thursday | Prioritize P0 over P1 |

---

_Working note for project: the-agency-book_
_Planning doc for workshop preparation_
