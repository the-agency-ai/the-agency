---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/handoff *), Read, Write
description: Write a session handoff using the handoff tool — archive, write, verify
---

# Session Handoff

Write a handoff file for session continuity. **Always use the handoff tool** — never write handoff files manually.

## Arguments

- `$ARGUMENTS`: Optional trigger name (e.g., `pre-restart`, `phase-complete`, `discussion-milestone`). Defaults to `manual`.

## Instructions

### Step 1: Archive and signal

Run the handoff tool to archive the current handoff and prepare for a new one:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/handoff write --trigger $ARGUMENTS
```

If `$ARGUMENTS` is empty, use `--trigger manual`.

### Step 2: Write the handoff

Write the handoff file at the path the tool reported. Include:

1. **Date and context** — date, branch, session/agent name
2. **What was done** — completed work this session, key changes
3. **What's next** — immediate next steps for a fresh session
4. **Key decisions** — anything a new session needs to know
5. **Open items/blockers** — unresolved issues, pending discussions
6. **Discussion queue** — carried-forward discussion items

### Step 3: Verify

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/handoff read` to verify the handoff was written correctly.
