---
description: Read a dispatch and mark it as read — works from any branch or worktree
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Read Dispatch

Read a dispatch by ID, display its contents, and mark as read. Payloads resolve transparently across branches and worktrees — no merge needed.

## Arguments

- `$ARGUMENTS`: An integer dispatch ID. If empty, list available dispatches first.

## Instructions

### Step 1: List or read

If `$ARGUMENTS` is empty:

1. Run `./agency/tools/dispatch list` to show dispatches for the current agent.
2. If no dispatches, try `./agency/tools/dispatch list --all` for all agents.
3. Ask which dispatch to read.

If `$ARGUMENTS` is an integer ID:

1. Run `./agency/tools/dispatch read $ARGUMENTS` to display and mark as read.

To peek without marking as read, use `./agency/tools/dispatch fetch $ARGUMENTS` instead.

### Step 2: Evaluate findings

After reading the dispatch:

1. For each finding or directive, assess: is it actionable? Has context changed?
2. For review dispatches: classify each finding as **valid** (fix it), **stale** (code changed), or **disputed** (explain why).
3. Report your assessment before starting work.

### Step 3: Act on valid items

For review findings, follow the red-green cycle:
1. Write a bug-exposing test that fails (red).
2. Fix the code.
3. Verify the test passes (green).

For directives, execute the work as specified.

### Step 4: Respond and resolve

After all items are addressed:

1. Run `./agency/tools/dispatch reply <id> "summary of what was done"` to send a response.
2. Run `./agency/tools/dispatch resolve <id> --response <reply-id>` to mark as resolved.
3. Run `/iteration-complete` to commit your code changes.
