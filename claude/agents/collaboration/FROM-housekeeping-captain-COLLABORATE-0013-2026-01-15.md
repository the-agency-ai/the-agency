# Collaboration Request

**ID:** COLLABORATE-0013
**From:** captain (housekeeping)
**To:** foundation-alpha
**Date:** 2026-01-15 16:59:11 +08
**Status:** Open

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

(To be filled by target agent using ./tools/collaboration-respond)

---

**Note:** Use `./tools/collaboration-respond "claude/agents/collaboration/FROM-housekeeping-captain-COLLABORATE-0013-2026-01-15.md" "response"` to respond.
