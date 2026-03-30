# CoS Session Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-29 (session 4)

## Summary

Continued Ghostty tab status work from session 3. Fixed multi-session issues, documented new issues, and archived session transcripts.

## PR Contents (4 commits)

1. **Removed last `tab-status` call from Stop hook** in settings.json (session 3 edit had failed on JSON syntax)
2. **Registered `ghostty-status.sh`** in settings.json for SessionStart, SessionEnd, PostToolUse, Stop, Notification
3. **Session name bridge** — status line writes `session_name` to `/tmp/ghostty-agency-session-{session_id}` so hooks can read it (hook JSON doesn't include session_name)
4. **Per-session cache** — fixed global `/tmp/ghostty-session-name` file that caused all parallel sessions to show the same name
5. **Removed AppleScript `set_tab_title`** — it targeted "focused terminal of front window" causing cross-tab name pollution in multi-session setups
6. **Copied fixed hooks/settings to worktrees** — worktrees had old code with `tab-status` calls
7. **Recreated worktrees** — both markdown-pal and mock-and-mark worktrees were missing, recreated
8. **Documented ISS-011** (tab indicators, resolved) and **ISS-012** (dual worktree locations, open)
9. **Created dispatch** for captain to review/clean up ghostty integration
10. **Archived session transcripts** — 7 sessions zipped to `usr/jordan/session-transcripts.zip`

### Commits (this session)

- `bcc31b9` — fix session name in ghostty tab status
- `84c8f54` — update handoff for session 3
- `14a5613` — make ghostty session name per-session
- `280bed6` — add dispatch for ghostty cleanup review
- `d7d477a` — fix stale cache overriding session name
- `109a9e7` — remove AppleScript tab title (cross-tab pollution)
- `d27bc63` — add ISS-011, ISS-012 and update resolved status
- `8802335` — add session transcripts archive

### Known Limitation

OSC 2 tab titles may get overwritten by Claude Code's own title setting. Without the AppleScript (removed due to cross-tab pollution), the title relies on hook frequency to stay current. Works well during active use; may revert to Claude Code's default during idle.

### Open Issues (from issues-agency2-setup-20260329.md)

| Issue | Severity | Status |
|-------|----------|--------|
| ISS-007 | Medium | Open — agent-create must register in .claude/settings.json |
| ISS-008 | High | PR #7 merged — Dependabot alerts may still need triage |
| ISS-009 | Low | Open — status line redundant worktree naming |
| ISS-010 | Medium | Resolved |
| ISS-011 | Medium | Resolved |
| ISS-012 | Medium | Open — worktrees in two locations (.worktrees/ vs .claude/worktrees/) |

### Dispatches Pending

- `usr/jordan/captain/dispatch-ghostty-cleanup-20260329.md` — review ghostty integration, clean dead code, verify edge cases

### Worktrees

Both recreated and active:
- `.worktrees/markdown-pal/` (branch: `markdown-pal`, commit `6e7ca9c`)
- `.claude/worktrees/mock-and-mark/` (branch: `worktree-mock-and-mark`, commit `97666cf`)

Note: two different locations — see ISS-012.

### Git State

- Branch: `main`
- Working tree: clean
- All pushed to origin
- Last commit: `8802335`

## Pending / Next Steps

1. **ISS-012** — standardize worktree location
2. **ISS-007** — agent-create should register in settings.json
3. **ISS-009** — status line redundant worktree naming
4. **Dependabot triage** — address remaining alerts
5. **Tools unification step 2** — extract + formalize the framework spec
6. **Migrate principals** — `claude/principals/jordan/` → `usr/jordan/`
7. **Agency init/update design** — 7 scenarios, needs 1B1 session
8. **GTM agent** — ready to launch when scope is defined

## Key Files

- `usr/jordan/captain/issues-agency2-setup-20260329.md` — all issues (ISS-001 through ISS-012)
- `usr/jordan/captain/dispatch-ghostty-cleanup-20260329.md` — pending cleanup dispatch
- `usr/jordan/session-transcripts.zip` — all 7 session transcripts from today
- `claude/hooks/ghostty-status.sh` — Ghostty tab status hook
- `.claude/settings.json` — hook registrations
