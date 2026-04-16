---
type: release-planning
date: 2026-04-04
release: next
status: 1B1 in progress
---

# The Agency — Next Release Items

29 items for 1B1 discussion → PVR → A&D → Plan.

## Tier 1: Must Ship (Bootstrap & Permissions)

1. **Fix agency-init** — flat principals format, blocks on branchless repos, missing usr/** permissions in settings-template, doesn't ship flag+handoff tools, brace expansion triggers prompts
2. **Fix agent-create** — no bootstrap handoff, no tech-lead template, placeholder text in agent.md, doesn't register in settings.json, creates extra unspecified files
3. **Pre-approved permissions** — all non-destructive ops (read, ls, flag, dispatch read/list) zero-prompt on agent's own files in settings-template.json
4. **SessionStart hook** — mechanical startup sequence (not prose), validates principal resolves, usr/ exists, tools present, agency.yaml well-formed
5. **/push skill** — Enforcement Triangle for git push. Branch, push branch, create PR via gh. Block raw git push to origin/main.
6. **BATS test isolation** — AGENCY_PRINCIPAL=testuser leaks into shell, tests write to live INDEX.md and releases.md instead of fixtures
7. **Handoff tool multi-agent** — support {agent}-handoff.md per agent, not just handoff.md. workstream-create must scaffold these.

## Tier 2: Should Ship (Tooling & DevEx)

8. **Transcript mining tool** — formalize mine-transcripts.sh from usr/jordan/captain/tools/, ship to claude/tools/
9. **Dispatch auto-read** — mark dispatches as read after agent consumption
10. **Hookify rules terse** — one-liners with doc pointer (started with monofolk sync, continue pattern)
11. **Handoff typed frontmatter** — session-restore, agency-bootstrap, agent-bootstrap types so tools distinguish purpose
12. **Transcript commit discipline** — transcripts to master ASAP, accessible to all workstreams
13. **Kill agency-service** — replaced by ISCP + dispatches model. Remove all code and references.
14. **Kill /agency dispatcher** — old model, skills replace it
15. **DevEx workstream** — starter pack → provider catalog migration (from monofolk DevEx dispatch)

## Tier 3: Community, Content & Infrastructure

16. **the-agency-starter sunset** — README update, pinned issue explaining transition, archive repo. Mention mdpal and M&M as what's coming.
17. **Vouch model** — CONTRIBUTING.md, AI-POLICY.md, modeled on Ghostty's approach. Curated community.
18. **the-agency-content repo** — private repo the-agency-ai/the-agency-content, agency model, articles/book/workshops. jordandm + jordan-of access. Jordan works from both the-agency and monofolk contexts.
19. **X/Twitter integration** — build own MCP server/tool (not third-party). Post, read mentions, read timeline, search. Needs X API Basic tier ($200/mo). Jordan TODO: set up developer account at developer.x.com with @AgencyGroupAI.
20. **Provenance header enforcement** — hookify rule to warn when code written without What Problem / How & Why header. Telemetry to track compliance.
21. **MAR in CLAUDE-THEAGENCY.md** — define Multi-Agent Review acronym, document the pattern
22. **PROVIDER-SPEC.md** — formalize provider contract (required functions, signatures, exit codes, output format, env contract, error handling, registration). From DevEx dispatch.

## ISCP Owns (iscp workstream)

23. **Dropbox** — claude/dropbox/{principal}/{agent}/ file staging on master. Push from worktree→master, fetch from master→worktree.
24. **Flag agent-addressable + SQLite** — persistence outside repo, agent-addressable addressing
25. **Dispatch lifecycle** — create→commit→propagate→fetch→notify, full formalization
26. **Cross-repo delivery** — monofolk ↔ the-agency ↔ ghostty

## Decisions Needed

27. **Seeds location** — workstream dir (claude/workstreams/{name}/seeds/) or usr/{principal}/{agent}/seeds/?
28. **agency-init ordering** — agency init before or after claude init? (git init → agency init → claude init?)
29. **Ghostty-only terminal integration** — drop iTerm support, go Ghostty-only for status hooks?
