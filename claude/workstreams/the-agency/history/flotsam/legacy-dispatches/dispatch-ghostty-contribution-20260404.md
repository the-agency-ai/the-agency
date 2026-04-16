# Dispatch: Ghostty Contribution — Writable tab.name via AppleScript

**Date:** 2026-04-04
**From:** Captain (monofolk)
**To:** Captain (the-agency)
**Priority:** High — vouched, fork ready, implementation planned. Need to build and test today.

---

## Context

We need programmatic tab titles in Ghostty for multi-session fleet management. OSC 2 writes get clobbered by Claude Code's rendering loop. We've exhausted all workarounds (OSC 2, OSC 11, polling watchdog, delayed writes). The AppleScript layer is the only path that persists.

## What Happened

1. Built a ghostty-claude-hook with full state model (Working/Available/Needs Attention/No Session)
2. Confirmed via debug logging: hook writes succeed (rc=0, /dev/tty writable) but Claude Code clobbers OSC 2 immediately
3. Built a polling watchdog — wins on OSC 11 (background color) but still loses on OSC 2 (title)
4. Explored Ghostty codebase — found the fix is ~20 lines across 3 files
5. Filed vouch request: https://github.com/ghostty-org/ghostty/discussions/12093
6. **Vouched by jcollie (collaborator)** — approved to submit PRs
7. Forked to https://github.com/the-agency-ai/ghostty

## The Change

The `set_tab_title` keybinding action already writes to `controller.titleOverride` which takes priority over OSC 2 in Ghostty's title computation. We're just exposing that same path through AppleScript.

| File | Change |
|------|--------|
| `macos/Ghostty.sdef:67` | `access="r"` → `access="rw"` on tab `name` property |
| `macos/Sources/Features/AppleScript/ScriptTab.swift:41-48` | Add setter → `controller.titleOverride` |
| `macos/Sources/Features/AppleScript/AppDelegate+AppleScript.swift` | Add write handler if needed |

## Codebase Architecture (from exploration)

- **Title priority** (gtk/class/tab.zig:503-507): tab_override > surface_override > terminal > config > default
- **AppleScript dictionary**: `macos/Ghostty.sdef` — tab class at lines 64-84
- **ScriptTab wrapper**: `ScriptTab.swift:41-48` — read-only `title` getter, maps to `controller?.window?.title`
- **titleOverride storage**: `BaseTerminalController.swift:92-96` — property observer triggers `applyTitleToWindow()`
- **set_tab_title action**: `Ghostty.App.swift:1608-1633` — existing reference implementation for the write path
- **OSC 2 handler**: `osc/parsers/change_window_title.zig:6-20` — sets terminal title, NOT tab override

## Execution Plan

1. **Setup** — agency-init on `~/code/ghostty` fork, create `CLAUDE-GHOSTTYCONTRIBUTION.md` with AI Policy + Contributing rules
2. **Understand** — trace full title flow end-to-end, read all 3 target files completely
3. **Implement** — 3 files, ~20 lines
4. **Test locally** — build Ghostty from source, validate `osascript` can set tab names, verify persistence over OSC 2, test across 5-tab fleet
5. **QG + MAR** — full review squad, Ghostty's own test suite, edge cases
6. **Production use** — run locally for at least a week
7. **PR** — with full AI disclosure per Ghostty's policy

## Ghostty Contribution Rules (must follow)

- **AI disclosure required** in all contributions
- **Human must fully understand all code** — can explain without AI
- **Vouch system** — done, vouched by jcollie
- **PRs implement issues** — #12048 exists, tagged contributor friendly
- **No AI slop** — denouncement list for bad AI drivers

## Action Items for the-agency

1. Run agency-init on `~/code/ghostty` fork
2. Create `CLAUDE-GHOSTTYCONTRIBUTION.md` documenting Ghostty's AI Policy and Contributing rules
3. Spin up a worktree agent to implement, test, QG
4. Once validated, update monofolk's ghostty-claude-hook to use AppleScript instead of OSC 2
5. Update the-agency's hook to match

## Related

- Ghostty issue #12048 (contributor friendly): writable tab.name via AppleScript/JXA
- Ghostty vouch: https://github.com/ghostty-org/ghostty/discussions/12093
- Fork: https://github.com/the-agency-ai/ghostty
- Monofolk ghostty-claude-hook: `claude/tools/ghostty-claude-hook`
- Monofolk ghostty-state-watchdog: `claude/tools/ghostty-state-watchdog`
- 3 Claude Code feedback drafts at `claude/usr/jordan/captain/feedback-drafts/`
