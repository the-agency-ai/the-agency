# Dispatch: Refactor Tools + Standardize Telemetry & Logging

**Date:** 2026-03-30
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** High — blocking. Tools must be refactored before further development.

---

## Directive

Refactor existing tools AND standardize telemetry/logging to eliminate the agency-service dependency. Two JSONL files become the single source of truth for all operational data.

## Part 1: Unified Logging & Telemetry

### Two files, two purposes

```
.claude/logs/
  tool-runs.jsonl     — per-tool-run (debugging, failure investigation)
  telemetry.jsonl     — per-tool-use (usage patterns, analytics, token awareness)
```

### tool-runs.jsonl schema (written by `_log-helper`)
```json
{
  "run": "019d3e2c-...",       // UUID7 (time-sortable)
  "tool": "git-safe-commit",
  "event": "start|end|detail",
  "ts": "2026-03-30T10:00:00Z",
  "agency": "the-agency",      // repo/agency name
  "principal": "jordan",       // who owns this session
  "agent": "captain",          // agent class or instance name
  "session": "abc-123",        // Claude session ID
  "branch": "main",
  "args": "...",               // start only
  "outcome": "success|failure", // end only
  "exit": 0,                   // end only
  "duration_ms": 150,          // end only
  "summary": "...",            // end only
  "channel": "stdout|stderr",  // detail only
  "content": "..."             // detail only
}
```

### telemetry.jsonl schema (written by telemetry hook)
```json
{
  "ts": "2026-03-30T10:00:00Z",
  "agency": "the-agency",
  "principal": "jordan",
  "agent": "captain",
  "session": "abc-123",
  "tool": "Edit",              // Claude Code tool name
  "branch": "main",
  "input_summary": "..."       // first 100 chars of tool input
}
```

### Key fields added (vs current)
- `agency` — repo name (from `basename $(git rev-parse --show-toplevel)`)
- `principal` — resolved from `_path-resolve` or `$USER` mapping
- `agent` — from `$CLAUDE_SESSION_NAME` or `$AGENTNAME` or branch-derived

These enable cross-agent, cross-agency log aggregation later.

### Contention safety
- Worktree agents have separate `.claude/logs/` — no contention
- Same-repo agents: JSONL append with `printf` is atomic under pipe buffer size (~4KB macOS, ~64KB Linux) via `O_APPEND`
- Cross-agent aggregation: simple merge script reads all worktree JSONL files

### What this replaces in agency-service

| agency-service component | Replaced by | Status |
|--------------------------|-------------|--------|
| log-service (SQLite) | `.claude/logs/tool-runs.jsonl` | Ready |
| request-service | Plan documents | Killed in v2 |
| messages-service | ISCP (future) | Dispatched |
| dispatch-service | Dispatch files in `dispatches/` | Done |
| secret-service | `secret-vault` tool (file-based) | Done |
| bug-service | Fix-what-you-find discipline | Done |
| idea-service | Learnings JSONL (future) | Planned |
| observation-service | Learnings JSONL / memory | Planned |
| product-service | agency.yaml + workstreams | Done |
| test-service | `test-run` tool output + JSONL | Planned |

**Agency-service can be deprecated once tool-runs + telemetry JSONL are in place.** Full 1B1 on remaining agency-service components coming tomorrow.

## Part 2: Tool Refactor

### 1. Update `_log-helper`

The new `_log-helper` at `claude/tools/lib/_log-helper`:
- UUID7 run IDs (time-sortable)
- Append-only JSONL at `.claude/logs/tool-runs.jsonl`
- `tool_output()` for 3-line token-conserving stdout
- `log_start()` / `log_end()` / `log_detail()` for structured logging
- Includes `agency`, `principal`, `agent` fields in every log entry
- No agency-service dependency

Migrate all tools to source `claude/tools/lib/_log-helper` instead of `tools/_log-helper`.

### 2. Update telemetry hook

`claude/hooks/tool-telemetry.sh` writes to `.claude/logs/telemetry.jsonl` with the new schema (adding `agency`, `principal`, `agent` fields). Replace current telemetry hook.

### 3. Noun-verb naming

Rename tools:
- `commit` → `git-safe-commit`
- `tag` → `git-tag`
- `sync` → `git-sync`
- `whoami` + `agentname` → `agency-whoami`
- `tool-new` → `tool-create`
- `now` → keep

Update `settings.json` permissions.

### 4. Move to `claude/tools/`

Framework tools that ship via `agency-init` move from `tools/` to `claude/tools/`:
- Copy tool to `claude/tools/{new-name}`
- Update source path for `_log-helper`
- Update `settings.json` permissions
- Keep old name as forwarding stub until all references updated
- Delete stub once clean

### 5. Add `git-fetch` tool

New tool: `git-fetch` — wraps `git fetch origin` with token-conserving output. Returns branch status (ahead/behind/diverged) in 3 lines.

### 6. Cross-platform

All tools must work on macOS and Linux. Use fallback chains for OS-specific commands. No `sed -i` — use temp file + mv pattern.

## Part 3: Reader Tools

### `tool-log` (already built)
Reads `tool-runs.jsonl`:
- `tool-log <run-id>` — show all entries for a run
- `tool-log --tool <name>` — recent runs for a tool
- `tool-log --recent [N]` — last N runs
- `tool-log --tail` — follow the log

### `telemetry` (to build)
Reads `telemetry.jsonl`:
- `telemetry --summary` — usage breakdown by tool, agent, time window
- `telemetry --agent <name>` — usage for a specific agent
- `telemetry --cost` — token/cost analysis (if we capture cost data)

## Order of Operations

1. Update `_log-helper` with `agency`/`principal`/`agent` fields
2. Update telemetry hook with new schema
3. Build `git-fetch` (new, no migration needed)
4. Migrate `_log-helper` sourcing in existing tools
5. Rename tools to noun-verb convention
6. Move to `claude/tools/`
7. Update `settings.json` permissions
8. Clean up forwarding stubs
9. Build `telemetry` reader tool

## Acceptance Criteria

- All tools source `claude/tools/lib/_log-helper`
- All tools produce 3-line token-conserving output
- Every log entry includes `agency`, `principal`, `agent` fields
- `settings.json` permissions match new tool names/paths
- No agency-service dependency for logging or telemetry
- `tool-log --recent` shows entries from all migrated tools
- Telemetry hook writes to `.claude/logs/telemetry.jsonl`
- Cross-platform: macOS + Linux
