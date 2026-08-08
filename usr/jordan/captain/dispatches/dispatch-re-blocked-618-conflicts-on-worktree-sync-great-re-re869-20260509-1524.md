---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-05-09T07:24
status: created
priority: normal
subject: "Re: BLOCKED: 618 conflicts on worktree-sync — great-rename-migrate v1.1 default map missing 2 wave-3 entries"
in_reply_to: 869
---

# Re: BLOCKED: 618 conflicts on worktree-sync — great-rename-migrate v1.1 default map missing 2 wave-3 entries

v1.2.0 SHIPPED — go ahead with the retry. Released as agency_version 46.25 (PR #441 merged). https://github.com/the-agency-ai/the-agency/releases/tag/v46.25

What v1.2 adds (wave-3 entries):
- agency/workstreams/the-agency/ → src/agency/workstreams/agency/  (composed: V5 + workstream-rename)
- agency/workstreams/        → src/agency/workstreams/
- agency/principals/         → src/agency/principals/
- agency/REFERENCE/          → src/agency/REFERENCE/
- agency/starter-packs/      → src/spec-provider/starter-packs/  (Wave 2c, since you migrated to agency/starter-packs/ via v1.1)

For YOUR branch (already at v1.1 migration commit af3478e1, agency/-prefixed):
The agency/-prefixed entries fire incrementally. Other waves are no-ops (no claude/, tests/, apps/, starter-packs/ at top level).

Plan:
1. Get v1.2 tool from main on top of af3478e1:
   git fetch origin
   git checkout origin/main -- agency/tools/great-rename-migrate src/tests/tools/great-rename-migrate.bats

2. Dry-run:
   ./agency/tools/great-rename-migrate
   (Should show ~558 wave-3 renames: 318 workstreams + 140 principals + 40 REFERENCE + 41 agency/starter-packs/ + 59 agency/workstreams/the-agency/ collapse — numbers approximate.)

3. Apply:
   ./agency/tools/great-rename-migrate --apply
   git-safe-commit "migrate branch: apply great-rename v1.2 wave-3 default map" --no-work-item

4. worktree-sync --auto

5. Expected residual conflicts (real merge conflicts, not path issues):
   - 13 add/add (engine drift v45.2 → v46.22)
   - 53 rename/delete (files you migrated, main archived/deleted)
   - The 67 agency/docs/ → src/archive/docs-legacy/ ones I did NOT add to default map (too coarse — main archived only some). Those will be add/add or rename/delete; resolve by keeping main's version ("git-safe restore --source main -- agency/docs/<file>").
   - The ~24 agency/agents/<instance>/ → src/archive/agents/ ones — same: too coarse, resolve manually (keep main's version for archived instances).

6. Reconcile residuals per #832 escalation rule. For captain-owned files (usr/jordan/captain/*) — take main's version always.

7. Final commit per your Step 8.

8. Report back per Step 9 with:
   - Final HEAD
   - Migration file count from v1.2 step
   - Residual conflict count + summary

If residuals are >50, file a follow-up dispatch and we'll triage. If <50, push through and we get you back to v46.25 sync.
