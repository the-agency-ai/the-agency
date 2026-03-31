# Lessons from Building Claude Code: How We Use Skills

**Source:** @bcherny on X/Twitter — `https://x.com/bcherny/status/2038454336355999749`
**Captured:** 2026-03-31
**Type:** Anthropic internal practices shared publicly

## Summary

Boris Cherny (Anthropic) shares lessons from extensive internal use of skills in Claude Code — hundreds in active use. Covers skill taxonomy, authoring best practices, distribution, and measurement.

## Key Takeaways

### Skills Are Folders, Not Files
- Common misconception: "just markdown files"
- Skills are folders with scripts, assets, data that the agent discovers and manipulates
- Configuration options include registering dynamic hooks
- File system as progressive disclosure — split into references/, assets/, etc.

### 9 Skill Categories

1. **Library & API Reference** — internal libs, CLIs, SDKs, gotchas
2. **Product Verification** — test/verify code works (paired with playwright, tmux, etc.)
3. **Data Fetching & Analysis** — connect to data/monitoring stacks
4. **Business Process & Team Automation** — repetitive workflows → one command
5. **Code Scaffolding & Templates** — framework boilerplate generation
6. **Code Quality & Review** — enforce code quality, review code
7. **CI/CD & Deployment** — fetch, push, deploy code
8. **Runbooks** — symptom → investigation → structured report
9. **Infrastructure Operations** — routine maintenance with guardrails

### Authoring Best Practices

- **Don't state the obvious** — focus on info that pushes Claude out of its normal patterns
- **Build a Gotchas section** — highest-signal content, built from common failure points
- **Use progressive disclosure** — point to other files, Claude reads them when appropriate
- **Avoid railroading** — give info + flexibility, don't over-specify
- **Think through setup** — store user config in config.json, use AskUserQuestion for structured input
- **Description field is for the model** — it's a trigger condition, not a summary

### Memory & Data Storage

- Skills can store data (text logs, JSON, SQLite)
- Example: standup-post keeps standups.log for history
- Use `${CLAUDE_PLUGIN_DATA}` for stable storage that survives skill upgrades

### Scripts & Code Generation

- Give Claude scripts and libraries for composition
- Example: data science skill with helper functions → Claude generates analysis scripts on the fly

### On-Demand Hooks

- Skills can register hooks active only during the skill's session
- Examples: `/careful` blocks destructive commands, `/freeze` blocks edits outside a directory

### Distribution

- **Repo-checked** — `.claude/skills/` — good for small teams
- **Plugin marketplace** — internal marketplace, users install what they want
- Organic curation: sandbox folder → traction → PR to marketplace
- Warning: easy to create bad/redundant skills, need curation

### Measurement

- PreToolUse hook logs skill usage company-wide
- Find popular skills or ones undertriggering vs expectations

### Composition

- Skills can reference other skills by name
- No native dependency management yet — model invokes referenced skills if installed

## Relevance to The Agency

This article validates several Agency patterns and suggests enhancements:
- Agency skills (slash commands) already follow the folder-with-scripts pattern
- The 9-category taxonomy is useful for auditing our skill coverage
- On-demand hooks pattern maps directly to hookify rules
- The marketplace/distribution model is relevant for multi-principal scenarios
- Measurement via PreToolUse hook is directly implementable
- Progressive disclosure and gotchas sections are actionable improvements for existing skills
