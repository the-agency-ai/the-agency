# Getting Started with The Agency

This guide covers setting up The Agency framework on top of Claude Code. By the end, you'll have a fully instrumented development environment with named terminal tabs, agent identity, state persistence, and team collaboration infrastructure.

---

## Prerequisites (What The Agency Cannot Do For You)

Before starting, you need these things that The Agency cannot provision:

### 1. Claude Code Subscription

| Requirement | Options |
|-------------|---------|
| **Account** | Claude.ai Pro ($17-20/mo), Max ($100-200/mo), or Team ($150/mo/person) |
| **API Access** | Or Claude Console with pre-paid credits |

### 2. System Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | macOS, Linux, or Windows (WSL recommended) |
| **Node.js** | Version 18+ |
| **Git** | For version control |
| **Shell** | bash or zsh |

### 3. Terminal Application

| Requirement | Recommendation |
|-------------|----------------|
| **macOS** | iTerm2 (for named tabs, notifications) |
| **Linux** | Any terminal with tab support |
| **Windows** | Windows Terminal |

### 4. GitHub Account

For repository hosting and collaboration.

---

## Step 1: Install Claude Code

### macOS / Linux

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://claude.ai/install.ps1 | iex
```

### Verify Installation

```bash
claude --version
```

### PATH Setup (if needed)

If `claude` command not found, add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/.claude/bin:$PATH"
```

Then reload:

```bash
source ~/.zshrc  # or ~/.bashrc
```

---

## Step 2: Clone The Agency Starter

```bash
cd ~/code  # or your preferred directory
git clone https://github.com/the-agency-ai/the-agency-starter.git my-project
cd my-project
```

---

## Step 3: Initialize Your Agency

```bash
./tools/init-agency
```

This will:
- Create your principal identity
- Set up the agent directory structure
- Initialize CLAUDE.md with project context
- Configure TheCaptain guidance system

---

## Step 4: Start Your First Agent

```bash
./tools/myclaude general housekeeping
```

This launches Claude with:
- **Workstream:** `general` (where work belongs)
- **Agent Name:** `housekeeping` (your identity)

Your terminal tab will be renamed to show the agent context.

---

## Tools You Should Know

Claude Code gives you direct terminal access. The Agency provides a suite of tools you'll use constantly.

### The `!` Shortcut

In Claude Code, prefix any command with `!` to run it in bash mode:

```
> !git status
> !./tools/now
> !ls -la
```

Or just type commands directly - Claude understands bash.

### Essential Agency Tools

| Tool | What It Does | Example |
|------|--------------|---------|
| `./tools/now` | Current timestamp (SGT) | `!./tools/now` |
| `./tools/whoami` | Your principal identity | `!./tools/whoami` |
| `./tools/agentname` | Current agent name | `!./tools/agentname` |
| `./tools/workstream` | Current workstream | `!./tools/workstream` |

### Session Management

| Tool | What It Does |
|------|--------------|
| `./tools/hello` | Start session, get context |
| `./tools/welcomeback` | Resume after break |
| `./tools/backup-session` | Save session state |
| `./tools/restore` | Restore agent context |

### Quality & Deployment

| Tool | What It Does |
|------|--------------|
| `./tools/pre-commit-check` | Run all quality checks |
| `./tools/run-unit-tests` | Run test suite |
| `./tools/code-review` | AI code review |
| `./tools/ship` | Full Green-Red deployment |
| `./tools/sync` | Push to remote |

### Collaboration

| Tool | What It Does |
|------|--------------|
| `./tools/collaborate` | Request help from another agent |
| `./tools/post-news` | Broadcast to all agents |
| `./tools/read-news` | Read broadcasts |
| `./tools/add-nit` | Log a small issue for later |

### Instructions & Artifacts

| Tool | What It Does |
|------|--------------|
| `./tools/show-instructions` | See active instructions |
| `./tools/capture-instruction` | Create new instruction |
| `./tools/complete-instruction` | Mark instruction done |
| `./tools/capture-artifact` | Store a deliverable |

### Discovery

