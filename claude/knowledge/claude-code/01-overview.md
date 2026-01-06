# Claude Code Overview

**Back to:** [INDEX.md](INDEX.md)

---

## What Is Claude Code?

Claude Code is Anthropic's official agentic coding tool that operates directly in your terminal and IDE. It enables developers to work with Claude directly in their codebase, handling everything from bug fixes to feature implementation.

---

## Key Features

### Core Capabilities

| Feature | Description |
|---------|-------------|
| **Agentic Search** | Understands entire codebases without manual context selection |
| **Multi-file Changes** | Makes coordinated changes across multiple files |
| **Direct Action** | Edits files, runs commands, creates commits |
| **MCP Integration** | Connects to external tools (GitHub, Figma, Slack, etc.) |

### Developer Experience

- **Works in your terminal** - No additional chat windows or IDEs required
- **Permission-based** - Never modifies files without explicit approval
- **Adapts to your style** - Learns your coding standards and patterns
- **Unix philosophy** - Fully composable and scriptable

### Metrics (per Anthropic)

- "99.9% accuracy on complex code modifications"
- Ramp: "80% faster incident investigation time"
- Cred: "2x faster execution speed for features and fixes"
- Zapier: "89% AI adoption across all employees"

---

## Where Claude Code Works

| Interface | Description |
|-----------|-------------|
| **Terminal CLI** | Primary interface, automatic updates |
| **VS Code** | Native extension with inline diffs |
| **JetBrains** | IntelliJ, PyCharm, WebStorm support |
| **Web** | Browser-based, cloud infrastructure |
| **Desktop App** | Local or cloud execution |
| **Slack** | Delegate tasks from workspace (beta) |
| **Chrome Extension** | Browser integration (beta) |

---

## Pricing & Access

### Individual Plans

| Plan | Price | Notes |
|------|-------|-------|
| Pro | $17-20/month | Includes Claude Code |
| Max 5x | $100/month | Higher usage limits |
| Max 20x | $200/month | Highest individual tier |

### Team/Enterprise

| Plan | Price | Notes |
|------|-------|-------|
| Team | $150/month/person | Minimum 5 members |
| Enterprise | Custom | Advanced security, SSO |

### Developer API

- Pay-as-you-go at standard API rates
- No per-seat fees or platform charges

---

## Supported Models

- Claude Opus 4.5 (highest capability)
- Claude Sonnet 4.5 (default, balanced)
- Claude Haiku 4.5 (fastest, cheapest)

Enterprise users can deploy via Amazon Bedrock or Google Cloud Vertex AI.

---

## Security

- **Runs locally** in your terminal
- **Direct API communication** without backend servers
- **Permission-based** - requests approval before file modifications
- **No remote indexing** required

---

## Related

- [Installation](02-installation.md)
- [Quickstart](03-quickstart.md)
