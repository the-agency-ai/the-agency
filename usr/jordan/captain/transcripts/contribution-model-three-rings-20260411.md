---
type: transcript
mode: dialogue
agent: the-agency/jordan/captain
topic: Contribution Model — Three Rings of Trust
date: 2026-04-11
started: 2026-04-11
status: active
---

# Contribution Model — Three Rings of Trust

Strategic discussion about the contribution workflow, CI scope, and how trust asymmetry between internal/sister-project/community contributors should shape both CI and the review process. Sparked by skill validation tests that had been failing since the earliest days of the-agency, generating email noise nobody acted on.

## Context entering the discussion

- PR #76 (D36-R2) merged: fixed 4 skill validation CI failures (frontmatter, project-specific refs, allowed-tools test)
- CI failure emails had been firing for weeks across D35-R2, D35-R3, D36-R1, multiple main pushes — all the same broken skill validation tests
- Captain workflow uses local QG (commit-precheck, /pr-prep, /quality-gate) enforced by hookify rules
- Monofolk has been pushing directly to the-agency main as if they were internal — they're a sister project with their own captain

## Captain's analysis: CI in light of QG

**Question raised by Jordan:** What — if any — tests make sense to run on CI given our QG regime?

**Captain's analysis:**

Local QG is mandatory and enforced. CI duplication generates noise without value, except in three legitimate roles:

1. **Cross-environment parity** — dev on macOS (BSD utils, bash 3.2), users run Linux (GNU utils, bash 5+)
2. **Fresh-clone smoke test** — `git clone && agency init` is a path the dev never exercises locally
3. **Untrusted contributor gate** — community PRs from forks didn't run our QG

Proposed CI: two jobs only, both fast (<90s):
- `smoke-ubuntu` — every push, fresh-clone test on Ubuntu
- `fork-pr-full-qg` — PRs from forks only, full validation suite

What should be DELETED from CI: skill-validation, iscp-*, agent-identity, dispatch-*, flag, iscp-migrate — all should run at QG time locally, not 8 hours later via email.

Root cause of the broken-window problem: tests were never wired into local QG. They only ran in CI, sent emails, everyone learned to ignore them. Classic broken window.

## Jordan's key insight: trust is asymmetric

> "How we treat our own PRs, where we have strong confidence in the QG process, is different from how we handle a PR from a contributor. And I think we need to think through that process. We have been letting monofolk just commit directly. Think that needs to change and it is tied to our contributor process."

**Decision:** Monofolk is a sister project, NOT internal. They should be treated as a partner-trust contributor, not as a captain-equivalent. Direct push needs to stop.

## Captain's framing: the three rings

| Ring | Source | Trust | CI scope |
|------|--------|-------|----------|
| **Ring 1: Internal** | captain, devex, iscp worktrees | Full — runs QG, hookify enforced | Smoke test only |
| **Ring 2: Sister Projects** | monofolk and similar partners | Partner — they have OWN captain, OWN QG | Full validation gate |
| **Ring 3: Community / Workshop** | forks, students, public contributors | Zero — unknown engineer | Full gate + welcoming captain review |

CI scope grows as trust shrinks. Local QG depth stays the same.

**Insight:** Locking monofolk down via PR + full CI gate is actually KIND to monofolk — they get fast feedback on issues our QG would catch, instead of having bugs land and get dealt with later.

## Strategic frame — why this matters now

- Workshop is Monday at Republic Polytechnic — students will be the first community contributors at scale
- Plan to kill the-agency-starter and redirect to the main repo — main repo becomes the front door
- Contribution process must be a first-class experience, not bolted on later

Required artifacts before workshop:
- `CONTRIBUTING.md` at repo root
- Contributor PR template
- Fork-PR CI gate
- Captain review skill tuned for external PRs (welcoming tone)
- Code of conduct
- Maintainer response SLA

## Proposed sequence

Captain proposed (not yet committed):

