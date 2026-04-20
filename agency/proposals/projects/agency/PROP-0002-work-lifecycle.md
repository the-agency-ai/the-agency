# PROP-0002: Work Lifecycle Tools

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Currently we have `create-sprint` but no full lifecycle management. This means:
1. No explicit "start" ceremony that sets context
2. No "complete" action that summarizes and archives
3. Context window fills with old sprint details
4. No clean handoff between work phases

## Proposal

Explicit lifecycle tools for epic/sprint/iteration with context preservation.

### Tools

```bash
# Starting work
./tools/start-epic WORKSTREAM NNN        # Creates epic dir, sets focus
./tools/start-sprint WORKSTREAM NNN SSS  # Creates sprint, sets context
./tools/start-iteration NNN              # Finer-grained focus

# Completing work
./tools/complete-iteration NNN           # Summarizes iteration, clears focus
./tools/complete-sprint                  # Summarizes sprint, archives, posts news
./tools/complete-epic                    # Full retrospective, archives epic
```

### What Each Tool Does

**start-sprint:**
1. Creates sprint directory structure
2. Reads epic context
3. Sets CURRENT_SPRINT environment/file
4. Clears previous sprint's transient context
5. Posts news: "Starting sprint NNN"

**complete-sprint:**
1. Generates summary of work done
2. Archives sprint (moves completed items to archive section)
3. Updates WORKLOG.md with sprint summary
4. Posts news: "Completed sprint NNN: [summary]"
5. Preserves key context for next sprint
6. Clears transient working context

### Context Reduction

Each `complete-*` creates a compressed summary:
- What was accomplished
- Key decisions made
- Artifacts produced
- Open items carried forward

This summary replaces the full sprint details, reducing context burden.

## Key Points

- Explicit boundaries reduce cognitive load
- Automatic summarization preserves knowledge
- News integration keeps team informed
- Clean handoffs between phases

## Open Questions

- [ ] How granular should iterations be? (hours? days?)
- [ ] Should complete-sprint require all tasks done, or allow carry-forward?
- [ ] Integration with context stack (PROP-0003)?

## Dependencies

- Related proposals: PROP-0003 (Context Stack)
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Initial proposal from pre-dawn ideas session.
