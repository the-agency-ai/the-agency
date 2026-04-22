# Claude Code Advanced Features

**Back to:** [INDEX.md](INDEX.md)

---

## Checkpoints

Claude Code automatically saves your code state before each change.

### Accessing Checkpoints

- Press `Esc + Esc` to open rewind menu
- Use `/rewind` command
- Select what to restore: code, conversation, or both

### Limitations

- Tracks Claude's edits only
- Does NOT track: user edits, bash command side effects

---

## Subagents

Subagents handle specialized tasks while the main agent coordinates.

### Locations

| Location | Scope |
|----------|-------|
| `.claude/agents/` | Project-specific |
| `~/.claude/agents/` | Personal |

### Creating a Subagent

Create `.claude/agents/backend-api.yaml`:

```yaml
name: backend-api
description: Handles backend API development
model: claude-sonnet-4-5-20251101
tools:
  - Read
  - Write
  - Bash(npm:*)
  - Bash(node:*)
```

### Usage

Subagents can be:
- Explicitly invoked via `/agents`
- Automatically delegated based on task type

---

## Hooks

Hooks automatically trigger actions at specific points.

### Available Events

| Event | When |
|-------|------|
| `PreToolUse` | Before a tool runs |
| `PostToolUse` | After a tool runs |
| `UserPromptSubmit` | When user submits prompt |
| `Notification` | On notifications |
| `Stop` | When session stops |
| `SubagentStop` | When subagent completes |
| `PreCompact` | Before compacting context |
| `SessionStart` | When session begins |
| `SessionEnd` | When session ends |

### Configuration

In `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": {
      "match": "Write",
      "command": "npm run lint --fix"
    }
  }
}
```

---

## MCP (Model Context Protocol)

Connect Claude to external tools and data sources.

### Adding MCP Servers

```bash
claude mcp add <name> <command> [args...]
claude mcp list
claude mcp remove <name>
```

### Configuration Files

- Project: `.mcp.json`
- Global: `~/.claude/mcp.json`

### Common Integrations

- GitHub
- Figma
- Linear
- Notion
- Stripe
- Vercel
- Jira
- Google Drive
- Slack

---

## Headless Mode

For CI, pre-commit hooks, and automation.

### Basic Usage

```bash
claude -p "query"                           # Print result
claude -p --output-format json "query"      # JSON output
claude -p --output-format stream-json "query"  # Streaming JSON
```

### Limiting Turns

```bash
claude --max-turns 3 -p "query"
```

### Piping

```bash
echo "query" | claude -p
cat app.log | claude -p "summarize errors"
claude -p "<prompt>" --json | jq '.result'
```

### Use Cases

- Issue triage automation
- Code review in CI
- Pre-commit validation
- Release note generation

---

## Safe YOLO Mode

Skip all permission prompts for unattended operation.

```bash
claude --dangerously-skip-permissions
```

**WARNING:** Only use in isolated environments:
- Docker containers
- VMs without network access
- Dev containers

Risk: data loss or exfiltration without safeguards.

---

## Background Tasks

Keep long-running processes active without blocking.

```bash
> start the dev server in background
> run the test suite continuously
```

---

## Plugins

### Installing Plugins

```bash
/plugin marketplace add <url>
/plugin install <name>@<marketplace>
/plugin enable <name>
/plugin disable <name>
/plugin uninstall <name>
```

---

## VS Code Extension

Native extension with:
- Dedicated sidebar panel
- Inline diffs for real-time visibility
- Plan review before execution

Download from VS Code Extension Marketplace.

---

## Claude Code on the Web

Browser-based execution on Anthropic infrastructure.

Features:
- Parallel tasks across repositories
- Automatic PR creation
- Sandboxed execution
- Real-time progress tracking

Available for Pro, Max, Team, and Enterprise users at claude.com/code.

---

## Related

- [Commands Reference](04-commands.md)
- [Configuration](05-configuration.md)
