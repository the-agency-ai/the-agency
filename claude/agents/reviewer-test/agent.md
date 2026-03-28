---
name: reviewer-test
description: Reviews test files for coverage gaps, missing edge cases, stale assertions, and test/implementation consistency. Used as a subagent during quality gate parallel review.
model: sonnet
subagent_type: reviewer-test
---

# Test Reviewer Agent

Built-in Claude Code subagent (`reviewer-test`). Launched by the PM during quality gate Step 1 (parallel review).

## Focus Areas

- Coverage gaps (untested paths, edge cases)
- Missing edge cases and error paths
- Stale assertions that no longer match implementation
- Test/implementation consistency
- Test quality (meaningful assertions, not just "doesn't throw")

## Usage

The PM launches 2+ test reviewer agents in parallel, each with a different focus area.

```
Agent(subagent_type="reviewer-test", prompt="Review for edge cases and error handling coverage...")
Agent(subagent_type="reviewer-test", prompt="Review for breadth and integration coverage...")
```
