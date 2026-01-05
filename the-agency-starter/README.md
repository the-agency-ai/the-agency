# The Agency Starter

A multi-agent development framework for Claude Code.

## What is The Agency?

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase. Think Ruby on Rails, but for AI-assisted development.

**You get:**
- 🤖 **Specialized Agents** - Claude instances with persistent context and memory
- 📋 **Workstreams** - Organized areas of work with shared knowledge
- 👤 **Principal System** - Human stakeholders direct work via instructions
- 🤝 **Collaboration Tools** - Inter-agent communication and handoffs
- ✅ **Quality Gates** - Enforced standards via pre-commit hooks
- 🖥️ **Claude Desktop Integration** - MCP server for coordination

## Quick Start

```bash
# Clone this repo
git clone https://github.com/jordandm/the-agency-starter.git my-project
cd my-project

# Make tools executable
chmod +x tools/*

# Launch the housekeeping agent (your guide)
./tools/myclaude housekeeping housekeeping
```

The housekeeping agent will help you:
- Set up your project structure
- Create workstreams for your features
- Spawn specialized agents
- Apply framework-specific starter packs

## How It Works

```
You (Principal)
    │
    ├── Issue Instructions ──► Agents execute
    │
    └── Review Artifacts ◄── Agents deliver

Agents collaborate via:
    - Collaboration requests
    - News broadcasts
    - Handoffs
```

## Directory Structure

```
CLAUDE.md                    # The constitution
README.md                    # This file
apps/
  workbench/                 # Web UI for Agency management
    src/app/
      staff/                 # Staff Manager
      agents/                # Agent Manager
      content/               # Content Manager
      pulse/                 # Pulse Beat dashboard
      catalog/               # Agent catalog
packages/
  ui/                        # Shared UI components (shadcn)
  auth/                      # Auth utilities
claude/
  agents/                    # Agent definitions
    housekeeping/            # Your guide (ships ready)
    collaboration/           # Inter-agent messages
  workstreams/               # Work organization
  principals/                # Human stakeholders
  docs/                      # Guides and reference
  claude-desktop/            # MCP integration
tools/                       # CLI tools
```

## Core Concepts

### Agents
Specialized Claude Code instances with:
- Persistent identity and context
- Domain-specific knowledge
- Session restoration across conversations

### Workstreams
Areas of related work:
- Shared knowledge base
- Sprint-based planning
- Multiple agents can contribute

### Principals
Human stakeholders who:
- Direct work via instructions
- Review artifacts (deliverables)
- Set preferences for how they work

### Collaboration
Agents communicate via:
- `./tools/collaborate` - Request help from another agent
- `./tools/post-news` - Broadcast updates to all agents
- `./tools/read-news` - Read unread news messages

## Tools

Run `./tools/find-tool -l` to see all available tools. Key categories:

### Identity
- `whoami`, `agentname`, `workstream` - Agent identity
- `now` - Consistent timestamps

### Scaffolding
- `create-workstream` - Create a new workstream
- `create-agent` - Create a new agent

### Collaboration
- `collaborate` - Create collaboration requests
- `post-news` / `read-news` - Agent broadcasts

### Git Discipline
- `sync` - The ONLY way to push (logs all pushes)
- `commit-prefix` - Consistent commit message formatting

### Work Tracking
- `log-adhoc` - Log unplanned work

### Discovery
- `find-tool` - Search and discover tools
- `myclaude` - Launch agents

## Starter Packs

Framework-specific conventions (coming soon):
- Next.js
- React Native
- Python
- Swift/SwiftUI
- Kotlin

## Contributing

We welcome:
- Starter packs for new frameworks
- Tool improvements
- Documentation
- Bug reports

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT - See [LICENSE](LICENSE)

---

*Built with ❤️ by humans and Claude*
