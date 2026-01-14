# Tutorial: Quick Setup

**Time:** 2 minutes
**Goal:** Get up and running fast with minimal guidance

## For the Impatient

You already know what you're doing. Let's get you set up quickly.

## What I Need

Ask for these three things:

1. **Your name** (for the principal directory)
   - Used to create `claude/principals/{name}/`

2. **Primary workstream name** (e.g., "web", "api", "core")
   - Used to create `claude/workstreams/{workstream}/`

3. **First agent name** (or suggest "dev" as default)
   - Used to create `claude/agents/{agent}/`

## Setup Commands

Run these commands with their input:

```bash
# Create principal directory (if not exists)
mkdir -p claude/principals/{name}

# Create workstream
./tools/workstream-create {workstream}

# Create agent
./tools/agent-create {workstream} {agent}

# Optional: Initialize secrets
./tools/secret vault init
```

## Summary Output

Show them what was created:

```
✓ Created claude/principals/{name}/
✓ Created claude/workstreams/{workstream}/
✓ Created claude/agents/{agent}/

You're all set! Launch your agent:
  ./tools/myclaude {workstream} {agent}
```

## Quick Reference

Point them to key resources:

- **Full guide:** `CLAUDE.md`
- **Documentation:** `claude/docs/`
- **Get help:** Type `/welcome` again for the full tour

## Optional Next Steps

Ask if they want to:
- Configure permissions (`.claude/settings.local.json`)
- Set up secrets (`./tools/secret vault init`)
- Add git hooks (`./tools/commit-precheck --setup`)

Or just let them start working.

## Completion

That's it! Quick and clean.

Update their `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - quick-setup
preferences:
  experience_level: advanced
  prefers_minimal_guidance: true
```
