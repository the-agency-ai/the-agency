---
type: commit
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency/jordan/captain
date: 2026-08-11T09:03
status: created
priority: normal
subject: "Committed 386fdbf1 on devex-publish-path-repo-root: fix(publish-path): QG findings — -C was inert in a real captain session

The quality gate found the first cut of this change did not fix the bug it was
written for, and that my own tests hid it.

git-safe-commit passed -C "$PROJECT_ROOT", but PROJECT_ROOT prefers
CLAUDE_PROJECT_DIR and only falls back to the cwd toplevel. Claude Code sets
that variable to the MAIN CHECKOUT, so in any real captain session -C forwarded
the main checkout — exactly the leak it was meant to stop. Both new suites ran
with CLAUDE_PROJECT_DIR unset, so all of them passed, and one asserted the code
was cwd-derived by grepping a string that lives in the elif branch.

Derives COMMIT_REPO_ROOT strictly from git rev-parse --show-toplevel and passes
that. PROJECT_ROOT keeps its precedence — it exists for the per-agent
attribution lookup, which really is a property of the session. Adds a test that
runs step 4 with CLAUDE_PROJECT_DIR set to the captain root; it fails against
the old code while the two env-free tests still pass, which is what makes it
worth having. The captain fixture's .agency-agent also stops being literally
'captain', since the never-dispatch-to-self guard was silently suppressing the
announce and letting the locality assertions pass vacuously.

Also from the gate:
- pr-create ran receipt-verify in the caller's cwd while discovering the receipt
  under -C. diff-hash is cwd-based, so a receipt found in one tree could be
  graded against another; the land flow only agreed by luck because it also cd's.
  Now wrapped in (cd "$REPO_ROOT").
- dispatch derived the ISCP DB name from agency.yaml under the RETARGETED root —
  branch-supplied data. A branch editing repo.name would divert its dispatches to
  a different database. ISCP_DB_PATH is now pinned from the install root before
  the override, so -C moves the payload and not the index.
- receipt-sign checked only --workstream for traversal while interpolating five
  more components into the filename; -C made the write root caller-chosen too.
  All six are checked now.
- Both suites git init -b main: with GIT_CONFIG_GLOBAL nulled the default branch
  is the git build's, so the pr-create branch assertion passed on macOS and would
  have failed on Linux CI.
- Replaced an unmatchable sed range with grep -A2, and corrected the allowlist
  rationale that rested on the false cwd-derived claim.

Deferred with reasons recorded in the QGR: pr-create's relative --body-file under
-C (latent, no current caller), dispatch's stale AGENCY_PRINCIPAL and cwd-relative
read strategies (pre-existing, unreachable from the land call sites)."
in_reply_to: null
---

# Committed 386fdbf1 on devex-publish-path-repo-root: fix(publish-path): QG findings — -C was inert in a real captain session

The quality gate found the first cut of this change did not fix the bug it was
written for, and that my own tests hid it.

git-safe-commit passed -C "$PROJECT_ROOT", but PROJECT_ROOT prefers
CLAUDE_PROJECT_DIR and only falls back to the cwd toplevel. Claude Code sets
that variable to the MAIN CHECKOUT, so in any real captain session -C forwarded
the main checkout — exactly the leak it was meant to stop. Both new suites ran
with CLAUDE_PROJECT_DIR unset, so all of them passed, and one asserted the code
was cwd-derived by grepping a string that lives in the elif branch.

Derives COMMIT_REPO_ROOT strictly from git rev-parse --show-toplevel and passes
that. PROJECT_ROOT keeps its precedence — it exists for the per-agent
attribution lookup, which really is a property of the session. Adds a test that
runs step 4 with CLAUDE_PROJECT_DIR set to the captain root; it fails against
the old code while the two env-free tests still pass, which is what makes it
worth having. The captain fixture's .agency-agent also stops being literally
'captain', since the never-dispatch-to-self guard was silently suppressing the
announce and letting the locality assertions pass vacuously.

Also from the gate:
- pr-create ran receipt-verify in the caller's cwd while discovering the receipt
  under -C. diff-hash is cwd-based, so a receipt found in one tree could be
  graded against another; the land flow only agreed by luck because it also cd's.
  Now wrapped in (cd "$REPO_ROOT").
