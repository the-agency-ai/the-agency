# The Agency

A multi-agent development framework for Claude Code.

## Overview

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase. Built for developers who want to scale their AI-assisted development workflows.

## Key Features

- **Multiple Agents** - Specialized Claude Code instances with persistent context
- **Workstreams** - Organized areas of work with shared knowledge
- **Collaboration** - Inter-agent communication and handoffs
- **Quality Gates** - Enforced standards via pre-commit hooks
- **Session Continuity** - Backup and restore agent context across sessions

## Getting Started

For new projects, use [The Agency Starter](https://github.com/the-agency-ai/the-agency-starter):

```bash
curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
```

## Repository Structure

This is the development repository for The Agency. It contains:

- `tools/` - CLI tools for The Agency
- `claude/` - Agent definitions, workstreams, and documentation
- `the-agency-starter/` - Starter template (submodule)

## For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Submit starter packs
- Improve core tools
- Report issues

## Documentation

- [CLAUDE.md](CLAUDE.md) - The constitution (main documentation)
- [claude/docs/](claude/docs/) - Guides and references
- [claude/docs/cookbooks/](claude/docs/cookbooks/) - Claude Cookbook patterns

## License

MIT License - see [LICENSE](LICENSE)

---

*The Agency - Multi-agent development, done right.*
