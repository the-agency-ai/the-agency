---
type: commit
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
date: 2026-04-14T19:13
status: created
priority: normal
subject: "Committed 1a18718 on mdpal-cli: Phase 1.4: feat: bundle management — DocumentBundle, revisions, prune, dual latest

DocumentBundle wraps the .mdpal directory with create/open, listRevisions
(silent-skip non-revision files with documented rationale), createRevision
(refuses overwrite via fileExists guard), bumpVersion, currentDocument,
updateConfig, prune (merges resolved comments forward, gates on concurrent
writers). Dual-latest mechanism: latest.md symlink (atomic POSIX rename) +
.mdpal/latest pointer file (reconciled on open if they diverge after a
crash). BundleConfig with deterministic Yams Node encoding and STRICT type
validation (auto must be bool, keep must be > 0). VersionId helper for
parse/format with explicit ASCII-digit check (rejects +001/-001) and
cached DateFormatter. RevisionInfo and PruneResult value types. Auto-prune
surfaces failures to stderr instead of swallowing them. New EngineError
case invalidBundlePath distinguishes structural validation from runtime
bundleConflict.

Source + 51 bundle tests passing (175 total). Full QG: 6 source/design
findings fixed, 9 test gaps covered. Iteration 1.4 closes Phase 1."
in_reply_to: null
---

# Committed 1a18718 on mdpal-cli: Phase 1.4: feat: bundle management — DocumentBundle, revisions, prune, dual latest

DocumentBundle wraps the .mdpal directory with create/open, listRevisions
(silent-skip non-revision files with documented rationale), createRevision
(refuses overwrite via fileExists guard), bumpVersion, currentDocument,
updateConfig, prune (merges resolved comments forward, gates on concurrent
writers). Dual-latest mechanism: latest.md symlink (atomic POSIX rename) +
.mdpal/latest pointer file (reconciled on open if they diverge after a
crash). BundleConfig with deterministic Yams Node encoding and STRICT type
validation (auto must be bool, keep must be > 0). VersionId helper for
parse/format with explicit ASCII-digit check (rejects +001/-001) and
cached DateFormatter. RevisionInfo and PruneResult value types. Auto-prune
surfaces failures to stderr instead of swallowing them. New EngineError
case invalidBundlePath distinguishes structural validation from runtime
bundleConflict.

Source + 51 bundle tests passing (175 total). Full QG: 6 source/design
findings fixed, 9 test gaps covered. Iteration 1.4 closes Phase 1.

## Commit: 1a18718

**Branch:** mdpal-cli
**Agent:** the-agency/jordan/mdpal-cli
**Message:** housekeeping/captain: Phase 1.4: feat: bundle management — DocumentBundle, revisions, prune, dual latest

DocumentBundle wraps the .mdpal directory with create/open, listRevisions
(silent-skip non-revision files with documented rationale), createRevision
(refuses overwrite via fileExists guard), bumpVersion, currentDocument,
updateConfig, prune (merges resolved comments forward, gates on concurrent
writers). Dual-latest mechanism: latest.md symlink (atomic POSIX rename) +
.mdpal/latest pointer file (reconciled on open if they diverge after a
crash). BundleConfig with deterministic Yams Node encoding and STRICT type
validation (auto must be bool, keep must be > 0). VersionId helper for
parse/format with explicit ASCII-digit check (rejects +001/-001) and
cached DateFormatter. RevisionInfo and PruneResult value types. Auto-prune
surfaces failures to stderr instead of swallowing them. New EngineError
case invalidBundlePath distinguishes structural validation from runtime
bundleConflict.

Source + 51 bundle tests passing (175 total). Full QG: 6 source/design
findings fixed, 9 test gaps covered. Iteration 1.4 closes Phase 1.

### Metadata
- commit_hash: 1a18718
- branch: mdpal-cli
- files_changed: 8
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
apps/mdpal/Sources/MarkdownPalEngine/Bundle/BundleConfig.swift
apps/mdpal/Sources/MarkdownPalEngine/Bundle/DocumentBundle.swift
apps/mdpal/Sources/MarkdownPalEngine/Bundle/VersionId.swift
apps/mdpal/Sources/MarkdownPalEngine/Core/EngineError.swift
apps/mdpal/Tests/MarkdownPalEngineTests/BundleTests.swift
usr/jordan/mdpal-cli/dispatches/dispatch-to-captain-re-day-40-check-in-bootloader-working-resuming-1-4-20260414-1538.md
usr/jordan/mdpal-cli/dispatches/dispatch-to-captain-re-merge-from-main-clean-no-conflicts-no-blockers-20260414-2156.md
usr/jordan/mdpal/qgr-iteration-complete-1-4-880dbce-20260415-0311.md
```
