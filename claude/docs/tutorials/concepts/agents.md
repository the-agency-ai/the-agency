# Concepts: Agents

**Time:** 3 minutes
**Goal:** Deep dive into what agents are and how they work

## Agent Definition

An agent is:
- A specialized Claude Code instance
- With persistent context and memory
- Focused on a specific workstream
- That accumulates knowledge over time

Not just a chat session - a team member.

## Agent Anatomy

Each agent has:

### 1. Identity (`agent.md`)
- Name and role
- Responsibilities
- Capabilities
- Personality

### 2. Knowledge (`KNOWLEDGE.md`)
- Patterns learned
- Best practices
- Common pitfalls
- Solutions to recurring problems

### 3. Work Logs
- `WORKLOG.md` - Sprint-based work
- `ADHOC-WORKLOG.md` - Quick tasks
- Session backups - State snapshots

### 4. Context
- Workstream knowledge (shared)
- Principal instructions
- Past conversations
- Code they've worked on

## Creating an Agent

```bash
./tools/agent-create {workstream} {name}
```

This creates:
```
claude/agents/{name}/
  ├── agent.md
  ├── KNOWLEDGE.md
  ├── WORKLOG.md
  ├── ADHOC-WORKLOG.md
  ├── backups/
  ├── logs/
  └── notes/
```

## Agent Lifecycle

**1. Creation**
- Define identity and role
- Assign to workstream
- Set initial context

**2. Work Sessions**
- Launch with `./tools/myclaude`
- Complete tasks
- Document learnings

**3. Knowledge Growth**
- Patterns emerge
- Best practices documented
- KNOWLEDGE.md expands

**4. Collaboration**
- Request help from other agents
- Share insights via news
- Coordinate on complex work

## Agent Specialization

Agents specialize through:

**Focus Area:**
- `frontend` - UI, components, styling
- `backend` - APIs, database, services
- `testing` - QA, test automation

**Technical Stack:**
- `react-dev` - React expertise
- `python-api` - Python/FastAPI
- `mobile-ios` - iOS development

**Responsibility:**
- `reviewer` - Code reviews
- `architect` - System design
- `documenter` - Documentation

## Agent Memory

Agents remember through:

1. **Worklogs** - What they worked on
2. **KNOWLEDGE.md** - Lessons learned
3. **Session backups** - Recent context
4. **Workstream knowledge** - Shared learning

When you launch an agent, they pick up where they left off.

## Best Practices

**DO:**
- Give agents clear, focused roles
- Let them specialize over time
- Document learnings in KNOWLEDGE.md
- Use multiple agents for large projects

**DON'T:**
- Make agents too generic
- Skip documenting patterns
- Overload one agent with everything
- Forget to share knowledge via workstream

## Key Takeaways

✓ Agents are specialized, persistent team members
✓ They have identity, knowledge, and memory
✓ Specialization comes from focused work
✓ Knowledge compounds over time

## Next Steps

Ask if they want to learn about:
- Principals (who directs agents)
- Workstreams (how agents are organized)
- Try creating their own agent

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - concepts.agents
```
