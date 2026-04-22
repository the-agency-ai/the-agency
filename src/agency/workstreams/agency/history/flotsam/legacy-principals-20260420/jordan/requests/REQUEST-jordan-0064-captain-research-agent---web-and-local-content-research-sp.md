# REQUEST-jordan-0064: Research Agent - Web and Local Content Research Specialist

**Status:** Complete
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-18
**Updated:** 2026-01-18

## Summary

Create a specialized research agent for the housekeeping workstream that can research topics in depth using both local and web resources, and produce comprehensive knowledge documents.

## Details

### Purpose

The research agent is a specialized agent that excels at:
- Deep research on technical topics
- Synthesizing information from multiple sources
- Producing well-structured knowledge documents
- Understanding The Agency's existing documentation patterns

### Capabilities Required

**Local Content Access:**
- Read and analyze existing codebase documentation
- Search through local files for relevant patterns
- Understand project structure and conventions
- Reference existing KNOWLEDGE.md files for patterns

**Web Content Access:**
- WebFetch for fetching and analyzing web pages
- WebSearch for discovering relevant sources
- Browser MCP integration (when available) for authenticated content
- Extract structured information from documentation sites

**Knowledge Production:**
- Create KNOWLEDGE.md-style documents following Agency conventions
- Cite sources appropriately
- Include practical examples and code snippets
- Structure information for discoverability

### Example Use Cases

1. **Google Docs Integration** - Research how to integrate with Google Docs from Claude Code (APIs, authentication, MCP options)
2. **Technology Evaluation** - Compare frameworks or tools for a specific use case
3. **API Documentation Synthesis** - Create a knowledge doc from scattered API documentation
4. **Pattern Research** - Research best practices for specific development patterns

### Tools Available

| Tool | Purpose |
|------|---------|
| WebFetch | Fetch and analyze web content |
| WebSearch | Search web with source citations |
| Read/Glob/Grep | Access local files and codebase |
| Browser MCP (optional) | Authenticated web access |
| Perplexity (via Browser MCP) | Deep search with AI synthesis |

### Perplexity Integration

The research agent should be able to:
1. **Consume Perplexity sessions** - Read and extract information from existing Perplexity search results (via authenticated browser session)
2. **Conduct Perplexity searches** - Initiate new searches when deeper AI-synthesized research is needed (assumes authorized session available)
3. **Cite Perplexity sources** - Properly attribute information from Perplexity including its underlying sources

### Output Format

Research results should be delivered as:
1. A KNOWLEDGE.md file in the appropriate location
2. Source citations with URLs
3. Practical code examples where applicable
4. Clear sections: Overview, Key Concepts, Implementation, Examples, Caveats, Sources

## Acceptance Criteria

- [ ] Create `agency/agents/research/agent.md` with full spec
- [ ] Define research workflow and methodology
- [ ] Document tool usage patterns
- [ ] Include example prompts for common research tasks
- [ ] Create KNOWLEDGE.md template for research output
- [ ] Test with example: "Research Google Docs integration for Claude Code"

## Deliverables

1. **Agent Spec** - `agency/agents/research/agent.md`
2. **Knowledge Template** - Template for research output documents
3. **Example Output** - Research document on Google Docs integration

## Work Completed

<!-- Document completed work here -->

---

## Activity Log

### 2026-01-18 - Created
- Request created by jordan
