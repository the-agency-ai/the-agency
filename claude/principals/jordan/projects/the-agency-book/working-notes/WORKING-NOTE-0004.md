# THE-AGENCY-BOOK-WORKING-NOTE-0004

**Date:** 2026-01-03 16:09 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Terminal and Settings Setup - Claude Code Configuration

---

## Source

Material from official Claude Code documentation:

- https://code.claude.com/docs/en/terminal-config
- https://code.claude.com/docs/en/settings

---

## Terminal Configuration

### Themes and Appearance

- Claude Code cannot control your terminal's theme directly—that's handled by your terminal application
- Use `/config` command to match Claude Code's theme to your terminal
- Configure a custom status line for contextual information (model, working directory, git branch)

### Line Breaks / Newlines

**Quick Escape:** Type `\` followed by Enter

**Keyboard Shortcuts:**

- **Shift+Enter** (VS Code or iTerm2): Run `/terminal-setup` to auto-configure
- **Option+Enter**:
  - Mac Terminal.app: Settings → Profiles → Keyboard → "Use Option as Meta Key"
  - iTerm2/VS Code: Settings → Profiles → Keys → Set Left/Right Option to "Esc+"

### Notification Setup

**iTerm 2:**

1. Preferences → Profiles → Terminal
2. Enable "Silence bell" and Filter Alerts → "Send escape sequence-generated alerts"
3. Set notification delay

**Custom:** Create notification hooks for advanced handling

### Handling Large Inputs

- Avoid direct pasting of very long content
- Use file-based workflows (write to file, ask Claude to read)
- VS Code terminal is prone to truncating long pastes

### Vim Mode

Enable with `/vim` or `/config`. Supports:

- Mode switching: `Esc` (NORMAL), `i`/`I`/`a`/`A`/`o`/`O` (INSERT)
- Navigation: `h`/`j`/`k`/`l`, `w`/`e`/`b`, `0`/`$`/`^`, `gg`/`G`
- Editing: `x`, `dw`/`de`/`db`/`dd`/`D`, `cw`/`ce`/`cb`/`cc`/`C`, `.` (repeat)

---

## Settings Configuration

### File Locations (precedence high→low)

1. **Enterprise managed** - Centrally enforced
2. **Project** - `.claude/settings.json` (check into source control)
3. **Project local** - `.claude/settings.local.json` (gitignored, personal)
4. **User** - `~/.claude.json` (global defaults)

### Permission Types

- **Bash Commands** - Exact or wildcard: `npm run test:*`, `git:*`
- **Read/Edit** - File access patterns: `Read(/path/**)`
- **WebFetch** - Domain access: `WebFetch(domain:example.com)`

### Hooks Events

- **SessionStart** - When Claude starts
- **SessionEnd** - When Claude ends
- **PreToolUse** - Before tool execution
- **PostToolUse** - After tool completion
- **Notification** - When Claude sends notifications
- **Stop** - When Claude finishes responding

### Hook Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./tools/pre-commit-check"
          }
        ]
      }
    ]
  }
}
```

### Enterprise Controls

- `allowManagedHooksOnly` - Restrict to managed hooks only

---

## For The Agency Book

### Recommended Setup Chapter Content

1. Terminal app choice (iTerm2 recommended for notifications)
2. `/terminal-setup` for Shift+Enter
3. Settings file structure explanation
4. Pre-approved permissions patterns
5. Hook examples (session start, pre-commit, formatting)

### The Agency-Specific Configuration

We use extensive hooks and permissions in `.claude/settings.local.json`:

- SessionStart: Load env, restore context, show instructions
- PreToolUse: Pre-commit checks on git commit
- PostToolUse: Log tool results, auto-format with prettier
- Friction logging for blocked permissions

---

## Decisions Made

- Terminal configuration material goes in the Setup chapter
- Settings configuration material also goes in Setup chapter
- Agency-specific examples should be included as reference implementation

## Action Items

- Include terminal setup instructions in Setup chapter
- Include settings configuration in Setup chapter
- Cross-reference with Agency-specific examples

## Next Steps

- Gather more material from docs as Claude Code evolves
- Consider splitting into separate chapters if content grows

_Working note for project: the-agency-book_
