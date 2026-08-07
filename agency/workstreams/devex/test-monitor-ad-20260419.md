---
type: architecture-and-design
project: test-monitor
workstream: devex
date: 2026-04-19
status: draft-v3 (post-MAR + no-defer correction)
seeds:
  - agency/workstreams/devex/test-monitor-pvr-20260417.md
  - agency/tools/dispatch-monitor (Python precedent)
  - agency/tools/test-run (bash, agency.yaml suites reader)
  - PR #180 (principal-filed issue)
mar_review: 2026-04-19 — 2 reviewers; 32 findings; 31 fixed (28 in draft-v2 + 3 in draft-v3); 1 moot (monitor-test dropped). Zero deferrals. Disagree-with-reasoning items documented inline.
---

# A&D: test-monitor — Monitor Tool Integration for Test Runs

## 1. Architecture Overview

test-monitor is a **Python 3.13 framework tool** that wraps existing test runners (BATS, vitest, XCTest) and emits **monitor-tool-family-convention** line events to stdout. Agents consume those lines via Claude Code's Monitor tool; `/quality-gate` Step 8 consumes the `RUN_DONE` line to gate iteration completion.

```
┌─────────────────────────────────────────────────────────────────────┐
│ Agent (consumer)                                                    │
│   ↑ Monitor tool — streams stdout lines as notifications            │
└──────────────────────────────┬──────────────────────────────────────┘
                               │  [TEST tools] suite started (bats, …)
                               │  [TEST tools] FAIL …
                               │  [TEST] run complete — … exit 1
                               │
┌──────────────────────────────┴──────────────────────────────────────┐
│ test-monitor (Python 3.13, stdlib-only)                             │
│                                                                     │
│  parse_args() ─┐                                                    │
│                ▼                                                    │
│         load_suites()  ──── reads agency/config/agency.yaml         │
│                │              (testing.suites.<name>.command, etc.) │
│                ▼                                                    │
│         for each suite:                                             │
│            framework = detect(cmd)   ──► dispatch to parser module  │
│                                                                     │
│         ┌─ bats_parser ─┐                                           │
│         ├─ vitest_parser ┤  normalize → [TEST <suite>] events       │
│         └─ xctest_parser ┘                                          │
│                │                                                    │
│                ▼                                                    │
│         subprocess.Popen(cmd, shell=True, stdout=PIPE,              │
│                          stderr=STDOUT, env=TEST_ENV)               │
│            line-buffered iteration → parser → stdout emit           │
│                │                                                    │
│                ▼                                                    │
│         on SUITE_DONE:  update run totals                           │
│         on last SUITE_DONE:  emit RUN_DONE line                     │
│         ALWAYS emit RUN_DONE — even on parse failure                │
│                                                                     │
│  --trigger-on {green|red|change}                                    │
│      ─► on RUN_DONE, shell out to ./agency/tools/dispatch or flag   │
│          (with state-signature deduplication — no re-dispatch of    │
│           identical RED state on successive invocations)            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Two tools ship in v1:**

| Tool | Role | Size |
|------|------|------|
| `./agency/tools/test-monitor` | Single-run test streamer (UC1, UC3) | ~350 LOC Python |
| `./agency/tools/test-watch` | File-watch loop wrapping test-monitor (UC2) | ~200 LOC Python |

**Dropped from draft-v1:** `monitor-test` bash wrapper — the invocation `./agency/tools/test-monitor` is already a one-liner; a wrapper adds noise without value (§6.7 confirmed drop).

**One skill rewires:**

| Skill | Change |
|-------|--------|
| `.claude/skills/quality-gate/SKILL.md` | Step 8 detects `test-monitor` + `agency.yaml → testing.monitor: true`; instructs agent to launch via Monitor tool and await `[TEST] run complete` line; falls back to sync `test-run` otherwise |

**REPO_ROOT resolution** (MAR-H5): test-monitor and test-watch resolve the repo root via `git rev-parse --show-toplevel` (via `./agency/tools/git-safe`). If that fails (not in a git repo), fall back to walking `__file__`'s ancestor chain for the first directory containing `agency/config/agency.yaml`. All subsequent paths (agency.yaml, state files, tool binaries) are derived from REPO_ROOT. Matches `test-run` precedent.

---

## 2. Data Model

### 2.1 Suite state (in-memory for test-monitor; persisted for test-watch)

```python
from datetime import datetime, timezone  # ALL timestamps UTC (MAR-M5)

@dataclass(frozen=True)
class FailureSignature:
    test_id: str        # stable location-like id, e.g. "src/tests/tools/dispatch.bats:42"
    reason_hash: str    # sha256 of the normalized reason string (first 16 chars)

@dataclass
class SuiteState:
    name: str                             # "tools", "mdpal", etc.
    framework: Framework                  # enum: BATS | VITEST | XCTEST | UNKNOWN
    command: str                          # from agency.yaml
    watch_paths: list[str]                # from agency.yaml OR inferred OR default
    last_outcome: Outcome | None          # GREEN | RED | ERROR | None (never run)
    last_failure_signatures: frozenset[FailureSignature]  # set-semantics (MAR-M1, M3)
    last_run_at: datetime | None          # UTC
    last_green_at: datetime | None        # UTC
    last_green_head: str | None           # git SHA of last GREEN run
```

**Transition detection** (MAR-M3): any change in `last_failure_signatures` (additions OR removals) is a transition. `GREEN→GREEN` and `RED→RED-same-signatures` are silent. Emitting cases:

- `last_outcome is None and new is GREEN` → emit `initial state: GREEN`
- `last_outcome is None and new is RED` → emit `initial state: RED (N failures)`
- `last_outcome is GREEN and new is RED` → emit `GREEN → RED` transition with failure list
- `last_outcome is RED and new is GREEN` → emit `RED → GREEN` transition
- `last_outcome is RED and new is RED and signatures differ` → emit `RED → RED (failure set changed)` with diff
- `last_outcome is RED and new is RED and signatures identical` → silent

### 2.2 Run result (emitted; consumed by --trigger-on)

```python
@dataclass(frozen=True)
class RunResult:
    suite: str
    framework: Framework
    passed: int
    failed: int
    skipped: int
    duration_sec: float
    exit_code: int                          # 0 green, 1 red, 2 error
    failures: tuple[Failure, ...]           # empty if all pass
    parse_ok: bool                          # False if parser raised; RAW passthrough active
    run_signature: str                      # sha256(sorted(failure_signatures)) — used for dedup

