# Claude Agent SDK

Research and reference documentation for programmatic agent orchestration.

## Overview

The Claude Agent SDK (formerly Claude Code SDK) is Anthropic's framework for building autonomous AI agents programmatically. It provides the same capabilities as Claude Code but accessible via Python and TypeScript.

**Key Insight:** Claude Code is built on top of the Agent SDK - they share the same agent harness.

## Installation

### TypeScript/Node.js
```bash
npm init -y
npm install @anthropic-ai/claude-agent-sdk
npm install -D typescript @types/node tsx
```

### Python
```bash
# Using uv (recommended)
uv init && uv add claude-agent-sdk

# Or with pip
python3 -m venv .venv && source .venv/bin/activate
pip3 install claude-agent-sdk
```

### Prerequisites
- Claude Code CLI installed (`curl -fsSL https://claude.ai/install.sh | bash`)
- Authentication completed (`claude`)
- Node.js 18+ (for some features)

## Basic Usage

### Python - One-Off Query
```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Find and fix the bug in auth.py",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Edit", "Bash"],
            permission_mode="acceptEdits"
        )
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

### TypeScript - One-Off Query
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Find and fix the bug in auth.py",
  options: {
    allowedTools: ["Read", "Edit", "Bash"],
    permissionMode: "acceptEdits"
  }
})) {
  if ("result" in message) console.log(message.result);
}
```

### Python - Multi-Turn Conversation
```python
import asyncio
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, AssistantMessage, TextBlock

async def main():
    async with ClaudeSDKClient() as client:
        # First question
        await client.query("What's the capital of France?")
        async for message in client.receive_response():
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        print(f"Claude: {block.text}")

        # Follow-up - Claude remembers context
        await client.query("What's the population of that city?")
        async for message in client.receive_response():
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        print(f"Claude: {block.text}")

asyncio.run(main())
```

## Available Built-in Tools

| Tool | Capability |
|------|-----------|
| **Read** | Read files (text, images, PDFs, Jupyter notebooks) |
| **Write** | Create new files |
| **Edit** | Make precise edits to existing files |
| **Bash** | Run terminal commands with optional timeout |
| **Glob** | Find files by pattern (`**/*.ts`, `src/**/*.py`) |
| **Grep** | Search file contents with regex |
| **WebSearch** | Search the web for current information |
| **WebFetch** | Fetch and parse web page content |
| **Task** | Spawn subagents for delegation |
| **AskUserQuestion** | Ask clarifying questions with multiple choice |
| **TodoWrite** | Manage task lists |

## Permission Modes

```python
# Auto-approve file changes
permission_mode="acceptEdits"

# Run without prompts (CI/CD)
permission_mode="bypassPermissions"

# Custom approval logic via callback
permission_mode="default"
can_use_tool=async_permission_handler

# Planning mode without execution
permission_mode="plan"
```

## Spawning Sub-Agents

### Python Example
```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions, AgentDefinition

async def main():
    async for message in query(
        prompt="Use the code-reviewer agent to review this codebase",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Glob", "Grep", "Task"],
            agents={
                "code-reviewer": AgentDefinition(
                    description="Expert code reviewer for quality and security reviews.",
                    prompt="Analyze code quality and suggest improvements.",
                    tools=["Read", "Glob", "Grep"]
                ),
                "security-reviewer": AgentDefinition(
                    description="Security vulnerabilities specialist.",
                    prompt="Look for security issues, injection attacks, credential exposure.",
                    tools=["Read", "Glob", "Grep"]
                )
            }
        )
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

### TypeScript Example
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Use the code-reviewer agent to review this codebase",
  options: {
    allowedTools: ["Read", "Glob", "Grep", "Task"],
    agents: {
      "code-reviewer": {
        description: "Expert code reviewer for quality and security reviews.",
        prompt: "Analyze code quality and suggest improvements.",
        tools: ["Read", "Glob", "Grep"]
      }
    }
  }
})) {
  if ("result" in message) console.log(message.result);
}
```

### Subagent Constraints
- Subagents **cannot spawn other subagents** (no nested delegation)
- Each subagent has isolated context window
- Claude uses subagent descriptions to decide when to delegate

## MCP Server Integration

The SDK shares MCP servers with Claude Code:

```python
options = ClaudeAgentOptions(
    mcp_servers={
        "playwright": {"command": "npx", "args": ["@playwright/mcp@latest"]},
        "browser-mcp": {"command": "npx", "args": ["@browsermcp/mcp"]}
    }
)
```

### Configuration File Hierarchy
```
~/.claude/settings.json              # User global
.claude/settings.json                # Project shared (version controlled)
.claude/settings.local.json          # Project local (gitignored)
```

