---
type: commit
from: the-agency/jordan/fix-reference-paths
to: the-agency/jordan/captain
date: 2026-08-13T02:49
status: created
priority: normal
subject: "Committed dd51c370 on fix-reference-paths: fix(refs): repair Great-Rename REFERENCE-path rot across skills/hookify/README/agents + add validator (flag #213)

Broken doc pointers from the claude/→agency/ Great Rename, in two forms:
- claude/REFERENCE-X.md  (pre-Rename prefix)
- agency/REFERENCE-X.md  (missing the /REFERENCE/ subdir)
both should be agency/REFERENCE/REFERENCE-X.md. These sat in skills'
required_reading frontmatter (silently breaking ref-following), skill bodies,
hookify rule guidance, README, and agent docs. Swept all active-doc pointers to
the correct path; every target now resolves.

Durable guard: new skill-validation test asserts every required_reading path
exists (this class rotted precisely because nothing checked it).

Also synced 2 pre-existing stale-src mirror drifts found along the way:
sync-all (main-updated → master-updated) and worktree-create (SKILL.md missing
the v2.3.0 description from #470). CLAUDE-THEAGENCY's src mirror omits the
internal Telemetry-Discovery section — LEFT AS-IS (likely intentional
internal-vs-adopter difference), noted for review.

86 files, +229/-164. Skills suite green (123 tests incl. the new guard)."
in_reply_to: null
---

# Committed dd51c370 on fix-reference-paths: fix(refs): repair Great-Rename REFERENCE-path rot across skills/hookify/README/agents + add validator (flag #213)

Broken doc pointers from the claude/→agency/ Great Rename, in two forms:
- claude/REFERENCE-X.md  (pre-Rename prefix)
- agency/REFERENCE-X.md  (missing the /REFERENCE/ subdir)
both should be agency/REFERENCE/REFERENCE-X.md. These sat in skills'
required_reading frontmatter (silently breaking ref-following), skill bodies,
hookify rule guidance, README, and agent docs. Swept all active-doc pointers to
the correct path; every target now resolves.

Durable guard: new skill-validation test asserts every required_reading path
exists (this class rotted precisely because nothing checked it).

Also synced 2 pre-existing stale-src mirror drifts found along the way:
sync-all (main-updated → master-updated) and worktree-create (SKILL.md missing
the v2.3.0 description from #470). CLAUDE-THEAGENCY's src mirror omits the
internal Telemetry-Discovery section — LEFT AS-IS (likely intentional
internal-vs-adopter difference), noted for review.

86 files, +229/-164. Skills suite green (123 tests incl. the new guard).

## Commit: dd51c370

**Branch:** fix-reference-paths
**Agent:** the-agency/jordan/fix-reference-paths
**Message:** housekeeping/captain: fix(refs): repair Great-Rename REFERENCE-path rot across skills/hookify/README/agents + add validator (flag #213)

Broken doc pointers from the claude/→agency/ Great Rename, in two forms:
- claude/REFERENCE-X.md  (pre-Rename prefix)
- agency/REFERENCE-X.md  (missing the /REFERENCE/ subdir)
both should be agency/REFERENCE/REFERENCE-X.md. These sat in skills'
required_reading frontmatter (silently breaking ref-following), skill bodies,
hookify rule guidance, README, and agent docs. Swept all active-doc pointers to
the correct path; every target now resolves.

Durable guard: new skill-validation test asserts every required_reading path
exists (this class rotted precisely because nothing checked it).

Also synced 2 pre-existing stale-src mirror drifts found along the way:
sync-all (main-updated → master-updated) and worktree-create (SKILL.md missing
the v2.3.0 description from #470). CLAUDE-THEAGENCY's src mirror omits the
internal Telemetry-Discovery section — LEFT AS-IS (likely intentional
internal-vs-adopter difference), noted for review.

86 files, +229/-164. Skills suite green (123 tests incl. the new guard).

### Metadata
- commit_hash: dd51c370
- branch: fix-reference-paths
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/agency-issue/SKILL.md
.claude/skills/captain-log/SKILL.md
.claude/skills/captain-release/SKILL.md
.claude/skills/captain-review/SKILL.md
.claude/skills/captain-sync-all/SKILL.md
.claude/skills/captain-sync-all/examples.md
.claude/skills/compact-prepare/reference.md
.claude/skills/compact-resume/reference.md
.claude/skills/iteration-complete/SKILL.md
.claude/skills/phase-complete/SKILL.md
.claude/skills/post-merge/SKILL.md
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-merge/SKILL.md
.claude/skills/pr-captain-merge/examples.md
.claude/skills/pr-captain-post-merge/SKILL.md
.claude/skills/pr-merge/SKILL.md
.claude/skills/pr-submit/SKILL.md
.claude/skills/pr-submit/scripts/README.md
.claude/skills/principal-create/SKILL.md
.claude/skills/rebase/SKILL.md
```
