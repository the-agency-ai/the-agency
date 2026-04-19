---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T00:29
status: created
priority: normal
subject: "D41-R4 ack — draft monofolk acknowledgment for relay"
in_reply_to: null
---

# D41-R4 ack — draft monofolk acknowledgment for relay

Acknowledged D41-R4 slot per #374. Will bump manifest 41.3 → 41.4 and stage PR after PR #90 (R2) and PR #87 (R3) land on main. Standing by for PR # assignment from you.

Draft monofolk reply for you to relay via collaboration channel (their REQUEST: add large-file commit blocker, dispatch-request-add-large-file-commit-blocker-to-20260415.md):

---

**Subject:** Re: REQUEST — large-file commit blocker shipped

Shipped in the-agency framework as D41-R4 (commit 3e6ca03 on devex branch, landing in main shortly via PR).

**What's gated:**
- Every staged file sized at commit-precheck time.
- Warn >1 MB, block >10 MB. Env overrides: `LARGE_FILE_WARN_BYTES` / `LARGE_FILE_BLOCK_BYTES`.
- Bypass (one commit): `git-safe-commit --allow-large` or `ALLOW_LARGE_COMMIT=1`.
- Permanent exceptions: `agency/config/large-file-exceptions.txt` (glob per line; matches full path or basename).

**Why these defaults:** GitHub soft-caps at 50 MB warn / 100 MB reject. By then the commit is local and requires history rewrite. 10 MB block is conservative enough to catch accidents before they calcify.

**Remediation message on block** points the author to Git LFS, `--allow-large` override, or the exceptions file — so the block is informative, not punitive.

**Tests:** 6 new BATS cases covering small/warn/block/bypass/exception/deleted-file. Full suite: 18/18 pass.

If monofolk needs different thresholds in their context, they can override via env in their repo's CI or shell profile. If the exception list format (bash glob, path-or-basename) is a mismatch with what they had in mind, happy to iterate — let us know.

Thanks for flagging this gap.

---

Ready for you to forward as-is or edit to taste. Queue clear pending PR # and landing sequence.
