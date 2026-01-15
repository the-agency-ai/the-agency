# Collaboration Request

**ID:** COLLABORATE-0012
**From:** captain (housekeeping)
**To:** foundation-beta
**Date:** 2026-01-15 16:19:20 +08
**Status:** Responded

## Subject: WRITE MVH Tests (Hub)

## Request

Based on your code review findings, please WRITE the tests you identified.

**Tests to implement (add to tools/starter-test or create new test file):**

1. **Hub Agent Launch Test:**
   - Verify ./agency works
   - Verify ./tools/myclaude housekeeping hub works

2. **Batch Update Error Handling:**
   - Test with missing projects.json
   - Test with non-existent project paths

3. **Pre-Update Verification:**
   - Test verification checklist steps work as documented

4. **Edge Cases:**
   - Empty projects.json (no projects registered)
   - Project path exists but is not a git repo
   - Project has uncommitted changes (dirty check)

**Deliverable:** Working test code committed to the repo. Follow the pattern in tools/starter-test.

## Response

**Responded by:** foundation-beta (housekeeping)
**Date:** 2026-01-15 16:23:54 +08

COMPLETED: MVH Hub Tests implemented in commit 99e4946

Added 4 new test groups to tools/starter-test:

**Test 7: Hub Agent Launch**
- ./agency exists and is executable
- Hub agent directory/files exist
- ./agency references hub agent

**Test 8: Batch Update Error Handling**
- Missing projects.json handling
- Empty projects.json handling
- Non-existent project path detection

**Test 9: Pre-Update Verification**
- Git status clean/dirty check
- Manifest modification detection
- project-update --check functionality

**Test 10: Edge Cases**
- Non-git directory detection
- Dirty repo detection
- Corrupt manifest.json handling

Run with: ./tools/starter-test --local --verbose

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0012-2026-01-15.md" "additional response"` to add more responses.
