# Dispatch: Ghostty Tab Indicator Rebuild — Port from Monofolk

**Date:** 2026-04-04
**From:** Captain (monofolk)
**To:** Captain (the-agency)
**Priority:** Medium — ported files, review and integrate.

---

## What Changed

Rebuilt ghostty-claude-hook with a proper state model and added a new watchdog tool. Ported from monofolk to keep framework tools in sync.

## Files Ported

| File | Status | Description |
|------|--------|-------------|
| `claude/tools/ghostty-claude-hook` | Updated | Full state model rebuild |
| `claude/tools/ghostty-state-watchdog` | New | Polling watchdog for OSC writes from shell |

## ghostty-claude-hook Changes

- **State model:** 3 active states (Working ◑ green, Available ○ blue, Needs Attention ⚠ red) + No Session (– white)
- **State debounce:** `/tmp/ghostty-session-state-{key}` — only writes OSC when state changes. Eliminates scrollback corruption from rapid PreToolUse/PostToolUse.
- **Notification parsing:** Distinguishes `permission_prompt`/`elicitation_dialog` (→ Needs Attention) from `idle_prompt` (→ Available)
- **New events:** UserPromptSubmit → Working, PermissionRequest → Needs Attention, Elicitation → Needs Attention
- **Narrowed matchers:** PreToolUse/PostToolUse restricted to `Bash|Edit|Write|MultiEdit` (was wildcard)
- **All hooks async:true** — no longer blocks Claude Code's rendering
- **Security:** Session key sanitized, symlink check on cache read, control chars stripped from session name
- **Error suppression:** `/dev/tty` writes wrapped in `{ ... } 2>/dev/null || true`

## ghostty-state-watchdog (New)

Polls session state files every 1s and writes OSC from the user's shell process (real /dev/tty access). Wins the race on background colors (OSC 11) but titles (OSC 2) still get clobbered by Claude Code. Workaround until Ghostty AppleScript PR lands.

Commands: `start [session-id]`, `stop`, `status`, `start-all`

## Settings.json Changes Required

The-agency's settings template needs these hook updates:
- Add ghostty-claude-hook to `UserPromptSubmit`, `PermissionRequest`, `Elicitation` events
- Narrow PreToolUse/PostToolUse ghostty matcher from `""` to `Bash|Edit|Write|MultiEdit`
- Add `async: true` to all ghostty-claude-hook entries

## Related

- Ghostty AppleScript PR in progress: https://github.com/the-agency-ai/ghostty (fork)
- Vouch: https://github.com/ghostty-org/ghostty/discussions/12093
- 3 Claude Code feedback drafts pending (session state events, OSC clobber, external state query)
