# mdpal Bootstrap Transcript Mining — Findings for ISCP

**Date:** 2026-04-04
**Source:** mdpal-cli session (ac938883) and mdpal-app session (41066ba7)
**Relevance:** These findings directly inform ISCP design — the dispatch/handoff friction is what ISCP needs to solve.

---

## #1 Finding: Worktree/Master Path Confusion (Systemic)

The biggest source of friction across both sessions. mdpal-app used master paths **66 times** vs worktree paths **13 times**. Consequences:

- Commits going to wrong location (PVR committed to master instead of worktree)
- Dispatches committed on master were invisible to agents on the worktree
- Handoffs written to master, then manually copied to worktree
- User had to repeatedly ask "Did you look on the worktree or master?"

**ISCP implication:** The notification layer must be worktree-aware. An agent on a worktree needs to know about dispatches on master without having to merge first. The DB (outside git) solves notification; the payload location convention solves discovery.

## #2 Finding: dispatch-create and handoff Tools Principal Resolution Bug

Both tools resolved `$USER` to `testuser` instead of `jordan` in worktree context. The `_path-resolve` library's `AGENCY_PRINCIPAL` env var was leaked from the test suite.

**ISCP implication:** The new dispatch/flag tools must not rely on `AGENCY_PRINCIPAL` being correct in the environment. Validate against agency.yaml every time, or at minimum verify the resolved path exists.

## #3 Finding: Bootstrap Chicken-and-Egg

Agent registrations (`.claude/agents/mdpal-*.md`) said "Read your role" but didn't reference handoff files. The handoff paths were only in the handoff files themselves — which the agent needed to find first. The handoff wasn't on the worktree yet (needed `git merge main`).

**ISCP implication:** Bootstrap notifications ("you have a handoff") need to work before the agent has merged main. The DB notification layer handles this — agent gets "you got mail" pointing to the handoff location, regardless of git state.

## #4 Finding: Cross-Agent Dispatch on Same Worktree Fails

mdpal-cli and mdpal-app shared a worktree. mdpal-app committed a dispatch to master; mdpal-cli on the worktree couldn't find it. Required explicit user intervention to check master path.

**ISCP implication:** Same-worktree agents need a notification channel that doesn't depend on git state. The SQLite DB outside the repo handles this naturally.

## #5 Finding: No Versioning Convention for Artifacts

Agent tried to overwrite the PVR in-place. User caught it: "Why are you overwriting?!? Version! Always Version!" No naming convention was communicated.

**ISCP implication:** Dispatch payloads should be immutable once written. Convention: `{type}-{YYYYMMDD-HHMM}.md`. The notification points to a specific file, not a mutable path.

## #6 Finding: "Act on Startup" Doesn't Work Reliably

mdpal-cli said "Ready." and waited. mdpal-app partially self-oriented but only because the user asked "What should you be doing?" The agent registration had passive "Read..." directives that weren't treated as imperative.

**ISCP implication:** ISCP v1 hook fires on SessionStart, checks for unread items, and surfaces them. This replaces reliance on agents reading their own handoff unprompted.

## #7 Finding: Transcript Discipline Failures

Both agents summarized instead of capturing actual dialogue. Each corrected 2-3 times. 1B1 protocol violated multiple times (blasting through items).

**ISCP implication:** Not directly ISCP, but transcripts are a dispatch payload type. Formalize transcript location and commit discipline — transcripts must get to master ASAP and be accessible to any workstream.

## Key Metrics

| Metric | mdpal-cli | mdpal-app |
|--------|-----------|-----------|
| Total tool calls | 82 | 100 |
| Orientation tool calls | ~18 | ~12 |
| Master-path calls | 1 | 66 |
| Worktree-path calls | 50 | 13 |
| User corrections needed | ~6 | ~8 |
| Self-oriented on startup | No | Partially |

## Patterns Worth Replicating

1. **Parallel read burst on startup** — mdpal-app read handoff, counterpart handoff, agent.md, KNOWLEDGE.md all at once. Best bootstrap behavior observed.
2. **Dispatch-based cross-agent coordination** worked well once files were in the right place. Structured format with frontmatter carried enough context.
3. **MAR loop for PVR review** — four parallel agents found real issues.

## Patterns to Avoid

1. **Passive directives in registrations** — not treated as imperative. Need hooks or explicit "On startup, do X before responding."
2. **Same worktree for cross-agent file sharing** without sync discipline.
3. **Summarizing transcripts** instead of capturing dialogue verbatim.
