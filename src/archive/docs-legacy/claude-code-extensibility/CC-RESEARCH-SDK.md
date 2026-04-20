---
title: Claude Agent SDK
created: 2026-01-21T13:40:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Agent SDK

## Overview

The Claude Agent SDK (formerly Claude Code SDK) provides programmatic access to Claude Code's capabilities. Build AI agents that autonomously read files, run commands, search the web, edit code, and more.

## Installation

### Prerequisites

```bash
# Install Claude Code (runtime)
curl -fsSL https://claude.ai/install.sh | bash
```

### TypeScript

```bash
npm install @anthropic-ai/claude-agent-sdk
```

### Python

```bash
pip install claude-agent-sdk
```

## Authentication

```bash
export ANTHROPIC_API_KEY=your-api-key
```

Alternative providers:
- Amazon Bedrock: `CLAUDE_CODE_USE_BEDROCK=1`
- Google Vertex AI: `CLAUDE_CODE_USE_VERTEX=1`
- Microsoft Foundry: `CLAUDE_CODE_USE_FOUNDRY=1`

## Basic Usage

### Python

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Find and fix the bug in auth.py",
        options=ClaudeAgentOptions(allowed_tools=["Read", "Edit", "Bash"])
    ):
        print(message)

asyncio.run(main())
```

### TypeScript

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

for await (const message of query({
  prompt: "Find and fix the bug in auth.py",
  allowedTools: ["Read", "Edit", "Bash"]
})) {
  console.log(message);
}
```

## Built-in Tools

| Tool | Description |
|------|-------------|
| Read | Read any file in working directory |
| Write | Create new files |
| Edit | Make precise edits to existing files |
| Bash | Run terminal commands, scripts, git |
| Glob | Find files by pattern |
| Grep | Search file contents with regex |
| WebSearch | Search the web |
| WebFetch | Fetch and parse web pages |
| AskUserQuestion | Ask clarifying questions |

## SDK Options

```python
ClaudeAgentOptions(
    allowed_tools=["Read", "Edit", "Bash"],  # Tool allowlist
    setting_sources=["project"],              # Load project config
    # ... other options
)
```

## Claude Code Features

Enable filesystem-based configuration with `setting_sources=["project"]`:

| Feature | Description | Location |
|---------|-------------|----------|
| Skills | Specialized capabilities | `.claude/skills/SKILL.md` |
| Slash commands | Custom commands | `.claude/commands/*.md` |
| Memory | Project context | `CLAUDE.md` |
| Plugins | Extensions | Programmatic via plugins option |

## Agent vs Client SDK

| Aspect | Client SDK | Agent SDK |
|--------|------------|-----------|
| Tool execution | You implement | Built-in |
| Agent loop | You implement | Automatic |
| Complexity | Higher | Lower |

### Client SDK (Manual Loop)

```python
response = client.messages.create(...)
while response.stop_reason == "tool_use":
    result = your_tool_executor(response.tool_use)
    response = client.messages.create(tool_result=result, ...)
```

### Agent SDK (Automatic)

```python
async for message in query(prompt="Fix the bug in auth.py"):
    print(message)
```

## Example: TODO Finder

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Find all TODO comments and create a summary",
        options=ClaudeAgentOptions(allowed_tools=["Read", "Glob", "Grep"])
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

## Supported Features

- Built-in tools
- Hooks
- Subagents
- MCP integration
- Permissions
- Sessions

## Reporting Issues

- TypeScript: [GitHub Issues](https://github.com/anthropics/claude-agent-sdk-typescript/issues)
- Python: [GitHub Issues](https://github.com/anthropics/claude-agent-sdk-python/issues)

## Agency Relevance

The Agent SDK could enhance The Agency:

1. **CI/CD Integration** - Run agents in pipelines
2. **Custom Automation** - Build agency-specific tools
3. **Parallel Agents** - Spawn multiple agents programmatically
4. **Testing Automation** - Automated agent testing
5. **External Integration** - Connect to external systems

## Example: Agency Integration

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def run_code_review(files: list[str]):
    """Run automated code review using Agency conventions."""
    async for message in query(
        prompt=f"Review these files following our code standards: {files}",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Glob", "Grep"],
            setting_sources=["project"]  # Load .claude config
        )
    ):
        yield message

async def main():
    async for result in run_code_review(["src/auth.py"]):
        print(result)

asyncio.run(main())
```

## Links/Sources

- [Agent SDK Overview](https://platform.claude.com/docs/en/agent-sdk/overview)
- [TypeScript SDK](https://github.com/anthropics/claude-agent-sdk-typescript)
- [Python SDK](https://github.com/anthropics/claude-agent-sdk-python)
