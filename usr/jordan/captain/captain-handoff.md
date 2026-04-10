---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-11
trigger: session-end
---

## Resume — Day 36

### Immediate

1. **PR #73 awaiting approval** — D36-R1: shared _colors lib (59 tools), pr-build MAR cleanup (8 fixes), commit-precheck MERGE_HEAD skip, --no-verify removed. Approve → merge → /post-merge 73.
2. **Flag #84** — PR tool needed (like git-commit wraps commit). Enforcement Triangle: tool + skill + hookify block on raw gh pr create.

### Day 35-36 Shipped

- **35.1** (PR #70) — dispatch-monitor (event-driven dispatch watching)
- **35.2** (PR #70) — changelog-monitor (Claude Code release awareness)
- **35.3** (PR #71) — block-raw-tools PreToolUse hook
- **PR #72** — dispatch monitoring docs (Monitor replaces /loop)
- **36.1** (PR #73) — _colors lib + pr-build MAR + MERGE_HEAD skip [PENDING MERGE]
- **Presence-detect** synced to 35.3

### Workshop — Monday 13 April at Republic Polytechnic

**22 invites sent.** Responses: Abel (US, wants future session), Andrew (Korea, nominating Deepak), Eliot (busy, caught date error).

**Outline:** `claude/workstreams/agency/seeds/workshop-outline-republic-poly-20260410.md`

**TODO (priority order):**
1. Workshop repo — `the-agency-ai/the-agency-workshop` created but empty. Needs CLAUDE.md + CAPTAIN.md.
2. Test full student flow: clone → agency init → claude login → remote-control → Desktop Code tab → toy project → Vercel deploy
3. mdslide — markdown slide tool for presentations
4. Move workshop content from the-agency to the-agency-group (content repo)
5. Anthropic outreach batch 2 (LinkedIn + Twitter for Max 20x licenses)

### Monofolk

- Dispatch sent: upstream pr-build MAR cleanup + _colors lib + block-raw-tools
- Hookify promotion dispatch received and resolved
- Pending: hookify upstream port (7 warn→block rules)

### Seeds Captured

- This Happened! + Breadcrumb — value-added services
- Monitor tool adoption — event-driven dispatch watching
- OODA structural framework + Process Intelligence (Celonis) — from monofolk
- Workshop outline + setup guide + bootstrap + start scripts

### Fleet State

- **devex** — dispatch #200 sent (SPEC:PROVIDER for NestJS + React/Next.js)
- **iscp** — blocked on merge until synced
- **Monitor running** — dispatch-monitor replaces /loop polling (task bh93ichaq)
- **block-raw-tools LIVE** — blocks cat/grep/find/sed/awk/head/tail. Already caught us!

### Open Flags (key)

- #55 CLAUDE.md revision
- #69 create-tool input validation
- #78 session naming
- #82 agency verify reads dependencies.yaml
- #83 ban raw git writes
- #84 PR tool needed (NEW — Enforcement Triangle)

### Collaborative Items from MAR (not yet resolved)

Items 11-16 from pr-build MAR need disposition:
- #11 multi-source builds
- #12 `is_captain` parameter redundant
- #13 principal name in help example
- #14 `--captain` policy assumption
- #15 BATS tests for pr-build
- #16 `--version` flag (done in this release)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
