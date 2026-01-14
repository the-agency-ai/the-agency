# Terminal Integration

The Agency provides visual feedback through iTerm tab colors and status indicators.

## Dynamic Tab Status

Tab status automatically updates based on agent state via Claude Code hooks:

**States:**
- **Blue ● Circle** - Available (ready for input)
- **Green ◐ Half-circle** - Working (processing)
- **Red ▲ Triangle** - Attention (needs user input)

**Automation:**
The status is updated automatically via Claude Code hooks configured in `.claude/settings.json`:
- `SessionStart` → Blue (available)
- `PreToolUse` → Green (working)
- `PostToolUse` → Green (working)
- `PermissionRequest` → Red (attention)
- `Stop` → Blue (available)
- `SessionEnd` → Runs backup

## Manual Control

For debugging or custom workflows:

```bash
./tools/tab-status available    # Set to ready state
./tools/tab-status working       # Set to working state
./tools/tab-status attention     # Set to needs-input state
./tools/tab-status clear         # Remove status indicator
```

## Accessibility

Status indicators use distinct **shapes** (not just colors) so colorblind users can distinguish states. Colors provide secondary visual cues through iTerm tab backgrounds:
- Blue: RGB(59, 130, 246)
- Green: RGB(34, 197, 94)
- Red: RGB(239, 68, 68)

## Terminal Compatibility

| Terminal | Tab Colors | Shapes | Badges |
|----------|-----------|---------|---------|
| iTerm2 | ✓ | ✓ | ✓ |
| Terminal.app | - | ✓ | - |
| Ghostty | - | ✓ | - |
| Kitty | - | ✓ | - |

iTerm2 provides the full experience with colored tab backgrounds and status badges. Other terminals show shape indicators in the tab title.

## Setup

The tab status feature is pre-configured in `.claude/settings.json` and requires no setup. It activates automatically when you launch a Claude Code session via `./tools/myclaude`.

## iTerm Profiles

To customize iTerm profiles for different agents:

```bash
./tools/iterm-setup principal-name
```

This creates dynamic profiles in iTerm with:
- Color-coded profiles for different agent types
- Proper working directory settings
- Badge displays for agent identification

Profiles are stored in `claude/principals/{principal}/config/iterm/` and symlinked to iTerm's DynamicProfiles directory.

## Troubleshooting

**Tab status not changing:**
- Verify you're using iTerm2 or a compatible terminal
- Check that `.claude/settings.json` has the hooks configured
- Run `./tools/tab-status available` manually to test

**Permission errors:**
- Verify `Bash(./tools/tab-status*)` is in `.claude/settings.json` permissions

**Hooks not running:**
- Check `.claude/settings.json` syntax is valid JSON
- Verify hooks reference the correct paths with `$CLAUDE_PROJECT_DIR`
