# Claude Code Configuration

**Back to:** [INDEX.md](INDEX.md)

---

## Configuration Priority

Settings are applied in this order (highest priority first):

1. **Enterprise:** `/etc/claude-code/managed-settings.json`
2. **Project Local:** `.claude/settings.local.json`
3. **Project Shared:** `.claude/settings.json`
4. **User Global:** `~/.claude/settings.json`

---

## CLAUDE.md Files

CLAUDE.md is a special file Claude automatically incorporates into conversations.

### Locations

| Location | Scope |
|----------|-------|
| `./CLAUDE.md` | Project root (most common) |
| `./.claude/CLAUDE.md` | Project hidden |
| `~/.claude/CLAUDE.md` | Global (all projects) |

### What to Include

- Bash commands and their purposes
- Core utility functions and files
- Code style guidelines and patterns
- Testing instructions and workflows
- Repository conventions (branching, merging)
- Developer environment requirements
- Project-specific quirks or warnings

### Pro Tips

- Treat like frequently-used prompts - iterate on effectiveness
- Use `#` keyboard shortcut to have Claude suggest additions
- Add emphasis keywords like "IMPORTANT" or "YOU MUST" for adherence

---

## Permissions

Claude requests permission before system-modifying actions.

### Managing Permissions

```bash
/permissions                    # Interactive management
```

Or edit `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(npm run *)", "Bash(git status)", "Bash(git diff)"],
    "ask": ["Bash(git push:*)", "Bash(npm install *)"],
    "deny": ["Read(./.env*)", "Bash(rm -rf:*)", "Bash(curl:*)"]
  }
}
```

### Permission Levels

| Level | Behavior |
|-------|----------|
| `allow` | Execute without asking |
| `ask` | Prompt for permission each time |
| `deny` | Never allow |

### CLI Override

```bash
claude --allowedTools "Read,Write,Bash(npm:*)"
```

---

## Custom Slash Commands

Store prompt templates that become available via `/` menu.

### Locations

| Location | Scope |
|----------|-------|
| `.claude/commands/` | Project-specific |
| `~/.claude/commands/` | Personal (all projects) |

### Creating a Command

Create `.claude/commands/my-command.md`:

```markdown
---
argument-hint: <issue-number>
description: Fix a GitHub issue
allowed-tools: Read, Write, Bash
---

Fix GitHub issue $ARGUMENTS.

1. Read the issue details
2. Understand the problem
3. Implement the fix
4. Create a commit
```

### Using Arguments

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments as string |
| `$1`, `$2`, etc. | Positional arguments |

### Usage

```bash
/my-command 1234
/project:fix-github-issue 1234
```

---

## Skills

Skills are model-invoked based on context (unlike slash commands which are user-invoked).

### Locations

| Location | Scope |
|----------|-------|
| `.claude/skills/` | Project-specific |
| `~/.claude/skills/` | Personal |

### Creating a Skill

Create `.claude/skills/SKILL.md`:

```markdown
---
name: deployment-checker
description: Check deployment status and health
allowed-tools: Bash, WebFetch
---

When asked about deployment status, check...
```

---

## Environment Variables

Set in your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
export ANTHROPIC_API_KEY="sk-..."
export CLAUDE_MODEL="claude-sonnet-4-5-20251101"
```

---

## Related

- [Commands Reference](04-commands.md)
- [Advanced Features](07-advanced.md)