- dispatch derived the ISCP DB name from agency.yaml under the RETARGETED root —
  branch-supplied data. A branch editing repo.name would divert its dispatches to
  a different database. ISCP_DB_PATH is now pinned from the install root before
  the override, so -C moves the payload and not the index.
- receipt-sign checked only --workstream for traversal while interpolating five
  more components into the filename; -C made the write root caller-chosen too.
  All six are checked now.
- Both suites git init -b main: with GIT_CONFIG_GLOBAL nulled the default branch
  is the git build's, so the pr-create branch assertion passed on macOS and would
  have failed on Linux CI.
- Replaced an unmatchable sed range with grep -A2, and corrected the allowlist
  rationale that rested on the false cwd-derived claim.

Deferred with reasons recorded in the QGR: pr-create's relative --body-file under
-C (latent, no current caller), dispatch's stale AGENCY_PRINCIPAL and cwd-relative
read strategies (pre-existing, unreachable from the land call sites).

## Commit: 386fdbf1

**Branch:** devex-publish-path-repo-root
**Agent:** the-agency/jordan/devex-publish-path-repo-root
**Message:** housekeeping/captain: fix(publish-path): QG findings — -C was inert in a real captain session

The quality gate found the first cut of this change did not fix the bug it was
written for, and that my own tests hid it.

git-safe-commit passed -C "$PROJECT_ROOT", but PROJECT_ROOT prefers
CLAUDE_PROJECT_DIR and only falls back to the cwd toplevel. Claude Code sets
that variable to the MAIN CHECKOUT, so in any real captain session -C forwarded
the main checkout — exactly the leak it was meant to stop. Both new suites ran
with CLAUDE_PROJECT_DIR unset, so all of them passed, and one asserted the code
was cwd-derived by grepping a string that lives in the elif branch.

Derives COMMIT_REPO_ROOT strictly from git rev-parse --show-toplevel and passes
that. PROJECT_ROOT keeps its precedence — it exists for the per-agent
attribution lookup, which really is a property of the session. Adds a test that
runs step 4 with CLAUDE_PROJECT_DIR set to the captain root; it fails against
the old code while the two env-free tests still pass, which is what makes it
worth having. The captain fixture's .agency-agent also stops being literally
'captain', since the never-dispatch-to-self guard was silently suppressing the
announce and letting the locality assertions pass vacuously.

Also from the gate:
- pr-create ran receipt-verify in the caller's cwd while discovering the receipt
  under -C. diff-hash is cwd-based, so a receipt found in one tree could be
  graded against another; the land flow only agreed by luck because it also cd's.
  Now wrapped in (cd "$REPO_ROOT").
- dispatch derived the ISCP DB name from agency.yaml under the RETARGETED root —
  branch-supplied data. A branch editing repo.name would divert its dispatches to
  a different database. ISCP_DB_PATH is now pinned from the install root before
  the override, so -C moves the payload and not the index.
- receipt-sign checked only --workstream for traversal while interpolating five
  more components into the filename; -C made the write root caller-chosen too.
  All six are checked now.
- Both suites git init -b main: with GIT_CONFIG_GLOBAL nulled the default branch
  is the git build's, so the pr-create branch assertion passed on macOS and would
  have failed on Linux CI.
- Replaced an unmatchable sed range with grep -A2, and corrected the allowlist
  rationale that rested on the false cwd-derived claim.

Deferred with reasons recorded in the QGR: pr-create's relative --body-file under
-C (latent, no current caller), dispatch's stale AGENCY_PRINCIPAL and cwd-relative
read strategies (pre-existing, unreachable from the land call sites).

### Metadata
- commit_hash: 386fdbf1
- branch: devex-publish-path-repo-root
- files_changed: 11
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/dispatch
agency/tools/git-safe-commit
agency/tools/pr-create
agency/tools/receipt-sign
src/agency/tools/dispatch
src/agency/tools/git-safe-commit
src/agency/tools/pr-create
src/agency/tools/receipt-sign
src/tests/skills/pr-captain-land-publish-locality.bats
src/tests/tools/repo-root-targeting.bats
usr/jordan/devex-publish-path-repo-root/dispatches/commit-to-captain-committed-8a533701-on-devex-publish-path-repo-root-20260811-1642.md
```
