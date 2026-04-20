# Investigation: iTerm Tab Title Shapes

**Bug:** HOUSEKEEPING-00007
**Related:** REQUEST-jordan-0048 (iTerm Tab Status + Permissions)
**Status:** Parked - needs investigation

## Problem

Tab status shapes (●, ◐, ▲) should display in the iTerm tab title alongside the agent name (e.g., "● captain"), but something is overriding our escape sequences.

**Expected:** Tab shows "● captain" with shape indicator
**Actual:** Tab shows "captain" only (no shape)

## What Works

1. **Tab background color** - Changes correctly (blue/green/red) via iTerm proprietary escape sequences
2. **Badge overlay** - Shows shape in terminal WINDOW content area (not tab bar)
3. **User variables** - Being set correctly (`agentTitle`, `agentIndicator`, `agentName`)

## What We Tried

### 1. OSC Escape Sequences
```bash
# In tools/tab-status
printf '\033]0;%s\007' "$TITLE" > /dev/tty  # OSC 0 - icon name + window title
printf '\033]1;%s\007' "$TITLE" > /dev/tty  # OSC 1 - icon name (tab)
printf '\033]2;%s\007' "$TITLE" > /dev/tty  # OSC 2 - window title
```
**Result:** Something overrides these for the tab title specifically.

### 2. iTerm User Variables
Set user variables via iTerm proprietary escape sequence:
```bash
TITLE_B64=$(echo -n "$TITLE" | base64)
printf '\033]1337;SetUserVar=%s=%s\007' "agentTitle" "$TITLE_B64" > /dev/tty
```
Then in iTerm Edit Session → Tab Title field: `\(user.agentTitle)`

**Result:** Displayed literal text "\(user.agentTitle)" instead of interpolating the variable.

### 3. Badge Feature
```bash
BADGE_B64=$(echo -n "$INDICATOR" | base64)
printf '\033]1337;SetBadgeFormat=%s\007' "$BADGE_B64" > /dev/tty
```
**Result:** Works, but badge appears as overlay in terminal window content area, not in the tab bar.

## iTerm Settings Checked

1. **Profiles → General → Title:** Set to "Shell" dropdown
2. **"Applications in terminal may change the title":** Checked (enabled)
3. **Edit Session → Tab Title:** Tried clearing and using variables

## Investigation Needed

1. **What's overriding the tab title?**
   - Claude Code itself?
   - Shell prompt (PROMPT_COMMAND, precmd)?
   - iTerm profile settings?

2. **Tab Name vs Tab Title vs Window Title**
   - iTerm may have separate concepts for these
   - The tooltip shows "Name: captain" - is this different from title?

3. **Escape sequence timing**
   - Is something setting title AFTER our hooks run?
   - Could add debug logging to track sequence

4. **iTerm2 documentation**
   - Research proprietary sequences for tab-specific title
   - Check if there's a "tab name" vs "window title" distinction

## Files Involved

- `tools/tab-status` - Sets colors, title, badge, user variables
- `.claude/settings.json` - Hooks that call tab-status
- `.claude/hooks/session-start.sh` - Calls tab-status on session start

## Workaround

Currently using tab COLORS (which work) for status indication. Shapes are visible in the badge overlay if looking at the terminal content.

## Notes

- The window title bar DOES show "● agent" sometimes, suggesting OSC sequences work for window but not tab
- This is a low-priority cosmetic issue - colors provide the primary status indication
- Shapes were intended for accessibility (colorblind users)
