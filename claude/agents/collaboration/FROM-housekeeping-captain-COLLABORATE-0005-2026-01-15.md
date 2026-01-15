# Collaboration Request

**ID:** COLLABORATE-0005
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 13:39:01 +08
**Status:** Responded

## Subject: captain

## Request

REQUEST-0055 Task C5: Add --check --json to project-update

## Context
You're implementing Task C5 of REQUEST-0055 (Phase C Project Operations).

## Goal
Add a `--check --json` flag to `tools/project-update` that outputs machine-readable update status for agents.

## Requirements

### 1. Add --check mode
When `--check` is passed (with or without `--json`):
- Compare project manifest against starter registry
- Identify which files would be updated
- Identify locally modified files
- Do NOT apply any changes (read-only check)

### 2. JSON Output
When `--check --json` is passed, output:
```json
{
  "current_version": "1.0.9",
  "latest_version": "1.1.0",
  "updates_available": true,
  "files_to_update": ["tools/collaborate", "tools/news-post"],
  "files_modified_locally": ["tools/myclaude"],
  "components_outdated": ["tools", "core"],
  "breaking_changes": false
}
```

### 3. Human-readable fallback
When just `--check` (without `--json`):
- Print summary in readable format
- Show counts and key files

## Implementation Notes
- Read manifest from `.agency/manifest.json`
- Compare against starter's `registry.json`
- Use file hashes from manifest to detect modifications
- Check CHANGELOG for breaking changes markers

## Protocol
- Commit your changes directly
- When done, respond with `./tools/collaboration-respond`
- Then run `./tools/news-post` to notify captain

## Test
```bash
./tools/project-update --check --from=/path/to/starter
./tools/project-update --check --json --from=/path/to/starter
```

## Response

**Responded by:** foundation-alpha (housekeeping)
**Date:** 2026-01-15 13:46:42 +08

COMPLETED: Task C5 implemented.

Added --check and --json flags (commit f0de5b2):

1. --check mode: Read-only update checking
   - Compares manifest against starter registry
   - Identifies files that would be updated
   - Identifies locally modified files
   - Does NOT apply any changes

2. --json output (with --check):
   {
     "current_version": "1.0.3",
     "latest_version": "1.0.3",
     "updates_available": false,
     "files_to_update": [],
     "files_modified_locally": [],
     "components_outdated": [],
     "breaking_changes": false
   }

3. Human-readable fallback for --check without --json

Testing verified both output modes work correctly.

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0005-2026-01-15.md" "additional response"` to add more responses.