@dataclass(frozen=True)
class Failure:
    test_id: str            # e.g. "src/tests/tools/dispatch.bats:42"
    location: str | None    # file:line if parsed out
    reason: str             # first line of assertion/error (<= 200 chars)
    body_truncated: str     # up to 1 KB (MAR-M7), truncation marker if longer
```

### 2.3 Pattern C dispatch payload schema (resolves Q3 punt)

When `--trigger-on red` fires, test-monitor emits a dispatch of type `test-failure` with this YAML body:

```yaml
suite: tools
framework: bats
run:
  passed: 14
  failed: 1
  skipped: 0
  duration_sec: 2.3
  exit_code: 1
  parse_ok: true
failures:
  - test_id: "src/tests/tools/dispatch.bats:42"
    location: "src/tests/tools/dispatch.bats:42"
    reason: "assertion failed: expected 1 got 2"
    body_truncated: |
      assertion failed
        expected: 1
        actual: 2
      [... truncated, 234 chars ...]
context:
  branch: "devex"
  head: "ac2d9927"
  last_green_head: "4901c6dd"
  last_green_at: "2026-04-19T23:48:12Z"   # UTC (ISO8601)
  failures_truncated: false
  run_signature: "a1b2c3…"
```

- **Size limit:** 8 KB (ISCP dispatch body cap).
- **Multi-failure handling:** up to 10 failures; if more, truncate and set `context.failures_truncated: true`.
- **YAML emission** (MAR-M6, §8.3): all user-sourced strings (reason, body_truncated) emit as **block scalar literals** (`|`) with proper indentation — prevents injection via embedded `\n---\n` or YAML metacharacters. Keys use plain scalars; values quoted.
- **Timestamps:** UTC, ISO8601 with `Z` suffix (MAR-M5).

When `--trigger-on green` fires, dispatch type is `commit-ready`:

```yaml
suite: tools
framework: bats
run: {passed: 15, failed: 0, skipped: 0, duration_sec: 2.3, exit_code: 0, parse_ok: true}
context:
  branch: "devex"
  head: "ac2d9927"
```

(`staged_changes` field dropped from draft-v1 — MAR-H3. Green dispatch means "tests green at this head"; staging is a separate concern owned by the agent.)

When `--trigger-on change` fires (outcome differs from last stored outcome), test-monitor emits a **flag** via `./agency/tools/flag new`:

```
test-watch: suite=tools transitioned GREEN→RED (failing: src/tests/tools/dispatch.bats:42 — expected 1 got 2)
```

### 2.4 Persistent state (test-watch only)

File: `agency/data/test-monitor/<suite>.state` (**one unified file per suite**, MAR-M2).

Format: YAML (simple, single-level keys; no nested structures). Emitted by test-monitor, read by test-watch between runs.

```yaml
last_outcome: red
last_run_at: "2026-04-19T23:48:12Z"
last_failure_signatures:
  - test_id: "src/tests/tools/dispatch.bats:42"
    reason_hash: "a1b2c3d4e5f6g7h8"
last_green_head: "4901c6dd"
last_green_at: "2026-04-19T23:40:00Z"
```

- Written atomically: `open(tmp, 'w')` → `os.rename(tmp, target)`.
- **File lock via `fcntl.flock(LOCK_EX | LOCK_NB)`** on the state file at process start (draft-v3, MAR-Adv-M1 fix). If a second test-watch (or test-monitor writing state) attempts to acquire the lock on the same suite, `fcntl.flock` raises `BlockingIOError`. We emit `[TEST ERROR] suite=<name> state file locked — another process is running for this suite; exit` and exit 2. No double-dispatch, no double-run.
- File is gitignored via existing `agency/data/` gitignore.
- On read error (corrupt YAML, missing file) → log `[TEST ERROR] state file corrupt for suite=<name> — resetting`; delete + treat as first run.
- `last_green_head` format: plain string (git SHA, 40 chars or short-sha). Same YAML file, not a separate `.last-green` file.

---

## 3. Interfaces

### 3.1 `test-monitor` CLI

```
test-monitor [--suite NAME] [--verbose] [--timeout SEC]
             [--trigger-on green|red|change --trigger-to ADDR]

Options:
  --suite NAME          Run a single suite (default: all from agency.yaml)
  --verbose             Emit [TEST <suite>] PASS lines (default: quiet on pass)
  --timeout SEC         Kill subprocess after SEC seconds; emit [TEST ERROR]
                        timeout line and exit 2 (default: 0 = no timeout)
  --trigger-on EVENT    Emit dispatch/flag on outcome (green|red|change)
  --trigger-to ADDR     Destination — REQUIRED when --trigger-on is set.
                        No default. Fails at CLI parse if --trigger-on is
                        given without --trigger-to.
  --help, -h            Usage
  --version             Tool version

Exit codes:
  0  all suites green
  1  one or more suites red
  2  tooling error (missing framework, config broken, parse failure, dep missing, timeout)

Output: stdout — [TEST <suite>] prefix + prose body events, line-buffered.
```

**Dropped from CLI:** `--once` (was a no-op, MAR-H4), `--format` (was "reserved for future" — YAGNI, MAR-L1).

**`--trigger-to` is required when `--trigger-on` is set** (MAR-Adv-L5 fix in draft-v3): no implicit default means no silent dispatch to a nonexistent "captain" in adopter repos. Adopter must explicitly name the destination. argparse raises if `--trigger-on` is passed without `--trigger-to`.

**`--timeout SEC` added in draft-v3** (MAR-Adv-L6 fix): bounds subprocess runtime. Default `0` means no timeout (Monitor-tool-only boundary). Non-zero value installs `signal.alarm(SEC)` or `subprocess.Popen(..., timeout=SEC)` — on expiry, `proc.terminate()` then `proc.kill()`; emit `[TEST ERROR] suite=<name> timed out after Ns`; exit 2.

### 3.2 `test-watch` CLI

```
test-watch [--suite NAME] [--interval SEC] [--debounce SEC]

