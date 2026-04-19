---
type: seed
workstream: agency
date: 2026-04-09
origin: captain Day 34 session — run-in Triangle build
status: captured
---

# Telemetry-Driven Tool Discovery

## The insight in one sentence

**The Bash tool log is a list of the tools we haven't built yet.**

## What happened

While building the `run-in` tool (and its hookify block against compound bash commands), Jordan said: *"We can analyze the record of compound commands and build other tools."*

That statement flipped a framework switch. It named a pattern that we've been doing informally for weeks but had never articulated as a discipline. Every time an agent writes `cd foo && bar && cd -`, that is not just a noisy bash command — it is a **request for a tool that does not yet exist**. The agent is papering over a missing primitive with shell plumbing. The friction is legible; the telemetry log sees it.

If the telemetry log captures every compound bash command, then the log itself is a queue of "tools that should exist but don't." We do not have to guess which tools to build next. We can **mine** the log for frequency, classify the patterns, and build a dedicated Agency tool for each high-frequency pattern.

## The loop

```
1. Agent writes a compound bash command (the hackaround).
2. Telemetry records the attempt and the pattern.
3. A scanner mines the log for high-frequency compound patterns.
4. For each pattern, the question: is there already a tool?
   - If yes: the agent didn't find it → discovery problem (skill, CLAUDE.md pointer).
   - If no: build a purpose-built tool → deprecate the pattern.
5. A hookify rule blocks the hackaround pattern, pointing to the new tool.
6. Agent uses the new tool. Telemetry records it cleanly. Audit trail intact.
7. Observe the next high-frequency pattern. Repeat.
```

## Why this is a framework primitive, not a one-off idea

Most frameworks evolve by *intuition* — someone notices a pain point and builds a tool. TheAgency already does this. But the telemetry-driven loop **inverts the causality**: the data chooses the tools, not the human. The human's job shifts from *spotting* friction to *interpreting* the friction that the data already surfaces.

This has implications far beyond compound bash commands:

- **Every missing tool announces itself through workaround patterns.** Compound bash is one category. Others include repeated ad-hoc scripts in `tmp/`, duplicated inline logic across tool calls, multi-step manual sequences that always happen together, repeated permission prompts on the same operation.
- **The friction is legible.** We do not need user feedback, surveys, or agent introspection to find it. The telemetry already has it.
- **Tool adoption has a built-in feedback signal.** If the hackaround pattern keeps appearing after the tool ships, the tool has a discoverability problem. Fix the skill, fix the hookify rule, fix the docs.
- **Deprecation is mechanical.** When a tool covers a pattern well, the hookify rule blocks the hackaround. The pattern stops appearing in the log. The tool's value is measured by the absence of the thing it replaced.

## The framework pattern name

**Friction → Telemetry → Tool → Block → Flow.**

Five steps. Each step is observable. Each step has a primitive in the framework already:

| Step | Primitive |
|------|-----------|
| Friction | The raw Bash tool call attempt |
| Telemetry | `log_start` / `log_end` in every Agency tool + the `bash` event hook |
| Tool | `agency/tools/{tool}` with the Triangle |
| Block | `agency/hookify/hookify.block-{pattern}.md` |
| Flow | The new primitive is used; telemetry confirms the pattern has stopped |

## Where this belongs

- **README-THEAGENCY.md** — add a section "Telemetry-Driven Tool Discovery" that explains this loop as a design principle. This is a first-class framework claim about *how TheAgency evolves*, not just a tactical observation.
- **CLAUDE-THEAGENCY.md** — add a short paragraph under Tool Discipline pointing to the loop, with a pointer to this seed for the long explanation.
- **Articles / talks / book** — this is the framing for "why TheAgency builds tools the way it builds tools." The telemetry-driven loop is the *methodology*; the Triangle (Tool + Skill + Hookify) is the *structure*; the Ladder (document → skill → tool → warn → block) is the *adoption curve*. All three together form the complete story of framework evolution.

## Immediate next actions

1. **Build the scanner.** A small Agency tool that reads `tool-runs.jsonl` (or wherever Bash tool calls land), extracts compound commands, classifies by shape (cd-compound, pipe-chain, sequence, substitution), and ranks by frequency. Output: a ranked list of "tools to build."
2. **Run the scanner against our current logs.** See what's on top. The top entry after `cd-compound` becomes the next Triangle build.
3. **Repeat weekly.** Telemetry-driven tool discovery is not a one-shot — it's a recurring review. Surface the ranked list in the captain's log as a weekly pattern review.

## The harder question this surfaces

If the Bash tool log is a list of the tools we haven't built, then **every framework has a telemetry-shaped shadow of the tools it's missing**. Most frameworks never look at it. Most projects don't even collect it. Teams building with LLMs are producing massive streams of friction data right now, and almost none of it is being mined for tool opportunities.

This feels like a *thesis*, not just a tactic. The framework that mines its own friction is the framework that evolves fastest. TheAgency ships that as a built-in.

## Related

- Tool: `agency/tools/run-in` (the first tool built under this discipline)
- Hookify: `agency/hookify/hookify.block-compound-bash.md`
- Flag #54 — "Analyze telemetry logs of Bash tool calls to mine compound command patterns"
- Framework primitives: Triangle, Ladder, Valueflow