### Loading Project Settings
```python
async for message in query(
    prompt="Add a new feature following project conventions",
    options=ClaudeAgentOptions(
        system_prompt={"type": "preset", "preset": "claude_code"},
        setting_sources=["project"],  # Required for CLAUDE.md
        allowed_tools=["Read", "Write", "Edit"]
    )
):
    print(message)
```

## Multi-Agent Patterns

### Pattern 1: Parallel Execution
```python
# Independent tasks run simultaneously
async for message in query(
    prompt="Review 3 modules: frontend, backend, database. Use specialized agents.",
    options=ClaudeAgentOptions(
        agents={
            "frontend-reviewer": AgentDefinition(...),
            "backend-reviewer": AgentDefinition(...),
            "db-reviewer": AgentDefinition(...)
        },
        allowed_tools=["Read", "Glob", "Grep", "Task"]
    )
):
    pass
```

### Pattern 2: Sequential Execution
```python
# First agent generates plan
# Second agent executes based on plan
# Third agent validates results
async for message in query(
    prompt="1) Generate test plan, 2) Run tests, 3) Report results",
    options=ClaudeAgentOptions(
        agents={
            "test-planner": AgentDefinition(...),
            "test-runner": AgentDefinition(...),
            "test-reporter": AgentDefinition(...)
        }
    )
):
    pass
```

### Pattern 3: File-Based Delegation
```python
# Write intermediate results to files
# Next agent reads from file instead of context
# Keeps context windows clean
```

## Session Management

```python
# Session 1: Gather requirements
session_id = None
async for message in query(
    prompt="Analyze requirements",
    options=ClaudeAgentOptions(allowed_tools=["Read", "Glob"])
):
    if hasattr(message, 'subtype') and message.subtype == 'init':
        session_id = message.session_id

# Session 2: Resume with full context
async for message in query(
    prompt="Now implement based on requirements",
    options=ClaudeAgentOptions(resume=session_id)
):
    pass
```

## Hooks for Observability

```python
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, HookMatcher
from datetime import datetime

async def log_tool_use(input_data, tool_use_id, context):
    tool = input_data.get('tool_name', 'unknown')
    with open('audit.log', 'a') as f:
        f.write(f"{datetime.now()}: {tool}\n")
    return {}

options = ClaudeAgentOptions(
    allowed_tools=["Read", "Edit", "Bash"],
    hooks={
        "PostToolUse": [HookMatcher(hooks=[log_tool_use])]
    }
)
```

## Comparison: SDK vs CLI

| Aspect | Agent SDK | Claude Code CLI |
|--------|----------|-----------------|
| **Use Case** | Production agents, CI/CD | Interactive development |
| **Control** | Programmatic | Conversational |
| **Sessions** | Full context management | Persistent |
| **Customization** | Maximum | Fixed workflows |

## API and Availability

| Method | Authentication |
|--------|----------------|
| **API Key** | `ANTHROPIC_API_KEY` env var |
| **Claude Code CLI** | OAuth (one-time) |
| **Bedrock** | AWS credentials |
| **Vertex AI** | Google Cloud auth |

## The Agency Integration

The Agent SDK can enhance The Agency with:

1. **Programmatic Agent Spawning** - Launch agents from code instead of CLI
2. **Custom Orchestration** - Implement Cowork-style lead agent + sub-agents
3. **CI/CD Integration** - Run agents in automated pipelines
4. **Parallel Execution** - Multiple agents working simultaneously

### Example: The Agency + Agent SDK
```python
from claude_agent_sdk import query, ClaudeAgentOptions, AgentDefinition

# Define agents matching The Agency conventions
agents = {
    "code-reviewer": AgentDefinition(
        description="Code quality and security review specialist",
        prompt="Review code following CLAUDE.md conventions",
        tools=["Read", "Glob", "Grep"]
    ),
    "test-runner": AgentDefinition(
        description="Test execution and validation",
        prompt="Run tests and report results",
        tools=["Read", "Bash", "Glob"]
    )
}

async for message in query(
    prompt="Review the codebase and run tests",
    options=ClaudeAgentOptions(
        setting_sources=["project"],  # Load CLAUDE.md
        agents=agents,
        allowed_tools=["Read", "Glob", "Grep", "Task", "Bash"]
    )
):
    print(message)
```

## References

- [Agent SDK Overview](https://platform.claude.com/docs/en/agent-sdk/overview)
- [Python Reference](https://platform.claude.com/docs/en/agent-sdk/python)
- [TypeScript Reference](https://platform.claude.com/docs/en/agent-sdk/typescript)
- [GitHub - Python SDK](https://github.com/anthropics/claude-agent-sdk-python)
- [GitHub - TypeScript SDK](https://github.com/anthropics/claude-agent-sdk-typescript)
- [Building Agents](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Custom Subagents](https://code.claude.com/docs/en/sub-agents)