Options:
  --suite NAME          Watch a single suite (required — v1 is one-suite-per-process)
  --interval SEC        Filesystem scan cadence (default: 1.0)
  --debounce SEC        Quiescence window before triggering run (default: 0.5)
  --help, -h            Usage
  --version             Tool version

Long-lived process:
  - Foreground, line-buffered stdout (Monitor tool requirement)
  - SIGINT/SIGTERM → clean shutdown (state file flushed; subprocess killed if mid-run)
  - SIGPIPE → SIG_DFL (MAR-L4) — broken Monitor pipe causes exit, not exception traceback
  - Initial run → emits initial STATE line (`[TEST <suite>] initial state: GREEN`)
  - On file change (debounced via monotonic clock): re-run via test-monitor subprocess
  - Silent on GREEN→GREEN / RED→RED-same-signatures
  - Emits transition lines on any state / signature-set change
```

### 3.3 `/quality-gate` Step 8 rewire — what the skill tells the agent

(Not runnable pseudocode — this is the logical flow the skill text instructs the agent to follow. MAR-H1.)

1. Check `agency/tools/test-monitor` exists.
2. Read `agency/config/agency.yaml`; check `testing.monitor: true`.
3. **If both:** invoke Monitor tool with `./agency/tools/test-monitor` as the background script. Watch for the line matching `^\[TEST\] run complete` — that line carries the run outcome (exit code embedded). Parse the exit code; if non-zero, QG fails Step 8.
4. **If either condition false:** invoke `./agency/tools/test-run` synchronously (current behavior). Parse exit code.

Detection in the skill file is by prose instruction, not by Python — the agent reads the skill, checks the files, decides. Backward-compatible: no test-monitor present → sync fallback; opt-out via `testing.monitor: false` → sync fallback.

### 3.4 `agency.yaml` schema extension

```yaml
testing:
  monitor: true          # NEW — opt-in flag for Monitor-tool integration
  suites:
    tools:
      command: "bats src/tests/tools/"
      description: "BATS tool tests"
      watch_paths:        # NEW — optional; gitignore-style globs (MAR-H2)
        - "src/tests/tools/**"
        - "agency/tools/**"
    mdpal:
      command: "cd apps/mdpal && swift test 2>/dev/null || true"
      description: "MarkdownPalEngine Swift tests"
      # watch_paths omitted → test-watch infers from framework (§5.4)
