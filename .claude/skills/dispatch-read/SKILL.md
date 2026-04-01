---
allowed-tools: Bash(./claude/tools/dispatch:*), Read, Grep, Glob
description: Read a dispatch from master and mark it as read — no merge needed
---

# Read Dispatch

Read a dispatch file from master without merging. Marks the dispatch as read on master's working tree.

## Arguments

- $ARGUMENTS: The dispatch file path (e.g., `usr/{principal}/{project}/code-reviews/{project}-dispatch-YYYYMMDD-HHMM.md`). If empty, list available dispatches first.

## Instructions

### Step 1: List or read

If `$ARGUMENTS` is empty:

1. Run `./claude/tools/dispatch list` to show dispatches for the current project.
2. If no dispatches, try `./claude/tools/dispatch list --all` for all projects.
3. Ask which dispatch to read.

If `$ARGUMENTS` is provided:

1. Run `./claude/tools/dispatch read $ARGUMENTS` to display the dispatch and mark it as read.

### Step 2: Evaluate findings

After reading the dispatch:

1. For each finding, investigate the code — is it still valid? Has the code changed?
2. Classify each finding: **valid** (fix it), **stale** (code changed), **disputed** (explain why it's wrong).
3. Report your assessment before starting fixes.

### Step 3: Fix valid findings

For each valid finding, follow the red-green cycle:

1. Write a bug-exposing test that fails (red).
2. Fix the code.
3. Verify the test passes (green).

### Step 4: Resolve

After all findings are addressed:

1. Run `./claude/tools/dispatch resolve $ARGUMENTS` to mark as resolved on master.
2. Write a Resolution table directly to the dispatch file on master.
3. Run `/iteration-complete` to commit your code fixes.
