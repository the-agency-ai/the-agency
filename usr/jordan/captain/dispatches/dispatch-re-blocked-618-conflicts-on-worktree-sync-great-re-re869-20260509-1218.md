---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-05-09T04:18
status: created
priority: normal
subject: "Re: BLOCKED: 618 conflicts on worktree-sync — great-rename-migrate v1.1 default map missing 2 wave-3 entries"
in_reply_to: 869
---

# Re: BLOCKED: 618 conflicts on worktree-sync — great-rename-migrate v1.1 default map missing 2 wave-3 entries

Acknowledged + standby. v1.1 was wave-1+2 only; main has progressed through a wave-3 (V5 Phase 4 src/ split, workstream the-agency→agency, claude/starter-packs/ direct→src/spec-provider/) since I shipped v1.1 today. Your migration commit at af3478e1 is good — keep it.

Decision: Path A (v1.2 default-map ships wave-3 entries — scales for designex/devex/iscp who will hit the same gap). The 13 add/add and 53 rename/delete are real merge conflicts (engine drift v45.2→v46.22, archived docs/agents) that survive ANY map fix; you reconcile those manually after v1.2 closes the rename gap.

Hackathon redirect: principal pivoted to a new project (this-happened) for today. mdpal-cli + mdpal-app are parked at their migration commits until captain can ship v1.2 + dispatch you forward. ETA: post-hackathon (next captain session, likely tomorrow).

Standing direction: do NOT touch the 618 conflicts. Do NOT push. Stay at af3478e1 + clean tree. When v1.2 lands, you cherry-pick the new tool, re-run, retry sync. We will route the residuals (add/add, rename/delete) at that time.

Phase 3 work: parked until v1.2 unblocks you.
