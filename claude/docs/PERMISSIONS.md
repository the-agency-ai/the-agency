# Permissions

The Agency uses a layered permissions model for Claude Code that separates framework defaults from user customizations.

## Settings Files

### `.claude/settings.json` - Framework Defaults

**Purpose:** Versioned with The Agency, contains framework-level permissions and hooks.

**Contains:**
- Agency tool permissions (`Bash(./tools/*)`)
- Framework hooks (tab-status, session-backup, check-messages)
- Standard terminal operations

**DO NOT EDIT DIRECTLY:** This file is synced from the-agency to the-agency-starter and will be overwritten when you update The Agency.

### `.claude/settings.local.json` - User Overrides

**Purpose:** Your project-specific permissions (gitignored, never versioned).

**Contains:**
- Git operations you use
- Package manager commands (npm, pnpm, yarn)
- WebFetch domains for your project
- Build/test commands
- Custom hooks for your workflow

**EDIT FREELY:** This file is gitignored and survives Agency framework updates.

### `.claude/settings.local.json.example` - Template

A starter template showing common permission patterns. Copy this to get started:

```bash
cp .claude/settings.local.json.example .claude/settings.local.json
```

## Settings Precedence

Claude Code merges settings in this order (highest priority first):

1. **Enterprise managed:** `/etc/claude-code/managed-settings.json` (if configured)
2. **Project Local:** `.claude/settings.local.json` ← **Your overrides**
3. **Project Shared:** `.claude/settings.json` ← **Framework defaults**
4. **User Global:** `~/.claude/settings.json`

Your local settings override framework defaults, allowing you to customize without conflicts.

## Permission Types

### Bash Commands

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",      // Exact match with wildcard
      "Bash(npm run:*)",          // Package manager commands
      "Bash(./tools/*)"           // All Agency tools
    ],
    "deny": [
      "Bash(rm -rf:*)",           // Dangerous operations
      "Bash(git push --force:*)"
    ]
  }
}
```

### WebFetch Domains

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:localhost)",
      "WebFetch(domain:127.0.0.1)",
      "WebFetch(domain:api.example.com)",
      "WebSearch"
    ]
  }
}
```

### File Operations

```json
{
  "permissions": {
    "allow": [
      "Read(/path/to/files/**)",
      "Edit(/path/to/files/**)"
    ],
    "deny": [
      "Read(./.env*)",            // Protect secrets
      "Edit(./.env*)"
    ]
  }
}
```

## Common Patterns

### Git Operations

```json
"allow": [
  "Bash(git status:*)",
  "Bash(git log:*)",
  "Bash(git diff:*)",
  "Bash(git branch:*)",
  "Bash(git add:*)",
  "Bash(git commit:*)",
  "Bash(git pull:*)",
  "Bash(git fetch:*)",
  "Bash(git checkout:*)",
  "Bash(git stash:*)",
  "Bash(git show:*)"
]
```

### Package Management

```json
"allow": [
  "Bash(npm install:*)",
  "Bash(npm run:*)",
  "Bash(pnpm install:*)",
  "Bash(pnpm run:*)",
  "Bash(yarn install:*)",
  "Bash(yarn run:*)",
  "Bash(npx:*)"
]
```

### Build/Dev/Test

```json
"allow": [
  "Bash(node:*)",
  "Bash(python3:*)",
  "Bash(pytest:*)",
  "Bash(bun:*)",
  "Bash(tsx:*)"
]
```

### File Operations

```json
"allow": [
  "Bash(ls:*)",
  "Bash(cat:*)",
  "Bash(mkdir:*)",
  "Bash(find:*)",
  "Bash(grep:*)",
  "Bash(head:*)",
  "Bash(tail:*)",
  "Bash(wc:*)",
  "Bash(echo:*)"
]
```

## Hooks

Both settings files can define hooks. Framework hooks are in `.claude/settings.json`, and you can add project-specific hooks in `.claude/settings.local.json`.

Example custom hook:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$FILE_PATH\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

## Updating The Agency

When you update The Agency framework:

1. `.claude/settings.json` receives updated framework permissions and hooks
2. Your `.claude/settings.local.json` is preserved (gitignored)
3. No conflicts, no overwrites
4. Review `.claude/settings.local.json.example` for new patterns

## Best Practices

### Do:
- ✓ Put project-specific permissions in `.claude/settings.local.json`
- ✓ Use wildcard patterns for flexibility (`npm run:*`)
- ✓ Add comments to explain unusual permissions
- ✓ Copy `.claude/settings.local.json.example` as a starting point

### Don't:
- ✗ Edit `.claude/settings.json` directly (will be overwritten on updates)
- ✗ Commit `.claude/settings.local.json` to git (it's gitignored)
- ✗ Grant overly broad permissions (`Bash(*:*)` is dangerous)
- ✗ Allow destructive operations without careful consideration

## Troubleshooting

**Permission prompts for Agency tools:**
- Verify `Bash(./tools/*)` is in `.claude/settings.json`
- Check that the settings file is valid JSON

**Custom permissions not working:**
- Verify `.claude/settings.local.json` exists and is valid JSON
- Check precedence order - local overrides shared

**Hooks not running:**
- Verify hook syntax in your settings file
- Check that commands reference correct paths
- Use `2>/dev/null || true` to prevent hook failures from blocking

## Reference

- Claude Code Docs: `claude/knowledge/claude-code/05-configuration.md`
- Hook Events: `claude/knowledge/claude-code/07-advanced.md`
- Settings Priority: https://code.claude.com/docs/en/settings
