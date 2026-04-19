---
type: seed
workstream: the-agency
slug: what-is-claude-code-components
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
topic: "What are the components of Claude — CLAUDE.md vs commands/skills: WHY/WHAT vs HOW framing"
status: captured (reference material for fleet-wide framing)
source: "principal-provided research summary, pasted 2026-04-19 D45-R3 session"
intended_scope: "the-agency-group — shared grounding across adopters + framework"
---

# Seed — Components of Claude: CLAUDE.md vs commands/skills

Captured per principal directive: *"Capture both of those in the-agency-group for 'What is Claude' and 'What are the components of Claude'."*

This is the **second of two companion seeds** — the mental model for separating CLAUDE.md (persistent project identity) from commands/skills (task-level procedures). Companion: `seed-what-is-claude-code-anthropic-architecture-20260419.md`.

## Why capture this

Understanding what goes WHERE is load-bearing for skill authoring (#309), for the-agency's adopter-facing CLAUDE.md template (#325), and for the Great Rename (#270). This seed preserves the canonical CLAUDE.md-vs-skills framing from primary research.

## Content — CLAUDE.md vs commands/skills (verbatim research summary)

Broadly yes, that's a **good mental model**, with a couple of nuances worth calling out.

### 1. What CLAUDE.md is "about"

**`CLAUDE.md`** is primarily about:

- **WHY** the project exists and **WHAT** it is (domain, business purpose, big picture).
- **WHAT** the main pieces are (architecture, directories, services, data flows).
- **HOW (at a policy / convention level)** you want Claude to operate:
  - Code style, patterns, and anti-patterns.
  - Project workflows (e.g., "always run tests with `pnpm test:unit` before committing").
  - Guardrails ("never touch infra/ directory", "don't rotate secrets").

So it's more like a **persistent product + engineering spec / playbook** that becomes part of Claude's **system prompt** for that repo. It absolutely contains some **"how"**, but at the level of **rules, habits, and workflows**, not low-level step sequences.

You can summarize it as:

> **`CLAUDE.md` = the project's "WHY + WHAT + high-level HOW" baked into the agent's identity for that repo.**

### 2. Commands and skills: more about the concrete "HOW"

By contrast, **commands and skills** are more about **"how to do a task right now"**:

- **Built-in commands** (e.g., `/init`, `/review`, `/debug`)
  - Hard-coded behaviors in the client/CLI that run specific flows: generate `CLAUDE.md`, run a review, compact context, etc.
  - These are very much **"do X using this procedure"**: the immediate "how".

- **Skills**
  - Prompt-based "mini-playbooks" that Claude loads when you call `/my-skill` or when it auto-matches a skill.
  - They typically encode **step-by-step HOW** for a repeated workflow, often:
    - "When invoked, do A → B → C, using tools T1/T2, maybe in a subagent."
  - Skills can:
    - Spawn **subagents** (`context: fork`, `agent: Explore|Plan|…`).
    - Restrict or grant **tools** (`allowed-tools`).
    - Run shell, tests, etc., as part of a structured routine.

So yes, skills/commands are closer to **"executable procedures = HOW"**, often very concrete and operational.

### 3. A slightly more precise framing

If you want a working summary that keeps you out of trouble:

- **`CLAUDE.md`**
  - **Scope:** Repo-wide, persistent.
  - **Focus:**
    - **WHY / WHAT** (purpose, architecture, domain).
    - **Policy-level HOW** (coding standards, workflows, constraints).
  - **Role:** Shapes **how Claude thinks** about the project and what "good work" looks like.

- **Commands & skills**
  - **Scope:** Per-task or per-workflow.
  - **Focus:**
    - Concrete **HOW-to-execute** sequences (run this tool, in this order, with this agent type, etc.).
  - **Role:** Shapes **how Claude acts** to carry out tasks, often using the policies/context from `CLAUDE.md` as inputs.

So the statement:

> "`CLAUDE.md` is more about **what** to do with some **how**, while commands and skills are about **how** to do it"

is **basically right** if you read "what" as **project goals/structure/conventions** and "how" as **task-level procedures**, with the caveat that `CLAUDE.md` also includes some "how at the guideline level," and skills/commands can encode a bit of "what this workflow is for."

## Summary

- **`CLAUDE.md`:** repo-wide **WHY/WHAT + guideline-level HOW**, part of the agent's identity and long-term memory.
- **Commands/skills:** **task-specific, executable HOW** — the actual procedures Claude uses to get things done, often leveraging subagents and tools.
- The mental model is **safe and useful**, as long as you remember that `CLAUDE.md` still includes some "how," just at the policy/workflow level instead of the step-by-step execution level.

## Anthropic canonical sources

- Writing a good CLAUDE.md — https://www.humanlayer.dev/blog/writing-a-good-claude-md
- What is the claude.md file — https://www.mindstudio.ai/blog/what-is-claude-md-file-instruction-manual/
- Using CLAUDE.MD files (Anthropic blog) — https://claude.com/blog/using-claude-md-files
- CLAUDE.md Memory System Deep Dive — https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/deep-dive/
- How Skills compares to prompts, Projects, MCP, and subagents — https://claude.com/blog/skills-explained
- Commands docs — https://code.claude.com/docs/en/commands
- Extend Claude with skills — https://code.claude.com/docs/en/skills
- How I structure Claude Code projects (CLAUDE.md, Skills, MCP) — https://www.reddit.com/r/ClaudeAI/comments/1r66oo0/how_i_structure_claude_code_projects_claudemd/
- Understanding CLAUDE.md vs Skills vs Slash Commands vs Plugins — https://www.reddit.com/r/ClaudeAI/comments/1ped515/understanding_claudemd_vs_skills_vs_slash/

## How this fits the-agency — direct implications

### CLAUDE.md layering (policy-level HOW)

- Root `CLAUDE.md` — project-specific (for the-agency: "This is the framework development repo")
- `@agency/CLAUDE-THEAGENCY.md` — framework-wide bootloader (methodology, discipline, safe-tools family)
- `@agency/REFERENCE-AGENT-DISCIPLINE.md` — agent-class discipline (Two Priorities + Over/Over-and-out)
- `@usr/{principal}/{agent}/CLAUDE-{agent}.md` — personal overlay per principal-agent

### Skills as HOW (v2 spec)

Skills now mandate:
- `required_reading:` frontmatter pointing at CLAUDE.md + REFERENCE-*.md that contain the POLICY they execute against
- `when_to_use:` frontmatter for trigger-phrase matching
- `argument-hint:` for invocation syntax

Rationale: skills execute the HOW, but they need to reference the WHY/WHAT/POLICY-HOW from CLAUDE.md. Without that reference, skills drift from project intent.

### Critical gap in andrew-demo (#325)

Andrew's `CLAUDE.md` is a placeholder stub (20 lines, all `<!-- comment -->` blanks). Result: his Claude Code session starts with zero project context. Every skill he invokes operates without the policy-level HOW / WHY / WHAT that CLAUDE.md should inject.

Fix direction: `agency init` should rewrite CLAUDE.md from a template that:
1. Names the project + principal
2. Imports framework bootloader (`@agency/CLAUDE-THEAGENCY.md` or future `@agency/CLAUDE-AGENCY.md`)
3. Reserves sections for project-specific WHY/WHAT/HOW the adopter fills in
4. Links to their workstreams + agent classes

## Related

- #308 `REFERENCE-WHAT-IS-CLAUDE-CODE.md` (monofolk PR pending upstream merge)
- #309 `REFERENCE-SKILL-AUTHORING.md` (v2 methodology — grounds skills as HOW)
- #325 `CLAUDE.md` placeholder stub (the-agency needs to fix install)
- `seed-true-installer-bootstrap-20260419.md` (this seed's structural parent — the installer that puts CLAUDE.md in the right shape)
- Companion seed: `seed-what-is-claude-code-anthropic-architecture-20260419.md`

*Captured as seed for the-agency-group context so CLAUDE.md-vs-skills framing is shared across framework + adopters.*
