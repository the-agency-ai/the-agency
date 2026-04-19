# PROP-0003: Context Stack (Push/Pop)

**Status:** draft
**Priority:** medium
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Two scenarios lack good support:

1. **Focus shift within session:** "I'm working on A, but need to quickly handle B, then return to A"
2. **Shutdown/restore:** Save context before ending session, restore when resuming

Currently we lose context during these transitions.

## Proposal

Stack-based context management, inspired by how humans say "push that on the stack" and "pop the stack."

### Core Concept

```bash
# Push current context onto stack
./tools/push-context "working on auth refactor"

# ... do something else entirely ...

# Return to previous context
./tools/pop-context

# See what's on the stack
./tools/list-context-stack
```

### What Gets Saved

When pushing context:
- Current focus description
- Active files/directories
- In-progress work state
- Relevant environment (WORKSTREAM, AGENTNAME, etc.)
- Timestamp

### Stack Operations

```bash
./tools/push-context "description"    # Push current, start fresh
./tools/pop-context                   # Restore most recent
./tools/peek-context                  # Show top without popping
./tools/list-context-stack            # Show all saved contexts
./tools/drop-context [N]              # Discard context N (default: top)
./tools/swap-context                  # Swap top two contexts
```

### Storage

```
claude/context-stack/
├── STACK.json           # Stack metadata
├── context-001.json     # Oldest saved context
├── context-002.json     # Next...
└── context-003.json     # Most recent (top of stack)
```

### Integration with Lifecycle

- `complete-sprint` could auto-pop if sprint context was pushed
- `start-sprint` could auto-push previous sprint context
- Shutdown hook could offer to push current context

## Key Points

- Mental model: just like a stack in programming
- Multiple contexts can be saved
- Each push saves everything needed to resume
- Pop restores exactly where you were

## Open Questions

- [ ] How deep should the stack go? (limit? auto-cleanup?)
- [ ] Should there be named contexts (like git stash)?
- [ ] Auto-push on certain events (sprint change, focus shift)?
- [ ] How to handle conflicts if files changed while context was stacked?

## Dependencies

- Related proposals: PROP-0002 (Work Lifecycle)
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Initial proposal. Jordan's framing: "In Principal Life (IPL) we will sometimes say, hey, push that on the stack, so we can tackle this, and then pop the stack."
