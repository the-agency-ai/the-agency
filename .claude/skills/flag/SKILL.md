---
description: Quick-capture observations to a queue for later follow-up or 1B1 discussion
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Flag

Zero-friction capture of observations during work. Flag something now, discuss it later. Flags are stored in the ISCP SQLite DB (outside git) — instant capture from any worktree.

## Arguments

- `$ARGUMENTS`: The message to flag, or a subcommand (`list`, `clear`, `count`, `discuss`), or `--to <agent> <message>` to route to a specific agent.

## Instructions

### Flagging an item (to self)

If `$ARGUMENTS` is a message (not a subcommand):

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag "$ARGUMENTS"
```

Confirm: "Flagged: [message summary]"

### Flagging to a specific agent

If `$ARGUMENTS` starts with `--to`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag --to <agent-address> "message"
```

The agent address must be fully qualified (`repo/principal/agent`). The flag appears in the target agent's queue on their next `flag list` or `iscp-check`.

### Listing the queue

If `$ARGUMENTS` is `list`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag list
```

Displays all unread flags and marks them as `read` (Slack-style seen behavior). Three-state lifecycle: unread → read (on list) → processed (on discuss/clear).

### Counting items

If `$ARGUMENTS` is `count`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag count
```

Returns unread count only.

### Clearing the queue

If `$ARGUMENTS` is `clear`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag clear
```

Marks all flags as `processed`.

### Discussing flagged items

If `$ARGUMENTS` is `discuss`:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/flag discuss
```

Outputs the queue as a numbered 1B1 agenda and marks all as `processed`. Then invoke `/discuss` with the agenda items for structured resolution.

## Flag Lifecycle

```
capture → unread → read (on list) → processed (on discuss/clear)
```

Flags are DB-only — no git payload, instant capture. They're designed for quick observations during work, not formal communication (use dispatches for that).

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
