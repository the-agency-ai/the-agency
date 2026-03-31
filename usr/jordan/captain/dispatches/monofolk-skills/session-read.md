---
allowed-tools: Read, Glob, Grep, Bash(wc:*), Bash(stat:*), Bash(head:*), Bash(tail:*), Bash(find:*)
description: Read a past session and produce a structured summary (messages, tool calls, files, decisions)
---

# /session-read

Extract a structured summary from a Claude Code session JSONL file.

## Arguments

`$ARGUMENTS` is a session ID (full UUID or partial prefix) or a session index from `/session-list`.

## Steps

1. **Find the JSONL file** matching the ID:

   ```
   find ~/.claude/projects/ -name "$ARGUMENTS*.jsonl" -type f
   ```

   If multiple matches, show them and ask the user to be more specific.

2. **Read the full JSONL file** using the Read tool (it may be large — use offset/limit if needed).

3. **Parse and extract** a structured summary with these sections:

### Session Metadata

- Session ID, date range (first to last timestamp), branch, directory, Claude Code version

### User Messages (chronological)

For each `type: "user"` line:

- Timestamp (relative: "10:23", "10:45", etc.)
- Content (full text, not truncated)

### Tool Activity Summary

For each `type: "assistant"` line that contains `tool_use` blocks in `message.content[]`:

- Tool name and input summary:
  - Bash: the command
  - Edit/Write: the file path
  - Read: the file path
  - Glob/Grep: the pattern
  - Agent: subagent type + description
  - Skill: skill name
- Group consecutive tool calls together

### Files Modified

Unique list of file paths from Edit, Write, and MultiEdit tool_use blocks (extracted from `tool_input.file_path`).

### Key Decisions

Scan assistant text blocks for phrases indicating decisions:

- "decided", "chose", "going with", "plan is", "approach:", "the fix is"
- Extract the surrounding sentence/paragraph

### Git Operations

Scan Bash tool_use blocks for git commands:

- `git commit` — extract commit message
- `git push`, `git merge`, `git rebase` — note the operation
- `git branch` — note branch changes

4. **Output** the summary in markdown format with clear section headers.

## JSONL Format Reference

Each line is a JSON object:

- `type: "user"` — has `message.content` (string), `timestamp`, `cwd`, `gitBranch`
- `type: "assistant"` — has `message.content[]` (array of text/tool_use/thinking blocks)
- `type: "progress"` — hook events, tool result progress (skip these)
- `type: "file-history-snapshot"` — file backup metadata (skip these)

Tool use blocks in assistant messages:

```json
{
  "type": "tool_use",
  "name": "Bash",
  "input": { "command": "git status", "description": "..." }
}
```

## Notes

- Large sessions (>1MB) may need to be read in chunks using offset/limit
- Focus on user messages and tool calls — skip thinking blocks and progress events
- The summary should be concise enough to fit in a single screen but complete enough to reconstruct what happened
