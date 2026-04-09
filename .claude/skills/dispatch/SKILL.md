---
description: Manage dispatches — list, read, fetch, reply, create, resolve
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Dispatch Management

Manage ISCP dispatches for inter-agent communication. Dispatches are indexed in the ISCP SQLite DB with payload files in git. All operations use integer dispatch IDs, not file paths.

## Arguments

- `$ARGUMENTS`: Subcommand and arguments. One of:
  - `list` — list dispatches addressed to current agent
  - `list --all` — list all dispatches across agents
  - `list --status <s>` — filter by status (unread, read, resolved)
  - `list --type <t>` — filter by type
  - `read <id>` — display dispatch payload and mark as read
  - `fetch <id>` — read-only peek (no status change)
  - `reply <id> "message"` — quick response to a dispatch
  - `create --to <addr> --subject <text>` — create a new dispatch
  - `create --to <addr> --subject <text> --body <text>` — create with inline content
  - `resolve <id>` — mark a dispatch as resolved
  - `check` — silent check for unread items (hook use)
  - `status <id>` — show full dispatch record

If empty, defaults to `list`.

## Instructions

### list

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch list $ARGUMENTS` and display results.

### read / fetch

- `read <id>` — displays the dispatch and marks it as read. Use when you're committing to process it.
- `fetch <id>` — displays the dispatch without changing status. Use to peek before deciding.

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch read <id>` or `fetch <id>`.
Summarize the content for the user.

### reply

Quick response to an existing dispatch. Auto-resolves the recipient from the original sender, prefixes subject with "Re:", and sets the in_reply_to FK.

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch reply <id> "Your response message"
```

### create

Create a new dispatch. The `--to` address must be fully qualified (`repo/principal/agent`).

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch create --to <addr> --subject <text> [--body <text>] [--type <type>] [--priority <p>]
```

- Without `--body`: writes a template payload (warns about placeholders — edit before committing)
- With `--body`: writes the message as payload content (no template)
- Types: directive, seed, review, review-response, commit, master-updated, escalation, dispatch
- Priority: normal (default), high, low

### resolve

Mark a dispatch as resolved, optionally linking a response dispatch:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch resolve <id> [--response <id>]
```

### check

Silent check for unread items. Returns JSON `{"systemMessage": "..."}` when items are waiting, silent exit 0 when empty. Used by the `iscp-check` hook.

### status

Show the full record for a dispatch including timestamps, read_by, and payload path:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch status <id>
```

## Dispatch Workflow

1. **Receive:** `dispatch list` → see what's waiting
2. **Peek:** `dispatch fetch <id>` → inspect without committing
3. **Read:** `dispatch read <id>` → commit to processing, marks as read
4. **Reply:** `dispatch reply <id> "message"` → quick acknowledgment or response
5. **Resolve:** `dispatch resolve <id>` → mark as done

## Payload Resolution

Dispatch payloads are resolved transparently across branches and worktrees. The resolution ladder: local worktree → main checkout → git show all branches → scan all worktree directories. You don't need to merge main to read a dispatch — just `dispatch read <id>`.
