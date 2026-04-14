---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-09
trigger: break-2000sgt
---

## Resume after 0200 SGT

### Immediate on resume

1. **PR #69 (D34-R5)** — open, awaiting approval. 813/813 tests green + ISCP merge unblock. Approve → merge → `/post-merge 69`.
2. **ISO download** — Ubuntu 24.04.4 ARM64 desktop downloading to `~/Downloads/ubuntu-24.04.4-desktop-arm64.iso`. Should be done. Verify: `ls -lh ~/Downloads/ubuntu-24.04.4-desktop-arm64.iso` — expect ~3.3 GB.
3. **Create VM** in Fusion from the ISO → bootstrap script → agency init → snapshot → OVA. Workshop is Monday.

### Day 34 shipped (on origin)

- **34.1** (PR #60) — agency-version tool + statusline
- **34.2** (PR #63) — run-in Triangle + fixes #56/#57/#171
- **34.3** (PR #66) — worktree-sync main/master fix + skill allowed-tools audit (48 files)
- **34.4** (PR #67) — agency-health v1 (3-dimensional fleet health)
- **34.5** (PR #69) — 27 test failures killed + schema skip guard + scaled timeout [PENDING MERGE]

### Fleet state

- **devex** — standing autonomy, crushed tasks #8-#13. docker-heal shipped. Worktree naming, hookify rename, agent-create dispatch loops all in progress.
- **iscp** — blocked on merge until #69 lands. Has 3 conflict files to resolve (flag, _iscp-db, flag.bats). Direction sent via #183/#184/#197/#199. Standing autonomy.
- **mdpal-app** — worktree in weird split state (1449 deletions). Dispatched #181 for agent diagnosis. Stub handoff created.
- **mdpal-cli** — synced to main, .agency-agent created, stub handoff created.
- **mock-and-mark** — worktree created, identity set, settings synced. Ready for reactivation session. Jordan: "fix it, launching soon."

### Monofolk

- Graduated to full-install (sandbox removed)
- Agency-health v1 committed to them as Wave 1 diagnostic tool
- PR workflow converging (D#-R# naming, no-squash, captain builds PRs)
- pr-build tool coming from them (upstream contribution)
- Dropbox tool design routed to iscp (#177)
- Awaiting their reply on QGR location alignment + D-counter retroactive question

### Workshop — Monday 2026-04-14 at Republic Polytechnic

- Ubuntu 24.04 LTS ARM64 VM in VMware Workstation Pro (free)
- Ghostty + brew + Docker + Claude Code + agency init
- ISO downloading. Next: create VM, run bootstrap, snapshot, export OVA
- Students get OVA, open Ghostty, `claude login`, `cd ~/workshop`, `claude`
- "No compromises. As close to macOS as we can get."

### Principles locked today

- **No broken windows.** If we use it or have used it, it gets included.
- **No compromises** on the workshop experience.
- **Be the Man Who Was Too Lazy to Fail** — invest in tools, not heroic manual execution.
- **Rapid release discipline** — D#-R# naming, no squash, one PR per release.
- **Standing autonomy** — agents execute without per-step approval.
- **No reviews on GitHub** — PRs are shipping mechanism only.
- **Ban raw git writes** (flag #83, pending 1B1 on scope).

### Open flags (31 total, key ones)

- #55 CLAUDE.md revision (rich material ready)
- #69 create-tool input validation (all *-create tools)
- #78 session naming issues (needs 1B1)
- #82 agency verify reads dependencies.yaml
- #83 ban raw git writes (needs 1B1)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
