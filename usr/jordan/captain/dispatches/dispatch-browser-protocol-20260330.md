# Dispatch: Design Agent Browsing Protocol

**Date:** 2026-03-30
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** Medium

---

## Directive

Design a browsing protocol that guides agents through web content retrieval. Agents currently try WebFetch, get garbage or a 403, and give up. They need an escalation ladder and behavioral guidance.

## Problem

Agents don't know how to browse effectively:
- Try `WebFetch` once, fail, give up
- Don't escalate to Playwright MCP when WebFetch returns raw HTML or blocks
- Dump entire pages into context instead of extracting what they need
- Don't handle common failures (bot detection, JS-required sites, login walls)
- Don't know when to use snapshots vs screenshots vs page content

## Requirements

### Escalation Ladder
1. **WebFetch** — try first (fast, cheap, no browser needed)
2. **Playwright MCP snapshot** — if WebFetch fails or returns garbage (renders JS, structured output, token-efficient)
3. **Playwright MCP screenshot** — if visual context needed (layout, design, errors)
4. **Docker container** — future: for sites requiring isolation, persistent sessions, or heavy automation

### Behavioral Guidance
- Extract what you need, don't dump the whole page
- Use `browser_snapshot` over `browser_take_screenshot` for content (structured, cheaper)
- Handle 403/bot detection: try Playwright before giving up
- Handle JS-required: WebFetch won't work, go straight to Playwright
- Token budget: summarize content, don't paste raw HTML into context

### Delivery Options
1. **Hookify rule** — warn when agent uses WebFetch and gets an error, suggest Playwright escalation
2. **Reference doc** — `claude/docs/BROWSING-PROTOCOL.md` injected by ref-injector when browsing tools are invoked
3. **Agent class guidance** — include browsing protocol in tech-lead and researcher class definitions
4. **All three** — layered enforcement

## Prior Art
- gstack's `/browse` skill — persistent Chromium daemon with CLI, snapshot-first approach
- gstack's `$B snapshot` with structured flags — token-efficient page extraction
- Playwright MCP plugin — already available, full browser automation

## Future Consideration
- Docker-based browser containers for isolation and reproducibility
- Pluggable provider pattern: `browser-playwright`, `browser-docker`
- Possible `/browse` skill that wraps the escalation ladder as a guided workflow
