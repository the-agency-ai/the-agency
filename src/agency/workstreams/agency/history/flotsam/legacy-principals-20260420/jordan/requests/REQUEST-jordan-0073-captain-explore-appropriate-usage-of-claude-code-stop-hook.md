# REQUEST-jordan-0073: Explore appropriate usage of Claude Code Stop hooks for The Agency workflow

**Status:** Open
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-23
**Updated:** 2026-01-23

## Summary

Explore appropriate usage of Claude Code Stop hooks for The Agency workflow

## Details

We have a prototype Stop hook (`.claude/hooks/stop-check.py`) that checks for:
1. Uncommitted git changes
2. Incomplete TODOs

This REQUEST is to explore what other checks would be valuable for The Agency workflow and when the Stop hook is the right mechanism (vs other approaches).

### Questions to Explore

1. **What should trigger a Stop hook block?**
   - Uncommitted changes (already implemented)
   - Incomplete TODOs (already implemented)
   - Context not saved?
   - Tests not run after code edits?
   - Pending collaboration requests?
   - WORKLOG not updated?
   - Open nits?

2. **When is Stop hook the wrong tool?**
   - What's too aggressive/annoying?
   - When should we use reminders vs blocks?
   - How do we avoid infinite loops or user frustration?

3. **What context does the Stop hook have access to?**
   - JSON input fields
   - Transcript parsing capabilities
   - Environment variables
   - External state (files, git, services)

4. **Should Stop hooks be configurable?**
   - Per-project settings?
   - Per-agent settings?
   - User preferences?

### Background

- Stop hook fires when Claude is about to stop responding
- Can return `{"decision": "block", "reason": "..."}` to prevent stopping
- `stop_hook_active` flag prevents infinite loops (only blocks once)
- Prompt-type hooks have a bug (#11786) - must use command-type

## Acceptance Criteria

- [ ] Document recommended Stop hook checks for Agency workflow
- [ ] Identify checks that are too aggressive / should be optional
- [ ] Propose configuration mechanism if needed
- [ ] Update stop-check.py with finalized checks
- [ ] Update CLAUDE.md or docs with Stop hook guidance

## Work Completed

<!-- Document completed work here -->

---

## Activity Log

### 2026-01-23 - Created
- Request created by jordan
