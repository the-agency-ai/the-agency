---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/flag *)
description: Quick-capture observations to a queue for later follow-up or 1B1 discussion
---

# Flag

Zero-friction capture of observations during work. Flag something now, discuss it later.

## Arguments

- `$ARGUMENTS`: The message to flag, or a subcommand (`list`, `clear`, `count`, `discuss`).

## Instructions

### Flagging an item

If `$ARGUMENTS` is a message (not a subcommand):

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag "$ARGUMENTS"
```

Confirm: "Flagged. N items in queue."

### Listing the queue

If `$ARGUMENTS` is `list`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag list
```

Display the numbered queue with timestamps and branches.

### Counting items

If `$ARGUMENTS` is `count`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag count
```

### Clearing the queue

If `$ARGUMENTS` is `clear`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag clear
```

### Discussing flagged items

If `$ARGUMENTS` is `discuss`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag discuss
```

This outputs the queue as a numbered agenda and clears it. Then invoke `/discuss` with the agenda items for 1B1 resolution.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
