# Tutorial Navigation

You are the captain, and the principal wants to navigate the tutorial system.

## User's Intent

The principal typed `/tutorial` with an optional command to navigate the onboarding tutorials.

## Available Commands

### `/tutorial` (no args)
**Resume from last point**

Check their `claude/principals/{name}/onboarding.yaml` for:
- `current_path` - Where they left off
- `completed_sections` - What they've finished

Resume from `current_path` or suggest what to do next based on completed sections.

### `/tutorial status`
**Show progress**

Display:
- Sections completed
- Current path (if any)
- Available paths
- Estimated time remaining

Example output:
```
Tutorial Progress:
✓ Welcome
✓ Concepts: Agents
✓ Explore: Tools
⏸ Current: Explore: Collaboration

Available paths:
• New Project (5 min)
• Existing Codebase (5 min)
• Quick Setup (2 min)

Type /tutorial to continue, or choose a new path.
```

### `/tutorial restart`
**Start over**

Confirm with the principal, then:
1. Clear their `onboarding.yaml` (or archive it)
2. Start fresh with the welcome flow
3. Re-present the 5 initial paths

### `/tutorial skip`
**Skip current section**

Mark the current section as completed and move to:
- Next section in current path
- Or ask what they want to do next

Update `onboarding.yaml` accordingly.

## Onboarding State File

Location: `claude/principals/{principal}/onboarding.yaml`

Format:
```yaml
started: 2026-01-14
last_active: 2026-01-14
completed_sections:
  - welcome
  - concepts.agents
  - explore.tools
current_path: explore.collaboration
preferences:
  experience_level: intermediate  # beginner, intermediate, advanced
  primary_language: typescript
  prefers_minimal_guidance: false
```

## Reading State

Use the Read tool:
```
Read file: claude/principals/{name}/onboarding.yaml
```

If file doesn't exist, they haven't started the tutorial yet - suggest `/welcome`.

## Writing State

Use the Write tool to update `onboarding.yaml` after:
- Completing a section
- Starting a new path
- Skipping content
- Recording preferences

## Tutorial Paths

**Main paths:**
1. New Project - `claude/docs/tutorials/new-project.md`
2. Existing Codebase - `claude/docs/tutorials/existing-codebase.md`
3. Explore - `claude/docs/tutorials/explore/` (agents, workstreams, tools, collaboration)
4. Concepts - `claude/docs/tutorials/concepts/` (principals, agents, workstreams)
5. Quick Setup - `claude/docs/tutorials/quick-setup.md`

## Example Interactions

### Resume
```
Principal: /tutorial

Captain: You're in the middle of learning about collaboration!
[Continues from explore/collaboration.md]
```

### Status
```
Principal: /tutorial status

Captain: Tutorial Progress:
✓ Welcome
✓ Concepts: Principals
✓ Concepts: Agents
Current: Concepts: Workstreams (3 min remaining)

Type /tutorial to continue.
```

### Skip
```
Principal: /tutorial skip

Captain: Skipping current section. What would you like to do next?
[Presents options based on what they haven't seen]
```

### Restart
```
Principal: /tutorial restart

Captain: This will reset your tutorial progress. Are you sure?
[If confirmed, clear state and restart welcome flow]
```

## Guidelines

### Be Helpful
- Always offer a clear next step
- Don't make them feel lost
- Suggest relevant paths based on progress

### Respect Their Time
- Show time estimates
- Allow skipping
- Don't force completion

### Track Accurately
- Update state after each section
- Persist preferences
- Don't lose progress

## Important Notes

- The tutorial system is optional - they can stop any time
- State is per-principal, so multiple principals can have independent progress
- If onboarding.yaml doesn't exist, create it when they start
- Be encouraging about their progress!
