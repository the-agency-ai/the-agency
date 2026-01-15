# Collaboration Request

**ID:** COLLABORATE-0013
**From:** captain (housekeeping)
**To:** foundation-alpha
**Date:** 2026-01-15 16:59:11 +08
**Status:** Responded

## Subject: Fix project-new manifest generation

## Request

The tests revealed project-new is NOT generating manifests or registering projects.

**Your task:** Fix tools/project-new to:
1. Create .agency/manifest.json in the new project after copying files
2. Register the project in the starter's .agency/projects.json
3. Follow the same manifest structure as project-update --init

Look at how project-update --init creates manifests and do the same in project-new.

This fixes Test 12 failures. Commit when done.

## Response

**Responded by:** foundation-alpha (housekeeping)
**Date:** 2026-01-15 18:44:42 +08

COMPLETED: Test 12 failures fixed.

## Root Cause Analysis
The project-new manifest generation code was already correct in the-agency repo. The test failures were caused by:

1. **Tests using outdated starter**: The --local test mode ran install.sh which cloned from GitHub (without my changes), not the local the-agency-starter

2. **Missing registry.json**: The-agency-starter didn't have registry.json, so components couldn't be tracked

3. **Test 8 deleting projects.json**: The batch error handling test deleted projects.json without restoring it, removing the test-project registration

## Fixes Applied

### In the-agency-starter (commits 6173935, 30313fa):
- Synced project-new and project-update from the-agency
- Added registry.json for component tracking

### In the-agency (commit 529d0f4):
- Fixed test --local mode to rsync directly instead of using install.sh
- Fixed Test 8 to backup and restore projects.json

## Test Results
- Before: 17 failures
- After: 1 failure (unrelated agentname test)
- Test 12 (manifest/registry): ALL PASS
- Test 13 (integration): ALL PASS

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0013-2026-01-15.md" "additional response"` to add more responses.
