---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-11
trigger: end-of-day
---

## Resume — Workshop Weekend Push

### Day 35 Shipped

- **35.1** (PR #70) — dispatch-monitor + changelog-monitor
- **35.2** (PR #70) — changelog-monitor
- **35.3** (PR #71) — block-raw-tools PreToolUse hook (upstream from monofolk)
- **PR #72** — dispatch monitoring docs fix (Monitor replaces /loop)
- **Presence-detect** synced to 35.3

### Workshop — Monday 13 April at Republic Polytechnic

**DATE IS MONDAY 13 APRIL** (not 14th — corrected by Eliot)

**22 invites sent.** Responses so far:
- Abel Ang — in US, wants future session, will arrange
- Andrew McGlinchey — in Korea, nominating Deepak (friend)
- Eliot, OGP — busy Mon/Tue, caught date error, "you were right about Claude Code"

**Full outline:** `claude/workstreams/agency/seeds/workshop-outline-republic-poly-20260410.md`

### TODO for Weekend (priority order)

1. **Workshop repo** — `the-agency-ai/the-agency-workshop` created but empty. Needs:
   - CLAUDE.md (workshop-specific, captain knows curriculum)
   - CAPTAIN.md (tutor mode agent definition)
   - Test: clone → agency init → claude login → remote-control → Desktop Code tab
   - Test: toy project (personal page + mini-blog) → Vercel deploy

2. **mdslide** — Jordan wants to build a markdown slide tool for the workshop presentations. Scope TBD.

3. **Slides content** — outline is written, needs to become actual slides (via mdslide or Keynote)

4. **Move workshop content** from the-agency to the-agency-group (content repo). Workshop materials (outline, setup guide, bootstrap script, seeds) shouldn't be in the framework repo.

5. **Anthropic outreach batch 2** — LinkedIn + Twitter to more Anthropic folks for Max 20x licenses

6. **Monofolk hookify upstream port** — 7 rules promoted from warn → block

### Workshop Architecture

- Students on Windows x86 machines
- VM: Ubuntu 24.04 in VMware Workstation (setup guide sent, bootstrap at workshop)
- Claude Code in VM with remote-control
- Students work from Claude Desktop Code tab on Windows
- Captain bootstrap knows curriculum, acts as tutor
- Students' captains collaborate with Jordan's captain
- Toy project: personal page + mini-blog → Vercel deploy
- AI Q&A stretch goal (if they have API keys / Anthropic provides Max 20x licenses)

### VM State (Jordan's test VM)

- Fusion VM at `~/Virtual Machines.localized/TheAgency-Workshop-Ubuntu-64-bit-ARM.vmwarevm/`
- 3 snapshots: clean-install, pre-bootstrap, post-bootstrap
- All tools verified: chromium, git, node, npm, claude, jq, sqlite3, gh, docker, brew
- SSH working (192.168.1.115, bridged mode)

### Seeds Captured

- This Happened! + Breadcrumb — value-added services
- Monitor tool adoption — event-driven dispatch watching
- OODA structural framework — from monofolk
- Process Intelligence (Celonis) — from monofolk
- Workshop outline + setup guide + bootstrap + start scripts

### Dispatches

- #200 to devex — SPEC:PROVIDER for NestJS + React/Next.js
- Monofolk: This Happened query, SPEC:PROVIDER directive
- Monofolk: hookify promotion received and resolved

### Content Knowledge (session context, not in files)

- MacHack: "It's all Jordan's fault" — conference mantra
- MacsBug (PM), MDS (PM), MPW (PM) — abstraction ladder
- "72 Hours Caffeine and Code" — "that was my original plan but I got overruled"
- Jamon Holmgren's 8 practices
- Workshop is one-day format; two-day is future product
- Boris + Thariq outreach for 25-30 Max 20x licenses pending
- Monitor tool replaces /loop polling — running in this session
- block-raw-tools is LIVE in settings.json — blocks cat/grep/find/sed/awk/head/tail

### Invite List (for reference)

All sent via WhatsApp or email. Committee emails via email with CC to wong_wai_ling@rp.edu.sg.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
