---
title: Claude Code Agent SDK
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/agent-sdk
---

# Claude Code Agent SDK

The Agent SDK provides programmatic access to Claude Code capabilities in Python and TypeScript.

## Overview

The Agent SDK allows you to build custom applications that leverage Claude Code's agentic capabilities. You can create agents programmatically, control their behavior, and integrate them into larger systems.

## Key Features

### SDK Capabilities

| Capability | Description |
|------------|-------------|
| Session management | Create, resume, and manage sessions |
| Tool execution | Run tools programmatically |
| Streaming | Stream responses in real-time |
| Hooks | Programmatic lifecycle hooks |
| Custom tools | Define and register custom tools |

### Installation

```bash
# Python
pip install claude-code-sdk

# TypeScript/Node.js
npm install @anthropic/claude-code-sdk
```

## Configuration

### Python SDK

```python
from claude_code_sdk import ClaudeCode, Session

# Initialize client
client = ClaudeCode(api_key="your-key")

# Create session
session = client.create_session(
    project_dir="/path/to/project",
    model="sonnet"
)

# Send message
response = session.send("Explain this codebase")
print(response.content)
```

### TypeScript SDK

```typescript
import { ClaudeCode, Session } from '@anthropic/claude-code-sdk';

// Initialize client
const client = new ClaudeCode({ apiKey: 'your-key' });

// Create session
const session = await client.createSession({
  projectDir: '/path/to/project',
  model: 'sonnet'
});

// Send message
const response = await session.send('Explain this codebase');
console.log(response.content);
```

### Streaming Responses

```python
# Python streaming
for chunk in session.stream("Write a function"):
    print(chunk.content, end="", flush=True)
```

```typescript
// TypeScript streaming
for await (const chunk of session.stream('Write a function')) {
  process.stdout.write(chunk.content);
}
```

## Examples

### Simple Agent

```python
from claude_code_sdk import ClaudeCode

client = ClaudeCode()

with client.create_session(project_dir=".") as session:
    # Have Claude analyze and fix issues
    response = session.send("""
        1. Run the tests
        2. Fix any failing tests
        3. Report what was changed
    """)
    print(response.content)
```

### Custom Tool Integration

```python
from claude_code_sdk import ClaudeCode, Tool

# Define custom tool
class DatabaseTool(Tool):
    name = "query_database"
    description = "Execute SQL query"

    def execute(self, query: str) -> str:
        # Your database logic
        return f"Query result: {query}"

client = ClaudeCode()
session = client.create_session(
    project_dir=".",
    tools=[DatabaseTool()]
)
```

### Programmatic Hooks

```python
from claude_code_sdk import ClaudeCode, Hook

def on_tool_use(event):
    print(f"Tool used: {event.tool_name}")
    if event.tool_name == "Bash":
        print(f"Command: {event.input.command}")

client = ClaudeCode()
session = client.create_session(
    project_dir=".",
    hooks={
        "PostToolUse": on_tool_use
    }
)
```

### Batch Processing

```python
from claude_code_sdk import ClaudeCode

client = ClaudeCode()

# Process multiple files
files = ["src/a.py", "src/b.py", "src/c.py"]

for file in files:
    with client.create_session(project_dir=".") as session:
        response = session.send(f"Review {file} for security issues")
        print(f"\n=== {file} ===\n{response.content}")
```

### CI/CD Integration

```python
#!/usr/bin/env python3
# ci-code-review.py
from claude_code_sdk import ClaudeCode
import subprocess
import sys

# Get changed files
result = subprocess.run(
    ["git", "diff", "--name-only", "main...HEAD"],
    capture_output=True, text=True
)
changed_files = result.stdout.strip().split("\n")

client = ClaudeCode()

with client.create_session(project_dir=".") as session:
    response = session.send(f"""
        Review these changed files for issues:
        {chr(10).join(changed_files)}

        Focus on:
        - Security vulnerabilities
        - Performance issues
        - Code style violations
    """)

    if "CRITICAL" in response.content:
        print(response.content)
        sys.exit(1)

    print("Review passed")
```

## Agency Relevance

**Very High** - SDK enables programmatic agent orchestration:

| Current Agency | SDK Equivalent |
|----------------|---------------|
| `./tools/myclaude` | SDK session creation |
| Manual agent launching | Programmatic session management |
| Shell-based collaboration | SDK message passing |
| Script-based workflows | Python/TypeScript workflows |

### Benefits
1. **Programmatic control** - Launch agents from code
2. **Custom tools** - Extend beyond built-in tools
3. **Integration** - Embed in larger systems
4. **Streaming** - Real-time response handling
5. **Hooks** - Programmatic lifecycle control

### Implementation Ideas

#### Agent Orchestrator

```python
from claude_code_sdk import ClaudeCode

class AgencyOrchestrator:
    def __init__(self):
        self.client = ClaudeCode()

    def launch_agent(self, workstream: str, agent: str, task: str):
        """Launch an Agency agent programmatically."""
        project_dir = f"agency/agents/{agent}"

        with self.client.create_session(
            project_dir=".",
            system_prompt=open(f"{project_dir}/agent.md").read()
        ) as session:
            return session.send(task)

    def parallel_review(self, work_item: str):
        """Run parallel code reviews."""
        import concurrent.futures

        reviewers = ["reviewer-1", "reviewer-2", "security"]

        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = [
                executor.submit(
                    self.launch_agent,
                    "housekeeping", reviewer, f"Review {work_item}"
                )
                for reviewer in reviewers
            ]

            return [f.result() for f in futures]
```

#### Collaboration via SDK

```python
def collaborate(from_agent: str, to_agent: str, message: str):
    """Send collaboration request via SDK."""
    client = ClaudeCode()

    with client.create_session(project_dir=".") as session:
        return session.send(f"""
            You are {to_agent}.
            {from_agent} sent you this collaboration request:

            {message}

            Respond appropriately.
        """)
```

## Links/Sources

- [Agent SDK Documentation](https://code.claude.com/docs/en/agent-sdk)
- [Python SDK Reference](https://code.claude.com/docs/en/sdk-python)
- [TypeScript SDK Reference](https://code.claude.com/docs/en/sdk-typescript)
- [SDK Examples](https://github.com/anthropics/claude-code-sdk-examples)
