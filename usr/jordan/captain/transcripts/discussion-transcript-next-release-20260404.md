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

