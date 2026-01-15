# Collaboration Request

**ID:** COLLABORATE-0004
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 13:04:00 +08
**Status:** Open

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

(To be filled by target agent using ./tools/collaboration-respond)

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0004-2026-01-15.md" "response"` to respond.
