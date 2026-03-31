# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 9)

## Current State

On `main` branch. Tool refactor PR #18 merged. Two post-merge fixes committed. Clean working tree.

## Immediate Priority: Fix Browser Access

**Bug report:** `claude/workstreams/agency/seeds/browser-access-bug-20260331.md`

Browser MCP (`npx @browsermcp/mcp`) is non-functional:
- Server starts, `/mcp` shows "✓ connected"
- On first tool use (or when Chrome opens a new tab): server crashes
- `claude mcp list` reports stale "Connected" status after crash
- All `mcp__browser-mcp__*` tools permanently deregistered from session — no recovery without restart
- Computer Use MCP is read-only for browsers (hardcoded tier, not user-overridable)

**Next step:** Relaunch with `claude --debug` to capture browser-mcp crash logs. Test immediately in fresh session before server crashes.

**Blocked:** Two X/Twitter posts to capture into knowledge base:
- `https://x.com/trq212/status/2033949937936085378`
- `https://x.com/bcherny/status/2038454336355999749`

## Session 9 Work (this session)

- Updated handoff, archived session 8
- Browser-mcp tools are deregistered from current session (server crashed earlier)
- Need session restart to pick up tools again

## Dispatch Queue

| # | Dispatch | Status |
|---|----------|--------|
| 1 | Plugin Provider Framework | MERGED |
| 2 | Agency 2.0 Bootstrap | MERGED |
| — | Workstream Bootstrap | MERGED |
| 3 | ISCP Design | NOT STARTED |
| 4 | Browser Protocol | NOT STARTED (bug blocks this) |
| 5 | Tool Refactor | DONE (PR #18 merged) |
| 6 | QG Hardening | DONE |
| 7 | Code Survey / Incremental Capture | READ (needs /discuss) |
| 8 | Token Economics Tools | PARTIAL (needs /discuss) |

## Open Issues

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

## Parked Topics

- **Status line for agent activity** — needs `/discuss` with principal
- **Token Economics** — compound bash rule done, 4 items remain

## Git State

- Branch: `main`
- HEAD: 9632a86
- Working tree: clean (except handoff + history)
