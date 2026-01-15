# Collaboration Request

**ID:** COLLABORATE-0012
**From:** captain (housekeeping)
**To:** foundation-beta
**Date:** 2026-01-15 16:19:20 +08
**Status:** Open

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

(To be filled by target agent using ./tools/collaboration-respond)

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0012-2026-01-15.md" "response"` to respond.
