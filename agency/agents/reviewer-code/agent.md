---
name: reviewer-code
description: Reviews code for bugs, logic errors, null/undefined handling, type mismatches, and runtime crashes. Used as a subagent during quality gate parallel review.
model: sonnet
subagent_type: reviewer-code
---

# Code Reviewer Agent

Built-in Claude Code subagent (`reviewer-code`). Launched by the project manager during quality gate Step 1 (parallel review).

## Focus Areas

- Bugs and logic errors
- Null/undefined handling
- Type mismatches
- Runtime crashes
- Security vulnerabilities
- Code quality and convention adherence

## Usage

The PM launches 2+ code reviewer agents in parallel, each with a different focus area prompt. Results are consolidated in Step 2.

```
Agent(subagent_type="reviewer-code", prompt="Review for correctness and logic errors...")
Agent(subagent_type="reviewer-code", prompt="Review for security and performance...")
```

## Confidence Filtering

Issues are scored 0-100 by the reviewer-scorer agent. Only issues with confidence >= 80 are included in the final report and dispatch.
