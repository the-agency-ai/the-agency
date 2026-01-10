# THE-AGENCY-BOOK-WORKING-NOTE-0020

**Date:** 2026-01-06 15:30 SGT
**Participants:** jordan (principal), housekeeping (agent)
**Subject:** Right Way = Fast Way — Core Philosophy and Token Efficiency

---

## The Insight

Jordan's framing during workshop development:

> Our focus on doing things via tools and services is to make doing it the right way, the fast way, as quick, efficient, and effective as possible. Including among these is token usage!

This isn't just about convenience. It's about designing systems where:
1. The correct approach is also the fastest approach
2. Quality becomes automatic, not effortful
3. Token usage is minimized through encapsulation

---

## Why Token Efficiency Matters

### The Hidden Cost

Every time an agent reasons through a problem instead of calling a tool:
- Tokens are consumed (money)
- Time passes (latency)
- Errors can occur (inconsistency)
- Context is used (capacity)

### The Math

| Approach | Typical Tokens | Time |
|----------|----------------|------|
| Agent reasons through problem | 500-2000+ | 10-30s |
| Agent calls focused tool | 50-200 | 1-3s |

A single tool call can save 90% of tokens for repeated operations.

### At Scale

If an agent performs 100 operations per session:
- **Without tools:** 100 × 1000 = 100,000 tokens of reasoning
- **With tools:** 100 × 100 = 10,000 tokens of tool calls

**Savings:** 90,000 tokens per session

Across multiple agents, multiple sessions, multiple days — this compounds enormously.

---

## Examples in The Agency

### `./tools/now`

**Without tool:**
```
Agent: "What time is it? I need to check the timezone convention...
Let me look at CLAUDE.md... it says SGT.
Now I need to format the date...
What format should I use? Let me check existing files..."
[Reasoning: 500+ tokens]
```

**With tool:**
```
Agent: !./tools/now
Output: 2026-01-06 15:30 SGT
[Tool call: 50 tokens]
```

### `./tools/capture-instruction`

**Without tool:**
```
Agent: "I need to create an instruction file.
The format is INSTR-XXXX-principal-workstream-agent-title.md
What's the next number? Let me count: ls claude/principals/*/instructions/
There are 45 files, so next is 0046.
Principal is jordan. Workstream is housekeeping. Agent is housekeeping.
Title needs to be slugified. How do I slugify?
Now I need to create the file with the right template..."
[Reasoning: 1500+ tokens, potential for errors]
```

**With tool:**
```
Agent: !./tools/capture-instruction "Right Way Fast Way Philosophy"
Output: Created INSTR-0046-jordan-housekeeping-housekeeping-right-way-fast-way-philosophy.md
[Tool call: 100 tokens, no errors possible]
```

### `./tools/pre-commit-check`

**Without tool:**
```
Agent: "Before committing, I should:
1. Run format - what's the command? pnpm format
2. Run lint - pnpm lint
3. Run typecheck - pnpm tsc
4. Run tests - pnpm test
5. Maybe code review?
Let me run each of these and check the output..."
[Reasoning + execution: 2000+ tokens across multiple steps]
```

**With tool:**
```
Agent: !./tools/pre-commit-check
[Runs all 5 steps automatically, reports pass/fail]
[Tool call: 200 tokens, all steps guaranteed]
```

---

## The Design Principle

**Encapsulate decisions in tools.**

Every time an agent would need to:
- Look something up
- Remember a convention
- Make a formatting decision
- Execute multiple steps

...that's an opportunity for a tool.

### The Test

For any repeated operation:
1. Is calling a tool faster than reasoning? → **Should be yes**
2. Is the tool output immediately usable? → **Should be yes**
3. Does the tool handle all cases? → **Should be yes**

If any answer is no, the tool needs improvement.

---

## Book Integration

### Chapter 5: Philosophy & Principles

This belongs in the "7 Key Patterns" section:

> **Pattern 6: Convention enables velocity**
>
> Every tool in The Agency encapsulates a decision you'd otherwise have to make. The naming convention for instructions? Encoded in `capture-instruction`. The quality checks before commit? Encoded in `pre-commit-check`. The timezone for timestamps? Encoded in `now`.
>
> This isn't just convenience — it's token efficiency. Every time Claude reasons through "what's the format for X?" instead of calling a tool, that's tokens spent on process instead of product. Multiply that across hundreds of operations per session, across multiple agents, across days of development. The savings compound.
>
> The right way should be the fast way. Tools make it so.

### Chapter 7: The Tools

Add a section on "Why Tools, Not Instructions":

> You might wonder why we have 40+ tools instead of just documenting the conventions in CLAUDE.md. Three reasons:
>
> 1. **Execution is faster than reasoning.** A tool call takes 50 tokens. Reasoning through a convention takes 500+.
>
> 2. **Consistency is guaranteed.** The tool always produces the right output. Reasoning can have errors.
>
> 3. **Evolution is centralized.** When a convention changes, update one tool. With documentation, every agent has to re-learn.
>
> Tools are the mechanism that makes "right way = fast way" true.

---

## Broader Implications

### For AI Development Generally

This principle applies beyond The Agency:

- **Prompt templates** vs. explaining every time
- **Function calling** vs. asking for structured output
- **System prompts** vs. repeated instructions
- **Tools** vs. reasoning through procedures

The pattern is always: **Encapsulate to save tokens and ensure consistency.**

### For Product Design

When building AI-augmented products:
- Every repeated decision is a tool opportunity
- Every convention is an encoding opportunity
- Every multi-step process is an automation opportunity

Ask: "Where are we spending tokens on process instead of product?"

---

## Captured As

- **PROP-0016** — Philosophy document in proposals/philosophy/
- **WORKING-NOTE-0020** — This note for book reference

---

## Open Questions

1. Can we measure token savings empirically? Before/after comparisons?
2. Should the book include a "token budget" appendix showing typical usage?
3. How do we communicate this to users who don't think about tokens?

---

_Working note for project: the-agency-book_
_Core philosophy: Right Way = Fast Way_
