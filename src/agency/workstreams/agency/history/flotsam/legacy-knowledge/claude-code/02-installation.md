# Claude Code Installation

**Back to:** [INDEX.md](INDEX.md)

---

## System Requirements

- macOS, Linux, or Windows
- Node.js 18+ (for npm install)
- Claude.ai account (recommended) or Claude Console account

---

## Installation Methods

### macOS / Linux / WSL (Recommended)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows PowerShell

```powershell
irm https://claude.ai/install.ps1 | iex
```

### Windows CMD

```batch
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

### Homebrew (macOS)

```bash
brew install --cask claude-code
```

### NPM (Node.js 18+)

```bash
npm install -g @anthropic-ai/claude-code
```

---

## First Run

```bash
cd your-project
claude
```

You'll be prompted to log in on first use.

### Login Options

```bash
claude           # Interactive login prompt
/login           # Explicit login command
```

### Account Types

| Type | Description |
|------|-------------|
| **Claude.ai** | Subscription plans (Pro, Max, Team) - recommended |
| **Claude Console** | API access with pre-paid credits |

---

## Updates

Claude Code auto-updates by default. See advanced setup for manual control.

---

## Verification

After installation:

```bash
claude --version    # Check version
claude --help       # Show help
claude              # Start interactive session
```

---

## Troubleshooting

### PATH Issues

If `claude` command not found after installation:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.claude/bin:$PATH"

# Then reload
source ~/.bashrc  # or ~/.zshrc
```

### Permission Denied

```bash
chmod +x ~/.claude/bin/claude
```

### Node Version

Ensure Node.js 18+:
```bash
node --version
```

---

## Related

- [Quickstart](03-quickstart.md)
- [Configuration](05-configuration.md)
