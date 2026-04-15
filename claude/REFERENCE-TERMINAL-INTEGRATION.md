# Terminal Integration

The Agency provides visual feedback through Ghostty tab titles and background color tints.

## Dynamic Tab Status

Tab status automatically updates based on agent state via the `ghostty-status.sh` Claude Code hook:

**States:**
- **○ Circle** — Available (ready for input, blue tint)
- **◑ Half-circle** — Working (processing, green tint)
- **⚠ Triangle** — Attention (needs user input, red tint)

**Automation:**
The status is updated automatically via Claude Code hooks configured in `.claude/settings.json`:
- `SessionStart` → Available (blue)
- `PreToolUse` → Working (green)
- `PostToolUse` → Working (green)
- `Notification` → Attention (red)
- `Stop` → Available (blue)
- `SessionEnd` → Reset to plain shell

## Terminal Compatibility

| Terminal    | Tab Title | Background Tint |
|-------------|-----------|-----------------|
| Ghostty     | ✓         | ✓               |
| Terminal.app | ✓        | -               |
| Kitty       | ✓         | -               |

Ghostty provides the full experience with tab title indicators and background color tints via OSC escape sequences.

## Setup

Terminal integration is pre-configured in `.claude/settings.json` and requires no additional setup. It activates automatically when Claude Code sessions are started.

## Troubleshooting

**Tab status not changing:**
- Verify you are running Ghostty (`TERM_PROGRAM=ghostty`)
- Check that `.claude/settings.json` has the `ghostty-status.sh` hook configured
- Verify the hook file exists at `.claude/hooks/ghostty-status.sh`

**Hooks not running:**
- Check `.claude/settings.json` syntax is valid JSON
- Verify hooks reference the correct paths with `$CLAUDE_PROJECT_DIR`
