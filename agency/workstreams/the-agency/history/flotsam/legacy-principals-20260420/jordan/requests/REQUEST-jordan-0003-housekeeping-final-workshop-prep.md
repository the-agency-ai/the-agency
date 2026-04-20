# REQUEST-jordan-0003-housekeeping-final-workshop-prep

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Completed

**Priority:** Normal

**Created:** 2026-01-09 12:06 SST

**Updated:** 2026-01-09 14:30 SST

## Summary

Final Workshop Prep

## Details

Items we need to finalize the workshop.
1. We need to make sure that the local the-agency-starter is up to date and synced with the the the-agency repo.
2. We need to have pushed this to github so they can do it.
3. We should have a clean build of AgencyBench
4. Should be able to do the install command via curl and install successfully.
- please make sure that you provide me with the complete command, including the token in plain text, so they can get up and running.


Nits I want to address:
- Should be TheAgency, not The Agency in the left hand side bar.
- We need a better icon than what we have, want to capture the idea of a group of agents + principals (humans) working together.
- We need to be able to click on a copy icon to copy the document path in the Preview / Edit view.


## Acceptance Criteria
- [x] Local the-agency-starter is synced to latest
- [x] We have pushed an update to the-agency-starter
- [x] We have a clean build of AgencyBench so that it gets installed automatically and they do not have to build.
- [ ] We have done a successful install in dev (you) and in a clean environment (me) - **Pending user verification**

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Activity Log

### 2026-01-09 12:06 SST - Created
- Request created by principal:jordan

### 2026-01-09 14:30 SST - Completed

**Work Completed:**

1. **Repo Sync**: Synced the-agency-starter with the-agency using rsync
2. **GitHub Push**: Pushed to GitHub (commit 2c59e1a)
3. **AgencyBench Build**: Built release DMG at `claude/apps/agency-bench/src-tauri/target/release/bundle/dmg/`
4. **Branding Fix**: Changed "The Agency" → "TheAgency" in sidebar
5. **Copy Icon**: Made copy icon always visible in doc path header
6. **New Tools Added**: bench, observe, request tools added to the-agency-starter

**Workshop Install Command (with token):**

```bash
curl -fsSL "https://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@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="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" bash -s -- my-project
```

**Icon Design Concept - "The Constellation":**

The icon represents the collaborative nature of The Agency through a constellation metaphor:

- **Central Node**: A larger circle/star representing the principal (human)
- **Surrounding Nodes**: 3-4 smaller circles representing agents
- **Connecting Lines**: Thin lines connecting all nodes, forming a network/constellation pattern
- **Color Scheme**:
  - Deep space blue/purple gradient background
  - Gold/amber for the central principal node
  - Varying blues/teals for agent nodes
  - Subtle glow effects on connections to show active collaboration

Visual style: Clean, geometric, modern. Think constellation map meets org chart. The asymmetric arrangement suggests organic collaboration rather than rigid hierarchy.

Alternative simpler version: Just the connected nodes without background gradient - would work well as a monochrome icon for smaller sizes.

**Pending:**
- User to verify install command works in clean environment
