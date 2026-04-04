# Discussion Transcript: Next Release Scoping — 29 Items

**Date:** 2026-04-04
**Mode:** discussion
**Branch:** main
**Participants:** Jordan (principal), Captain (agent)
**Source:** `usr/jordan/captain/next-release-items-20260404.md`

---

## Item 1: Fix agency-init

**Decision:** #1 priority. Five bugs (flat principals, branchless repos, missing usr/** permissions, missing flag+handoff tools, brace expansion). Front door to the framework — if init is broken, nothing else matters. Smoke test against fresh repo + Ghostty fork as real-world target.

---

## Item 2: Fix agency-update

**Decision:** #2 priority. Three audiences: monofolk (active), starter migrants (transitioning), new adopters (future). Tier assignment for framework vs project files, never overwrite project config, handle add/update/remove. Without this, every adopter forks and drifts.

---

## Item 3: Fix agent-create

**Decision:** #3 priority. Five bugs (no bootstrap handoff, no tech-lead template, placeholder text, extra files, no settings registration). Two entry points: standalone (agent-create on its own) and as dependency of workstream-create's agent assignment phase. Same tool, same output either way.

---

## Item 4: Pre-approved permissions

**Decision:** High priority, fix early. Known gaps (usr/**, claude/**, .claude/**, non-destructive tools) into settings-template.json immediately. Systematic discovery: mine tool logs and transcripts for permission prompts, either pre-approve or wrap in tools. Captain's discretion on organizational home.

---

## Item 5: SessionStart hook

**Decision:** Keep pushing toward mechanical enforcement. Iterate, learn from transcripts, dial tighter each pass. Progress over perfection — aim for ideal, don't block on it.

---

## Item 6: /pr skill (was /push)

**Decision:** Renamed to `/pr`. Captain-only skill. Workflow: build PR branch from landed workstream work → pre-PR quality gate → create PR via gh → push → auto-merge after CI (no human review). Push is an implementation step inside /pr, not separate. Full Enforcement Triangle: tool + skill + hookify rule. Block all push to origin AND all `gh pr create` from non-captain agents. PRs are logical units of work — typically one workstream, buildable, testable, delivers value. Quality gates already ran at every boundary — the PR is just the delivery mechanism.

---

## Item 7: BATS test isolation → Docker container test execution

**Decision:** Docker containers for all test runs. Full Enforcement Triangle: tool (container runner with structured output), skill (/test or similar), hookify (block raw test commands). Engineers never run tests directly — skill orchestrates, container isolates, results come back structured. Test isolation as best practice enforced through tooling, not discipline. Bonus: runs clean locally = runs clean in GitHub Actions CI. Future: test result reporting service (database-backed, wired into quality gates, similar pattern to ISCP/dispatches).

---

## Item 8: Handoff tool multi-agent

**Decision:** Support {agent}-handoff.md per agent. Agent name from --agent flag or agent registration. workstream-create scaffolds per-agent handoff files during agent assignment. Straightforward fix.

---

## Item 9: Transcript mining tool

**Decision:** Formalize mine-transcripts.sh and ship to claude/tools/. Mine and analyze for now. Downstream: agentic pipeline for automated friction detection and usage pattern analysis. Feeds into permissions discovery (Item 4) and continual improvement loop.

---

## Item 10: Dispatch auto-read

**Decision:** Abstraction layer now — clean interface ("mark as read" / "get unread"), file-rename implementation behind it. When ISCP delivers SQLite, swap implementation, callers don't change. Dispatch the requirement to ISCP so they design for it. Burns context and tokens every session — high urgency for short-term hack.

---

## Item 11: Hookify rules terse

**Decision:** Adopt as the standard pattern for all hookify messages, current and future. One-liner + doc cross-reference + kittens. Audit remaining verbose rules and tighten. Token-efficient, agents parse fast, doc pointer gives depth when needed.

---

## Item 12: Handoff typed frontmatter

**Decision:** Add type: field to handoff frontmatter (session-restore, agency-bootstrap, agent-bootstrap). Tools and SessionStart hook adjust behavior based on type. Small change, big leverage.

---

## Item 13: Transcript commit discipline

**Decision:** Transcript tool dual-writes: current worktree (local access) AND master checkout (shared access). Agents don't think about it — tooling handles accessibility automatically.

---

## Item 14: Kill agency-service

**Decision:** Delete all code, remove all references. Salt the earth. Same treatment as ADHOC. ISCP + dispatches + skills replace everything it was trying to do.

---

## Item 15: Kill /agency dispatcher

**Decision:** Document what it was, why it was built, why it failed — capture patterns and anti-patterns before deleting. Inform future design decisions. Then delete.

---

## Item 16: the-agency-starter sunset

**Decision:** Mine starter repo for uncaptured content. Reach out to 8 stargazers, 1 follower, 1 fork — notify them of transition to the-agency. Update README with redirect + migration guidance. Pin transition issue. Archive once agency-update (Item 2) proves the migration path. Also review/update the-agency's own README.

---

## Item 17: Vouch model

**Decision:** Ghostty-style vouch model (CONTRIBUTING.md) — apply via GitHub Discussion, human vouches, agent pre-screens. AI-POLICY.md grounded in Anthropic's 4Ds (Delegation, Description, Discernment, Diligence). Transparent about agent-built/principal-directed workflow. Jordan's Ghostty vouch submission (ghostty-org/ghostty#12093) as the template. Both docs needed before public launch.

---

## Item 18: the-agency-content repo

**Decision:** Create the-agency-ai/the-agency-content (private). Migrate all content from the-agency (voice guide, article queue, workshop materials, book). Agency repo with content workstreams (articles, book, workshops, presentations). Captain oversees as CoS across repos. Add to sync loop. Both jordandm and jordan-of access.

---

## Item 19: X/Twitter integration

**Decision:** Custom X MCP server/tool (not third-party). Pay-per-use tier — expected under $10/mo for our volume ($0.01/post write, $0.005/post read). Jordan TODO: developer account at developer.x.com with @AgencyGroupAI. Curated follow/watch list for intelligence gathering (Boris, Anthropic, Claude AI, targeted list). Purpose: information into knowledge base, not social engagement.

---

## Item 20: Provenance header enforcement

**Decision:** Hookify rule on Write to code files — check for `What Problem:` and `How & Why:` with non-empty content after each marker. Block if missing. Full Enforcement Triangle: hookify rule (block) + skill (part of QG) + telemetry for compliance tracking. Standard kittens trademark.

---

## Item 21: MAR in CLAUDE-THEAGENCY.md

**Decision:** Define MAR (Multi-Agent Review) as a formal pattern in CLAUDE-THEAGENCY.md. Four parts: (1) concept + acronym definition, (2) the review loop — create → MAR → findings → discuss with principal if needed → revise → repeat until clean, (3) composition per quality gate — iteration QG, phase QG, plan-end QG, pre-push/PR, PVR review, A&D review, plan review, reference review — each with generic review agents + named domain agents (e.g., captain reviews ISCP, sibling agents cross-review) + principal in the loop, (4) red-green discipline — every code finding gets a bug-exposing test first (red), then fix (green), no exceptions for nits. Enforcement Triangle for test-before-fix ordering. Quality compounds through consistent discipline, loop after loop.

---

## Item 22: PROVIDER-SPEC.md

**Decision:** Yes, formalize PROVIDER-SPEC.md. Create DevEx workstream + agent in the-agency to own it. Bootstrap with context transfer from monofolk's DevEx agent — especially provider work and starter pack migration decisions. Use collaboration-monofolk repo as coordination channel. The-agency DevEx scope: great developer experience for both agents and principals.

---

## Item 23: ISCP — Dropbox

**Decision:** Dropbox sits outside the repo (not claude/dropbox/). ISCP owns design and implementation. No ducking.

---

## Item 24: ISCP — Flag SQLite

**Decision:** ISCP owns. Database sits outside the repo.

---

## Item 25: ISCP — Dispatch lifecycle

**Decision:** ISCP owns. Database sits outside the repo. Same principle as dropbox and flags: don't bloat repos with operational data.

---

## Item 26: ISCP — Cross-repo delivery

**Decision:** ISCP owns eventually. Priority order: (1) intra-agency communication first (current ISCP work), (2) inter-agency same repo, (3) cross-repo same value stream (collab repos via GitHub as bridge), (4) cross-repo different value streams. ISCP grows into each layer as the previous one stabilizes.

---

## Item 27: Seeds location

**Decision:** Seeds live in claude/workstreams/{name}/seeds/. They belong to the workstream, not the agent. Input material that predates agent assignment, persists regardless of who works on them.

---

## Item 28: agency-init ordering

**Decision:** Already settled: git init → agency init → claude (just run Claude Code). Not reopened.

---

## Item 29: Ghostty-only terminal integration

**Decision:** Ghostty-only for terminal integration — covers macOS and Linux. Not anti-iTerm, but we don't maintain other terminals. Community contributes via vouch/contribution model. IDE targets: VS Code and Zed. No Cursor (uses model but not Claude Code). Four supported surfaces: Ghostty, VS Code, Zed, CLI. Community adds others.

---

## 1B1 Complete

All 29 items resolved across two sessions (2026-04-04 and 2026-04-05).

---

