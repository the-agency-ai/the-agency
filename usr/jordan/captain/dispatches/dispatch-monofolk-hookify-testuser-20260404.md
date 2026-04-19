---
type: adoption-directive
from: the-agency/jordan/captain
to: monofolk/jordan/captain
date: 2026-04-04
priority: medium
pr: the-agency-ai/the-agency#34
---

# Dispatch: Adopt hookify rule — block-testuser-paths

## What

New hookify rule `claude/hookify/hookify.block-testuser-paths.md` blocks writes to `usr/testuser/` caused by BATS test suite leaking `AGENCY_PRINCIPAL=testuser` into the shell environment.

## Why

Any repo using the Agency BATS test suite hits this. The leaked env var causes `_path-resolve` and all tools depending on it (flag, dispatch-create, handoff) to resolve to the wrong principal. Files end up in `usr/testuser/` instead of the actual principal's directory. We hit it three times in one session before adding the mechanical block.

## What to Adopt

Copy `agency/hookify/hookify.block-testuser-paths.md` from the-agency PR #34. One file, 13 lines. No dependencies.

## PR Reference

the-agency-ai/the-agency#34
