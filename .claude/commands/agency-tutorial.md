# Tutorial navigation

The user typed: `/agency-tutorial $ARGUMENTS`

You are the captain, and the principal wants to navigate the tutorial system.

## Route Based on Arguments

| If $ARGUMENTS is... | Action |
|---------------------|--------|
| (empty) | Resume from last point |
| `status` | Show progress |
| `restart` | Start over (confirm first) |
| `skip` | Skip current section |

---

## Resume (no args)

1. Read `claude/principals/{name}/onboarding.yaml`
2. If `current_path` exists, continue from there
3. If no state file exists, suggest: "No tutorial in progress. Run `/agency-welcome` to start."

---

## Status

Display progress like:

```
Tutorial Progress:
  Welcome
  Concepts: Agents
  Explore: Tools
  Current: Explore: Collaboration

Available paths:
- New Project
- Existing Codebase

Type /agency-tutorial to continue.
```

Read from `claude/principals/{name}/onboarding.yaml` to get:
- `completed_sections` - What they've finished
- `current_path` - Where they are now

---

## Restart

1. Confirm with the principal: "This will reset your tutorial progress. Are you sure?"
2. If confirmed:
   - Delete or archive their `onboarding.yaml`
   - Start fresh with the welcome flow (same as `/agency-welcome`)
3. If not confirmed, do nothing

---

## Skip

1. Mark the current section as completed in `onboarding.yaml`
2. Move to the next section in the current path
3. If no more sections, ask what they want to do next

Update `onboarding.yaml` accordingly.

---

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
  experience_level: intermediate
  primary_language: typescript
  prefers_minimal_guidance: false
```

## Tutorial Paths

**Main paths:**
1. New Project - `claude/docs/tutorials/new-project.md`
2. Existing Codebase - `claude/docs/tutorials/existing-codebase.md`
3. Explore - `claude/docs/tutorials/explore/` (agents, workstreams, tools, collaboration)
4. Concepts - `claude/docs/tutorials/concepts/` (principals, agents, workstreams)
5. Quick Setup - `claude/docs/tutorials/quick-setup.md`

## Guidelines

- Always offer a clear next step
- Don't make them feel lost
- Show progress encouragingly
- Respect their time - allow skipping
- Track state accurately
