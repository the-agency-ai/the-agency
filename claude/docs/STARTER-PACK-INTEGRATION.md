# Starter Pack Integration for Captain Rename

## Overview

This document describes what needs to be integrated into `the-agency-starter` after the captain agent rename and Captain's Tour implementation.

## Files to Include

### 1. Captain Agent Structure

**Include in starter:**
```
claude/agents/captain/
  ├── agent.md              # From this repo
  ├── KNOWLEDGE.md          # Empty or minimal starter content
  ├── ADHOC-WORKLOG.md      # Empty
  ├── WORKLOG.md            # Empty
  ├── backups/
  │   └── latest/
  │       └── context.jsonl # First-launch context
  └── logs/
```

### 2. First-Launch Context

**File:** `claude/agents/captain/backups/latest/context.jsonl`

**Content:** (from `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl`)
```jsonl
{"timestamp":"2026-01-01 00:00:00 +00","type":"checkpoint","content":"Captain's first session - principal just installed The Agency"}
{"timestamp":"2026-01-01 00:00:01 +00","type":"checkpoint","content":"Your role: Guide this principal through their first steps with The Agency"}
{"timestamp":"2026-01-01 00:00:02 +00","type":"append","content":"Greet them warmly and offer to help set up their project"}
{"timestamp":"2026-01-01 00:00:03 +00","type":"append","content":"Key offers: Configure permissions, initialize secrets, create first workstream/agent"}
{"timestamp":"2026-01-01 00:00:04 +00","type":"append","content":"Suggest they try '/welcome' for the interactive guided tour"}
{"timestamp":"2026-01-01 00:00:05 +00","type":"park","content":"This context will be replaced with real session context as you work together"}
```

**Why:** Provides captain-focused guidance on first launch.

### 3. Tutorial Content

**Include in starter:**
```
claude/docs/tutorials/
  ├── new-project.md
  ├── existing-codebase.md
  ├── quick-setup.md
  ├── explore/
  │   ├── agents.md
  │   ├── workstreams.md
  │   ├── tools.md
  │   └── collaboration.md
  └── concepts/
      ├── principals.md
      ├── agents.md
      └── workstreams.md
```

**Why:** Enables the `/welcome` interactive tour out of the box.

### 4. Commands

**Include in starter:**
```
.claude/commands/
  ├── welcome.md
  └── tutorial.md
```

**Why:** Provides `/welcome` and `/tutorial` commands for onboarding.

### 5. Documentation Updates

**Files to sync:**
- `CLAUDE.md` - Updated Quick Start and Getting Help sections
- `claude/docs/FIRST-LAUNCH.md` - Updated paths and references
- `README.md` - No changes needed (already generic)

### 6. Tools to Sync

**Files to sync:**
- `tools/myclaude` - Updated example usage (line 12)
- `tools/commit` - Updated default agent (line 119)
- `.claude/hooks/session-start.sh` - Updated default AGENTNAME (line 5)
- `tools/iterm-setup` - Updated profile name, GUID, badge (lines 68-89)

### 7. Configuration Template

**File:** `.claude/settings.local.json.example`

No changes needed - already generic.

**File:** `claude/principals/TEMPLATE/config/iterm/agency-profiles.json`

Update the housekeeping profile to captain:
```json
{
  "Name": "Agency - Captain",
  "Guid": "agency-captain-PRINCIPALNAME",
  "Badge Text": "captain",
  "Initial Text": "# Captain agent session\n./tools/myclaude housekeeping captain"
}
```

## Installation Flow

When a user runs the installer:

1. **Clone/copy the-agency-starter**
2. **Initialize git** (if new repo)
3. **Create principal directory** for the user
4. **Copy captain agent structure** to `claude/agents/captain/`
5. **Preserve first-launch context** in `backups/latest/context.jsonl`
6. **Launch first session:** `./tools/myclaude housekeeping captain`

On first launch:
- SessionStart hook reads `context.jsonl`
- Captain sees guidance about helping the principal
- Principal is greeted and offered help or `/welcome` tour

## Testing the Integration

### Test 1: Fresh Install
```bash
# Simulate fresh install
rm -rf test-install/
mkdir test-install && cd test-install

# Run installer (however that works in starter)
# ...

# Launch captain
./tools/myclaude housekeeping captain

# Expected: See first-launch context display
# Expected: Captain greets and offers help
```

### Test 2: Welcome Tour
```bash
# In captain session
# Type: /welcome

# Expected: 5 paths presented
# Expected: Can select path and follow tutorial
# Expected: State saved to onboarding.yaml
```

### Test 3: Tutorial Navigation
```bash
# Type: /tutorial status
# Expected: Shows progress

# Type: /tutorial skip
# Expected: Moves to next section

# Type: /tutorial restart
# Expected: Resets progress
```

## Migration Notes

### For Existing Installations

Users with existing installations will need to:

1. **Rename agent directory:**
   ```bash
   git mv claude/agents/housekeeping claude/agents/captain
   ```

2. **Update tools:**
   - Pull latest from the-agency repo
   - Tools will reference captain automatically

3. **Optional: Add tutorial content:**
   ```bash
   # Copy from the-agency repo
   cp -r the-agency/.claude/commands .claude/
   cp -r the-agency/claude/docs/tutorials claude/docs/
   ```

4. **Update local config:**
   - Update `.claude/settings.local.json` if it references housekeeping
   - Update iTerm profiles

### Backward Compatibility

- No breaking changes to the API
- Old REQUEST files remain unchanged (historical record)
- Principals can still create agents named "housekeeping" if they want
- Commit pattern changes: `housekeeping/housekeeping` → `housekeeping/captain`

## Checklist for Starter Pack

- [ ] Copy captain agent structure
- [ ] Include first-launch context.jsonl
- [ ] Include all tutorial content (9 files)
- [ ] Include /welcome and /tutorial commands
- [ ] Sync CLAUDE.md documentation
- [ ] Sync FIRST-LAUNCH.md documentation
- [ ] Sync updated tools (myclaude, commit, session-start, iterm-setup)
- [ ] Update iTerm profile template
- [ ] Test fresh installation flow
- [ ] Test /welcome command works
- [ ] Test /tutorial navigation works
- [ ] Document migration path for existing users

## Questions

- Should we provide a migration script for existing installations?
- Should installer prompt for principal name or detect from git config?
- Should we auto-run `/welcome` on first launch or just suggest it?

## Related Files

- `claude/docs/FIRST-LAUNCH.md` - First-launch experience documentation
- `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl` - Template context file
- `claude/agents/captain/agent.md` - Captain's full identity
- REQUEST-jordan-0049 - This work item

---

*Document created for the-agency-starter integration after captain rename*
