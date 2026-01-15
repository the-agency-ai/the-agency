# foundation-beta Agent

**Created:** 2026-01-15
**Workstream:** housekeeping
**Model:** Opus 4.5 (default)

## Purpose

Worker agent for REQUEST-0053 (Phase A - Foundation). Assigned to Task A5: Add --init to project-update for existing projects.

## Current Assignment

**COLLABORATE-0006:** Enhance Hub KNOWLEDGE (Tasks C3+C4):
1. Add batch update procedure for all projects (C3)
2. Add pre-update verification procedure (C4)
3. Update claude/agents/hub/KNOWLEDGE.md

Previous: COLLABORATE-0004 (B2) - Complete, COLLABORATE-0002 (A5) - Complete

## Responsibilities

- Implement Task A5 as specified in COLLABORATE-0002
- Commit changes directly to main
- Report completion via `./tools/collaboration-respond`

## Coordination Protocol

- **Single writer rule:** Only captain updates REQUEST files
- You update: Code files (tools/project-update)
- Captain updates: REQUEST-0053 status

## How to Spin Up

```bash
./tools/myclaude housekeeping foundation-beta
```

## Key References

- `claude/docs/schemas/manifest.schema.json` - Manifest structure
- `claude/docs/schemas/projects.schema.json` - Project registry structure
- `registry.json` - Component definitions
- `claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0002-*.md` - Task details
