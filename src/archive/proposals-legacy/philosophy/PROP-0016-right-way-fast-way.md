# PROP-0016: Right Way = Fast Way — Design Philosophy

**Status:** accepted
**Priority:** foundational
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Type:** philosophy

---

## The Principle

**Make doing it the right way, the fast way.**

Every tool, service, and convention in The Agency should make the correct approach also be the quickest, most efficient, and most effective approach.

This is not about enforcement through friction. It's about design that makes the right path the path of least resistance.

---

## Why This Matters

### The Alternative Fails

When the "right way" is slower or harder:
- People skip it under time pressure
- Shortcuts become habits
- Quality degrades over time
- Technical debt accumulates
- Eventually the "right way" is forgotten

### When Right = Fast

When the correct approach is also the fastest:
- No willpower required
- No trade-off between speed and quality
- Patterns compound (tools build on tools)
- Quality becomes automatic
- The system gets better over time

---

## Applications

### 1. Tools Over Manual Steps

**Instead of:** "Remember to run format, lint, typecheck, test, and review before committing"

**We build:** `./tools/commit-precheck` — one command, all steps, automatic

**Result:** Quality gates are faster than remembering the steps

### 2. Conventions Encoded in Tools

**Instead of:** "Follow the naming convention for instructions: INSTR-XXXX-principal-workstream-agent-title"

**We build:** `./tools/instruction-capture` — generates the name automatically

**Result:** Correct naming is faster than figuring out the format

### 3. Session Management

**Instead of:** "Remember to check for pending instructions, read news, review uncommitted changes..."

**We build:** SessionStart hooks that do this automatically

**Result:** Proper session hygiene happens without thinking

### 4. Token Efficiency

**Instead of:** Agent reasons through "how do I check the current timestamp in the project's timezone?"

**We build:** `./tools/now` — returns the answer directly

**Result:**
- One tool call vs. multi-step reasoning
- Tokens saved
- Consistency guaranteed
- Faster response

---

## Token Efficiency Deep Dive

Tools and services are dramatically more token-efficient than reasoning:

| Approach | Tokens Used | Time |
|----------|-------------|------|
| Agent reasons through problem | 500-2000+ | 10-30s |
| Agent calls focused tool | 50-200 | 1-3s |

### Why Tools Save Tokens

1. **No reasoning required** — Tool encapsulates the logic
2. **No exploration** — Tool knows exactly what to do
3. **No error recovery** — Tool handles edge cases
4. **Consistent output** — No parsing or interpretation needed

### Example: Getting Current Time

**Without tool (agent reasons):**
```
Agent thinks: "I need to get the current time. What timezone?
Let me check CLAUDE.md... SGT. How do I format it?
Let me use the date command... what format string?"
[500+ tokens of reasoning]
```

**With tool:**
```
Agent: ./tools/now
Output: 2026-01-06 15:30 SGT
[50 tokens total]
```

**Savings:** 90% fewer tokens, 10x faster

### Example: Creating an Instruction

**Without tool:**
```
Agent thinks: "I need to create an instruction file.
What's the naming format? INSTR-XXXX...
What's the next number? Let me count existing files...
What's the principal? What's the workstream? What's the agent?
What template should I use? Let me look for examples..."
[1000+ tokens of reasoning]
```

**With tool:**
```
Agent: ./tools/instruction-capture "Title of the instruction"
[Creates file with correct name, number, template, metadata]
[100 tokens total]
```

**Savings:** 90% fewer tokens, consistent output every time

---

## Design Guidelines

When building tools and services:

1. **Encapsulate decisions** — Don't make the agent decide what the tool should decide
2. **Handle edge cases** — The tool should never require follow-up reasoning
3. **Return clean output** — Minimize parsing/interpretation needed
4. **Be discoverable** — `./tools/tool-find` so agents find tools quickly
5. **Be documented** — Tools should explain themselves

### The Test

For any repeated operation, ask:
- "Is calling a tool faster than reasoning through it?"
- "Is the tool output immediately usable?"
- "Does the tool handle all the cases?"

If yes to all three, the tool is well-designed.

---

## Implications

### For Tool Development

Every tool should be evaluated on:
- Does it make the right way faster?
- Does it save tokens vs. reasoning?
- Does it eliminate decisions the agent would otherwise make?

### For Framework Design

The Agency should continuously identify:
- Where do agents spend tokens reasoning about process?
- Where do patterns require remembering vs. being automatic?
- Where is the "right way" slower than a shortcut?

Then build tools to close those gaps.

### For Onboarding

New users should experience this immediately:
- The install script (one command)
- The `/welcome` interview (guided, not manual)
- The tools (faster than figuring it out)

They should think: "This is easier than I expected."

---

## Related Patterns

- **Convention over Configuration** (Rails philosophy)
- **Pit of Success** (.NET design principle)
- **Make the Change Easy, Then Make the Easy Change** (Kent Beck)

---

## Acceptance

This is a foundational philosophy, not a feature to implement. It's accepted by being practiced.

Every new tool, service, and convention should be evaluated against this principle:

**Does it make doing it the right way, the fast way?**

If not, redesign until it does.

---

_Philosophy document for The Agency framework_
_Captured 2026-01-06_
