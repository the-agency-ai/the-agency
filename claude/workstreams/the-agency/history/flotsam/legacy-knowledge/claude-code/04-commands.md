# Claude Code Commands Reference

**Back to:** [INDEX.md](INDEX.md)

---

## CLI Commands

### Basic Usage

```bash
claude                      # Start interactive mode
claude "task"               # Run one-time task
claude -p "query"           # One-off query, print result, exit
claude -c                   # Continue most recent conversation
claude -r                   # Resume a previous conversation
claude commit               # Create a Git commit
```

### Flags

| Flag | Description |
|------|-------------|
| `-p "query"` | Print mode (non-interactive) |
| `-c` | Continue most recent conversation |
| `-r` | Resume a previous conversation |
| `--output-format json` | JSON output with metadata |
| `--output-format stream-json` | Streaming JSON output |
| `--max-turns N` | Limit agentic turns |
| `--dangerously-skip-permissions` | Skip all permission prompts (use with caution) |
| `--allowedTools` | Session-specific tool access |
| `--mcp-debug` | Debug MCP configuration |
| `--verbose` | Verbose output for debugging |

---

## Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| `!` | Bash mode prefix |
| `@` | Mention files/folders |
| `#` | Add to CLAUDE.md |
| `?` | Show keyboard shortcuts |
| `Esc` | Interrupt Claude |
| `Esc + Esc` | Open rewind menu |
| `Ctrl+R` | Full output/context |
| `Ctrl+C` | Exit Claude Code |
| `Shift+Tab` | Auto-accept ("yolo mode") |
| `Shift+Tab+Tab` | Plan mode |
| `↑` | Command history |
| `Tab` | Command completion |

---

## Slash Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/clear` | Clear conversation history |
| `/compact [instructions]` | Summarize history |
| `/config` | View/modify settings |
| `/cost` | Token usage statistics |
| `/login` | Log in to account |
| `/logout` | Log out |
| `/model` | Change AI model |
| `/permissions` | Manage permissions |
| `/status` | Session status |

### Navigation

| Command | Description |
|---------|-------------|
| `/add-dir` | Add working directories |
| `/memory` | Edit CLAUDE.md files |
| `/resume` | Resume previous conversation |

### Features

| Command | Description |
|---------|-------------|
| `/agents` | Manage subagents |
| `/init` | Initialize project |
| `/install-github-app` | Install GitHub integration |
| `/mcp` | View MCP server status |
| `/rewind` | Undo changes (restore checkpoint) |
| `/sandbox` | Isolated bash environment |
| `/vim` | Enter vim mode |

---

## Configuration Commands

```bash
claude config list                 # View all settings
claude config get <key>            # Check specific setting
claude config set <key> <value>    # Change setting
claude config add <key> <value>    # Add to array setting
claude config remove <key> <value> # Remove from array
```

---

## MCP Commands

```bash
claude mcp add <name> <command> [args...]  # Add MCP server
claude mcp list                            # List servers
claude mcp remove <name>                   # Remove server
```

---

## Headless Mode (Automation)

```bash
# Non-interactive, print result
claude -p "query"

# JSON output with metadata
claude -p --output-format json "query"

# Streaming JSON
claude -p --output-format stream-json "query"

# Limit agentic turns
claude --max-turns 3 -p "query"

# Process piped input
echo "query" | claude -p

# Pipe to other commands
claude -p "<prompt>" --json | your_command
```

---

## Related

- [Configuration](05-configuration.md)
- [Advanced Features](07-advanced.md)
