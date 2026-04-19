---
type: dispatch-broadcast-draft
workstream: housekeeping
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-18
trigger: D45-R1 Python 3.13 floor broadcast
status: HOLD — awaits principal authorization on wake
supersedes: D44-R6 3.12 floor broadcast (dispatches #649–#656)
---

# D45-R1 Fleet Broadcast — DRAFT, DO NOT SEND

Drafted during autonomous 0300 setup. **Principal must authorize send on wake.**
Send only after PR #213 merges. Captain runs one `dispatch create --type main-updated` per
fleet target, with the body below. This supersedes the D44-R6 3.12 floor broadcast
(#649–#656).

## Fleet targets (8 agents)

- `the-agency/jordan/devex`
- `the-agency/jordan/designex`
- `the-agency/jordan/iscp`
- `the-agency/jordan/mdpal-cli`
- `the-agency/jordan/mdpal-app`
- `the-agency/jordan/mdslidepal-mac`
- `the-agency/jordan/mdslidepal-web`
- `the-agency/jordan/mock-and-mark`

## Dispatch type

`main-updated` — agents will see on next `iscp-check` / session-resume.

## Subject

`Python 3.13 floor — supersedes 3.12 (D45-R1)`

## Body (identical across all 8)

```
Fleet,

Framework floor is now Python 3.13 (D45-R1 / PR #213). This supersedes the
D44-R6 3.12 floor — see dispatch #649-#656 (now stale).

## What changed

1. **Floor version.** Framework tools, hooks, and services now require
   Python 3.13+. Adopters with only Python 3.12 are no longer supported.

2. **Shebang convention.** Framework Python files now use
   `#!/usr/bin/env python3` + a runtime `sys.version_info < (3, 13)` guard.
   NOT `#!/usr/bin/env python3.13`. Reason: exact-minor shebangs break
   pyenv/nix/conda/Apple-stock installs that don't create the per-minor
   symlink (D44's `python3.12` shebang caused Monitor 127 on the dev
   machine on 2026-04-17 — that is what prompted the flip to 3.13).

3. **Adopter install.** `brew install python` (unversioned — creates the
   `python3` symlink). NOT `brew install python@3.13` — the versioned
   keg does not create the symlink and leaves Apple stock 3.9 winning
   on PATH. `agency/config/dependencies.yaml` has `brew: python` with
   `brew_alt: python@3.13` documenting the alternative.

## What you need to do on your next session

1. Run `./agency/tools/worktree-sync --auto` (or `/session-resume`).
2. Confirm `python3 --version` returns `>= 3.13`. If not:
   - macOS: `brew install python` (unversioned keg).
   - Linux: `sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt install python3.13 && sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1`
   - pyenv/nix: point `python3` at a 3.13+ interpreter.
3. If you get `Python 3.13+ required (got <version>)` from any framework
   tool, that is the guard firing. Fix your PATH per step 2.
4. New Python tools you write: scaffold from `agency/templates/TOOL.py`.
   It now carries the correct shebang + guard.

## References

- PR: #213 (release/python-3.13-floor → main)
- Briefing: `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md`
- Updated docs: `agency/CLAUDE-THEAGENCY.md` (Runtime Floor), `agency/REFERENCE-PROVENANCE-HEADERS.md`
- Config: `agency/config/dependencies.yaml`, `agency/config/agency-dependencies.yaml`
- QGR: `agency/workstreams/the-agency/qgr/...-d406320.md`

## Follow-ups (tracked in GH, not blocking for you)

- Propagate runtime guard to `.claude/hooks/*.py`, `validate-schema.py`,
  captain tools (ID 4 in QGR — file as GH issue)
- Add `python3 >= 3.13` check to `agency-health` (B3 upgrade — see #209)
- Teach `_agency-deps` to consume `min_version` / `version_cmd`

Questions: reply to this dispatch or flag to captain.

— captain
```

## Send command (for captain on authorization)

```bash
for agent in devex designex iscp mdpal-cli mdpal-app mdslidepal-mac mdslidepal-web mock-and-mark; do
  ./agency/tools/dispatch create \
    --type main-updated \
    --to "the-agency/jordan/$agent" \
    --subject "Python 3.13 floor — supersedes 3.12 (D45-R1)" \
    --body-file usr/jordan/captain/dispatches/drafts/d45-r1-python-3.13-body.md
done
```

The body text (between the ``` fences above) should be extracted to
`usr/jordan/captain/dispatches/drafts/d45-r1-python-3.13-body.md` before the
send loop runs (captain action on authorization).

## Acknowledgement tracking

On authorization, file a single aggregate tracking note in captain-log:
"D45-R1 fleet broadcast sent to 8 agents — await ACKs on individual
session-resumes."

If any agent fails to ACK within 48 hours, surface in the next handoff.

---

*HOLD until principal authorization. Do NOT send autonomously.*
