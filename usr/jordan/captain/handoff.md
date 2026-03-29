# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-29 (session 3)

## This Session Summary

Short continuation session. Fixed Ghostty tab status — replaced iTerm-focused `tab-status` with Ghostty-native `ghostty-status.sh` in all Claude Code hooks.

### What Was Done

1. **Removed all `tab-status` calls from `.claude/settings.json`** — 4 calls removed (PreToolUse, PostToolUse, PermissionRequest, Stop). These were iTerm-focused and overwrote Ghostty's correct output.
2. **Registered `ghostty-status.sh` in settings.json** — added to SessionStart, SessionEnd, PostToolUse (`*`), Stop, and new Notification hook section.
3. **Cleaned up `ghostty-status.sh`** — removed unused `TAB_STATUS` variable and all `tab-status` delegation calls from event handlers. Now purely Ghostty-only.
4. **Committed:** `7cffc9a`

### What This Fixes

- **ISS-010:** Agent name not appearing in terminal tabs — `ghostty-status.sh` resolves name from `$CLAUDE_SESSION_NAME` → `$AGENTNAME` → cache → git branch
- **ISS-011:** Wrong indicators — `tab-status` used `●` (filled) and `▲`; `ghostty-status.sh` uses correct `○` (available), `◑` (working), `⚠` (attention)
- **Slowness** — no more double-setting (both `ghostty-status.sh` and `tab-status` were firing on every event)

### Not Yet Tested

The fix needs a session restart to take effect. User was about to exit and resume to test.

### Open Issues (from issues-agency2-setup-20260329.md)

| Issue | Severity | Status |
|-------|----------|--------|
| ISS-007 | Medium | Open — agent-create must register in .claude/settings.json |
| ISS-008 | High | PR #7 merged — Dependabot alerts may still need triage |
| ISS-009 | Low | Open — status line redundant worktree naming |
| ISS-010 | Medium | Fix committed (7cffc9a) — needs testing |

### Agents Previously Launched

- **markdown-pal** — in worktree, PVR/A&D discussion
- **mock-and-mark** — in worktree, PVR/A&D discussion

Launch commands:
```bash
claude --agent markdown-pal --name markdown-pal
claude --agent mock-and-mark --name mock-and-mark
```

### Git State

- Branch: `main`
- Working tree: clean
- Last commit: `7cffc9a` (ghostty tab status fix)
- Needs push to origin

## Pending / Next Steps

1. **Test ghostty tab status** — resume session, verify `○`/`◑`/`⚠` indicators and agent name in tabs
2. **Push to origin** — `7cffc9a` and any prior unpushed commits
3. **ISS-009** — status line redundant worktree naming (low priority)
4. **ISS-007** — agent-create should register in settings.json
5. **Dependabot triage** — check if PR #7 merge cleared alerts, address remaining
6. **Tools unification step 2** — extract + formalize the framework spec
7. **Migrate principals** — `claude/principals/jordan/` → `usr/jordan/`
8. **Agency init/update design** — 7 scenarios, needs 1B1 session
9. **GTM agent** — ready to launch when scope is defined

## Key Files

- `usr/jordan/captain/issues-agency2-setup-20260329.md` — all issues
- `claude/hooks/ghostty-status.sh` — Ghostty tab status hook (just fixed)
- `.claude/settings.json` — hook registrations (just updated)
- `tools/tab-status` — iTerm tool, no longer called from hooks (kept for potential future iTerm support)
