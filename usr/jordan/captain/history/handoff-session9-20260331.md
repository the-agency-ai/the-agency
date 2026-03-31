# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 9, post-filing)

## Current State

On `main` branch. Clean working tree. Tool refactor PR #18 merged.

## Session 9 Work

### Browser Access Investigation (COMPLETE — bugs filed, not fixed)

Relaunched with `--debug`. Findings:

1. **Browser MCP (`@browsermcp/mcp`)** — third-party package, needs its own Chrome extension which is NOT installed. The "Claude (MCP)" tab is served by the npm server, not a Chrome extension. User rightfully won't install untrusted third-party extensions.
2. **Claude in Chrome (v1.0.49)** — Anthropic's extension, but has CSP errors blocking its own inline scripts. Non-functional. Does NOT expose `mcp__Claude_in_Chrome__*` tools to Claude Code.
3. **Computer Use MCP** — tier guidance references `mcp__Claude_in_Chrome__*` tools that don't exist.
4. **`/feedback` command** — fails with HTTP 413 (payload too large). Bundles entire conversation context. Misleading "try again" UX — retry appears to succeed but silently drops.
5. **`claude mcp list`** — reports stale "Connected" after server crash.
6. **browser-mcp crashed again** during this session (tools deregistered mid-conversation).

### GitHub Issues Filed (7 total)

| Issue | Title |
|-------|-------|
| anthropics/claude-code#41363 | `/feedback` fails with HTTP 413 — oversized context, silent drop |
| anthropics/claude-code#41367 | `claude mcp list` stale "Connected" after server crash |
| anthropics/claude-code#41370 | Computer Use tier references nonexistent `mcp__Claude_in_Chrome__*` tools |
| anthropics/claude-code#41371 | Claude in Chrome CSP errors block inline scripts |
| anthropics/claude-code#41099 | `request_access` lacks binary path and actionable guidance |
| anthropics/claude-code#41101 | Permissions reset on every CLI update (version-pinned binary) |
| anthropics/claude-code#41104 | No Safari browser automation support |

All cross-referenced. Thread: **zero working paths to autonomous browser interaction from CLI**.

## Blocked Items

**Two X/Twitter posts** — blocked on browser access (no working path):
- `https://x.com/trq212/status/2033949937936085378`
- `https://x.com/bcherny/status/2038454336355999749`
- Workaround: principal pastes content manually

## Dispatch Queue

| # | Dispatch | Status |
|---|----------|--------|
| 1 | Plugin Provider Framework | MERGED |
| 2 | Agency 2.0 Bootstrap | MERGED |
| — | Workstream Bootstrap | MERGED |
| 3 | ISCP Design | NOT STARTED |
| 4 | Browser Protocol | BLOCKED (bugs filed, no working browser path) |
| 5 | Tool Refactor | DONE (PR #18 merged) |
| 6 | QG Hardening | DONE |
| 7 | Code Survey / Incremental Capture | READ (needs /discuss) |
| 8 | Token Economics Tools | PARTIAL (needs /discuss) |

## Open Issues (Internal)

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

## Parked Topics

- **Status line for agent activity** — needs `/discuss` with principal
- **Token Economics** — compound bash rule done, 4 items remain
- **Weekly/Session limit discrepancies** — Team vs Personal Max20, mentioned in #41363, needs separate investigation

## Git State

- Branch: `main`
- HEAD: d12025f
- Working tree: clean (except handoff)
