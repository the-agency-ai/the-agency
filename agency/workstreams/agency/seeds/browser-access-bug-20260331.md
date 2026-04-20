# Bug: No Working Path for Autonomous Web Browsing

**Date:** 2026-03-31
**Filed by:** captain
**Severity:** High — blocks all web content retrieval workflows

## Problem

Agents have zero autonomous web browsing capability. Every available path is broken or restricted.

## Attempted Paths (All Failed)

### 1. Browser MCP (`mcp__browser-mcp__*`)
- **Server:** `npx @browsermcp/mcp` configured in `/Users/jdm/.claude.json`
- **Chrome extension:** "Claude (MCP)" tab installed and shows green checkmark
- **Initial state:** `/mcp` shows `browser-mcp · ✓ connected`
- **On first tool call:** returns "No connection to browser extension" — server process is running but can't reach the Chrome extension
- **After repeated attempts:** server crashes, `/mcp` shows `browser-mcp · ✗ failed`
- **Stale health check:** `claude mcp list` still reports "✓ Connected" AFTER the server has failed
- **Tools deregistered:** Once server crashes, all `mcp__browser-mcp__*` tools are permanently removed from the session. Cannot recover without restarting Claude Code.
- **Possible trigger:** Server may have crashed when Chrome opened a new tab

### 2. Computer Use MCP (`mcp__computer-use__*`)
- **Works** for screenshots — can see screen content
- **Hardcoded read-only tier for browsers** — "granted at tier 'read' (visible in screenshots only; no clicks or typing)"
- **Cannot** navigate, click, type, or interact with Chrome in any way
- **macOS accessibility permissions** are granted (user confirmed, re-approved for latest Claude Code binary)
- **Tier guidance says** to use "Claude-in-Chrome MCP" (`mcp__Claude_in_Chrome__*`) which doesn't exist as a configured tool
- **Root cause:** Computer Use MCP policy decision — browsers are always read-only regardless of user permission

### 3. WebFetch
- Works for simple, unauthenticated sites
- **Fails on X/Twitter** — bot detection, login walls, JS-heavy rendering
- **Not a browser** — can't handle modern web apps

### 4. Nitter Mirrors (X/Twitter workaround)
- `nitter.poast.org` — 503 Service Unavailable
- `nitter.privacydev.net` — ECONNREFUSED
- All known public Nitter instances appear dead as of 2026-03-31

## Impact

- Cannot fetch X/Twitter posts for knowledge base capture
- Cannot browse documentation sites that require JS
- Cannot navigate to any URL autonomously
- Principal must manually navigate browser and either paste content or position windows for screenshots
- Dispatch #4 (Browser Protocol) assumes working browser MCP — it doesn't work

## Bugs to File

### 1. Browser MCP: Server crashes mid-session
- Server starts and shows connected, but crashes on first tool use or shortly after
- `claude mcp list` reports stale "Connected" status after crash
- Tools are permanently deregistered from session — no recovery path
- **Debug step:** Relaunch with `claude --debug` to capture server crash logs

### 2. Computer Use MCP: Read-only browser tier too restrictive
- User explicitly grants Chrome access and macOS accessibility permissions
- System overrides user intent by hardcoding browser tier to read-only
- Tier guidance references "Claude-in-Chrome MCP" which may not be configured
- **Feedback:** User should be able to grant full browser control when they choose to

### 3. Browser MCP: "No connection to browser extension" despite extension showing connected
- Chrome extension tab shows green checkmark and "Claude (MCP)" label
- MCP server process running and reporting healthy
- But the WebSocket(?) link between server and extension is not established
- May require specific Chrome extension interaction to establish connection

## Next Steps

1. Relaunch with `claude --debug` to capture browser-mcp crash logs
2. Investigate Browser MCP Chrome extension connection protocol
3. File Anthropic feedback on Computer Use read-only browser tier
4. Document working setup once fixed
