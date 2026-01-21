# Browser MCP Integration

This document describes how to set up browser control capabilities for The Agency using MCP (Model Context Protocol).

## Overview

Browser MCP enables Claude Code agents to control a browser for:
- Web research and content extraction
- Form filling and automation
- Authenticated access to web apps
- Screenshot capture and visual analysis

## Setup Options

### Option 1: Browser MCP (Recommended)

Privacy-preserving local browser control using your real Chrome profile.

**Install Chrome Extension:**
1. Visit [browsermcp.io](https://browsermcp.io)
2. Install the Browser MCP Chrome extension
3. The extension handles communication between Claude and Chrome

**Add MCP Server:**
```bash
claude mcp add browser-mcp npx @browsermcp/mcp
```

**Features:**
- Uses real browser fingerprint (bypasses basic bot detection)
- Access to authenticated sessions (Gmail, GitHub, etc.)
- Runs locally - no data sent to external servers
- 14+ automation tools (click, type, scroll, screenshot, etc.)

### Option 2: Chrome DevTools MCP

Direct CDP (Chrome DevTools Protocol) access for debugging and development.

```bash
claude mcp add chrome-devtools npx chrome-devtools-mcp
```

**Best For:**
- Performance profiling
- Network request inspection
- Console log monitoring
- DOM inspection

### Option 3: Browser Use MCP (Cloud)

Cloud-hosted browser automation service.

```bash
claude mcp add --transport http browser-use https://api.browser-use.com/mcp
```

**Requires:** API key from browser-use.com

## Verification

Check configured MCP servers:
```bash
claude mcp list
```

View available tools:
```
/mcp
```

## Usage Examples

### Basic Web Fetch (No MCP Required)

```
Claude: Use WebFetch to get the content from https://example.com
```

### Browser Navigation (Requires Browser MCP)

```
Claude: Navigate to github.com and click on the "Sign in" button
```

### Form Filling (Requires Browser MCP)

```
Claude: Fill the search form on example.com with "test query" and submit
```

## Security Considerations

1. **Browser MCP runs locally** - Your browsing activity stays on your machine
2. **Uses existing sessions** - Can access sites you're already logged into
3. **Requires visible browser** - No headless mode (you can see what's happening)
4. **Confirmation for sensitive actions** - MCP prompts before significant actions

## Troubleshooting

### MCP Server Not Connecting
```bash
# Check if extension is running
# Chrome extension icon should be active

# Restart the MCP server
claude mcp remove browser-mcp
claude mcp add browser-mcp npx @browsermcp/mcp
```

### Extension Not Communicating
1. Check Chrome is running
2. Verify extension is enabled
3. Check browser console for errors

### Permission Denied
- Ensure the Chrome extension has necessary permissions
- Some sites may block automation - try a different approach

## Integration with The Agency

### Browser Agent

The `browser` agent (`claude/agents/browser/agent.md`) is configured to use Browser MCP when available:

```bash
./tools/myclaude housekeeping browser
```

### Collaboration Requests

Other agents can request browser work:

```bash
./tools/collaborate browser "Fetch the API documentation from..."
```

## References

- [Browser MCP](https://browsermcp.io)
- [Chrome DevTools MCP](https://github.com/anthropics/chrome-devtools-mcp)
- [Browser Use](https://browser-use.com)
- [Claude Code MCP Docs](https://code.claude.com/docs/mcp)
