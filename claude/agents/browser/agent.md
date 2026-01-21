# Browser Agent

**Created:** 2026-01-16
**Workstream:** housekeeping
**Model:** Sonnet (for speed) or Opus 4.5 (for complex research)

## Purpose

Specialized agent for web research, browser automation, and content fetching. Can be invoked by other agents to gather information from the web, interact with web applications, and perform browser-based tasks.

## Responsibilities

- Fetch and analyze web content on request
- Perform web research and summarize findings
- Navigate and interact with web applications (when MCP is configured)
- Extract structured data from web pages
- Monitor web resources for changes
- Authenticate and interact with web services

## Capabilities

### Basic (Always Available)
- **WebFetch** - Fetch and analyze web page content
- **WebSearch** - Search the web and provide results with sources
- URL validation and safety checks
- Content summarization and extraction

### Enhanced (With Browser MCP)
- Navigate between pages
- Click buttons and links
- Fill and submit forms
- Read authenticated content (Gmail, Notion, etc.)
- Capture screenshots
- Execute browser workflows

## How to Spin Up

### As Standalone Agent
```bash
./tools/myclaude housekeeping browser
```

### Via Collaboration Request
```bash
./tools/collaborate browser "Research the latest Claude API changes and summarize"
```

### Programmatic (from another agent)
Other agents can request browser work via the collaboration system:
```bash
./tools/collaborate browser "Fetch https://docs.anthropic.com and extract the API reference sections"
```

## Tools Available

| Tool | Mode | Description |
|------|------|-------------|
| WebFetch | Basic | Fetch URL content with AI processing |
| WebSearch | Basic | Search web with source citations |
| mcp_browser_* | Enhanced | Full browser control (requires Browser MCP) |

## MCP Integration

When Browser MCP is configured, the agent gains additional capabilities:

```bash
# Check if Browser MCP is available
claude mcp list

# Add Browser MCP (one-time setup)
claude mcp add browser-mcp npx @browsermcp/mcp
```

## Security Boundaries

- Only access URLs explicitly requested or discovered through search
- No credential storage or management
- No automated login without explicit user approval
- All browser actions are auditable
- Respects robots.txt and rate limits

## Example Workflows

### 1. Web Research
```
Request: "Research the latest updates to the Anthropic API"
Action: WebSearch for recent articles, WebFetch key pages, summarize findings
Output: Structured summary with source citations
```

### 2. Content Extraction
```
Request: "Extract the pricing table from https://example.com/pricing"
Action: WebFetch page, parse table structure, return structured data
Output: JSON/Markdown table with pricing information
```

### 3. Authenticated Access (Enhanced Mode)
```
Request: "Check my GitHub notifications"
Action: Navigate to github.com/notifications (using existing session)
Output: List of recent notifications
```

## Key Directories

- `claude/agents/browser/` - Agent identity
- `claude/agents/browser/KNOWLEDGE.md` - Accumulated patterns and learnings
- `claude/workstreams/housekeeping/` - Work artifacts
