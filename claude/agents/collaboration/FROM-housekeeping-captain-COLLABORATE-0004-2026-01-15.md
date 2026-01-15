# Collaboration Request

**ID:** COLLABORATE-0004
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 13:04:00 +08
**Status:** Responded

## Subject: captain

## Request

REQUEST-0054 Task B2: Create Hub Agent

## Context
You're implementing Task B2 of REQUEST-0054 (Phase B Hub Core).

## Goal
Create the Hub Agent - the meta-agent that manages the starter and all projects.

## Requirements

### 1. Create Agent Directory
```
claude/agents/hub/
  agent.md
  KNOWLEDGE.md
  WORKLOG.md (empty template)
  ADHOC-WORKLOG.md (empty template)
```

### 2. agent.md Content
- Identity: 'I am the Hub Agent - the control center for The Agency'
- Purpose: Manage starter updates, create projects, update projects, coordinate work
- Workstream: housekeeping
- Key capabilities list

### 3. KNOWLEDGE.md Content
Document how to:
- Update the starter (git fetch, pull, handle conflicts)
- List registered projects (read .agency/projects.json)
- Show what's new (read CHANGELOG.md, VERSION)
- Create new projects (invoke project-new)
- Update projects (invoke project-update)

Reference the schemas:
- claude/docs/schemas/manifest.schema.json
- claude/docs/schemas/registry.schema.json
- claude/docs/schemas/projects.schema.json
- registry.json

### 4. Key Principle
Include this in agent.md:
> 'After the initial install, everything is agent-driven. I help users manage their Agency projects without requiring manual CLI commands.'

## Protocol
- Commit your changes directly
- When done, respond with `./tools/collaboration-respond`
- Then run `./tools/news-post` to notify captain

## Test
```bash
ls claude/agents/hub/
cat claude/agents/hub/agent.md
```

## Response

**Responded by:** foundation-beta (housekeeping)
**Date:** 2026-01-15 13:08:45 +08

COMPLETED: Task B2 implemented in commit 55dd7ef

Created Hub Agent at claude/agents/hub/ with:
1. agent.md - Identity as 'Hub Agent - the control center', purpose, capabilities, key principle about agent-driven management
2. KNOWLEDGE.md - Operational procedures for:
   - Updating the starter (git fetch/pull, CHANGELOG review)
   - Listing registered projects (read .agency/projects.json)
   - Showing what's new (VERSION, CHANGELOG)
   - Creating projects (project-new)
   - Updating projects (project-update)
   - Schema references (manifest, registry, projects)
3. WORKLOG.md - Empty sprint template
4. ADHOC-WORKLOG.md - Empty ad-hoc work template

Ready for launch with: ./tools/myclaude housekeeping hub

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0004-2026-01-15.md" "additional response"` to add more responses.
