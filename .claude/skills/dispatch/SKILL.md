---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch *), Bash(bash claude/tools/dispatch *), Read, Write
description: Manage dispatches — list, read, create, resolve
---

# Dispatch Management

Manage dispatch files for inter-agent communication (code review findings, task assignments).

## Arguments

- `$ARGUMENTS`: Subcommand and arguments. One of:
  - `list` — list dispatches for the current project
  - `list --all` — list all dispatches across projects
  - `read <file>` — read a dispatch and mark as read
  - `create <project> <slug>` — create a new dispatch
  - `resolve <file>` — mark a dispatch as resolved
  - `check` — check for unread dispatches
  - `status <file>` — show dispatch lifecycle status

If empty, defaults to `list`.

## Instructions

### list / list --all

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch $ARGUMENTS` and display results.

### read

1. Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch read <file>` to display and mark as read.
2. Summarize the findings for the user.

### create

1. Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch create <project> <slug>` to scaffold a new dispatch.
2. Report the created file path so the user or agent can fill in the content.

### resolve

1. Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch resolve <file>` to mark as resolved.
2. Confirm resolution status.

### check

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch check` and report any unread dispatches.

### status

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch status <file>` and display the lifecycle state.
