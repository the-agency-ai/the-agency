---
type: briefing
workstream: housekeeping
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-18
trigger: D45-R1 shebang resolution (pre-PR)
supersedes: D44 convention `#!/usr/bin/env python3.12`
---

# Python Shebang Investigation — D45-R1

## Purpose

Decide the shebang convention for framework Python tools (`agency/tools/*.py`, `agency/hooks/*.py`, the `dispatch-monitor`, the `TOOL.py` template) as part of the Python 3.13 floor migration (D45-R1). The D44 convention hard-codes the exact interpreter binary name (`python3.12`), which proved fragile tonight when the dev machine had `python3.13` but not `python3.12` on PATH and Monitor exited 127.

## Current convention (to be replaced)

```python
#!/usr/bin/env python3.12
```

- **Requires:** a binary literally named `python3.12` on PATH.
- **Fails when:** the host has Python ≥ 3.12 installed but under a different executable name — e.g. `python3.13`, `python3`, or a pyenv shim that doesn't create a per-minor symlink.
- **Observed failure:** this captain's dev machine has `python3.13` only; `env: python3.12: No such file or directory` → Monitor 127.
- **Not theoretical:** the principal directive to flip the floor from 3.12 to 3.13 was a direct consequence of this fragility.

## Options

### B1 — Switch exact binary to `python3.13`

```python
#!/usr/bin/env python3.13
```

**Pros**
- Smallest diff (one-character change per file).
- Mechanical enforcement — the binary either exists or it doesn't.

**Cons**
- **Same fragility, different number.** Any host without a `python3.13` binary on PATH — pyenv shim setups, Debian/Ubuntu stable with `python3.11`, Linux distros that install as `python3` only, nix, conda envs — fails identically to the way we failed tonight on 3.12.
- When we bump to 3.14 next year, we repeat the exercise.
- Rejects the lesson of tonight's incident.

### B2 — Flexible shebang + runtime guard

```python
#!/usr/bin/env python3
"""...docstring..."""
import sys
if sys.version_info < (3, 13):
    sys.exit(
        f"Python 3.13+ required (got {sys.version_info.major}.{sys.version_info.minor}). "
        f"See agency/config/dependencies.yaml."
    )
```

**Pros**
- Any Python 3 ≥ 3.13 on PATH works — brew default, pyenv global, Apple stock (when it catches up), nix, conda, Docker, every reasonable adopter.
- Explicit failure message names the floor and points at the dependency config.
- Zero extra process invocation (the guard runs inside the interpreter we already started).

**Cons**
- Failure is runtime, not shebang-resolution — tool *starts*, then immediately exits. Slightly later fail-fast than B1.
- Every tool carries the same five-line preamble (can be deduped via `agency/tools/lib/_py_floor.py` import, but adds one stat per startup — trivial).

### B3 — Hybrid: B2 + `agency-health` check

Everything in B2, plus an `agency-health` assertion:

```
python3 resolves to 3.13+ → ✓
python3 resolves to <3.13 → ! warn with actionable fix (brew install python@3.13, link, etc.)
python3 missing → ✗ critical
```

**Pros**
- Install-time visibility in addition to runtime visibility — adopters running `./agency/tools/agency-health` after `agency init` learn the floor *before* they invoke a broken tool.
- Pairs naturally with `agency/config/dependencies.yaml` — `agency-health` already reads this file; adding a `min_version` check on `python3` is a one-function addition.
- Keeps B2's adopter ergonomics (flexible shebang).

**Cons**
- Slightly more work than B2 alone — but the incremental cost is small (~20 LOC in `agency-health` plus one dependencies.yaml field update).

## Tradeoff matrix

| Dimension               | B1 (`python3.13`) | B2 (`python3` + guard) | B3 (hybrid)        |
|-------------------------|-------------------|------------------------|--------------------|
| Adopter ergonomics      | Poor              | Good                   | Good               |
| Mechanical enforcement  | Shebang-only      | Runtime                | Runtime + install  |
| Survives 3.14 bump      | No (same edit)    | Yes (guard bump only)  | Yes (guard + health) |
| Fail-fast speed         | Fastest           | ~same (ms)             | ~same (ms)         |
| Install-time visibility | None              | None                   | Yes                |
| LOC delta vs D44        | ~0 (rename)       | +5/file                | +5/file + ~20 LOC  |
| Handles pyenv/nix       | No                | Yes                    | Yes                |