1. Document the three rings explicitly — `claude/docs/CONTRIBUTION-MODEL.md`
2. Draft `CONTRIBUTING.md` at repo root
3. Define monofolk's transition — dispatch announcing new PR-only policy with deadline
4. Wire branch protection on main — AFTER monofolk is informed
5. Rework CI to match the three-ring model

## Open questions to Jordan

1. Does the three-ring model match how you see it, or is there a category missing?
2. Is monofolk Ring 2 (sister project, partner trust) or closer to Ring 1 (internal, just different repo)?
3. Workshop students start as Ring 3 — do we need a Ring 2.5 path for "vetted external contributor → trusted maintainer"?

## Jordan's response

> "Are we on transcript?"

**Action:** Started this transcript to capture the design discussion in real time. Discussion to continue with Jordan's answers to the open questions above.

---

## Workshop interlude — Kiren Kumar response

Jordan shared WhatsApp screenshot showing Kiren Kumar's response to the workshop invite:
- "Hey Jordan hope u are doing well sir! This looks amazing :)"
- "I can send two of my officers to observe and see how we can upskill many more!"
- "My staff Spenser and Zeph will be there 🙏🙏"
- "Catch up soon sir"

**Confirmed attendees +3:** Kiren Kumar (DCEO IMDA), Spenser, Zeph
**Strategic significance:** DCEO IMDA — Singapore government technology authority. Long relationship from Indeed/EDB days. Two officers as observers + intent to "upskill many more" = potential pathway to government adoption/pilot program. Tracks Dorcas Tan (also IMDA) who was on the invite list.

**Action:** Update workshop attendee tracking, follow up on Kiren's "catch up soon sir" after workshop.

## 1B1 — Jordan's three questions

Jordan requested 1B1 protocol on the three open questions from the contribution model discussion.

---

### Q1: Does the three-ring model match how you see it?

**Proposed:** Ring 1 Internal (full trust, smoke CI), Ring 2 Sister Projects (partner trust, full gate), Ring 3 Community (zero trust, full gate + welcoming review). CI scope grows as trust shrinks; local QG depth stays the same.

**Jordan:** "I like this."

**Decision:** Three-ring model approved as the contribution trust framework. Proceed with this as the foundation for CONTRIBUTION-MODEL.md.

### Q2: Monofolk — Ring 2 (sister project) or Ring 1 (internal, different repo)?

**Captain's lean:** Ring 2. Monofolk has its own captain, own QG runs, own team — calling them internal is a fiction that creates supply chain risk. Moving them to Ring 2 is actually *kind* to them because they get fast feedback via our gate instead of discovering issues post-merge.

**Jordan:**
> "They are not Ring 1, but Ring 2"
> "They follow our processes, but not necessarily all of our players."
> "So, it is a 'trust but verify'"

**Key refinement:** The captain's initial framing ("different captain, different QG, different standards") was wrong in a subtle but important way. Monofolk doesn't have a *different* QG — they have the **same processes with different players**. Same Valueflow, same QG regime, same three-bucket triage, same hookify rules. What's different is *who* is running them.

