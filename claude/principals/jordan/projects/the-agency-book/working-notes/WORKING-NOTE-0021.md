# THE-AGENCY-BOOK-WORKING-NOTE-0021

**Date:** 2026-01-06 16:00 SGT
**Participants:** jordan (principal), housekeeping (agent)
**Subject:** Tools as Compiled Knowledge — Philosophy Deep Dive

---

## Core Philosophy

**Make doing it the right way, the fast way.**

Tools and services should make the correct approach also be the quickest, most efficient, and most effective approach.

---

## The Framing: Agent Efficiency First

The primary benefit is **agent efficiency** — the principal doesn't have to think and do. A tool replaces actions.

**Token efficiency is a side benefit.** Important, but secondary to the user experience of "I don't have to figure this out."

### The User Experience

Without tools:
- "How do I format this timestamp?"
- "What's the naming convention for instructions?"
- "What steps do I run before committing?"

With tools:
- `./tools/now`
- `./tools/capture-instruction "Title"`
- `./tools/pre-commit-check`

**The principal's cognitive load drops to near zero.** They just call the tool.

### The Token Benefit (Side Effect)

Every tool call that replaces reasoning:
- ~50-200 tokens (tool call) vs ~500-2000 tokens (reasoning)
- 1-3 seconds vs 10-30 seconds latency
- Guaranteed consistency vs potential errors

This compounds across sessions, agents, and days. But it's a side effect of good design, not the primary goal.

---

## Tools as Compiled Knowledge

**First time:** Reason through the problem (expensive)
**Recognize pattern:** This will happen again
**Encode:** Build a tool that captures the reasoning
**Forever after:** Call the tool (cheap)

The tool "compiles" the knowledge into an executable form. The reasoning happened once, when the tool was written. Now it's a single function call forever.

### Examples

| Without Tool | With Tool | What's Compiled |
|--------------|-----------|-----------------|
| "What timezone? What format? How do I invoke date?" | `./tools/now` | Timezone convention, format string, command |
| "What's the naming format? What's the next number? What template?" | `./tools/capture-instruction` | Naming convention, counter, template |
| "Format, lint, typecheck, test, review... in what order?" | `./tools/pre-commit-check` | Quality gate sequence, pass/fail logic |

---

## When Reasoning Is Better

Tools aren't always the answer. **Reasoning is appropriate for:**

1. **Novel problems** — First time encountering something, no pattern yet
2. **One-time tasks** — Won't happen again, not worth encoding
3. **Creative work** — Exploration, ideation, design
4. **Context-dependent decisions** — Too many variables to encode
5. **Learning** — Sometimes reasoning through builds understanding

### The Heuristic

> If you'll do it more than twice, and the steps are predictable, it should be a tool.

If it's genuinely novel or one-time, reason through it. But be alert: "one-time" tasks often recur.

---

## Tool Discovery: Managing Proliferation

**Risk:** Too many tools become their own cognitive load.

**Solution:** Discovery tools that make finding tools fast.

| Discovery Tool | What It Does |
|----------------|--------------|
| `./tools/find-tool "keyword"` | Search tools by keyword |
| `./tools/how "what I want to do"` | Intent-based discovery |
| `./tools/list-tools` | See all available tools |

The meta-pattern: **Tools for finding tools** ensure that having many tools doesn't create overhead. If finding the right tool is fast, having 50+ tools is an asset, not a burden.

---

## Token Leakage and Latency

Jordan's framing: Look for **"token leakage"** — places where we're spending tokens on process that could be a tool. Fix these along with the added latency.

### Where to Look

1. **Repeated reasoning** — "How do I X?" more than twice
2. **Convention lookups** — Checking CLAUDE.md for formats
3. **Multi-step sequences** — Doing A, then B, then C manually
4. **Status gathering** — Checking multiple sources for state

### Audit Questions

For any repeated operation:
- Are we reasoning instead of calling?
- Are we looking up instead of encoding?
- Are we sequencing instead of composing?

---

## Future Opportunity: Narrowcast vs Broadcast

**Current:** `./tools/post-news` broadcasts to all agents. `./tools/read-news` shows everything.

**Problem:** Agents may receive news that isn't applicable or helpful. Token waste reading irrelevant updates.

**Proposed:** Message queue with subscriptions

```
Agent subscribes to:
- Messages addressed to them directly
- Messages for their workstream
- Messages tagged with their domain

Agent receives:
- Only relevant messages
- Focused, narrow cast
- No noise
```

**Benefits:**
- Less token waste reading irrelevant news
- Faster news checking
- More signal, less noise
- Agents can "tune in" to what matters

This is a future enhancement — captured here for consideration.

---

## Documentation Impact

### CLAUDE.md Updates

Add philosophy section:

```markdown
## Tools Over Instructions

Every repeated decision is encoded in a tool. The principle:
**Make doing it the right way, the fast way.**

When you need to:
- Know the time → `./tools/now` (don't reason about timezone)
- Know your identity → `./tools/whoami` (don't search for config)
- Create an instruction → `./tools/capture-instruction` (don't figure out naming)
- Check quality → `./tools/pre-commit-check` (don't remember the steps)

**Why tools?**
1. You don't have to think — the tool encapsulates the decision
2. Consistency is guaranteed — the tool always does it right
3. Speed — one call vs. figuring it out

**When to reason instead:**
- Novel problems (no pattern yet)
- One-time tasks (won't recur)
- Creative work (exploration, design)

**Finding tools:**
- `./tools/find-tool "keyword"` — search by keyword
- `./tools/how "intent"` — search by what you want to do
```

### agent.md Updates

Add to agent template:

```markdown
## Operating Principles

### Tools First
Before reasoning through a process, check if a tool exists:
- `./tools/find-tool "keyword"`
- `./tools/how "what I want to do"`

A tool call replaces thinking and doing. Use it.

### When to Reason
Tools aren't always the answer. Reason through:
- Novel problems (first encounter)
- One-time tasks
- Creative work
- Complex, context-dependent decisions
```

---

## The Cascade

```
Philosophy (Right Way = Fast Way)
    ↓
CLAUDE.md (Framework level — all agents read this)
    ↓
agent.md (Agent level — individual behavior)
    ↓
Tool usage (Actual efficiency gains)
    ↓
Session efficiency (Faster, cheaper, more consistent)
    ↓
Principal experience (Less cognitive load, more output)
```

---

## Summary

| Principle | Implementation |
|-----------|----------------|
| Right way = Fast way | Tools encode the right way |
| Agent efficiency | Tools replace thinking and doing |
| Token efficiency (side benefit) | ~50 tokens vs ~500+ per operation |
| Discovery over memorization | find-tool, how, list-tools |
| Know when NOT to use tools | Novel, one-time, creative |
| Fix token leakage | Audit for repeated reasoning |
| Future: Narrowcast | Message subscriptions vs broadcast |

---

## Action Items

1. **Update CLAUDE.md** — Add "Tools Over Instructions" philosophy section
2. **Update agent.md template** — Add "Operating Principles" with tools-first guidance
3. **Create documentation** — PHILOSOPHY.md for the-agency-starter
4. **Consider narrowcast** — Future proposal for message subscriptions

---

_Working note for project: the-agency-book_
_Philosophy deep dive: Tools as Compiled Knowledge_
