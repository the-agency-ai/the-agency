---
type: commit
from: the-agency/jordan/fix-reference-paths
to: the-agency/jordan/captain
date: 2026-08-13T02:57
status: created
priority: normal
subject: "Committed 7fd05be0 on fix-reference-paths: fix(refs): extend REFERENCE-path sweep to adopter templates + top-level READMEs

Follow-up in the same PR after review found the sweep stopped short of the
adopter-facing surface: README-GETTINGSTARTED, README-THEAGENCY, templates/
CLAUDE-USER, YOUR-FIRST-RELEASE, and the principal-v2 CLAUDE-PRINCIPAL +
captain-handoff templates all still carried pre-Rename claude/REFERENCE-*.md
pointers. These SHIP to adopters, so leaving them broken was the worst place to
stop. Fixed; all targets resolve; 0 broken active-doc pointers remain repo-wide.

Also added a parser-limitation note to the new required_reading test.

Pre-existing src-mirror drift LEFT AS-IS (both README-THEAGENCY and
CLAUDE-THEAGENCY): the running copies carry an internal 'Telemetry-Driven Tool
Discovery' section (referencing our flotsam seed) that the adopter src/ payload
deliberately omits — an intentional internal-vs-adopter difference, not rot."
in_reply_to: null
---

# Committed 7fd05be0 on fix-reference-paths: fix(refs): extend REFERENCE-path sweep to adopter templates + top-level READMEs

Follow-up in the same PR after review found the sweep stopped short of the
adopter-facing surface: README-GETTINGSTARTED, README-THEAGENCY, templates/
CLAUDE-USER, YOUR-FIRST-RELEASE, and the principal-v2 CLAUDE-PRINCIPAL +
captain-handoff templates all still carried pre-Rename claude/REFERENCE-*.md
pointers. These SHIP to adopters, so leaving them broken was the worst place to
stop. Fixed; all targets resolve; 0 broken active-doc pointers remain repo-wide.

Also added a parser-limitation note to the new required_reading test.

Pre-existing src-mirror drift LEFT AS-IS (both README-THEAGENCY and
CLAUDE-THEAGENCY): the running copies carry an internal 'Telemetry-Driven Tool
Discovery' section (referencing our flotsam seed) that the adopter src/ payload
deliberately omits — an intentional internal-vs-adopter difference, not rot.

## Commit: 7fd05be0

**Branch:** fix-reference-paths
**Agent:** the-agency/jordan/fix-reference-paths
**Message:** housekeeping/captain: fix(refs): extend REFERENCE-path sweep to adopter templates + top-level READMEs

Follow-up in the same PR after review found the sweep stopped short of the
adopter-facing surface: README-GETTINGSTARTED, README-THEAGENCY, templates/
CLAUDE-USER, YOUR-FIRST-RELEASE, and the principal-v2 CLAUDE-PRINCIPAL +
captain-handoff templates all still carried pre-Rename claude/REFERENCE-*.md
pointers. These SHIP to adopters, so leaving them broken was the worst place to
stop. Fixed; all targets resolve; 0 broken active-doc pointers remain repo-wide.

Also added a parser-limitation note to the new required_reading test.

Pre-existing src-mirror drift LEFT AS-IS (both README-THEAGENCY and
CLAUDE-THEAGENCY): the running copies carry an internal 'Telemetry-Driven Tool
Discovery' section (referencing our flotsam seed) that the adopter src/ payload
deliberately omits — an intentional internal-vs-adopter difference, not rot.

### Metadata
- commit_hash: 7fd05be0
- branch: fix-reference-paths
- files_changed: 14
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/README-GETTINGSTARTED.md
agency/README-THEAGENCY.md
agency/templates/CLAUDE-USER.md
agency/templates/YOUR-FIRST-RELEASE.md
agency/templates/principal-v2/CLAUDE-PRINCIPAL.md.template
agency/templates/principal-v2/captain-handoff.md.template
src/agency/README-GETTINGSTARTED.md
src/agency/README-THEAGENCY.md
src/agency/templates/CLAUDE-USER.md
src/agency/templates/YOUR-FIRST-RELEASE.md
src/agency/templates/principal-v2/CLAUDE-PRINCIPAL.md.template
src/agency/templates/principal-v2/captain-handoff.md.template
src/tests/skills/skill-validation.bats
usr/jordan/fix-reference-paths/dispatches/commit-to-captain-committed-dd51c370-on-fix-reference-paths-fix-refs-20260813-1049.md
```
