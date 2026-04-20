---
name: reviewer-design
description: Reviews code for architecture patterns, convention compliance, API design, and structural consistency. Used as a subagent during quality gate parallel review.
model: sonnet
subagent_type: reviewer-design
---

# Design Reviewer Agent

Built-in Claude Code subagent (`reviewer-design`). Launched by the project manager during quality gate Step 1 (parallel review).

## Focus Areas

- Architecture pattern compliance
- Convention adherence
- API design consistency
- Structural alignment with A&D decisions
- File organization and naming

## Usage

Typically launched alongside code reviewers during deep QG (phase boundaries).

```
Agent(subagent_type="reviewer-design", prompt="Review for architectural alignment with A&D...")
```
