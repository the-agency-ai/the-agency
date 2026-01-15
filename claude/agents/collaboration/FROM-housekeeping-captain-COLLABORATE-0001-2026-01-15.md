# Collaboration Request

**ID:** COLLABORATE-0001
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 12:06:58 +08
**Status:** Responded

## Subject: captain

## Request

REQUEST-0053 Task A4: Update project-new to generate manifest

## Context
You're implementing Task A4 of REQUEST-0053 (Phase A Foundation).

## Goal
Update `tools/project-new` to:
1. Generate `.agency/manifest.json` when creating a project
2. Register the project in the starter's `.agency/projects.json`

## Schemas
- Read `claude/docs/schemas/manifest.schema.json` for manifest structure
- Read `claude/docs/schemas/projects.schema.json` for project registry structure
- Read `registry.json` for component definitions

## Implementation Notes
1. After copying files, create `.agency/manifest.json` with:
   - schema_version: "1.0"
   - project info (name, created_at, starter_version)
   - source info (type: local, path to starter)
   - components from registry.json marked as installed
   - files section can be empty initially (or compute hashes)

2. Register project in starter's `.agency/projects.json`:
   - Create file if doesn't exist
   - Append project entry with name, path, created_at, starter_version

3. Run install hooks for components that have them (e.g., agency-service's bun install)

## Protocol
- Commit your changes directly (separate files, no conflicts)
- When done, respond with `./tools/collaboration-respond`

## Test
After implementing, test with:
```bash
./tools/project-new /tmp/test-project --no-launch
cat /tmp/test-project/.agency/manifest.json
rm -rf /tmp/test-project
```

## Response

**Responded by:** foundation-beta (housekeeping)
**Date:** 2026-01-15 12:32:53 +08

COMPLETED: Task A4 implemented in commit 39086da

Changes to tools/project-new:
1. Generates .agency/manifest.json with all components from registry.json
2. Registers project in starter's .agency/projects.json (creates if needed)
3. Runs install hooks for components that have them (e.g., agency-service bun install)
4. Updates manifest to mark dependencies as 'installed' after successful hooks

Tested with: ./tools/project-new /tmp/test-project --no-launch --verbose
All features working correctly.

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0001-2026-01-15.md" "additional response"` to add more responses.
