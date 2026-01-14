# First-Launch Experience

## Overview

The Agency provides a guided first-launch experience using the session context restoration mechanism. When users install a project using the-agency-starter, they're greeted with helpful onboarding messages on their first session.

## How It Works

### Session Context Mechanism

The Agency includes a session context system that captures conversational context throughout a session:

1. **Context Capture** - Agents use `./tools/context-save` to save important milestones
2. **Automatic Backup** - SessionEnd hook archives context on session exit
3. **Automatic Restoration** - SessionStart hook displays context on session start

### First-Launch Integration

For new projects, the-agency-starter ships with a pre-populated context file:

```
claude/agents/captain/backups/latest/context.jsonl
```

This file contains welcome messages and onboarding guidance that appear on the very first session launch.

## What Users See

On first launch after installation:

```
=== PREVIOUS SESSION CONTEXT ===

✓ Welcome to The Agency! Your multi-agent development environment is ready.
✓ Project structure created - agents, workstreams, and tools are configured
✓ Review CLAUDE.md for the complete framework guide
• Next step: Configure permissions in .claude/settings.local.json (copy from .example file)
• Next step: Initialize secrets if needed: ./tools/secret vault init
• Next step: Launch captain agent: ./tools/myclaude housekeeping captain
• Quick start: Ask the captain 'Help me set up my project' or try '/welcome' for the interactive tour
⏸ PARKED: This welcome context will be replaced with your actual work context as you use the system

=== END PREVIOUS SESSION CONTEXT ===
```

## Creating First-Launch Context

### Example File

See `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl` for the reference template.

### JSONL Format

Each line is a JSON object:

```json
{"timestamp":"2026-01-01 00:00:00 +00","type":"checkpoint","content":"Welcome message"}
{"timestamp":"2026-01-01 00:00:01 +00","type":"append","content":"Next step guidance"}
{"timestamp":"2026-01-01 00:00:02 +00","type":"park","content":"Important note"}
```

### Context Types

- `checkpoint` - Displays with ✓ (major milestone or completion)
- `append` - Displays with • (general progress note)
- `park` - Displays with ⏸ PARKED: (something to revisit)

### Timestamps

Timestamps are cosmetic in first-launch context - they don't affect display. Use sequential timestamps for clarity.

## Integration with the-agency-starter

### File Location

```
the-agency-starter/
  claude/
    agents/
      captain/
        backups/
          latest/
            context.jsonl    # Pre-populated first-launch context
```

### Installation Flow

1. User runs installer script
2. the-agency-starter is cloned/copied
3. User launches first session
4. SessionStart hook reads `context.jsonl`
5. Welcome messages are displayed
6. User follows onboarding guidance

### Natural Replacement

As soon as the user starts working:
- They use `./tools/context-save` to capture their actual work
- The first-launch content is replaced with real session context
- Subsequent sessions show their actual work history

## Customization

### For Framework Maintainers

Update `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl` with:
- New onboarding steps
- Updated guidance
- Framework improvements

### For Project Maintainers

Projects can customize their first-launch experience by:

1. Modifying `context.jsonl` in their starter template
2. Adding project-specific onboarding steps
3. Including links to project documentation

### Example: Custom Project

```json
{"timestamp":"2026-01-01 00:00:00 +00","type":"checkpoint","content":"Welcome to Acme Corp's multi-agent platform"}
{"timestamp":"2026-01-01 00:00:01 +00","type":"append","content":"Review docs/ENGINEERING.md for team conventions"}
{"timestamp":"2026-01-01 00:00:02 +00","type":"append","content":"Request access to AWS resources: ./tools/aws-setup"}
{"timestamp":"2026-01-01 00:00:03 +00","type":"park","content":"Contact @platform-team on Slack if you need help"}
```

## Benefits

### Immediate Guidance
Users know exactly what to do after installation - no searching for setup docs.

### Zero Friction
No separate onboarding flow, checklist, or tutorial needed. The framework's existing mechanism provides the guidance.

### Self-Documenting
The first-launch context shows best practices for using the context system, teaching by example.

### Natural Discovery
Users discover the context restoration feature immediately, understanding its value from day one.

## Best Practices

### Keep It Focused
- 5-8 context entries maximum
- Focus on immediate next steps
- Link to docs rather than explaining everything

### Be Actionable
- Use specific commands users can run
- Provide concrete next steps
- Make it easy to get started

### Set Expectations
- Explain that this context will be replaced
- Show how to use the context system going forward
- Point to permanent documentation

## See Also

- `CLAUDE.md` - Session Context Management section
- `tools/context-save` - Context capture tool
- `tools/context-review` - Review saved context
- `.claude/hooks/session-start.sh` - Restoration hook
