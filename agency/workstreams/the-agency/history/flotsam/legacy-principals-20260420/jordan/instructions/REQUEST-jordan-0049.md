# REQUEST-jordan-0049

**Status:** impl
**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Priority:** Critical (blocking - context loss breaks session continuity)
**Created:** 2026-01-14

## Problem Statement

Session context was lost across sessions, causing the agent to start with zero context on two consecutive session restarts. The existing `session-backup` system only captured git state (branch, patches, status) but not conversational context (what was discussed, what was accomplished, what's parked, next steps).

This is a critical flaw in The Agency's session continuity system - without conversational context, agents cannot effectively resume work.

## Request

Implement automatic session context capture system that:
1. Allows agents to save conversational context incrementally during sessions
2. Automatically restores context when sessions start
3. Works even if session ends abruptly (incremental saves)
4. Uses structured format that's both machine-parseable and human-readable
5. Is Claude-driven (agent decides when to save)

## Solution Implemented

### Architecture

**Incremental context capture** - Context saved throughout session, not just at end (critical because SessionEnd hook runs after conversation ends)

**Claude-driven** - Agent proactively saves context at key moments using `./tools/context-save`

**JSONL format** - Appendable without parsing entire file, each line independently valid JSON

**Hook-based restoration** - SessionStart hook automatically injects previous context

### Files Created

1. **`tools/context-save`** - Context capture tool
   - `--append "text"` - General progress note
   - `--checkpoint "text"` - Significant milestone
   - `--park "text"` - Something to revisit later
   - `--clear` - Clear context (new session)

2. **`tools/context-review`** - Review tool
   - Default: Formatted timeline view
   - `--summary`: Last checkpoint + parked items
   - `--raw`: Raw JSONL

3. **`.claude/hooks/session-start.sh`** - Context restoration hook
   - Reads `agency/agents/{AGENT}/backups/latest/context.jsonl`
   - Formats and displays last 10 context entries
   - Shows parked items prominently (⏸ PARKED)
   - Shows git status summary if uncommitted changes
   - Runs `tab-status available`

### Files Modified

1. **`.claude/settings.json`**
   - Changed SessionStart hook from inline `tab-status` to `.claude/hooks/session-start.sh`
   - Added permissions: `Bash(./tools/context-save*)`, `Bash(./tools/context-review*)`

2. **`tools/session-backup`**
   - Added archiving of `context.jsonl` to historical backups
   - Preserves context alongside git state

3. **`CLAUDE.md`**
   - Added "Session Context Management" section after Permissions
   - Documents when to save context (5 key moments)
   - Provides usage examples
   - Explains context types and automatic restoration
   - Emphasizes best practice: save proactively, not reactively

### File Format

**Location:** `agency/agents/{AGENT}/backups/latest/context.jsonl`

**Format:** JSONL (JSON Lines) - one JSON object per line

```jsonl
{"timestamp":"2026-01-14 15:48:55 +08","type":"append","content":"Working on feature X"}
{"timestamp":"2026-01-14 15:48:56 +08","type":"checkpoint","content":"Feature X complete"}
{"timestamp":"2026-01-14 15:48:57 +08","type":"park","content":"Bug in validation logic"}
```

### Session Workflow

**During Session:**
1. Agent works on tasks
2. After completing subtask: `./tools/context-save --checkpoint "what was done"`
3. When finding issue for later: `./tools/context-save --park "issue description"`
4. Before context switch: `./tools/context-save --checkpoint "switching to X"`
5. SessionEnd hook archives context automatically

**Next Session:**
1. User launches agent
2. SessionStart hook displays previous context:
   ```
   === PREVIOUS SESSION CONTEXT ===
   ✓ Feature X complete
   ⏸ PARKED: Bug in validation logic
   • Working on tests
   === END PREVIOUS SESSION CONTEXT ===
   ```
3. Agent continues from where it left off

## Testing Completed

- ✅ `context-save` creates valid JSONL
- ✅ `context-review` displays formatted output correctly
- ✅ Context persisted to correct location
- ✅ All three context types work (append, checkpoint, park)
- ⏸ SessionStart hook verification pending (requires session restart)

## Commits

- `30501da` - housekeeping/housekeeping: feat: Automatic session context capture

## Tags

- [ ] `REQUEST-jordan-0049-impl` - Implementation complete, tested
- [ ] `REQUEST-jordan-0049-review` - Code review complete
- [ ] `REQUEST-jordan-0049-tests` - Test review complete
- [ ] `REQUEST-jordan-0049-complete` - Fully complete, ready for release

## Next Steps

1. Verify SessionStart hook works correctly on next session launch
2. Monitor usage to ensure agents are saving context regularly
3. Consider adding system reminder if no context saved after N prompts (future enhancement)

## Notes

**Why JSONL over JSON:**
- Appendable without parsing entire file
- Each line independently valid
- Easy to parse and human-readable
- Timestamp-ordered naturally

**Why Claude-driven vs automatic:**
- Gives agent control over context quality
- Agent knows what's important vs noise
- More reliable than trying to parse conversation automatically

**Backward compatible:**
- Extends existing session-backup system
- Doesn't replace manual SESSION-BACKUP-*.md files
- Works alongside existing ADHOC-WORKLOG patterns
