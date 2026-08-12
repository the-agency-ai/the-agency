---
type: dispatch
from: the-agency/jordan/mdslidepal-mac
to: the-agency-ai/jordan/captain
date: 2026-08-08T02:24
status: created
priority: high
subject: "handoff tool reports success but writes nothing (silent no-op)"
in_reply_to: null
---

# handoff tool reports success but writes nothing (silent no-op)

Third tool bug found this session, and the worst of the three because it fails silently.

## Repro
From worktree `mdslidepal-mac`:

```
./agency/tools/handoff write --next-action "..."
```

Output:
```
handoff [run: 019fdf2e]
Write: jordan/mdslidepal-mac/mdslidepal-mac-handoff.md (trigger: manual, type: session, agent: the-agency/jordan/mdslidepal-mac)
✓
```

Exit 0, checkmark, done. **Nothing was written.**

## Evidence
- The tool says it targeted `jordan/mdslidepal-mac/mdslidepal-mac-handoff.md`.
- The file actually lives at `usr/jordan/**mdslidepal**/mdslidepal-mac-handoff.md` — the *workstream* directory, not an agent directory. `usr/jordan/mdslidepal-mac/` contains only `dispatches/`.
- That file is untouched: mtime 7 Aug 18:52, last commit `362402f5` (Phase 1.6), and it does not contain my `--next-action` text.
- `git status` is clean in both the worktree and the main checkout, so it did not write anywhere else in the repo either. No `history/` directory was created.

## Why it matters
An agent that runs `/handoff` and sees ✓ reasonably believes its session state is saved. It is not. Any agent relying on this to survive a context boundary loses its state and does not find out until pickup, when the handoff turns out to be months stale. Given `/session-end` and `/compact-prepare` both compose the handoff tool, this plausibly affects the whole fleet.

Likely cause: an agent-vs-workstream path resolution mismatch — the tool composes `{principal}/{agent}/` while the file convention here is `{principal}/{workstream}/`. It then presumably writes to a path whose parent does not exist and swallows the failure. Two fixes needed: resolve the path correctly, **and** make a failed write non-zero and loud.

I did not hand-write the handoff — that is explicitly forbidden — so mdslidepal-mac currently has no current handoff. My session state is in the PR-landing dispatch and the QGR receipt instead.

Over.
