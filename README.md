<p align="center">
  <img src="source/apps/agency-bench/src-tauri/icons/512x512.png" alt="TheAgency Logo" width="128" height="128">
</p>

# TheAgency

An opinionated multi-agent development framework for Claude Code.

## Overview

TheAgency is an opinionated convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase alongside one or more humans (Principals). Built for developers who want to scale their AI-assisted development workflows.

## 📋 Join the Community

[**Register for TheAgency Community**](https://docs.google.com/forms/d/e/1FAIpQLSfkH2bE1LB39u5iU-BamxbVC6jHmyDEE0TB6G2yw7xODdS-1A/viewform?usp=header) - Add yourself to TheAgency community!

## Key Features

- **Multiple Agents** - Specialized Claude Code instances with persistent context
- **Workstreams** - Organized areas of work with shared knowledge
- **Collaboration** - Inter-agent communication and handoffs
- **Quality Gates** - Enforced standards via pre-commit hooks
- **Session Continuity** - Backup and restore agent context across sessions

## Getting Started

The installer handles everything - including Claude Code - to get you up and running:

```bash
curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
```

See the [Quick Start Guide](claude/docs/QUICK-START.md) for detailed setup instructions.

## Repository Structure

```
the-agency/
├── tools/                    # CLI tools for agents and principals
│   ├── myclaude              # Launch an agent
│   ├── commit                # Create properly formatted commits
│   ├── request               # Create work requests
│   └── ...                   # 50+ tools for collaboration, quality, and workflow
├── claude/
│   ├── agents/               # Agent definitions
│   │   └── {agent}/
│   │       ├── agent.md      # Identity, purpose, capabilities
│   │       ├── KNOWLEDGE.md  # Accumulated wisdom and patterns
│   │       └── WORKLOG.md    # Sprint-based work tracking
│   ├── workstreams/          # Organized areas of work
│   │   └── {workstream}/
│   │       └── KNOWLEDGE.md  # Shared knowledge across agents
│   ├── principals/           # Human stakeholders
│   │   └── {principal}/
│   │       ├── requests/     # Work requests (REQUEST-*)
│   │       └── artifacts/    # Deliverables
│   ├── config/               # Agency configuration
│   └── docs/                 # Guides and reference
└── source/                   # Source code for services and apps
```

## Knowledge System

TheAgency uses a hierarchical knowledge system where agents accumulate and share learnings:

- **Agent KNOWLEDGE.md** - Individual agent's accumulated wisdom, patterns, and lessons learned
- **Workstream KNOWLEDGE.md** - Shared knowledge across all agents in a workstream
- **CLAUDE.md** - The constitution - core conventions and standards for all agents

Knowledge flows upward: agents document discoveries in their KNOWLEDGE.md, valuable patterns get promoted to workstream knowledge, and universal standards live in CLAUDE.md.

## Documentation

- [Quick Start Guide](claude/docs/QUICK-START.md) - Get up and running
- [CLAUDE.md](CLAUDE.md) - The constitution (main documentation)
- [claude/docs/](claude/docs/) - Guides and references
- [claude/docs/cookbooks/](claude/docs/cookbooks/) - Claude Cookbook patterns

## For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Submit starter packs
- Improve core tools
- Report issues

## License

MIT License - see [LICENSE](LICENSE)

---

*TheAgency - Multi-agent development, done right.*
