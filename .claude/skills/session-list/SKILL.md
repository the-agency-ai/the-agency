---
description: List past Claude Code sessions with metadata (date, branch, directory, size, first message)
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session List

List all Claude Code sessions for this project with metadata.

## Arguments

- `--branch <pattern>` — filter to sessions on a specific branch
- `--since YYYY-MM-DD` — only show sessions after this date
- No arguments shows all sessions, newest first

## Steps

1. **Find session files:** Glob `~/.claude/projects/*/*.jsonl` (exclude subagent files).

2. **Extract metadata** from each file's first user message line:
   - Timestamp, cwd, gitBranch, sessionId
   - First message content (truncate to 80 chars)
   - File size

3. **Filter** by `--branch` or `--since` if specified.

4. **Display as table** sorted by date (newest first):

   ```
   | Date       | Branch              | Directory                    | Size  | First Message          | Session ID |
   |------------|---------------------|------------------------------|-------|------------------------|------------|
   | 2026-03-20 | proto/proto-tooling | .worktrees/proto-tooling/    | 3.5MB | resume                 | abc123...  |
   ```

5. Show the session ID so the user can pass it to `/session-read`.
