---
type: commit
from: the-agency/jordan/fix-release-notes-meta
to: the-agency/jordan/captain
date: 2026-08-12T13:01
status: created
priority: normal
subject: "Committed 7101e6f4 on fix-release-notes-meta: fix(captain-release-notes): land the rename-review findings — v1.2.0→1.3.0, skills-index 10/64, rename records

Completeness fixes the #426 rename (PR #471) shipped without — devex's rename
review found these but stalled before reporting, and I signed the landing
receipt as 'mechanical, no findings' prematurely. Fixing now:
- TOOL_VERSION 1.2.0 → 1.3.0 (+ bats --version assertion) — user-visible rename
  deserves a version boundary; telemetry log_start key split is now marked.
- REFERENCE-SKILLS-INDEX retrofit count 9/63 → 10/64 (captain-release-notes was
  added but not counted).
- Rename recorded in the tool header comment and the skill Status line."
in_reply_to: null
---

# Committed 7101e6f4 on fix-release-notes-meta: fix(captain-release-notes): land the rename-review findings — v1.2.0→1.3.0, skills-index 10/64, rename records

Completeness fixes the #426 rename (PR #471) shipped without — devex's rename
review found these but stalled before reporting, and I signed the landing
receipt as 'mechanical, no findings' prematurely. Fixing now:
- TOOL_VERSION 1.2.0 → 1.3.0 (+ bats --version assertion) — user-visible rename
  deserves a version boundary; telemetry log_start key split is now marked.
- REFERENCE-SKILLS-INDEX retrofit count 9/63 → 10/64 (captain-release-notes was
  added but not counted).
- Rename recorded in the tool header comment and the skill Status line.

## Commit: 7101e6f4

**Branch:** fix-release-notes-meta
**Agent:** the-agency/jordan/fix-release-notes-meta
**Message:** housekeeping/captain: fix(captain-release-notes): land the rename-review findings — v1.2.0→1.3.0, skills-index 10/64, rename records

Completeness fixes the #426 rename (PR #471) shipped without — devex's rename
review found these but stalled before reporting, and I signed the landing
receipt as 'mechanical, no findings' prematurely. Fixing now:
- TOOL_VERSION 1.2.0 → 1.3.0 (+ bats --version assertion) — user-visible rename
  deserves a version boundary; telemetry log_start key split is now marked.
- REFERENCE-SKILLS-INDEX retrofit count 9/63 → 10/64 (captain-release-notes was
  added but not counted).
- Rename recorded in the tool header comment and the skill Status line.

### Metadata
- commit_hash: 7101e6f4
- branch: fix-release-notes-meta
- files_changed: 7
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/captain-release-notes/SKILL.md
agency/REFERENCE/REFERENCE-SKILLS-INDEX.md
agency/tools/captain-release-notes
src/agency/REFERENCE/REFERENCE-SKILLS-INDEX.md
src/agency/tools/captain-release-notes
src/claude/skills/captain-release-notes/SKILL.md
src/tests/tools/captain-release-notes.bats
```
