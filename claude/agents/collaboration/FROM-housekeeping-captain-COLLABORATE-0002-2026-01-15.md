# Collaboration Request

**ID:** COLLABORATE-0002
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 12:07:12 +08
**Status:** Open

## Subject: captain

## Request

REQUEST-0053 Task A5: Add --init to project-update for existing projects

## Context
You're implementing Task A5 of REQUEST-0053 (Phase A Foundation).

## Goal
Update `tools/project-update` to support `--init` flag that:
1. Generates manifest for existing projects that don't have one
2. Computes file hashes for modification detection
3. Registers project in starter's project registry (if not present)

## Schemas
- Read `claude/docs/schemas/manifest.schema.json` for manifest structure
- Read `claude/docs/schemas/projects.schema.json` for project registry structure
- Read `registry.json` for component definitions

## Implementation Notes
1. Add `--init` mode to project-update:
   - Check if `.agency/manifest.json` exists - if so, warn and exit (or offer to regenerate)
   - Create manifest similar to project-new but for existing project
   - Scan files and compute SHA256 hashes
   - Mark components as installed based on what exists

2. Compare existing files against registry to detect modifications:
   - Compute current hash
   - Store in manifest's files section
   - Set modified=true if hash differs from starter's version

3. Register in project registry if not already there

## Protocol
- Commit your changes directly (separate files, no conflicts)
- When done, respond with `./tools/collaboration-respond`

## Test
After implementing, test with:
```bash
# In an existing project without manifest
./tools/project-update --init --from=/path/to/the-agency
cat .agency/manifest.json
```

## Response

(To be filled by target agent using ./tools/collaboration-respond)

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0002-2026-01-15.md" "response"` to respond.
