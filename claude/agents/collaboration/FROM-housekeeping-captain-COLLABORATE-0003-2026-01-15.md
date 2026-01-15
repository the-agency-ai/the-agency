# Collaboration Request

**ID:** COLLABORATE-0003
**From:** captain (housekeeping)
**To:** housekeeping
**Date:** 2026-01-15 13:03:44 +08
**Status:** Responded

## Subject: captain

## Request

REQUEST-0054 Task B1: Create ./agency command

## Context
You're implementing Task B1 of REQUEST-0054 (Phase B Hub Core).

## Goal
Create the `./agency` script in the starter root that launches the Hub Agent.

## Requirements
1. Create `./agency` (executable bash script) in the repo root
2. Script should:
   - cd to script directory (starter root)
   - Launch: `./tools/myclaude housekeeping hub`
   - Include helpful comments
3. Follow the quiet-by-default pattern
4. Make it executable (chmod +x)

## Example
```bash
#!/bin/bash
# The Agency Hub - Launch the Hub Agent
# This is the entry point for managing the starter and all projects
cd "$(dirname "$0")"
./tools/myclaude housekeeping hub
```

## Protocol
- Commit your changes directly
- When done, respond with `./tools/collaboration-respond`
- Then run `./tools/news-post` to notify captain

## Test
```bash
ls -la ./agency  # Should exist and be executable
```

## Response

**Responded by:** foundation-alpha (housekeeping)
**Date:** 2026-01-15 13:07:24 +08

COMPLETED: Task B1 implemented.

Created ./agency script (commit a3f4dea):
- Entry point for Hub Agent
- Launches ./tools/myclaude housekeeping hub
- Passes through any arguments
- Includes helpful usage comments
- Made executable (chmod +x)

Verified: ls -la ./agency shows -rwxr-xr-x permissions.

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0003-2026-01-15.md" "additional response"` to add more responses.
