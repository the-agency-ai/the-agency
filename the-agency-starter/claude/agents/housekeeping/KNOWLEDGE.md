# Housekeeping Knowledge Base

Accumulated patterns and wisdom for running The Agency effectively.

## Core Principles

### Convention Over Configuration
- Establish clear conventions, enforce them
- Reduce decisions, increase consistency
- Make the right thing the easy thing

### Agents Are Specialists
- Each agent has a focused domain
- Context is preserved across sessions
- Handoffs are explicit, not assumed

### Principals Direct, Agents Execute
- Humans provide direction via instructions
- Agents own implementation decisions
- Artifacts capture deliverables for review

### Collaboration Is Explicit
- Use `./tools/collaborate` for cross-agent work
- Use `./tools/post-news` for broadcasts
- Don't assume other agents know your context

## Patterns

### Starting a New Project

1. Launch housekeeping: `./tools/myclaude housekeeping housekeeping`
2. Describe your project and tech stack
3. I'll help you:
   - Choose/create appropriate starter pack
   - Set up initial workstreams
   - Create your first agents
   - Configure quality gates

### Adding a New Feature Area

1. Create a workstream: `./tools/create-workstream {name}`
2. Create an agent: `./tools/create-agent {workstream} {name}`
3. Plan work with epics/sprints as needed
4. Launch the agent and start working

### Handling Cross-Cutting Work

When work spans multiple agents:
1. Lead agent creates collaboration requests
2. Use `./tools/dispatch-collaborations` to launch helpers
3. Each agent responds when done
4. Lead agent consolidates results

### Code Review Workflow

1. Create instruction: `INSTR-XXXX-principal-workstream-agent-code-review.md`
2. Housekeeping spawns review subagents in parallel
3. Findings distributed via collaboration requests
4. Agents address issues, respond when done
5. Artifact captures final report

## Anti-Patterns

### Don't
- Skip session restoration - you'll lose context
- Work without logging - use ADHOC-WORKLOG for out-of-plan work
- Assume shared knowledge - use collaboration tools
- Bypass quality gates - they exist for good reasons
- Create agents without purpose - each agent needs a clear role

### Do
- Read your context at session start
- Track all work (sprints or ad-hoc)
- Communicate explicitly via tools
- Run pre-commit checks before pushing
- Document learnings in KNOWLEDGE.md

## Tool Mastery

### Essential Daily Tools
```bash
./tools/myclaude {ws} {agent}  # Launch agent
./tools/sync                    # Push with checks
./tools/read-news               # Check broadcasts
./tools/dispatch-collaborations # Handle pending requests
```

### When Stuck
```bash
./tools/backup-session          # Save your context
./tools/collaborate {agent}     # Ask for help
./tools/add-nit {file}          # Flag for later
```

### Discovery
```bash
./tools/find-tool {keyword}     # Find a tool
./tools/list-tools              # See all tools
./tools/show-instructions       # See active instructions
```

## Framework-Specific Notes

_This section grows as you add starter packs._

### Next.js
- See `claude/starter-packs/nextjs/` when available
- Patterns for app router, server components, etc.

### React Native
- See `claude/starter-packs/react-native/` when available

### Python
- See `claude/starter-packs/python/` when available

## Learnings Log

_Add significant learnings here as you work._

---

*Last updated: Session start*
