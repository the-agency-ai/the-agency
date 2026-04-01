---
allowed-tools: Read, Glob, Grep, Bash(wc:*), Bash(stat:*)
description: Read a past session and produce a structured summary (messages, tool calls, files, decisions)
---

# Session Read

Extract a structured summary from a Claude Code session JSONL file.

## Arguments

`$ARGUMENTS` is a session ID (full UUID or partial prefix) or a session index from `/session-list`.

## Steps

1. **Find the JSONL file** matching the ID in `~/.claude/projects/`.

2. **Read the file** (use offset/limit for large files).

3. **Parse and extract** a structured summary:

### Session Metadata
- Session ID, date range, branch, directory

### User Messages (chronological)
- Timestamp and full content for each `type: "user"` line

### Tool Activity Summary
- Tool name and input summary (Bash commands, file paths, patterns, agent descriptions)
- Group consecutive tool calls

### Files Modified
- Unique file paths from Edit, Write, MultiEdit tool_use blocks

### Key Decisions
- Scan for "decided", "chose", "going with", "plan is", "approach:", "the fix is"

### Git Operations
- git commit messages, push/merge/rebase operations, branch changes

4. **Output** the summary in markdown format.

## Notes

- Large sessions may need chunked reading
- Focus on user messages and tool calls — skip thinking blocks and progress events
