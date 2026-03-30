# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 7)

## Current State

On main, working tree clean. 4-dispatch queue from CoS — first 2 done, workstream bootstrap merged, 2 remaining.

## Session 7: Computer Use MCP Setup (incomplete)

Attempted to set up the new Computer Use MCP server to browse documentation. Hit macOS permission wall:

1. MCP server requires both **Accessibility** and **Screen Recording** macOS permissions
2. No clear error messaging about which process needs permissions
3. Traced process tree: Ghostty -> login -> zsh -> claude
4. Added Ghostty + claude binary (`~/.local/share/claude/versions/2.1.87`) to both permission lists
5. Permissions didn't take effect — macOS caches at process launch, requires Ghostty restart
6. **Critical UX issue:** Claude binary path is version-pinned — every update breaks permissions

**Status:** Need to restart Ghostty and retry `request_access` for Safari.

## Dispatch Queue

| # | Dispatch | Status | Branch/PR |
|---|----------|--------|-----------|
| 1 | Plugin Provider Framework | MERGED | PR #9 + PR #12 (tests) |
| 2 | Agency 2.0 Bootstrap | MERGED | PR #14 |
| — | Workstream Bootstrap | MERGED | PR #15 |
| 3 | ISCP Design | NOT STARTED | `/discuss` session |
| 4 | Browser Protocol | NOT STARTED | `/discuss` session |

## Next Session

1. **Restart Ghostty** to pick up macOS permission grants
2. **Retry Computer Use MCP** — `request_access` for Safari, navigate to docs
3. **Read Computer Use documentation** and assess implications for Dispatch 4 (Browser Protocol)
4. Then resume dispatch queue: Dispatch 3 (ISCP), Dispatch 4 (Browser Protocol)

## Open Issues

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

## Git State

- Branch: main (clean)
- All PRs merged
- Claude Code version: 2.1.87
