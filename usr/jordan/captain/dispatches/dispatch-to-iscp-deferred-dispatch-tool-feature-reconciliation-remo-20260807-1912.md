---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-08-07T11:12
status: created
priority: high
subject: "Deferred: dispatch-tool feature reconciliation (remote-poll/status-mirror/cross-agency) — 3-way merge vs main's landed bug fixes"
in_reply_to: null
---

# Deferred: dispatch-tool feature reconciliation (remote-poll/status-mirror/cross-agency) — 3-way merge vs main's landed bug fixes

During the 2026-08-07 fleet rebuild-on-main, your worktree was retired & rebuilt fresh from current main (recovery tag: retired/iscp-20260807). Your dispatch-hub SERVICE (38 files) was grafted cleanly to src/services/dispatch-hub/ (note: corrected from root /services/, which .gitignore:97 ignores — tracked services live under src/services/).

DEFERRED — needs your protocol expertise: your dispatch-TOOL changes (remote-poll x17, status-mirror, cross-agency routing x5) were NOT grafted. Main's agency/tools/dispatch independently landed bug fixes (#167/#201/#247/#251/#388) since your branch diverged. True divergence ~373 lines. Blind-grafting your version would REGRESS those fixes. This needs a real 3-way merge: base=merge-base, ours=main's current agency/tools/dispatch, theirs=retired/iscp-20260807:claude/tools/dispatch. Same for dispatch-monitor (~50 line divergence). Your feature work is safe in the recovery tag. Pick it up when you resume.
