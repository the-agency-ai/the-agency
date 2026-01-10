# PROP-0007: Session Capture for Book Writing

**Status:** draft
**Priority:** medium
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Valuable content is generated during sessions:
1. Process knowledge (how we solved problems)
2. Technical knowledge (what we learned)
3. Pattern discoveries (reusable approaches)

This content should feed into book writing but is currently lost or scattered.

## Proposal

Structured capture mechanism for book-worthy content during sessions.

### Capture Types

| Type | Purpose | Example |
|------|---------|---------|
| process | How we did something | "How we designed the proposal system" |
| knowledge | What we learned | "Unix FHS pattern for distribution" |
| pattern | Reusable approach | "Context stack push/pop pattern" |
| dialogue | Instructive conversation | "Discussion about local vs upstream" |

### Usage

```bash
./tools/capture-for-book -t "Title" -T process
./tools/capture-for-book -t "Unix FHS Research" -T knowledge
./tools/capture-for-book -t "Context Stack Pattern" -T pattern
```

### Output

Creates entries in:
```
claude/principals/jordan/projects/the-agency-book/captures/
├── CAPTURE-0001-process-proposal-system-design.md
├── CAPTURE-0002-knowledge-unix-fhs-pattern.md
└── CAPTURE-0003-pattern-context-stack.md
```

### Capture Template

```markdown
# CAPTURE-0001: Title

**Type:** process | knowledge | pattern | dialogue
**Date:** 2026-01-06
**Session:** (reference to session/working-note)
**Book Section:** (suggested placement)

## Summary
Brief overview for quick scanning.

## Content
Full captured content.

## Book Notes
How this might be used in the book.
```

### Integration

- Working notes can be tagged for book capture
- Session summaries can highlight book-worthy content
- TheCaptain could suggest "this seems book-worthy"

## Key Points

- Structured capture preserves value
- Types help organize content
- Links back to source sessions
- Feeds directly into book project

## Open Questions

- [ ] Auto-suggest book-worthy content?
- [ ] Integration with working-note tool?
- [ ] How to handle sensitive/internal content?

## Dependencies

- Related proposals: none
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Jordan: "We need to be capturing these discussions and what we did from time-to-time in WORKNOTES for input to the book writing."