## Portability notes

- **macOS, brew:** `brew install python` (unversioned) installs 3.13 AND creates a `python3` symlink → B2/B3 work out of the box. `brew install python@3.13` (versioned keg) installs 3.13 but only creates `python3.13` (no unversioned `python3` symlink) → **B2/B3 fail with the guard message** because `python3` on PATH still resolves to Apple stock (3.9 on macOS 14). **Lesson:** recommend `brew install python`, not `python@3.13`. This was discovered on the captain's own dev machine at 0300 SGT 2026-04-18 — `python3 --version` returned 3.9 from `/usr/bin/python3` even with `python@3.13` keg installed. `dependencies.yaml` uses `brew: python` with `brew_alt: python@3.13` for the advanced case.
- **macOS, Apple stock:** Apple ships `python3` at `/usr/bin/python3` — currently 3.9 on macOS 14, may lag 3.13 for years. B1 + B2 + B3 all fail here; B2/B3 fail with a clear message, B1 fails with a cryptic `env` error. B2/B3 win the error-quality comparison.
- **Linux, Debian/Ubuntu:** system Python is often older than our floor. The standard pattern is `deadsnakes` PPA (`sudo add-apt-repository ppa:deadsnakes/ppa && apt install python3.13`), which *does* install as `python3.13`. B1 works here. B2/B3 also work if the user `update-alternatives` to make `python3 → python3.13`, which is the recommended deadsnakes workflow.
- **Linux, nix/NixOS:** `nix-shell -p python313` puts `python3` on PATH but not `python3.13`. B1 breaks. B2/B3 work.
- **pyenv:** `pyenv global 3.13` installs a shim that answers to `python3` (and `python3.13`, but not always depending on setup). B2/B3 work reliably; B1 works if the user also ran `pyenv rehash` with matching config.
- **conda/mamba:** virtual envs put `python3` on PATH. B2/B3 work. B1 requires the env to expose `python3.13` specifically.
- **Docker base images:** `python:3.13-slim` ships `python3` and `python3.13` both — all three options work. But `ubuntu:24.04 + apt install python3` ships 3.12 only — B1 and B2/B3 both reject it, but B2/B3 with a useful message.

Net: B2/B3 have strictly more compatibility than B1, with equal or better failure ergonomics.

## Recommendation

**B3 — hybrid.** Rationale:

1. The principal directive is "brew default is 3.13 so adopters get the floor for free." B3 honors that by not requiring any binary name beyond what brew (and every other reasonable package manager) already provides.
2. B2 alone is already a strict improvement over B1; B3 adds install-time visibility for the small marginal cost of one `agency-health` check.
3. `agency/config/dependencies.yaml` already has a `version_cmd` field for `python3`. Updating it from `python3.12 --version | ...` to `python3 --version | ...` is a one-line diff that makes `agency-health` correctness follow for free.
4. The D44→D45 migration already pays the cost of editing every shebang anyway. Doing it once to a shape that survives 3.14 and 3.15 is net cheaper than doing it again next year.

## Fallback

If B3 exceeds scope for a same-night PR (the `agency-health` update needs its own review care), default to **B2** for the D45-R1 PR and file a follow-up issue for the `agency-health` addition as "refinement" of the 3.13 floor.

**Do NOT fall back to B1.** B1 reproduces the exact fragility we are trying to fix.

## Implementation scope for Workstream A (D45-R1)

Per B3:

### Shebang changes (every framework Python file)

```diff
-#!/usr/bin/env python3.12
+#!/usr/bin/env python3
+"""...existing docstring..."""
+import sys
+if sys.version_info < (3, 13):
+    sys.exit(
+        f"Python 3.13+ required (got {sys.version_info.major}.{sys.version_info.minor}). "
+        f"See agency/config/dependencies.yaml."
+    )
```

Files touched (per runbook Workstream A):
- `agency/tools/dispatch-monitor`
- `agency/templates/TOOL.py`
- Any other `#!/usr/bin/env python3.12` in `claude/tools/` or `claude/hooks/` (sweep with grep).

### `agency/config/dependencies.yaml`

