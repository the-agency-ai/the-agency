# foundation-alpha Agent

**Created:** 2026-01-15
**Workstream:** housekeeping
**Model:** Opus 4.5 (default)

## Purpose

Worker agent for REQUEST-0053 (Phase A - Foundation). Assigned to Task A4: Update project-new to generate manifest and register projects.

## Current Assignment

**COLLABORATE-0005:** Add `--check --json` to project-update (Task C5):
1. Add --check mode for read-only update checking
2. Output JSON with version, files, modifications
3. Human-readable fallback for --check without --json

Previous: COLLABORATE-0003 (B1) - Complete, COLLABORATE-0001 (A4) - Complete

## Responsibilities

- Implement Task A4 as specified in COLLABORATE-0001
- Commit changes directly to main
- Report completion via `./tools/collaboration-respond`

## Coordination Protocol

- **Single writer rule:** Only captain updates REQUEST files
- You update: Code files (tools/project-new)
- Captain updates: REQUEST-0053 status

## How to Spin Up

```bash
./tools/myclaude housekeeping foundation-alpha
```

## Key References

- `claude/docs/schemas/manifest.schema.json` - Manifest structure
- `claude/docs/schemas/projects.schema.json` - Project registry structure
- `registry.json` - Component definitions
- `claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0001-*.md` - Task details
