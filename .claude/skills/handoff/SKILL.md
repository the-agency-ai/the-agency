---
description: Write a session handoff using the handoff tool — archive, write, verify
---

<!-- Flag #62/#63: allowed-tools removed. Inherit Bash(*) from settings.json. -->


# Session Handoff

Write a handoff file for session continuity. **Always use the handoff tool** — never write handoff files manually.

## Arguments

- `$ARGUMENTS`: Optional trigger name (e.g., `pre-restart`, `phase-complete`, `discussion-milestone`). Defaults to `manual`.

## Instructions

### Step 1: Archive and signal

Run the handoff tool to archive the current handoff and prepare for a new one:

```
bash ./claude/tools/handoff write --trigger $ARGUMENTS
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

**Integrity rule:** before writing, check `git status`. If any implementation
files (.ts, .py, .bats, .sh, claude/tools/*, hooks/*, etc.) are uncommitted,
either commit them first OR clearly mark them as "in progress — uncommitted"
in the Current State section. **Never write 'complete' for uncommitted work.**

The handoff tool will automatically detect uncommitted impl files and emit a
WARNING that you should include verbatim in the handoff Current State section.
This is the audit trail — the next session reading the handoff sees exactly
what was left dirty.

### Step 3: Verify

Run `bash ./claude/tools/handoff read` to verify the handoff was written correctly.
