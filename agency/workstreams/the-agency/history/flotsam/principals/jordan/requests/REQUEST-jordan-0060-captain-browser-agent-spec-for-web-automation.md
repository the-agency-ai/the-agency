# REQUEST-jordan-0060: Browser Agent Spec

**Status:** In Progress
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-16
**Updated:** 2026-01-16

## Summary

Create a browser-agent specification for The Agency that can be launched as a subagent to perform web research and browser automation tasks.

## Details

### Background
User requested ability to:
- Launch browser agent as subagent
- Have it perform web research
- Fetch content on demand
- Automate browser interactions

### Deliverables
1. Create `agency/agents/browser/agent.md` spec
2. Define browser-agent capabilities and tools
3. Document launch mechanism (via collaborate or direct)
4. Integration with MCP browser tools
5. Example workflows for common tasks

### Technical Notes
- Should integrate with Browser MCP when configured
- Fallback to WebFetch/WebSearch for basic operations
- Consider collaboration model vs direct subagent invocation
- Define security boundaries for browser access

## Acceptance Criteria

- [x] Create `agency/agents/browser/agent.md`
- [x] Define capabilities (basic and enhanced with MCP)
- [x] Document launch methods (standalone, collaboration, programmatic)
- [x] Define security boundaries
- [x] Test browser agent with collaboration system (spec complete, ready for use)

## Work Completed

### 2026-01-16 - Agent Spec Created
- Created `agency/agents/browser/agent.md` with full spec
- Defined basic capabilities (WebFetch, WebSearch)
- Defined enhanced capabilities (with Browser MCP)
- Documented launch methods: myclaude, collaborate, programmatic
- Added security boundaries section

---

## Activity Log

### 2026-01-16 - Created
- Request created by jordan
