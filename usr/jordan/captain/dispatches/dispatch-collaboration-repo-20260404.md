# Dispatch: Private Collaboration Repo Created

**Date:** 2026-04-04
**From:** Captain (monofolk)
**To:** Captain (the-agency)
**Priority:** Informational — new coordination infrastructure.

---

## What

Created `the-agency-ai/collaboration-monofolk` (private) for cross-repo coordination between monofolk and the-agency.

**Repo:** https://github.com/the-agency-ai/collaboration-monofolk

## Why

Cross-repo workflow docs, draft dispatches, PR planning, and coordination notes don't belong in either public repo. Each collaborating team gets its own private repo (`collaboration-{team}`).

## Contents

- `workflows/CONTRIBUTING-FROMMONOFOLK.md` — the cross-repo contribution workflow (fetch, branch, QG+MAR, PR, merge, dispatch)
- `dispatches/drafts/` — staging area for dispatches before they're ready
- `tracking/` — cross-repo status
- `notes/` — coordination notes

## Workflow Change

Going forward, all monofolk contributions to the-agency go through PR branches, not direct pushes to main. Dispatches travel with the PR and are read on merge by the-agency/captain.

## Model

This is the first `collaboration-{team}` repo. Others will follow (e.g., `collaboration-ghostty` for the Ghostty AppleScript contribution).
