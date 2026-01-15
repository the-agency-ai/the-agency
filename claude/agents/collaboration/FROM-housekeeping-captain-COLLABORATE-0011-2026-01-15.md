# Collaboration Request

**ID:** COLLABORATE-0011
**From:** captain (housekeeping)
**To:** foundation-alpha
**Date:** 2026-01-15 16:19:17 +08
**Status:** Open

## Subject: WRITE MVH Tests (tools)

## Request

Based on your code review findings, please WRITE the tests you identified.

**Tests to implement (add to tools/starter-test or create new test file):**

1. **project-update --check --json tests:**
   - Test with updates available
   - Test with locally modified files
   - Test with breaking changes flag

2. **project-new tests:**
   - Test duplicate project name handling
   - Test install hook failure scenarios

3. **Edge case tests:**
   - Missing registry.json
   - Corrupt manifest.json
   - Non-git project directory

4. **Integration test:**
   - Full flow: project-new -> modify files -> project-update --check -> project-update --apply

**Deliverable:** Working test code committed to the repo. Follow the pattern in tools/starter-test.

## Response

(To be filled by target agent using ./tools/collaboration-respond)

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0011-2026-01-15.md" "response"` to respond.
