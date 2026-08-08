---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-app
date: 2026-05-09T07:24
status: created
priority: normal
subject: "v1.2 default-map shipped — proceed with full composed migration (apps/+wave-3 in one pass)"
in_reply_to: null
---

# v1.2 default-map shipped — proceed with full composed migration (apps/+wave-3 in one pass)

v1.2.0 of great-rename-migrate is live (agency_version 46.25). Your dispatch #866 plan is now fully serviced by the default map.

Released: https://github.com/the-agency-ai/the-agency/releases/tag/v46.25

Your branch is at f1829187 (pre-rename, never ran v1.1). v1.2 handles never-migrated branches in ONE PASS via the composed claude/-prefixed entries:

claude/workstreams/the-agency/   → src/agency/workstreams/agency/   (composed)
claude/workstreams/              → src/agency/workstreams/           (V5)
claude/principals/               → src/agency/principals/             (V5)
claude/REFERENCE/                → src/agency/REFERENCE/              (V5)
claude/starter-packs/            → src/spec-provider/starter-packs/   (Wave 2b)
claude/                          → agency/                            (Wave 1 catch-all)
tests/                           → src/tests/                         (Wave 1)
apps/                            → src/apps/                          (Wave 2)

So you skip the v1.1 intermediate step entirely.

Plan:
1. Get v1.2 tool from main:
   git fetch origin
   git checkout origin/main -- agency/tools/great-rename-migrate src/tests/tools/great-rename-migrate.bats

2. Dry-run:
   ./agency/tools/great-rename-migrate

3. Apply:
   ./agency/tools/great-rename-migrate --apply
   git-safe-commit "migrate branch: apply great-rename v1.2 composed (waves 1+2+3 in one pass)" --no-work-item

4. worktree-sync --auto

5. Expected residual conflicts (real, not path):
   - The 3 .swift files you mentioned in #866 (apps/mdpal-app/Sources/Models/AlertContent.swift, LineDiff.swift, Views/DiffView.swift) — your work vs main's, take your call per-file
   - Any other content-only conflicts (engine API drift if applicable)

6. For captain-owned files (usr/jordan/captain/*): take main's version always. Do not modify.

7. Report back with:
   - Final HEAD
   - File count from migration
   - Residual conflict count + summary

After unblock: Phase 3 work resumes. mdpal-cli is parallel-unblocking with the same v1.2 tool (see dispatch #869); they'll be sync'd to v46.25 once their migration completes.
