---
allowed-tools: Bash(ls:*), Bash(stat:*), Bash(head:*), Bash(wc:*), Bash(find:*), Bash(sort:*), Read, Glob, Grep
description: List past Claude Code sessions with metadata (date, branch, directory, size, first message)
---

# /session-list

List all Claude Code sessions for this project with metadata.

## Arguments

`$ARGUMENTS` may contain:

- `--branch <pattern>` — filter to sessions on a specific branch
- `--since YYYY-MM-DD` — only show sessions after this date
- No arguments shows all sessions, newest first

## Steps

1. Find all JSONL session files (exclude subagent files):

   ```
   find ~/.claude/projects/ -name "*.jsonl" -type f -not -path "*/subagents/*"
   ```

2. For each file, extract the first user message using `grep -m 1`:

   ```
   grep -m 1 '"type":"user"' <file>
   ```

   - From that line, extract: `timestamp`, `cwd`, `gitBranch`, `sessionId`, `message.content` (truncate to 80 chars)
   - Get file size via `stat`

3. If `--branch <pattern>` is provided, filter to sessions where `gitBranch` matches the pattern.

4. If `--since YYYY-MM-DD` is provided, filter to sessions with timestamp after that date.

5. Display as a table sorted by date (newest first):

   ```
   | Date       | Branch              | Directory                    | Size  | First Message          |
   |------------|---------------------|------------------------------|-------|------------------------|
   | 2026-03-20 | proto/proto-tooling | .worktrees/proto-tooling/    | 3.5MB | resume                 |
   | 2026-03-19 | master              | /Users/.../code/monofolk/    | 1.3MB | Let's crawl the sites  |
   ```

6. Show the session ID for each row so the user can pass it to `/session-read`.

## Notes

- Session files live at `~/.claude/projects/<flattened-path>/<uuid>.jsonl`
- The flattened path uses dashes instead of slashes (e.g., `-Users-jordan-of-code-monofolk`)
- Each line in the JSONL is a JSON object with a `type` field
- Only `type: "user"` lines have the first message content
- The `cwd` field shows the working directory — shorten absolute paths for readability
