# Explore: Agents

**Time:** 3 minutes
**Goal:** Understand what agents are and how they work

## What Are Agents?

Agents are specialized Claude Code instances with:
- **Persistent context** - They remember what they've worked on
- **Specialized knowledge** - They learn patterns for their workstream
- **Independent sessions** - Each agent runs in its own session

Think of agents as team members with specific expertise.

## Agent Structure

Show them an agent directory:

```bash
ls -la claude/agents/captain/
```

Explain what they'll see:
- `agent.md` - Agent's identity and role
- `KNOWLEDGE.md` - Accumulated learnings
- `WORKLOG.md` - Sprint-based work tracking
- `ADHOC-WORKLOG.md` - Quick notes and ad-hoc work

## Creating an Agent

Walk through creating a test agent:

```bash
./tools/agent-create demo demo-agent
```

Show them what was created:
```bash
cat claude/agents/demo-agent/agent.md
```

## Launching an Agent

Show them how to launch:

```bash
./tools/myclaude demo demo-agent
```

Or with an initial prompt:
```bash
./tools/myclaude demo demo-agent "Help me understand agents"
```

## Agent Sessions

Explain how sessions work:
- Each launch starts a new session
- Context is preserved via worklogs
- Session backups capture state
- Agents resume where they left off

## Multiple Agents

Show why you'd want multiple agents:

**By Area:**
- `web-frontend` - UI components, styling
- `api-backend` - APIs, databases
- `mobile-app` - React Native code

**By Role:**
- `dev` - Implementation
- `reviewer` - Code reviews
- `tester` - Testing focus

**By Feature:**
- `auth-agent` - Authentication system
- `payment-agent` - Payment processing

## Demo: Talk to an Agent

If they want, let them try:

```bash
./tools/myclaude demo demo-agent "Introduce yourself"
```

## Key Takeaways

✓ Agents are specialized Claude Code instances
✓ They have persistent context and memory
✓ Each agent focuses on a specific area
✓ Multiple agents can collaborate on work

## Next Steps

Ask if they want to explore:
- Workstreams (how agents are organized)
- Tools (what agents can do)
- Collaboration (how agents work together)

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - explore.agents
```
