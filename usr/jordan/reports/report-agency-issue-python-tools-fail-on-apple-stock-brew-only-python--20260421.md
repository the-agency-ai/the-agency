---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-21
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/394
github_issue_number: 394
status: open
---

# Python tools fail on Apple-stock + brew-only python@3.13 host (no unversioned python3 link)

**Filed:** 2026-04-21T05:17:01Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#394](https://github.com/the-agency-ai/the-agency/issues/394)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

## What happened

On a host with only brew's `python@3.13` installed (no unversioned `python3` link), framework Python tools (`dispatch-monitor`, etc.) fail their runtime guard:

```
Python 3.13+ required (got 3.9). See agency/config/dependencies.yaml.
```

The Monitor tool exits 1 and the dispatch monitor never arms.

### Reproduction

On macOS with:

- `/usr/bin/python3` → Apple stock `3.9.6` (unavoidable default)
- `/opt/homebrew/bin/python3.13` → brew-installed `3.13.x`
- **No** `/opt/homebrew/bin/python3` (brew `python@3.13` is keg-only style for the unversioned name)

Run any framework Python tool:

```
./agency/tools/dispatch-monitor --include-collab
# → exit 1, prints: Python 3.13+ required (got 3.9)
```

`/usr/bin/env python3` resolves to the Apple-stock `/usr/bin/python3` (3.9), the guard fires, exit 1.

### Root cause

D45-R1 shebang convention is `#!/usr/bin/env python3` + `sys.version_info < (3, 13)` runtime guard (per `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md`). This was chosen to avoid the D44 trap where `#!/usr/bin/env python3.12` broke on hosts where brew had installed only `python3.13`.

D45-R1 assumed the user's `python3` binary would resolve to ≥3.13. On Apple-stock macOS + brew-only install of `python@3.13`, this assumption fails: brew does not create `/opt/homebrew/bin/python3` → `python3.13` unless you `brew link --overwrite --force python@3.13` (non-default, not documented in Agency onboarding).

The D45-R1 runtime guard catches it but leaves the user dead in the water with no remediation hint beyond "See agency/config/dependencies.yaml."

### Fix options

1. **Document `brew link --overwrite --force python@3.13`** in onboarding / README. Fast, user still has to do it.
2. **Ship `agency/tools/_py-launcher`** — a tiny bash wrapper that finds the first `python3.13+` on PATH (trying `python3.13`, `python3.14`, `python3`) and execs the target script. Change tool shebangs to `#!/usr/bin/env bash` with a wrapper exec, or use `#!/usr/bin/env -S _py-launcher` (env -S GNU extension — may not be portable on stock macOS, which uses BSD env; needs verification).
3. **Wrapper scripts:** rename `dispatch-monitor` → `dispatch-monitor.py`, write a bash `dispatch-monitor` that finds py and execs. Adds one layer; fully portable.

Recommendation: ship #2 or #3 (auto-discovery); update onboarding for #1 as interim.

### Error message improvement

Current message: `Python 3.13+ required (got 3.9). See agency/config/dependencies.yaml.`

Better: `Python 3.13+ required (got 3.9 at /usr/bin/python3). Install via: brew install python@3.13 && brew link --overwrite --force python@3.13`

### Acceptance criteria

- [ ] Framework Python tools run on a fresh-install macOS host with brew + `python@3.13` without requiring `brew link --overwrite`.
- [ ] `dispatch-monitor`, `iscp-db`, and other Python-shebang tools succeed at first run.
- [ ] Monitor tool watching `dispatch-monitor` does not exit 1 on startup.
- [ ] Error message (if guard still fires) tells the user exactly how to fix it.

### Related

- Existing briefing: `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md` (D45-R1 decision)
- Incident D44: `python3.12` shebang failed on 3.13-only hosts.
- New incident 2026-04-21: `python3` → 3.9 on Apple-stock + brew-only host.
- Principal-raised during 2026-04-21 session-resume root-cause sweep.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-21:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/394