**This reframes Ring 2 as "trust but verify" rather than "partner but different":**
- We trust the processes they're running (because they're our processes)
- We verify the execution via CI (because different engineers are running them and we can't see their local QG runs)
- This is **federation with reciprocal verification**, not hierarchy or partnership

**Decision:** Monofolk moves to Ring 2. Direct push ends. All contributions via `upstream-port` → PR → full CI gate as verification layer → captain review with partner-trust SLA. The seed has been updated to reflect the "trust but verify" framing.

### Q3: Ring 2.5 — vetted external contributors?

**Jordan:** Implicitly deferred by "capture this as a seed (all of this) and then let's apply it." Seed captures Ring 2.5 as an open question for when we actually have community contributors graduating from Ring 3.

**Decision:** Deferred until we have a real candidate. Not a Day 1 problem. Park it in the seed.

---

## Apply mode — execution began

**Jordan:** "So, capture this as a seed (all of this) and then let's apply it"

Seed written and updated. Application phase commenced. See below for full session continuation.

---

## Session continuation: 2026-04-11 → 2026-04-12

### What was built (in session order)

**Contribution model rollout:**
- ✅ `claude/docs/CONTRIBUTION-MODEL.md` — three-ring trust reference doc
- ✅ `CONTRIBUTING.md` — contributor front door (repo root)
- ✅ `.github/PULL_REQUEST_TEMPLATE.md` — contributor PR template
- ✅ `agency/config/agency.yaml` — full principal identity (email, github, platforms)
- ✅ PR #76 (D36-R2) merged — CI now green

**Feedback batch to Anthropic (6 items, 3 filed):**
1. ✅ FILED: Comms gap — `/feedback` broken 5+ months while team directs users to it → [#46531](https://github.com/anthropics/claude-code/issues/46531) / `95fe4771`
2. ✅ FILED: Debug logging — log `/feedback` errors to `~/.claude/debug/` → [#46538](https://github.com/anthropics/claude-code/issues/46538) / `229cbbce`
3. ✅ FILED: Content filter opacity — zero diagnostic signal → [#46546](https://github.com/anthropics/claude-code/issues/46546) / `cc00b303`
4. DRAFTED: Agent permission UX / trusted framework paths
5. DRAFTED: `--agent/--name` env var missing
6. DRAFTED: macOS permissions break on every update
7. TO DRAFT: `/feedback` should auto-include Feedback ID in GitHub issue body

**Key moment:** discovered that `/feedback` has been broken since November 2025 (GitHub #10905, closed + auto-locked, 21 comments reporting continued failure). Found @trq212's tweet directing users to `/feedback` during Opus 4.5 degradation in Feb 2026. Jordan made this public via @AgencyGroupAI tweet same day.

**Figma → UI research (4 parallel agents):**
- Agent 1: Designer workflow for handoff-ready Figma files
- Agent 2: Codegen tooling survey (Builder.io, Figma Make, Anima, Locofy, etc.)
- Agent 3: Design-system bridge (DTCG tokens, Style Dictionary, shadcn/Tamagui pipelines)
- Agent 4: React vs React Native platform differences

All 4 completed. Reports saved to `agency/workstreams/agency/seeds/research-figma-*-20260411.md`. Dispatch sent to monofolk for parallel research. Key finding: nobody has solved React Native cleanly; Builder.io Visual Copilot is the best option but no Tamagui target.

**mdslidepal (new workstream — markdown slide tool):**
- Shared contract spec written (v1.0 → v1.1 → v1.2 → v1.3)
- Shared theme JSON files created (agency-default, agency-dark + schema)
- 8-fixture corpus committed
- Plan B safety net committed (reveal.js vendored, template works NOW)
- MAR with 4 agents (technical correctness, completeness, scope realism, divergence risk) — all autonomous triage applied
- Two planning agents (web + mac) ran in parallel — both plans completed
- Reconciliation: 4 decisions resolved 1B1:
  1. Fixture 08 strictness: Option B (50-line regex pre-processor)
  2. License: RSL (matches app-workstream precedent)
  3. File layout: workstream for coordination, apps/ for source trees
  4. Mac CLI: GUI only for MVP
- Implementation ready: web agent Saturday sprint, Mac agent proper pace

**CLAUDE.md bootloader refactoring (NEW):**
- Jordan observed CLAUDE-THEAGENCY.md is too big, should be a bootloader not a constitution
- Discussion produced the bootloader model: ~200-300 words of orientation, everything else via skills + hookify + ref-injector
- Seed captured at `agency/workstreams/agency/seeds/seed-claude-md-bootloader-refactoring-20260412.md`
- Handed to DevEx for execution, captain supervises

**Workshop updates:**
- Kiren Kumar (DCEO IMDA) confirmed attending with 2 officers (Spenser, Zeph) — intent to "upskill many more"
- Jordan tweeted about /ultraplan from @AgencyGroupAI
- /ultraplan tested — remote container failed after 90 minutes (silent failure — another data point for the feedback batch)

### Decisions captured

| Decision | Resolution | Who decided |
|---|---|---|
| Three-ring contribution model | Approved: Ring 1 Internal / Ring 2 Sister Projects (trust but verify) / Ring 3 Community | Jordan |
| Monofolk = Ring 2 | "They follow our processes, but not necessarily all of our players. Trust but verify." | Jordan |
| Feedback filing via /feedback + gh cross-file | Yes, always cross-file. Captain authors, principal files. | Jordan |
| mdslidepal name | mdslidepal (following "pal" convention) | Captain (Jordan confirmed) |
| Fixture 08 strictness | Option B — 50-line regex pre-processor in web Iteration 1 | Jordan |
| mdslidepal license | RSL (matches app-workstream precedent) | Jordan |
| File layout (workstream vs source tree) | "Workstream and source trees are different. One is how we manage things vs. where we put our source." | Jordan |
| Mac CLI | GUI only for MVP | Jordan |
| CLAUDE.md bootloader | Yes — DevEx runs, captain supervises, hyper warp | Jordan |
| Session as case study | "Transcript this and we make this all a case study for the workshop!" | Jordan |

### Handoffs

- **DevEx dispatch #201:** CLAUDE.md bootloader refactoring + contribution model rollout (CI, commit-precheck, ci-monitor, monofolk dispatch, branch protection, D36-R3 PR)
- **mdslidepal-web:** plan ready at `plan-mdslidepal-web-20260411.md`, implementation agent starts Saturday
- **mdslidepal-mac:** plan ready at `plan-mdslidepal-mac-20260411.md`, implementation agent starts at proper pace
- **Monofolk:** Figma research + ultraplan dispatch already sent, awaiting response

### Workshop case study note

**Jordan:** "Transcript this and we make this all a case study for the workshop!"

This entire session — from the PR #76 CI fix through the three-ring contribution model through the Anthropic feedback batch through the Figma research through mdslidepal planning through the CLAUDE.md bootloader discussion — is a real-world demonstration of the Valueflow in action. It shows:

- Seed capture → structured discussion → 1B1 decisions → execution
- Parallel agent research (4 agents, 4 angles, background execution)
- Contract-based multi-platform planning (shared spec, platform-specific plans)
- MAR with autonomous triage (4 reviewers, three-bucket disposition)
- Reconciliation protocol (divergence detection, decision resolution)
- Cross-repo coordination (monofolk dispatches)
- Feedback lifecycle (draft → review → file → cross-reference → track)
- Delegation patterns (captain → DevEx handoff)
- All in one session, with real artifacts committed to the repo

The case study for the workshop writes itself from this transcript.

---

*Transcript closed for this session. Case study development begins in the next session focused on workshop course materials.*

---

## Feedback 1B1 — Anthropic Claude Code reports

Mid-rollout, we discovered `/feedback` has been broken for weeks (silent failure). Master list of pending feedback lived at `usr/jordan/captain/anthropic-issues-to-file-20260406.md` with 4 items drafted but never filed, plus 1 new item (content filter opacity) drafted today.

**Jordan's public action:** Tweeted from @AgencyGroupAI calling out the content filter silent-failure pattern. Public pressure to improve.

**Draft list (all in `usr/jordan/reports/`, awaiting principal review):**
1. `feedback-slash-feedback-silent-failure-20260411.md` (META — high)
2. `feedback-content-filter-opacity-20260411.md` (tweet public)
3. `feedback-agent-permission-ux-20260411.md` (folds in brace expansion)
4. `feedback-agent-name-env-var-20260411.md`
5. `feedback-macos-permissions-break-on-update-20260411.md`

**Jordan:** "let's 1B1 them"

Proceeding 1B1 in priority order.
