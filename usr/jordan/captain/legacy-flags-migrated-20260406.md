---
type: reference
date: 2026-04-06
source: usr/jordan/flag-queue.jsonl (legacy pre-ISCP flag queue)
migrated_by: the-agency/jordan/captain
---

# Legacy Flags — Migrated from flag-queue.jsonl

62 flags from sessions 17-19 (2026-04-03 to 2026-04-05). Categorized for triage.

---

## Bugs (12)

1. **agent-create does not register in settings.json** — `2026-04-04` (session 17)
2. **Ghostty tab-status icons wrong** — filled circle for idle (should be hollow), filled triangle for input-needed — `2026-04-04`
3. **`--name` flag on claude CLI doesn't set AGENTNAME env var** — tabs all show 'agent' — `2026-04-04`
4. **/feedback command broken** — gives SHA but feedback never filed, silent failure — `2026-04-04`
5. **agency-init blocked on non-main branch** — fresh git init repos have no branch yet — `2026-04-04`
6. **BATS tests write to live INDEX.md and releases.md** — test isolation failure — `2026-04-04` (FIXED by ISCP efa00d6)
7. **agency-init flat principals format** — wrote `jordan: jordan` instead of nested — `2026-04-04`
8. **agent-create no bootstrap handoff** — skill says single write path but doesn't write one — `2026-04-04`
9. **No tech-lead template in agent-create** — primary class has no template — `2026-04-04`
10. **agent-create placeholder text** — `[Key responsibility]` and wrong myclaude command — `2026-04-04`
11. **agent-create creates extra files** — IDEAS.md, ONBOARDING.md, logs/permissions.md not in spec — `2026-04-04`
12. **agency-init doesn't ship flag and handoff tools** — Enforcement Triangle broken — `2026-04-04`

## Friction (10)

13. **Bootstrap agents prompted for own handoff** — need pre-approved in settings.json — `2026-04-04`
14. **Brace expansion triggers permission prompts** — agency-init must avoid — `2026-04-04`
15. **Bootstrap agents don't auto-act** — "act on startup" prose unreliable — `2026-04-04`
16. **Stop hook repeats uncommitted changes warning** — same file flagged 3+ times — `2026-04-04`
17. **Hookify rule messages full-screen** — should be one-liners with doc pointer — `2026-04-04`
18. **agency-init settings-template missing usr/** pre-approval** — `2026-04-04`
19. **ISCP agent prompted for git commit** — git-commit needs pre-approved permissions — `2026-04-04`
20. **ISCP agent prompted for own handoff/dispatches** — worktree settings need broader usr/** — `2026-04-04`
21. **Worktree status line redundant** — name shown 3 times — `2026-04-04`
22. **Explore agent overkill on bootstrap** — 22 tool calls for lightweight orientation — `2026-04-04`

## Decisions (7)

23. **Drop iTerm, go Ghostty-only** for terminal status integration — `2026-04-04`
24. **Kill agency-service** — replaced by ISCP + dispatches — `2026-04-04`
25. **the-agency-starter repo sunset** — agency-init replaces it — `2026-04-04`
26. **Kill /agency dispatcher skill** — old model — `2026-04-04`
27. **agency init runs BEFORE claude init** — git init → agency init → claude init — `2026-04-04`
28. **Seeds live in workstream dir** — `claude/workstreams/{name}/seeds/` — `2026-04-04`
29. **Transcript skill silent** — don't echo captured content, just confirm — `2026-04-04`

## Tool Gaps (10)

30. **Command audit** — review all / commands for relevance — `2026-04-03`
31. **Multi-agent handoff** — tool hardcoded to handoff.md, needs per-agent — `2026-04-03`
32. **Worktree merge-main tool** — pre-approved `git merge main` — `2026-04-03`
33. **Transcript mining automation** — manually mining 58MB transcripts expensive — `2026-04-04`
34. **Environment-setup skill** — detect platform, guide provider setup — `2026-04-04`
35. **Dispatch auto-mark read** — done by ISCP — `2026-04-04` (DONE)
36. **Test management** — multiple frameworks, define boundary run — `2026-04-04`
37. **SessionStart validation hook** — verify principal, usr/, tools, agency.yaml — `2026-04-04`
38. **Provenance header enforcement** — hookify rule + telemetry — `2026-04-04`
39. **/push skill (Enforcement Triangle)** — prevents direct push to origin/main — `2026-04-04`

## Process (5)

40. **Handoff typed frontmatter** — session-restore, agency-bootstrap, agent-bootstrap — `2026-04-04`
41. **Dispatches sent to old path** — monofolk using pre-migration layout — `2026-04-04`
42. **All non-destructive tools pre-approved** — zero prompts for own files — `2026-04-04`
43. **Inline scripts without provenance** — the pattern that motivated the discipline rule — `2026-04-04`
44. **MAR acronym not in CLAUDE-THEAGENCY.md** — agents don't recognize it — `2026-04-04`

## Content / Community (6)

45. **Adopt vouch model** — look at Ghostty CONTRIBUTING and AI-POLICY — `2026-04-04`
46. **Retarget the-agency-starter followers** to the-agency — `2026-04-04`
47. **X/Twitter monitoring** — @AgencyGroupAI, explore API — `2026-04-04`
48. **Build own X/Twitter MCP** — post, read mentions, search — `2026-04-04`
49. **Jordan TODO: X developer account** — developer.x.com, Basic tier — `2026-04-04`
50. **Private content repo** — the-agency-ai/the-agency-content — `2026-04-04`

## Ideas / Future (6)

51. **Review mdpal bootstrap transcripts** — learn what worked/didn't — `2026-04-03`
52. **Flag tool persistence** — git add on write, warn on SessionStart — `2026-04-03` (DONE — ISCP)
53. **Thoughts on Principles document** — tent poles, progress over perfection — `2026-04-04`
54. **Test result reporting service** — DB-backed, structured, wires into QG — `2026-04-04`
55. **claude/dropbox/ staging area** — file staging between worktrees, tied to ISCP — `2026-04-04`
56. **Always-on transcription** — compaction lost detailed discussion, auto-capture all dialogue — `2026-04-05`

## Resolved (6)

57. **BATS test isolation** — `2026-04-04` → FIXED by ISCP (efa00d6, 52222e7)
58. **Dispatch auto-mark read** — `2026-04-04` → DONE in dispatch tool
59. **Flag persistence** — `2026-04-03` → DONE (ISCP DB-backed flags)
60. **SessionStart hook force startup** — `2026-04-04` → PARTIALLY DONE (iscp-check hook)
61. **/push Enforcement Triangle** — `2026-04-04` → IN PROGRESS (Development Workflow seed)
62. **testuser principal leak** — `2026-04-04` → artifact, not actionable
