---
type: handoff
agent: the-agency/jordan/captain
workstream: housekeeping
date: 2026-04-16
trigger: session-end
---

## D43 Session End — 4 releases shipped

### Releases

| Release | PR | What |
|---------|-----|------|
| v43.1 | #145 | TOOL.sh/TOOL.py templates (#140 #141) + D42 doc sweep (65+ stale refs across 33 files) + README review (#142) + workshop pitch (#143) + CI fix (#148) |
| v43.2 | #152 | Hotfix — agency update crash (#147) + dispatch-monitor stale-read (#144) + agency deps macOS (#135) + phantom test (#149) |
| v43.3 | #154 | agency update auto-commit framework files + auto-verify |
| v43.4 | #156 | agency update version display from manifest.json (#155) |

### Issues closed: #134, #135, #140, #141, #142, #143, #144, #147, #148, #149, #151, #153, #155

### Issues filed: #146, #147, #148, #149, #150, #151, #153, #155, #157

### Open issues

- **#146** — Block AGENCY_ALLOW_RAW escape hatch (waiting on monofolk input)
- **#150** — Linux deps support (apt/dnf) — future
- **#157** — D-R format in version display — next release

### Key decisions (D43)

1. **No more raw git.** Principal directive: use tools and skills only. If the tool can't do it, build the capability. AGENCY_ALLOW_RAW escape hatch to be blocked (#146).
2. **Always file issues.** Every bug gets an issue, even if fixed immediately. No silent fixes.
3. **agency update must be zero-friction for adopters.** Auto-commit framework files, auto-verify, no manual git steps.
4. **_sync-main-ref doesn't update working tree.** Post-merge flow needs `git checkout HEAD -- .` after `_sync-main-ref` to keep files in sync.
5. **D-R format for version display** (#157) — next release.

### Fleet status

- 4 worktrees synced (devex, mdpal-app, mdpal-cli, mdslidepal-web)
- 3 worktrees pending resolution (iscp, mdslidepal-mac, mock-and-mark — dispatched)
- designex resolved merge conflict and shipping Phase 1.1

### Behavioral notes for next session

- NEVER suggest compact. Principal monitors via statusline.
- NEVER use raw git. Use tools/skills. If blocked, build the tool.
- Always file issues. Bug → issue → fix → close.
- `git add -A` requires explicit principal approval every time.
- Over/Over-and-out protocol for 1B1 discussions.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
