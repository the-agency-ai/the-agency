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

Initialize Agency in any git repo:

```bash
cd your-project
git init && claude init
agency init
```

See `claude/README-GETTINGSTARTED.md` for detailed setup instructions.

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
│   │       └── agent.md      # Identity, purpose, capabilities
│   ├── workstreams/          # Organized areas of work
│   │   └── {workstream}/
│   ├── principals/           # Human stakeholders
│   │   └── {principal}/
│   │       ├── requests/     # Work requests (REQUEST-*)
│   │       └── artifacts/    # Deliverables
│   ├── config/               # Agency configuration
│   └── docs/                 # Guides and reference
└── source/                   # Source code for services and apps
```

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

## Licensing

This repository uses an **open core** model:

- **Framework** (tools, agents, docs, methodology) — [MIT License](LICENSE)
- **App workstreams** (Markdown Pal, Mock and Mark, future apps/services) — [Reference Source License](claude/workstreams/markdown-pal/LICENSE) (view, contribute, no commercial redistribution)

Each app workstream directory contains its own LICENSE file.

---

*TheAgency - Multi-agent development, done right.*
