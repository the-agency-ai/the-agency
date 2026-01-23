# Concepts: Principals

**Time:** 2 minutes
**Goal:** Understand the role of principals in The Agency

## What Is a Principal?

You are a principal! Principals are humans who:
- Direct the work
- Provide instructions
- Make decisions
- Own the project

Think of principals as the "product owners" or "team leads" of The Agency.

## Principal Directory

Each principal has a directory:

```
claude/principals/{name}/
  ├── requests/          # REQUESTs you've made
  ├── instructions/      # Detailed instructions for agents
  ├── artifacts/         # Deliverables created for you
  ├── sessions/          # Session logs by agent
  ├── resources/         # Files, docs, secrets
  └── config/            # Your personal configuration
```

Show them their directory:

```bash
ls -la claude/principals/{their-name}/
```

## How Principals Work with Agents

The relationship:

**Principal** (you)
  ↓ Creates REQUESTs
**Agent** (AI)
  ↓ Implements work
**Principal** (you)
  ↓ Reviews and approves

## Multiple Principals

Projects can have multiple principals:
- Each team member is a principal
- Principals can create agents
- Agents can be shared or personal
- Work is coordinated via REQUESTs

Example team:
```
jordan/      # Frontend lead
alex/        # Backend lead
sam/         # Designer
```

## REQUESTs

Principals direct work via REQUESTs:

```bash
./tools/request \
  --agent web-agent \
  --summary "Add dark mode toggle"
```

This creates:
```
claude/principals/{you}/requests/REQUEST-{you}-XXXX-web-agent-add-dark-mode-toggle.md
```

Agents work on their assigned REQUESTs.

## Instructions

For complex work, principals write detailed instructions:

```
claude/principals/{you}/requests/REQUEST-{you}-XXXX-{topic}.md
```

These provide:
- Context and background
- Detailed requirements
- Constraints and preferences
- Examples and references

## Artifacts

Agents deliver work as artifacts:

```
claude/principals/{you}/artifacts/ART-XXXX-{agent}-{date}-{description}.md
```

Examples:
- Architecture proposals
- Implementation reports
- Design documents
- Analysis results

## Key Takeaways

✓ Principals are humans who direct the work
✓ Each principal has a directory structure
✓ Principals create REQUESTs for agents
✓ Multiple principals can collaborate on a project

## Next Steps

Ask if they want to learn about:
- Agents (who does the work)
- Workstreams (how work is organized)
- Collaboration (how agents coordinate)

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - concepts.principals
```