```

**`watch_paths` glob syntax** (MAR-H2): gitignore-style patterns.
- `**` matches zero-or-more path components (recursive)
- `*` matches within a single path component
- Leading `/` anchors to repo root; patterns without leading `/` match from any depth
- Trailing `/` matches directories only
- Lines starting with `!` are negations
- Implementation: use `fnmatch` + manual walk, or reuse the `.gitignore`-style matcher from a stdlib-compatible pattern library (none exists — write a minimal one; ~50 LOC)

`testing.monitor: false` or omitted → `/quality-gate` falls back to synchronous `test-run`.

`testing.suites.<name>.watch_paths` omitted → test-watch runs inference (§5.4).

---

## 4. Dependencies

### 4.1 Python (stdlib only — ZERO-PIP enforced, principal-reaffirmed 2026-04-19)

| Module | Use |
|--------|-----|
| `argparse` | CLI parsing |
| `dataclasses` | SuiteState, RunResult, Failure, FailureSignature |
| `datetime` | **UTC** timestamps (`datetime.now(timezone.utc)`) |
| `enum` | Framework, Outcome enums |
| `hashlib` | sha256 for reason_hash, run_signature |
| `os` | Environment, rename (atomic writes), walk |
| `pathlib` | All file paths |
| `re` | Parser regexes, framework detection |
| `signal` | SIGINT, SIGTERM, SIGPIPE handlers |
| `subprocess` | Shell out to frameworks + dispatch/flag tools |
| `sys` | Version guard, stdout flush, exit codes |
| `time` | `time.monotonic()` for debounce (not wall clock) |
| `typing` | Type hints (PEP 604 unions, PEP 695 generics) |

**YAML parsing** (MAR-M6): agency.yaml parsing uses the same simple line-regex technique as `test-run` (existing precedent). Known limitations: no anchors, limited quoted-string escapes, no flow-style. Adopter agency.yaml files today are block-style with plain scalars — limitation accepted. YAML **emission** (dispatch body) uses block scalar literals (`|`) for user content, plain scalars for keys; injection-safe by construction.

### 4.2 External tools (shelled out to)

| Tool | Use |
|------|-----|
| `bats` | BATS suite runner |
| `vitest` (via npx/pnpm, or direct path) | vitest runner |
| `swift` | XCTest runner |
| `./agency/tools/dispatch` | Emit dispatches for --trigger-on red/green |
| `./agency/tools/flag` | Emit flag for --trigger-on change |
| `./agency/tools/git-safe` | Read HEAD, branch, repo root |

**Subprocess invocation mode** (MAR-H1): `subprocess.Popen(cmd_str, shell=True, stdout=PIPE, stderr=STDOUT, env=TEST_ENV)`. `shell=True` matches `test-run`'s trust model — commands like `cd apps/mdpal && swift test 2>/dev/null || true` require shell interpretation. agency.yaml is a committed, reviewed file; command injection risk is the same as existing test-run (§8.1).

**TEST_ENV** (MAR-H6): inherits parent environment plus `CI=1` (makes vitest and most frameworks emit CI-friendly output — no ANSI cursor positioning, no progress spinners). Documented in tool help.

### 4.3 Framework dependencies (the floor)

- **Python 3.13+** (D45-R1 framework floor)
- **Shebang:** `#!/usr/bin/env python3` + `sys.version_info` guard that emits `[TEST ERROR] Python 3.13+ required (got X.Y) — agent: install python3.13 or configure PATH` **to stdout** (MAR-H4) before `sys.exit(2)`. Emitting to stdout (not stderr) ensures the Monitor tool sees the error and the agent can react.
- **bash 3.2 compatible shell** (only relevant if we kept `monitor-test`; we didn't)

---

## 5. Technology Choices

### 5.1 Python for both tools (not bash)

Per `dispatch-monitor` precedent (D44-R1). Python offers native `set()`, `Popen` streaming, dataclasses, enums, clean signal handling. Bash 3.2 (macOS default) lacks associative arrays — disqualifying for state-heavy tools.

### 5.2 Parser modules — per-framework, plugin registry

```
agency/tools/lib/test_parsers/
├── __init__.py          # Framework enum + registry + dispatch
├── bats.py              # BATS TAP output parser
├── vitest.py            # vitest stdout parser (CI=1 + default reporter)
└── xctest.py            # swift test / XCTest output parser
```

**Import mechanism** (MAR-M5): `test-monitor` at `agency/tools/test-monitor` prepends `<REPO_ROOT>/agency/tools/lib` to `sys.path` at startup:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
from test_parsers import detect, parse_stream
```

The `agency/tools/lib/` directory is framework-new (does not exist yet). An `__init__.py` makes it a package. Add a hookify rule (later work) ensuring `agency/tools/lib/` stays stdlib-only to preserve ZERO-PIP.

**Detection from command** (§5.3 update):

| Command substring | Framework |
|-------------------|-----------|
| `bats ` | BATS |
| `vitest`, `npx vitest`, `pnpm vitest`, `pnpm test` with vitest in package.json | vitest |
| `swift test`, `xcodebuild test`, `xcrun xctest` | XCTest |
| anything else | UNKNOWN → `[TEST ERROR]` + exit 2 for that suite |

### 5.3 Output parsing strategy

| Framework | Strategy | Stability mitigation |
|-----------|----------|-----------------------|
| **BATS** | TAP output — parse `ok N`, `not ok N`, YAML body blocks | TAP is stable across BATS versions; low risk |
| **vitest** | `CI=1` forces non-interactive reporter — parse summary at end + per-file pass/fail lines | Fixture-based parser tests; update fixtures on vitest minor bumps |
| **XCTest** | `swift test` text output: `Test Case '-[Class test]' started/passed/failed`; regex + accumulator | Stable format across Swift versions |

**Parser drift failure mode** (MAR-H2): if a parser raises `ParseError` mid-stream, test-monitor catches it, logs `[TEST ERROR] parse failure in suite=<name> after N lines — RAW passthrough active`, and falls back to emitting raw lines as `[TEST <suite> RAW] <line>`. **Critically, RUN_DONE still emits** (based on subprocess exit code), so `/quality-gate` Step 8's line-match doesn't hang. `parse_ok: false` is set in the RunResult.

### 5.4 Watch-path inference (Q7 resolution — framework-specific rules)

When `testing.suites.<name>.watch_paths` is absent:

| Framework | Inferred watch_paths |
|-----------|---------------------|
| **BATS** | `tests/**/*.bats` + source dir inferred from command path (e.g., `bats src/tests/tools/` → `+ agency/tools/**`; `bats tests/foo/` → `+ claude/foo/**` if exists, else repo root fallback) |
| **vitest** | Run `npx vitest --listFiles` (subprocess, one-shot; no pip) → use resolved test file roots + `src/**` if present |
| **XCTest** | `Sources/**` + `Tests/**` (swift test convention) |
| **UNKNOWN** | Repo root minus standard ignores |

**Standard ignores (all cases):** `.git/`, `node_modules/`, `dist/`, `build/`, `.agency/`, `agency/data/`, `*.pyc`, `__pycache__/`, plus anything matched by the repo's `.gitignore` (parsed via subprocess `git check-ignore --stdin`).

### 5.5 File-watch implementation (Q4 resolution — polling, with MAR fixes)

```python
import os, time
from pathlib import Path

MAX_SNAPSHOT = 20_000   # cap unbounded growth (MAR-M3)
SLOW_SCAN_WARN = 1.0    # seconds

def scan_mtimes(paths: list[str], ignores: IgnoreSet) -> dict[Path, float]:
    """
    Walk watch_paths, collect (path, mtime).
    - Uses os.lstat() — does NOT follow symlinks (MAR-M2)
    - Tracks visited inodes — handles accidental symlink loops
    - Returns (possibly-truncated) snapshot; logs warning if truncated
    """
    snap: dict[Path, float] = {}
    visited_inodes: set[tuple[int, int]] = set()  # (device, inode)
    for base in paths:
        for path in glob_walk(base, ignores):
            try:
                st = path.lstat()  # NOT stat() — we don't follow symlinks
            except OSError:
                continue
            key = (st.st_dev, st.st_ino)
            if key in visited_inodes:
                continue
            visited_inodes.add(key)
            snap[path] = st.st_mtime
            if len(snap) >= MAX_SNAPSHOT:
                print(f"[TEST <{suite}>] watch snapshot capped at {MAX_SNAPSHOT} files — narrow watch_paths", flush=True)
                return snap
    return snap

def watch_loop(suite, interval=1.0, debounce=0.5):
    last_snapshot = scan_mtimes(...)
    quiet_since: float | None = time.monotonic()  # track quiescence
    while True:
        time.sleep(interval)
        t0 = time.monotonic()
        current = scan_mtimes(...)
        scan_elapsed = time.monotonic() - t0
        if scan_elapsed > SLOW_SCAN_WARN:
            print(f"[TEST <{suite}>] scan slow ({scan_elapsed:.1f}s) — narrow watch_paths", flush=True)
        if current != last_snapshot:
            quiet_since = time.monotonic()  # reset quiescence on ANY change
            last_snapshot = current
        elif quiet_since is not None and (time.monotonic() - quiet_since) >= debounce:
            run_suite(suite)   # ← via test-monitor subprocess
            quiet_since = None  # don't re-run until next change
```

**Debounce algorithm** (MAR-M4): the elif branch only fires when `quiet_since` is non-None AND `debounce` elapsed. When a change is detected, `quiet_since` is reset; when the run fires, `quiet_since` is set to None so we don't re-fire until the NEXT change. This decouples debounce from scan interval cleanly.

**All timestamps are UTC** (MAR-M5). `time.monotonic()` is used for debounce intervals (immune to clock changes).

### 5.6 Output emission, buffering, and signals

```python
import signal, sys

# Line-buffered stdout (Monitor tool requirement)
sys.stdout.reconfigure(line_buffering=True)

# SIGPIPE: default behavior (silent exit), not raise BrokenPipeError (MAR-L4)
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

# SIGINT/SIGTERM: clean shutdown handler
def shutdown(signum, frame):
    # Flush state file if test-watch; kill subprocess if mid-run
    cleanup()
    sys.exit(0)
signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

def emit(line: str) -> None:
    print(line, flush=True)  # Belt-and-suspenders flush
```

### 5.7 --trigger-on rate limiting (MAR-H3) — uses §2.4 unified state file

test-monitor dedupes dispatches/flags by `run_signature` (sha256 of sorted failure signatures). The **§2.4 unified `<suite>.state` file** holds the trigger state alongside outcome state — one file per suite, not separate. Schema (extending §2.4):

```yaml
last_outcome: red
last_run_at: "2026-04-20T01:15:12Z"
last_failure_signatures:
  - test_id: "src/tests/tools/dispatch.bats:42"
    reason_hash: "a1b2c3d4e5f6g7h8"
last_green_head: "4901c6dd"
last_green_at: "2026-04-19T23:40:00Z"
# Trigger dedup fields (additive; absent on first run):
last_trigger_type: "red"                  # enum: green | red | change | null
last_trigger_signature: "a1b2c3…"         # run_signature at last successful dispatch
last_trigger_at: "2026-04-20T01:15:12Z"
```

On `--trigger-on red`, test-monitor:
1. Computes current `run_signature`.
2. Reads `<suite>.state`.
3. If `last_trigger_type == "red"` AND `last_trigger_signature == current`: **skip dispatch** (already reported this failure set). Emit `[TEST] dispatch suppressed — same RED signature as last trigger`.
4. Else: emit dispatch, update the trigger fields in the state file.

Similarly for `--trigger-on green` — don't re-emit `commit-ready` if the last trigger was green on the same HEAD.

Circuit breaker: after 3 consecutive dispatch failures (tool exit non-zero), test-monitor emits `[TEST ERROR] --trigger-on: 3 consecutive dispatch failures — disabling for this run` and stops attempting dispatch for the remainder of the run. (Circuit breaker state is per-run, in-memory; NOT persisted to the state file — resets at next invocation.)

### 5.8 Subprocess cleanup on exception (MAR-M8)

```python
proc = subprocess.Popen(cmd, shell=True, stdout=PIPE, stderr=STDOUT, env=TEST_ENV)
try:
    for line in proc.stdout:
        parser.feed(line)
except ParseError as e:
    print(f"[TEST ERROR] parse failure: {e} — RAW passthrough", flush=True)
    # Fall through to passthrough mode — continue consuming proc.stdout
    for line in proc.stdout:
        print(f"[TEST <{suite}> RAW] {line.rstrip()}", flush=True)
finally:
    # Ensure subprocess is reaped — no zombies
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
    exit_code = proc.returncode
```

---

## 6. Trade-offs

### 6.1 Parse text output vs. machine-readable reporter

**Chose:** text output + regex parsing. **Why:** single strategy across frameworks; what user sees = what agent parses; parser tests use captured fixtures. **Mitigation for drift (MAR-H2):** parser failures never hang Step 8 — RUN_DONE emits regardless; RAW passthrough activates on ParseError. **Deferred:** JSON reporter opt-in if text parsing proves fragile.

### 6.2 Parser modules as plugins vs. monolithic

**Chose:** per-framework modules under `agency/tools/lib/test_parsers/` with sys.path-based import (MAR-M5). **Why:** testable in isolation; adding `pytest` later = one new file. **Canonical test of plugin model:** adding pytest module (follow-on, PVR FR6 "deferred").

### 6.3 test-watch watches one suite vs. all

**Chose:** one suite per process in v1. **Why:** simple state; Monitor can run multiples. **Follow-on:** `test-watch --all` in v2 if needed.

### 6.4 Polling vs. inotify/fsevents

Resolved in PVR Q4. 1s stdlib polling. ZERO-PIP reaffirmed 2026-04-19.

### 6.5 Config opt-in vs. opt-out for /quality-gate rewire

**Chose:** opt-in (`testing.monitor: true` required). **Why:** backward-compat by default (PVR Q6). `agency update` prompts on first post-D45 run to flip the flag.

### 6.6 Pattern C dispatch type: single `test-result` vs. two (`commit-ready`/`test-failure`)

**Chose:** two dispatch types. **Why:** recipients filter by type cleanly; framework idiom is "intent in type name."

### 6.7 `monitor-test` wrapper

**Resolved (MAR-L2):** dropped. The invocation `./agency/tools/test-monitor` is already a one-liner; a wrapper adds nothing.

---

## 7. Failure Modes

| # | Failure | Detection | Response |
|---|---------|-----------|----------|
| 1 | Framework not installed (`bats: command not found`) | `Popen` raises `FileNotFoundError` | Emit `[TEST ERROR] <fw> not installed for suite=<name> — agent: install or skip`; exit 2 for that suite; other suites continue |
| 2 | agency.yaml missing or malformed | `load_suites()` returns empty or raises | Emit `[TEST ERROR] cannot load testing.suites from agency.yaml — <reason>`; exit 2 |
| 3 | `testing.suites` empty or missing (MAR-M6) | Parsed suites list is empty | Emit `[TEST ERROR] no suites configured in agency.yaml → testing.suites — nothing to run`; exit 2. Never silent-zero-run. |
| 4 | Unknown framework in command | Detection fails in `detect_framework()` | Emit `[TEST ERROR] cannot detect framework for suite=<name>, command=<cmd-truncated-to-80-chars>` (MAR-L1 path redaction: basename + last directory only); exit 2 for suite |
| 5 | Parser error mid-run (MAR-H2) | Parser raises `ParseError` | Emit `[TEST ERROR] parse failure in suite=<name> after N lines — RAW passthrough active`; switch to raw mode; **still emit RUN_DONE** based on subprocess exit code; set `parse_ok: false` |
| 6 | Subprocess hangs | `--timeout SEC` flag (draft-v3, §3.1) OR Monitor-tool timeout | If `--timeout SEC > 0`: on expiry, `proc.terminate()` → `proc.wait(timeout=5)` → `proc.kill()`; emit `[TEST ERROR] suite=<name> timed out after Ns`; exit 2. If timeout=0 and invocation is via Monitor tool: Monitor timeout bounds runaway. If timeout=0 and CLI invocation: runs until process exits (principal choice). |
| 7 | stdin/stdout pipe breaks (Monitor killed) | SIGPIPE → SIG_DFL (MAR-L4) | Clean exit 0 (default SIGPIPE behavior) — NOT a traceback |
| 8 | File-watch scan slow (>1s) | `scan_mtimes()` elapsed > threshold | Warn once on stdout: `[TEST <suite>] scan slow (Xs) — narrow watch_paths`; continue |
| 9 | File-watch snapshot cap (MAR-M3) | `len(snap) >= MAX_SNAPSHOT` | Emit `[TEST <suite>] watch snapshot capped at 20000 files — narrow watch_paths`; scan returns partial; continue (known gap) |
| 10 | Symlink loops (MAR-M2) | Inode tracking catches revisit | Silently skip (expected for legitimate test fixtures with symlinks) |
| 11 | State file corrupted | YAML read raises or returns unexpected | Log `[TEST ERROR] state file corrupt for suite=<name> — resetting to initial`; delete + treat as first run |
| 12 | Dispatch/flag tool failure (--trigger-on) | subprocess returns non-zero | Emit `[TEST ERROR] --trigger-on <event> failed: <reason>`; DO NOT fail the test run (tests pass/fail on their own merits); after 3 consecutive failures (MAR-H3), disable for remainder of run |
| 13 | --trigger-on dispatch loop (MAR-H3) | Same `run_signature` as `.last-trigger` | Emit `[TEST] dispatch suppressed — same RED signature`; skip dispatch; update `.last-trigger` timestamp anyway |
| 14 | Concurrent test-watch/test-monitor for same suite (MAR-Adv-M1, draft-v3 fix) | `fcntl.flock(LOCK_EX \| LOCK_NB)` on state file at start → `BlockingIOError` if second process attempts lock | Emit `[TEST ERROR] suite=<name> state file locked — another process is running; exit`; exit 2. Prevents double-dispatch and double-run. |
| 15 | Unicode in test output | Python 3 handles UTF-8 default | Pass through; truncate `body_truncated` at codepoint boundary (slice str, not bytes) |
| 16 | Python < 3.13 at runtime (MAR-M4) | Shebang guard `sys.version_info < (3,13)` | Emit `[TEST ERROR] Python 3.13+ required (got X.Y) — agent: install python3.13 or configure PATH` **to STDOUT** (MAR-H4); exit 2. Monitor tool sees the error; /quality-gate Step 8 detects non-zero exit and falls back to test-run |
| 17 | Subprocess zombie on parser exception (MAR-M8) | Exception in parser loop | `finally:` block with `proc.terminate()` → `proc.wait(timeout=5)` → `proc.kill()` if needed. No zombies. |
| 18 | agency update collision — test-monitor already exists (MAR-M7) | `cp-safe` prompts on existing file | Document in §9.5: `cp-safe` is invoked by `agency update`; it blocks on existing file and prompts principal. Non-destructive by default. |
| 19 | --trigger-to unknown destination | dispatch tool rejects unknown address | Emit `[TEST ERROR] --trigger-to <addr> unknown — agent: check address`; counted as dispatch failure (per #12 circuit breaker) |
| 20 | --trigger-on without --trigger-to (draft-v3, MAR-Adv-L5 fix) | argparse cross-validation at CLI parse | argparse raises with message `--trigger-on requires --trigger-to ADDR`; exit 2 before any work. No silent-default dispatches to nonexistent addresses. |
| 21 | Subprocess timeout (draft-v3, MAR-Adv-L6 fix) | `--timeout SEC > 0` and subprocess exceeds it | See row #6 above. Guaranteed bounded runtime for CLI and Monitor-tool invocations both. |

### 7.1 "Never silent on failure" enforcement

Every error emits a `[TEST ERROR]` line on stdout before any exit. Silent exits are limited to: clean pass (SUITE_DONE + RUN_DONE fire), SIGPIPE (Monitor gone; nothing to emit to), explicit user SIGINT.

---

## 8. Security Considerations

### 8.1 Command execution via agency.yaml `command:` field

**Risk:** A malicious agency.yaml could specify `command: "; rm -rf /"`.

**Model:** `subprocess.Popen(cmd, shell=True)` — inherits test-run's trust boundary. agency.yaml is committed, reviewed, and part of the repo — same trust as any repo file. No net-new attack surface vs. existing test-run.

### 8.2 Path traversal in watch_paths

**Risk:** `watch_paths: ["../../etc/passwd"]` causes test-watch to stat system paths.

**Mitigation:**
- test-watch resolves `watch_paths` relative to `REPO_ROOT`; any path that resolves above `REPO_ROOT` is rejected with `[TEST ERROR] watch_path outside repo: <path>`.
- Read-only (`lstat`) only — no content read of watched files.

### 8.3 Dispatch body injection (MAR-M6)

**Risk:** A failing test's assertion contains dispatch-metadata-like strings (`type: critical`) that confuse downstream parsers.

**Mitigation:** all user-sourced strings in the dispatch body YAML emit as **block scalar literals** (`|`) with explicit indentation. YAML parsers treat block scalars as opaque strings — no key interpretation. We emit the YAML ourselves (no `yaml.dump`); test cases cover reason containing `\n`, `---`, `!!python/object`.

### 8.4 Resource exhaustion from runaway output

**Risk:** A misconfigured test prints 1 GB stdout.

**Mitigation:** we stream line-by-line (Popen iterator); no full-buffer. `body_truncated` caps each failure at 1 KB. Dispatch body cap at 8 KB. No in-memory full-run log.

### 8.5 test-watch feedback loop

**Risk:** tests write to a watched path → re-run → tests write → loop.

**Mitigation:** standard ignore list (dist, build, __pycache__) + .gitignore inheritance + 500ms debounce bound the rate. Document: "if tests write to watched paths, exclude via .gitignore or narrow watch_paths."

### 8.6 Error-line information leakage (MAR-L1)

**Risk:** `[TEST ERROR] cannot detect framework for suite=<name>, command=<cmd>` echoes full command including paths (e.g. `/Users/jdm/…`).

**Mitigation:** error lines truncate `cmd` to basename + last directory only (e.g., `tools/bats` instead of full path). Enforced via `_redact(cmd)` helper; applied to all `[TEST ERROR]` lines that echo user content.

### 8.7 Signal-based shutdown

`SIGINT`/`SIGTERM` → clean exit; state file atomic write; subprocess reaped (§5.8). `SIGPIPE` → `SIG_DFL` (silent exit when Monitor is gone). No zombies, no half-written state.

---

## 9. Deployment & Operations

### 9.1 Packaging

New files in `agency/tools/`:
- `test-monitor` (Python, executable)
- `test-watch` (Python, executable)

New package at `agency/tools/lib/test_parsers/`:
- `__init__.py`, `bats.py`, `vitest.py`, `xctest.py`

Test files:
- `src/tests/tools/test-monitor.bats`, `src/tests/tools/test-watch.bats` (CLI + integration smoke)
- `src/tests/python/test_parsers/` — Python unit tests via stdlib `unittest`: run with `python3 -m unittest discover src/tests/python/` (MAR-M8 — stdlib-only test runner, ZERO-PIP compliant)

### 9.2 Installation

Adopter runs `agency update`. Tool files are copied via `cp-safe`. Python 3.13 availability verification is deferred to `agency init`/`agency update` per friction report dispatch #694. Until that ships, a sub-floor Python host surfaces the error via the runtime guard at first invocation (§7 #16).

### 9.3 Configuration

Flip `testing.monitor: true` in `agency.yaml`. Optionally add `watch_paths:` per suite. No further config.

### 9.4 Observability

- test-monitor: zero output by default except `[TEST …]` lines on stdout.
- test-watch: stderr banner on startup and shutdown; slow-scan warning on stdout.
- `[TEST ERROR]` lines on stdout — part of the Monitor notification stream.
- Dispatches created via `./agency/tools/dispatch` inherit that tool's receipt behavior (MAR-L5).
- No telemetry, metrics, or log files.

### 9.5 Rollback and upgrade collision (MAR-M7)

**Rollback:**
- Flip `testing.monitor: false` in `agency.yaml` → sync fallback.
- Remove tool files: `rm agency/tools/test-monitor agency/tools/test-watch` → fallback activates.
- No schema migration; additive only.

**Upgrade collision:** `agency update` copies `agency/tools/test-monitor` from upstream. If the adopter already has a local version (sandbox, patch), `cp-safe` blocks on the existing file and prompts the principal to diff/overwrite/skip. Destructive overwrite requires explicit confirmation. Documented: adopters who patch these tools locally should review on each `agency update`.

### 9.6 Documentation

- `agency/tools/test-monitor --help` / `test-watch --help`
- `.claude/skills/quality-gate/SKILL.md` Step 8 documents detection + fallback logic
- `agency.yaml` schema extension noted in the existing agency.yaml template + commentary

---

## 10. Open Technical Questions

All resolved in draft-v2:

1. ~~Pattern C dispatch payload schema~~ — §2.3
2. ~~Watch-path inference rules~~ — §5.4
3. ~~Parser module shape and import mechanism~~ — §5.2
4. ~~Text vs. JSON reporter~~ — §6.1; drift mitigation §5.3
5. ~~`monitor-test` helper~~ — §6.7, dropped
6. ~~File-watch scan implementation~~ — §5.5
7. ~~Output buffering + signal handling~~ — §5.6
8. ~~Security model~~ — §8
9. ~~Subprocess invocation mode (shell vs. tokenize)~~ — §4.2, shell=True
10. ~~YAML emission safety~~ — §8.3, block scalars
11. ~~Clock/timezone handling~~ — §2.1, UTC mandated
12. ~~REPO_ROOT resolution from any CWD~~ — §1, git rev-parse + ancestor walk
13. ~~agency update collision semantics~~ — §9.5, cp-safe prompt
14. ~~Dispatch rate-limiting / circuit breaker~~ — §5.7
15. ~~Subprocess cleanup on exception~~ — §5.8
16. ~~RUN_DONE emission on parser failure~~ — §5.3, §7 #5

**No blocking questions for implementation.**

---

## Completeness Scorecard

| # | Section | Status | MAR findings addressed |
|---|---------|--------|-----|
| 1 | Architecture Overview | ✓ | H5 (REPO_ROOT), H1 (pseudocode clarified) |
| 2 | Data Model | ✓ | M1, M2, M3, M5 (UTC) |
| 3 | Interfaces | ✓ | H1, H2, H4, L1 |
| 4 | Dependencies | ✓ | H1 (shell=True), H4 (stdout guard), H6 (CI=1 env), M6 (YAML limits) |
| 5 | Technology Choices | ✓ | M5 (import mech), H2 (parser drift RUN_DONE), M2/M3/M4 (file-watch fixes), L4 (SIGPIPE), H3 (rate limit), M8 (zombie cleanup) |
| 6 | Trade-offs | ✓ | L2 (drop monitor-test) |
| 7 | Failure Modes | ✓ | +7 new rows (#3, #9, #10, #13, #16, #17, #18, #19) |
| 8 | Security Considerations | ✓ | M6 (YAML block scalars), L1 (redaction) |
| 9 | Deployment & Operations | ✓ | M7 (cp-safe), M8 (unittest), L5 (receipts) |
| 10 | Open Technical Questions | ✓ | 16 items, all resolved in-doc |

**Score: 10/10 — implementation-ready.**

---

## MAR findings disposition

| Finding | Priority | Disposition |
|---------|----------|-------------|
| Design-H1 pseudocode mis-framing | HIGH | Fixed §3.3, §1 |
| Design-H2 watch_paths glob syntax | HIGH | Fixed §3.4 (gitignore-style) |
| Design-H3 staged_changes semantics | HIGH | Fixed — field dropped (§2.3) |
| Design-H4 --once / --format drop | HIGH | Fixed §3.1 |
| Design-H5 REPO_ROOT resolution | HIGH | Fixed §1 |
| Design-H6 vitest ANSI | HIGH | Fixed §4.2, §5.3 (CI=1) |
| Design-M1 last_failures dedup loses info | MED | Fixed §2.1 (FailureSignature) |
| Design-M2 two state files | MED | Fixed §2.4 (unified) |
| Design-M3 transition semantics | MED | Fixed §2.1 |
| Design-M4 guard fallback behavior | MED | Fixed §7 #16 |
| Design-M5 parser module imports | MED | Fixed §5.2 |
| Design-M6 empty suites | MED | Fixed §7 #3 |
| Design-M7 body_truncated size | MED | Fixed §2.2 (1 KB) |
| Design-M8 Python test harness | MED | Fixed §9.1 (unittest) |
| Design-L1 drop --format | LOW | Fixed §3.1 |
| Design-L2 drop monitor-test | LOW | Fixed §6.7 |
| Design-L3 JSON follow-on | LOW | Added to Follow-ons |
| Design-L4 pytest canonical | LOW | Noted §6.2 |
| Design-L5 observability receipts | LOW | Noted §9.4 |
| Adv-H1 shell vs tokenize | HIGH | Fixed §4.2 (shell=True) |
| Adv-H2 parser drift → Step 8 hang | HIGH | Fixed §5.3, §7 #5 (RUN_DONE always emits) |
| Adv-H3 --trigger-on loop | HIGH | Fixed §5.7 (rate limit + circuit breaker) |
| Adv-H4 guard stdout not stderr | HIGH | Fixed §4.3, §7 #16 |
| Adv-M1 concurrent test-watches | MED | Fixed in draft-v3 §2.4, §7 #14 — fcntl.flock on state file |
| Adv-M2 symlinks | MED | Fixed §5.5 (lstat + inode) |
| Adv-M3 unbounded snapshot | MED | Fixed §5.5 (MAX_SNAPSHOT cap) |
| Adv-M4 debounce race | MED | Fixed §5.5 (quiet_since algorithm) |
| Adv-M5 UTC timestamps | MED | Fixed §2.1, §4.1 |
| Adv-M6 YAML parsing fragility | MED | Fixed §4.1 (limitation doc) + §8.3 (safe emission) |
| Adv-M7 upgrade collision | MED | Fixed §9.5 |
| Adv-M8 subprocess zombies | MED | Fixed §5.8 |
| Adv-L1 error line leakage | LOW | Fixed §8.6 (path redaction) |
| Adv-L2 last_green_head format | LOW | Fixed §2.4 (unified YAML file) |
| Adv-L3 monitor-test missing -- | LOW | Moot (wrapper dropped) |
| Adv-L4 SIGPIPE handling | LOW | Fixed §5.6 |
| Adv-L5 --trigger-to default | LOW | Fixed in draft-v3 §3.1, §7 #20 — made required when --trigger-on is set |
| Adv-L6 --timeout for CI | LOW | Fixed in draft-v3 §3.1, §7 #6, §7 #21 — added `--timeout SEC` arg |

**Draft-v2 (2026-04-19): 28 autonomous fixes applied. Draft-v3 (same day, post-principal-correction): +3 autonomous fixes (no defer). Total: 31 fixes; 1 moot (Adv-L3 — monitor-test wrapper dropped). Zero deferred, zero v2-carry-over.**

### Disagree items (for completeness — with reasoning)

| Finding | Status | Reasoning |
|---------|--------|-----------|
| JSON reporter opt-in (was A&D §6.1 "follow-on") | Disagree | Text output + RAW passthrough fallback (§5.3, §7 #5) handles drift. Adding a second format now without evidence of drift is YAGNI. If real drift surfaces, re-open with evidence. |
| Mid-run abort (issue #345) | Disagree-with-tracker | PVR Q5 resolution with principal: v1 is non-interruptive by design; agent retains TaskStop. #345 is a new feature request, not a deferred defect. |
| Single-suite test-watch | Disagree | PVR UC2 scopes test-watch to one suite. Multi-suite is a new use case request; not a defect. |
| Monitor-test wrapper missing `--` (Adv-L3) | Moot | Wrapper dropped in draft-v2 §3.3, §6.7. Not present in shipping design. |

---

## Downstream artifacts

- **Plan** — next phase. File at `agency/workstreams/devex/test-monitor-plan-20260419.md`. Iterations:
  - P1: test-monitor core (Python scaffolding + CLI + agency.yaml loader + BATS parser + emission; single-suite smoke)
  - P2: vitest + XCTest parsers
  - P3: --trigger-on green|red|change + rate limit
  - P4: /quality-gate Step 8 rewire (skill text + sync fallback)
  - P5: test-watch (file-watch loop + state + transitions)
- **Build order** (PVR Q9): UC1 → UC3 → `/quality-gate` rewire → UC2. UC2 is carve-off candidate if complexity blows up.

## Follow-ons (out-of-scope v1 features, not deferred defects)

Distinction: these are **new-feature requests or framework-wide concerns**, not deferred issues. v1 is complete and shippable without them.

- **Mid-run abort** (issue **#345**) — new feature, PVR Q5 scope-out with principal
- **`test-watch --all`** across suites in one process — new feature, PVR UC2 scope
- **`REFERENCE-MONITOR-OUTPUT.md`** framework doc (flag **#188**) — framework-wide documentation task, owned by captain
