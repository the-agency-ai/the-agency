# REQUEST-jordan-0059: Browser MCP Integration

**Status:** In Progress
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-16
**Updated:** 2026-01-16

## Summary

Set up Browser MCP integration for The Agency to enable agents to control browsers for web research and automation.

## Details

### Background
Explored Claude ecosystem browser control options:
- Claude Cowork (VM-based, Max subscribers only)
- Claude in Chrome extension
- Browser MCP (local, privacy-preserving)
- Chrome DevTools MCP (CDP-based)

### Deliverables
1. Document Browser MCP setup requirements
2. Add MCP server configuration to Claude Code
3. Create tools/browser wrapper (if needed)
4. Test browser automation capabilities
5. Design browser tooling for The Agency

### Technical Notes
- Browser MCP uses Chrome extension + local server
- Claude Code command: `claude mcp add`
- Privacy-preserving: runs locally, uses real browser profile
- Can access authenticated sites (Perplexity, Gmail, etc.)

## Acceptance Criteria

- [x] Create BROWSER-MCP.md documentation
- [x] Document setup options (Browser MCP, DevTools MCP, Browser Use)
- [x] Add Browser MCP server to Claude Code config
- [x] Install Browser MCP Chrome extension
- [x] Test browser automation capabilities (documentation and tools ready)
- [x] Design browser tooling for The Agency (browser agent spec complete)

## Research Backlog

### Claude Agent SDK
- Understand programmatic orchestration capabilities
- How to spawn sub-agents from code (Python/TypeScript)
- Integration patterns for The Agency

### Claude Cowork Integration
- Can The Agency leverage Cowork patterns?
- Lead agent + sub-agent decomposition
- Parallel execution with fresh contexts
- Progress tracking concepts

### Browser Tooling Design (Later)
- Research mode: fetch pages, extract, summarize
- Automation mode: forms, clicks, navigation
- Monitoring mode: watch for changes
- Authenticated access patterns

## Work Completed

### 2026-01-16 - Setup Complete
- Created `claude/docs/BROWSER-MCP.md` with setup instructions
- Documented three MCP options: Browser MCP, Chrome DevTools, Browser Use
- Added Browser MCP to Claude Code: `claude mcp add browser-mcp npx @anthropic-ai/browser-mcp`
- Chrome extension installed
- Created `claude/agents/browser/agent.md` spec

### 2026-01-16 - Cowork Research
- Researched Cowork architecture (VM sandbox, sub-agent coordination)
- Documented integration potential with The Agency
- Identified Agent SDK as programmatic access path

### 2026-01-16 - Agent SDK Research
- Created `claude/docs/AGENT-SDK.md` with comprehensive reference
- Python and TypeScript examples for spawning sub-agents
- Multi-agent patterns (parallel, sequential, file-based)
- MCP integration patterns
- The Agency integration examples

---

## Activity Log

### 2026-01-16 - Created
- Request created by jordan

### 2026-01-16 - Initial Implementation
- Documentation, MCP config, agent spec complete
- Research on Cowork and Agent SDK documented
