# Contributing to The Agency

Thank you for your interest in contributing to The Agency!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Run `./install.sh` to set up dependencies
4. Run `./tools/myclaude housekeeping captain` to launch the captain

## Development Workflow

We follow a **Red-Green** development model. See `CLAUDE.md` for the full workflow:

1. **Implementation** - Write code + tests, commit when GREEN
2. **Code Review + Security Review** - Multi-agent review, consolidate findings
3. **Test Review** - Review test coverage, add security tests
4. **Complete** - Tag and release

**Key principle:** Never commit on RED. Every commit must have passing tests.

## Commit Conventions

See `CLAUDE.md` section "Git Commits" for format:

```
{WORK-ITEM} - {WORKSTREAM}/{AGENT} for {PRINCIPAL}: {SHORT SUMMARY}

{body}

Stage: {impl | review | tests}
Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

Use `./tools/commit` to create properly formatted commits.

## Code Standards

- Follow existing patterns in the codebase
- Run `./tools/commit-precheck` before committing
- Add tests for new functionality
- Update documentation as needed

## Pull Requests

1. Create a branch from `main`
2. Make your changes following the development workflow
3. Push and create a PR
4. PRs will be reviewed by maintainers

## What Can You Contribute?

- **Bug fixes** - Fix issues you encounter
- **Tools** - Add new tools to `tools/`
- **Agents** - Create specialized agents
- **Starter Packs** - Framework-specific conventions
- **Documentation** - Improve guides and examples

## Questions?

Launch the captain and ask:
```bash
./tools/myclaude housekeeping captain "How do I contribute X?"
```

---

*More detailed contribution workflows coming soon (see REQUEST-0057).*