| Tool | What It Does |
|------|--------------|
| `./tools/list-tools` | List all available tools |
| `./tools/find-tool "keyword"` | Search for a tool |
| `./tools/how "task"` | Get guidance on a task |

---

## Understanding Claude Code Basics

### Keyboard Shortcuts

| Shortcut | What It Does |
|----------|--------------|
| `!` | Bash mode prefix |
| `@` | Mention files/folders |
| `#` | Add to CLAUDE.md |
| `Esc` | Interrupt Claude |
| `Esc + Esc` | Rewind to checkpoint |
| `/` | Access slash commands |
| `Tab` | Command completion |
| `↑` | Previous command |

### Essential Slash Commands

| Command | What It Does |
|---------|--------------|
| `/help` | Show all commands |
| `/clear` | Clear conversation (use often!) |
| `/model` | Change AI model |
| `/compact` | Summarize long conversation |
| `/rewind` | Undo changes |
| `/permissions` | Manage tool permissions |

### Models

| Model | When to Use |
|-------|-------------|
| Opus 4.5 | Complex architecture, security |
| Sonnet 4.5 | Implementation, refactoring (default) |
| Haiku 4.5 | Quick searches, simple edits |

Switch with:
```
/model opus
/model sonnet
/model haiku
```

---

## What You Get With The Agency

After completing setup, you have:

### Named Terminal Tabs

Each agent session runs in a clearly labeled tab:

```
┌──────────────────┬──────────────────┬──────────────────┐
│ housekeeping     │ web              │ agents           │
│ (general)        │ (web)            │ (agents)         │
└──────────────────┴──────────────────┴──────────────────┘
```

### Persistent Agent Identity

```bash
$ ./tools/whoami
jordan

$ ./tools/agentname
housekeeping

$ ./tools/workstream
general
```

### Session State

Your agent knows:
- What it was working on (ADHOC-WORKLOG.md)
- Active instructions from principals
- Collaboration requests from other agents
- Recent news and updates

### Structured Work Tracking

```
claude/
├── agents/
│   └── housekeeping/
│       ├── agent.md          # Agent definition
│       ├── WORKLOG.md         # Sprint work
│       ├── ADHOC-WORKLOG.md   # Ad-hoc tracking
│       └── KNOWLEDGE.md       # Learned context
├── principals/
│   └── jordan/
│       ├── instructions/      # Tasks from principal
│       └── artifacts/         # Deliverables
└── workstreams/
    └── general/
        └── KNOWLEDGE.md       # Shared knowledge
```

### Quality Gates

Pre-commit checks run automatically:
1. Formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review

### Collaboration Infrastructure

Agents can:
- Request help from each other
- Broadcast news
- Leave nits for later
- Track who did what

---

## Versus Going Solo

| Capability | Vanilla Claude Code | The Agency |
|------------|---------------------|------------|
| Terminal naming | Manual | Automatic |
| Agent identity | None | Built-in |
| Session persistence | Basic `/resume` | Full state restoration |
| Work tracking | None | WORKLOG, ADHOC, instructions |
| Quality gates | Manual | Automated 5-step |
| Collaboration | None | Full agent-to-agent |
| Principal instructions | None | Structured system |
| Time awareness | None | `./tools/now` (SGT default) |
| Deployment | Manual git | Green-Red pipeline |

---

## Next Steps

1. **Explore the codebase:** Ask Claude "what does this project do?"
2. **Try the tools:** Run `./tools/list-tools` to see everything available
3. **Create your first instruction:** Use `./tools/capture-instruction`
4. **Read the architecture guide:** `claude/docs/guides/architecture-development-guide-v3.0.md`

---

## Troubleshooting

### "claude: command not found"

Add to PATH:
```bash
export PATH="$HOME/.claude/bin:$PATH"
source ~/.zshrc
```

### "Permission denied" on tools

```bash
chmod +x ./tools/*
```

### Agent not picking up context

```bash
./tools/restore
```

### Terminal tab not renaming

Ensure you're using iTerm2 (macOS) or a terminal that supports escape sequences for tab naming.

---

## Sources

- [Claude Code Product Page](https://claude.com/product/claude-code)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Claude Code Documentation](https://code.claude.com/docs/en/overview)