```diff
   python3:
-    brew: python@3.12
-    min_version: "3.12"
-    version_cmd: "python3.12 --version | grep -oE '[0-9]+\\.[0-9]+'"
+    brew: python@3.13
+    min_version: "3.13"
+    version_cmd: "python3 --version | grep -oE '[0-9]+\\.[0-9]+'"
     used_by:
       - ...
-    why: "... 3.12 buys native match, ..."
+    why: "framework tools, hooks, and services target modern Python. 3.13 is brew default so adopters get the floor for free. 3.13 adds optional features (PEP 703 no-GIL, PEP 744 JIT) that we do not require — floor is set for toolchain modernity, not opt-in runtime features."
     note: |
       ZERO-PIP CONSTRAINT for framework tools in agency/tools/ — stdlib only,
       no pip deps. Services (iscp dispatch-hub, etc.) may use pip.

       Floor raised 3.9 → 3.12 in D44-R6 (superseded) → 3.13 in D45-R1.
       Rationale: brew default is 3.13, adopters get the floor for free,
       3.13 adds nothing we must turn on, 3.12 was never installed on the
       dev machine (Monitor 127 on 2026-04-17 proved the fragility of
       exact-minor shebangs).

       Shebang convention: `#!/usr/bin/env python3` + runtime
       `sys.version_info` guard. See briefing
       usr/jordan/captain/briefings/python-shebang-investigation-20260418.md.
-    install:
-      brew_required: "brew install git bash jq sqlite node python@3.12 curl rsync gh"
+    install:
+      brew_required: "brew install git bash jq sqlite node python@3.13 curl rsync gh"
```

### `agency-health` (B3 addition)

Add a single check reading `dependencies.yaml.python3.min_version` and comparing against `$(python3 --version)`. Emit:
- ✓ when `python3 ≥ 3.13`
- ! (attention) when `python3 < 3.13` with actionable message
- ✗ (critical) when `python3` missing

**If this exceeds PR scope,** fall back to B2 for D45-R1 and file a follow-up issue.

### `agency/CLAUDE-THEAGENCY.md`

Runtime Floor section:

```diff
-- **Python: 3.12+.** Framework tools, hooks, and services target modern Python. Set in D44 per principal directive, superseding the prior 3.9+ floor. See `agency/config/dependencies.yaml` for rationale and what 3.12 buys us (native `match`, PEP 604 unions, PEP 695 generics, `typing.Self`, `tomllib`, ~10-15% perf). Framework tools in `agency/tools/` remain **zero-pip**: stdlib only. Services (iscp dispatch-hub, etc.) may use pip deps.
+- **Python: 3.13+.** Framework tools, hooks, and services target modern Python. Set in D45 per principal directive, superseding the D44 3.12 floor. Rationale: brew default is 3.13 so adopters get the floor for free; 3.13 adds nothing we must opt into (JIT + no-GIL are opt-in). Shebang convention: `#!/usr/bin/env python3` + runtime `sys.version_info` guard (not `python3.13` — see `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md`). Framework tools in `claude/tools/` remain **zero-pip**: stdlib only. Services (iscp dispatch-hub, etc.) may use pip deps.
```

## Why this resolves tonight's failure

Tonight's Monitor 127:

```
env: python3.12: No such file or directory
```

After B3:

- `dispatch-monitor` ships with `#!/usr/bin/env python3` shebang.
- The dev machine has `python3` → `python3.13` via brew.
- `sys.version_info` is `(3, 13, ...)`, guard passes.
- Monitor runs; no explicit-path shim needed.

The explicit-path workaround in the current captain-handoff (`/opt/homebrew/bin/python3.13 ./agency/tools/dispatch-monitor --include-collab`) can be retired the moment D45-R1 lands.

## Open items (not blocking)

- **`agency/tools/_py_floor.py` helper.** A single `from _py_floor import assert_floor` avoids the five-line preamble in every tool. Tradeoff: one import means the guard is only enforced after the import resolves; if the import itself fails (e.g. `sys.path` issue on a weird install), failure mode is worse than the inline version. Recommend inline for D45-R1; revisit a helper after the fleet stabilizes.
- **Hookify rule: block `python3.12`/`python3.13` shebangs in new files.** A `decision: block` hookify rule on Write/Edit of `#!/usr/bin/env python3\.\d+` in `claude/tools/` would prevent regression. Not blocking for D45-R1; file as follow-up.
- **`agency verify` enforcement.** `agency-health` reports; `agency verify` should gate `agency init` / `agency update`. Separate concern from this briefing.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
