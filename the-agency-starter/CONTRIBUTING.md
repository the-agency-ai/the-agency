# Contributing to The Agency

Thank you for your interest in improving The Agency!

## Ways to Contribute

### 1. Report Issues

Found a bug or have a suggestion? [Open an issue](https://github.com/the-agency-ai/the-agency-starter/issues).

Include:
- What you were trying to do
- What happened instead
- Steps to reproduce
- Your environment (OS, Node version, etc.)

### 2. Improve Documentation

Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add examples
- Improve Getting Started guide
- Add to CONCEPTS.md

### 3. Create Starter Packs

Starter packs provide framework-specific conventions. To create one:

```
claude/starter-packs/your-framework/
  PATTERNS.md       # Framework-specific patterns
  QUALITY.md        # Additional quality gates
  SCAFFOLDING.md    # Component/route generation
  tools/            # Framework-specific tools (optional)
```

Include:
- Common patterns for that framework
- Quality enforcement (linting rules, test patterns)
- Scaffolding helpers
- Example agent configurations

### 4. Improve Tools

The `tools/` directory contains CLI utilities. When improving:
- Maintain backward compatibility
- Add help text (`-h` flag)
- Use dynamic repo root detection
- Test on macOS and Linux

### 5. Enhance the MCP Server

The MCP server (`claude/claude-desktop/agency-server/`) bridges Claude Desktop and Code:
- Add new tools for coordination
- Improve resource exposure
- Add new primitives

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/the-agency-starter.git
cd the-agency-starter

# Make tools executable
chmod +x tools/*

# Install MCP server dependencies
cd claude/claude-desktop/agency-server
npm install
cd ../../..

# Test a tool
./tools/whoami
```

## Coding Standards

### Shell Scripts (tools/)

```bash
#!/bin/bash
# Tool: name
# Purpose: What it does
# Usage: ./tools/name [args]

set -e

# Find repo root dynamically
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Help text
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,5p' "$0" | sed 's/^# //'
  exit 0
fi

# ... implementation
```

### TypeScript (MCP server, Workbench)

- Use TypeScript strict mode
- Prefer explicit types over inference
- Handle errors gracefully
- Document public functions

### Markdown

- Use ATX headers (`#`, `##`, etc.)
- Include code examples
- Keep lines under 100 characters
- Use fenced code blocks with language hints

## Commit Messages

```
type(scope): message

[optional body]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Code refactoring
- `test` - Tests
- `chore` - Maintenance

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Make your changes
4. Run quality checks (`./tools/pre-commit-check` if available)
5. Commit with a descriptive message
6. Push to your fork
7. Open a Pull Request

### PR Description

Include:
- What the change does
- Why it's needed
- How to test it
- Any breaking changes

## Starter Pack Guidelines

When creating a starter pack:

1. **Be Opinionated** - Make decisions, don't leave everything configurable
2. **Document Patterns** - Explain why, not just what
3. **Include Examples** - Show real usage
4. **Test on Fresh Clone** - Ensure it works from scratch
5. **Keep It Focused** - One framework per pack

## Questions?

- Open a [Discussion](https://github.com/the-agency-ai/the-agency-starter/discussions)
- Ask the housekeeping agent: `./tools/myclaude housekeeping housekeeping "How do I contribute...?"`

---

## Staying Up to Date

After forking, you can receive updates from the upstream repository:

### Initial Setup

```bash
# Add upstream remote (one time)
git remote add upstream https://github.com/the-agency-ai/the-agency-starter.git
```

### Getting Updates

```bash
# Fetch latest changes
git fetch upstream

# See what's new
git log HEAD..upstream/main --oneline

# Merge updates (review changes first!)
git merge upstream/main --no-commit

# Resolve any conflicts, then commit
git commit -m "chore: merge upstream v0.2.0"
```

### What Gets Updated vs. What You Customize

| Category | Safe to Merge | Review Carefully |
|----------|---------------|------------------|
| `tools/*` | ✅ Rarely customized | |
| `claude/docs/*` | ✅ Documentation | |
| `CLAUDE.md` | | ⚠️ You likely customized this |
| `claude/config.yaml` | | ⚠️ Your project settings |
| `claude/agents/*` | | ⚠️ Your agents |
| `claude/principals/*` | | ⚠️ Your team |

### Checking the Version

```bash
cat VERSION        # Your current version
git fetch upstream
git show upstream/main:VERSION  # Latest version
cat CHANGELOG.md   # What changed
```

---

*Thank you for making The Agency better!*
