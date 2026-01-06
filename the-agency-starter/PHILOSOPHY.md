# The Agency Philosophy

## Right Way = Fast Way

The core design principle of The Agency:

**Make doing it the right way, the fast way.**

Every tool, service, and convention should make the correct approach also be the quickest, most efficient, and most effective approach.

This isn't about enforcement through friction. It's about design that makes the right path the path of least resistance.

---

## Tools as Compiled Knowledge

When you call `./tools/now`, you're not spending time figuring out:
- What timezone does this project use?
- What format should the timestamp be?
- How do I invoke the date command correctly?

That's all **compiled into the tool**. The reasoning happened once, when the tool was written. Now it's a single function call forever.

### The Pattern

1. **First time:** Reason through the problem
2. **Recognize:** This will happen again
3. **Encode:** Build a tool that captures the reasoning
4. **Forever after:** Call the tool

---

## Agent Efficiency

The primary benefit is **you don't have to think and do**. A tool replaces actions.

| Without Tool | With Tool |
|--------------|-----------|
| "What timezone? What format?" | `./tools/now` |
| "What's the naming convention?" | `./tools/capture-instruction` |
| "Format, lint, typecheck, test..." | `./tools/pre-commit-check` |

Your cognitive load drops to near zero. Just call the tool.

### Token Efficiency (Side Benefit)

Every tool call that replaces reasoning:
- ~50-200 tokens vs ~500-2000 tokens
- 1-3 seconds vs 10-30 seconds
- Guaranteed consistency vs potential errors

This compounds across sessions. But it's a side effect of good design, not the primary goal.

---

## When to Use Tools

**Use a tool when:**
- You'll do it more than twice
- The steps are predictable
- Consistency matters
- Speed matters

**Reason through it when:**
- It's genuinely novel (first encounter)
- It's truly one-time (won't recur)
- It's creative work (exploration, design)
- It's highly context-dependent

### The Heuristic

> If you'll do it more than twice, and the steps are predictable, it should be a tool.

---

## Finding Tools

With 40+ tools, discovery matters. Use:

| Command | What It Does |
|---------|--------------|
| `./tools/find-tool "keyword"` | Search by keyword |
| `./tools/how "what I want"` | Search by intent |
| `./tools/list-tools` | See everything |

The meta-pattern: **tools for finding tools** ensure that having many tools is an asset, not a burden.

---

## Looking for Token Leakage

Places where reasoning could be a tool:

1. **Repeated "how do I X?"** — Should be a tool
2. **Convention lookups** — Should be encoded
3. **Multi-step sequences** — Should be composed
4. **Status gathering** — Should be aggregated

When you find yourself reasoning through the same thing twice, that's "token leakage." Consider whether a tool would help.

---

## The Cascade

```
Philosophy (Right Way = Fast Way)
    ↓
CLAUDE.md (Framework conventions)
    ↓
agent.md (Agent behavior)
    ↓
Tool usage (Actual efficiency)
    ↓
Your experience (Less thinking, more doing)
```

---

## Summary

| Principle | What It Means |
|-----------|---------------|
| **Right way = Fast way** | Tools encode the right way |
| **Agent efficiency** | Tools replace thinking and doing |
| **Token efficiency** | Side benefit: fewer tokens, less latency |
| **Discovery over memorization** | find-tool, how, list-tools |
| **Know when NOT to** | Novel, one-time, creative work |

---

*This philosophy shapes every tool in The Agency. When something feels harder than it should be, that's a signal — maybe it should be a tool.*
