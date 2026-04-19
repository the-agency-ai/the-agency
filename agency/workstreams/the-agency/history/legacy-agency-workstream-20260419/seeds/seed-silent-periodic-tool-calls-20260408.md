---
type: seed
workstream: agency
date: 2026-04-08
captured_by: the-agency/jordan/captain
principal: jordan
status: filed
parked_for_revisit: true
anthropic_feedback_id: 8dd67e96-63ea-4a22-b687-d26a1b2d0add
github_issue: https://github.com/anthropics/claude-code/issues/45017
report: usr/jordan/reports/report-silent-periodic-tool-calls-20260408.md
---

**FILED 2026-04-08.** Anthropic feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add`; GitHub issue [anthropics/claude-code#45017](https://github.com/anthropics/claude-code/issues/45017). Tracking at `usr/jordan/reports/report-silent-periodic-tool-calls-20260408.md`.


# Seed: Silent Periodic Tool Calls (Claude Code gap — external feature request)

## What this is

A feedback/feature-request document to file with Anthropic (Claude Code team) asking for a native mechanism to execute periodic tool calls silently — i.e., without rendering in the terminal transcript. This is a **dependency** for the Fleet Awareness workstream: the autonomous-agent awareness substrate can't be fully silent without Claude Code harness changes.

Parked for later revisit. We may wait until Fleet Awareness reaches a deeper design stage before submitting, so we can cite specific impact.

## The gap (short version)

Claude Code today has silent mechanisms (hooks, status line, async hooks, subagent internals) but none combine **silent + periodic + agent-context-aware**. The only periodic mechanism (`CronCreate`/`/loop`) always renders visibly. For autonomous agents that self-poll external state between user turns, this is pollution that scales linearly with polling frequency.

## Related Agency work

This seed intersects with several current workstreams:

- **Fleet Awareness** (`seed-fleet-awareness-20260408.md`) — the primary consumer. Fleet's `/startup`, heartbeat, and `/captains-report` skills all need periodic checks that today cannot be silent. This is documented as a **constraint** in the Fleet Awareness seed (question #7-related).
- **ISCP** (`agency/workstreams/iscp/`) — the `iscp-check` hook is our existing silent notification path, but it's event-driven (fires on user actions only). The peer-to-peer collaboration work (iscp plan #165) increases the value of live fleet awareness.
- **Captain's dispatch loop convention** (now in `agency/CLAUDE-THEAGENCY.md` → "When You Have Mail") — the 5-minute fast-path loop pattern is the concrete pain point. The 30-minute visible nag loop is fine as-is; the fast-path is what's polluted.
- **Day 33 R1 work** — this seed was captured mid-Day-33 during the conversation that also produced iscp-check delta suppression (v1.1.0), the status line candidate architecture investigation, and the peer-to-peer collaboration dispatch (#165).

## Our research

Two rounds of research via `claude-code-guide` agent confirmed:

1. **Round 1 (doc scan)** — no native silent-cron mechanism exists; background bash + file logging is the documented workaround; async hooks are silent but non-periodic.
2. **Round 2 (silence mechanisms catalog)** — hooks silent (event-driven), status line silent (footer-only, can't inject agent context), subagent internals silent (not periodic), async hooks silent (not periodic), cron visible. **No combination provides silent + periodic + agent-context-aware.**

## Two proposed options + one hybrid question

The insight: **hooks are already silent by design.** We don't need a new "silent mode" for agent turns. We need a periodic trigger that fires a hook-style execution rather than a full agent turn.

### Option 1 (preferred) — Periodic hook type in settings.json

```json
{
  "hooks": {
    "Periodic": [
      { "interval": "5m", "command": ".claude/tools/iscp-check" }
    ]
  }
}
```

Fires on a timer; runs silently like all other hooks; can inject via `additionalContext` into the next agent turn. This is the hook-based analogue of cron jobs. Reuses all existing hook infrastructure (silent execution, `additionalContext` injection, JSON output contract). Minimal new surface area.

### Option 2 — Status line for display-only polling (already exists; document it)

```json
{
  "statusLine": { "type": "command", "command": ".claude/tools/iscp-statusline" }
}
```

Status line commands already run periodically and silently (~every UI tick). Output renders in the footer bar, not the transcript. This solves **display** (user sees mail count in footer) but cannot inject into agent context (footer output doesn't reach the agent's next turn). Good complement to Option 1 — use it for the visual indicator, use Periodic hooks for the context injection.

### Hybrid question — can CronCreate trigger a HOOK fire instead of a turn?

```typescript
CronCreate({
  cron: "*/5 * * * *",
  hook: ".claude/tools/iscp-check",
  recurring: true,
})
```

Rather than scheduling a `prompt` (which fires an agent turn and renders), let CronCreate schedule a `hook` command. The scheduled fire runs as a hook — silent by design, can inject via `additionalContext`. This is arguably the cleanest implementation: **no new hook type, just a new scheduler variant.** The existing silent-hook machinery runs unchanged; only the trigger source changes.

**Ask Anthropic:** is this feasible? Does the existing scheduler have the plumbing to invoke a hook-style command instead of a turn? Which of the two options (Periodic hook type vs CronCreate-with-hook) is a smaller change?

## What we've tried (for the feedback)

1. Delta suppression in existing hook (`iscp-check v1.1.0`, shipped Day 33) — works, but hooks only fire on user events.
2. Empty-output bash tool — still renders the `Bash(command)` line.
3. Status line polling — silent, but can't inject into agent context.
4. Background detached bash loop — silent after spawn, but hook-gated notification lag.
5. Async hooks — silent but non-periodic.

## Use case for the feedback

Multi-agent framework ([the-agency](https://github.com/the-agency-ai/the-agency)) where each agent runs as its own Claude Code session and agents coordinate via a SQLite-backed inter-session communication protocol (ISCP). Agents need to notice incoming dispatches from other agents within ~5 minutes so they can respond to directives, reviews, and escalations while their principal is away.

## Mechanical notes for submission

- `/feedback` skill files to GitHub automatically on success — **one submission** covers both channels (Anthropic feedback + public issue)
- Principal identity to include: Jordan Dea-Mattson, @jordandm (the-agency-ai org), email TBD
- Claude Code version: run `claude --version` at submission time
- Repository reference: https://github.com/the-agency-ai/the-agency

## Draft feedback text (ready to submit via /feedback)

---

# Silent/hidden mode for scheduled tool calls (for autonomous agents)

**Summary.** Claude Code has no mechanism to execute periodic scheduled tool calls (`CronCreate`, `/loop`) without rendering them in the terminal transcript. For autonomous-agent infrastructure that needs to self-poll between user turns, every fire produces visible `⎿ Bash(command) + output` pollution.

**Existing silent mechanisms each fail for this use case:**

| Mechanism | Silent | Periodic | Agent-context-aware |
|-----------|--------|----------|--------------------|
| SessionStart / UserPromptSubmit / Stop hooks | ✅ | ❌ | ✅ |
| Async hooks (`"async": true`) | ✅ | ❌ | Partial |
| Status line command | ✅ | ✅ | ❌ (footer only) |
| Subagent execution (internals) | ✅ | ❌ | Returns-only |
| `CronCreate` / `/loop` | ❌ | ✅ | ✅ |
| Background `Bash(run_in_background: true)` | Partial | ✅ | ❌ (file-gated) |

**No combination gives silent + periodic + agent-context-aware.**

**Use case.** Multi-agent framework (the-agency, https://github.com/the-agency-ai/the-agency) where agents coordinate via SQLite-backed inter-session messaging (ISCP) and need to notice dispatches within ~5 minutes while the principal is away. Hook-based notification catches mail on `UserPromptSubmit` and `Stop`, but between events the agent is blind. Polling via `/loop` fills the gap but pollutes the interactive session — at 5-minute intervals, an 8-hour day produces ~100 visible "no-op" renders.

**What we tried.**
1. Delta suppression in a hook (`iscp-check v1.1.0`) — works but hook only fires on user events
2. Empty-output bash tool — `Bash(command)` line still renders
3. Status line polling — silent but can't inject into agent context
4. Background detached bash loop — silent but hook-gated notification lag
5. Async hooks — silent, non-periodic

**Proposed feature (any one of three would solve it).**

**Option A — `hidden: true` flag on CronCreate.** Scheduled turns execute but don't render.
**Option B — `Periodic` hook type.** Timer-based hook with same silent + additionalContext semantics as other hooks.
**Option C — Per-tool-call `hidden` parameter.** Individual `Bash(..., hidden: true)` suppresses render; tool still runs, result still in agent context.

**Why it matters.** Unblocks multi-agent frameworks, background sync agents, monitoring agents, and any long-running autonomous pattern where the agent is observer rather than prompt-responder. The Claude Code docs emphasize autonomous operation and composable building blocks — periodic silent self-awareness is the missing primitive.

**Reporter.** Jordan Dea-Mattson, @jordandm (the-agency-ai)
**Framework.** https://github.com/the-agency-ai/the-agency
**Claude Code version.** TBD at submission

---

## Revisit triggers

File this feedback when one of these is true:

1. **Fleet Awareness PVR reaches design review** — having the PVR lets us cite the concrete substrate we're building and quantify the polling frequency we need
2. **Day 34 or later release cycle** — avoid piling too much on the Day 33 R1 branch
3. **New Claude Code release ships** — check if any of the mechanisms above change before filing
4. **Second concrete use case surfaces** — currently the only consumer is Fleet Awareness; if another workstream hits the same gap, that strengthens the request

## Conversation source

Captured during Day 33 from a principal-captain conversation where captain mistakenly claimed the 5-minute dispatch loop was silent, principal corrected by observing "I see places where I am not seeing tool calls and their results in my terminal session," two rounds of research clarified the silent-mechanism catalog, and principal directed "file a /feedback and github issue on this one. Write it up per protocol."
