# Research brief — Apple Containers for test isolation (issue #42)

**Date:** 2026-08-18 · **Author:** captain · **Status:** decision-ready
**Reframed #42:** "the purpose was TEST ISOLATION (which holds); research Apple
Containers as the better isolation mechanism than docker."

## TL;DR — the hypothesis reverses

Apple Containers is genuinely strong technology, but for issue #42 it is the
**wrong tool**, and adopting it would *mask* our actual bug rather than fix it.
**Recommendation: fix the bats isolation in-process** (extend the existing
`_test-isolation` helper). Apple Containers is a macOS-dev-only nicety with
**zero CI benefit** and doesn't address the defect. This contradicts the initial
"Apple Containers is the better way" framing — the evidence says otherwise, and
this session's own failures are the proof.

## What Apple Containers is

- `apple/container` (CLI) + `apple/containerization` (Swift framework), announced
  WWDC 2025, Apache-2.0, ~49k stars, v1.0.0 (2026-06-09) → v1.2.2 (2026-08-08).
- Isolation model: **each container runs in its own lightweight VM** on
  `Virtualization.framework` (Swift `vminitd` as PID 1, gRPC-over-vsock, ext4
  rootfs, per-container IP). A *stronger* boundary than Docker's shared-kernel.

## Three findings that decide it

1. **CI cannot use it — at all.** GitHub-hosted macOS runners are themselves VMs;
   **nested virtualization is unsupported** (Apple Virtualization.framework
   limitation). The request to expose it (`actions/runner-images` #13505) was
   **closed "not planned."** And our CI is **Linux** — a macOS-only,
   Apple-Silicon-only tool is a non-starter there by definition. Using it in CI
   would require a **self-hosted bare-metal Apple Silicon runner fleet** (real
   infra cost) and *still* only exercise the macOS path.

2. **Hard platform floor.** Full functionality needs **macOS 26 "Tahoe" +
   Apple Silicon**. macOS 15 works only with degraded networking. This conflicts
   with the framework's portability posture (bash 3.2 floor, macOS-primary dev
   but **Linux CI**).

3. **It masks the real bug.** Our leaks — a buggy test creating **~90 real git
   tags**, **worktrees leaking into the live checkout**, dependence on a
   **gitignored dev-only dir**, **order-dependence** through shared FS state —
   are all the *same class*: **a test operated on the real repo dir instead of a
   temp fixture.** These are test-authoring/filesystem/git-state bugs, not
   kernel/process-isolation bugs. A per-file VM hides them **on one developer's
   Mac** while the identical un-isolated tests keep running on Linux CI, where
   isolation matters most.

## The real fix (already 80% built)

The repo already ships `agency/tools/lib/_test-isolation`
(`test_isolation_setup`/`_teardown`): fake `HOME`, explicit `ISCP_DB_PATH`,
`GIT_CONFIG_GLOBAL=/dev/null`, unsets leaked `GIT_DIR`/author vars, snapshots
`.git/config` + framework dirs for debris detection.

**The gap it does NOT close:** tests that `cd` into `REPO_ROOT` and run git
against the **real `.git`** — config is isolated, but the object/ref store is
not. That's exactly the tag/worktree leak this session hit. **The fix is a
bounded extension of the helper we already have:**

- Force offending tests into a **throwaway fixture repo** (`git init` under
  `$BATS_TEST_TMPDIR`), never the live `.git`.
- Add a **teardown guard** that fails loudly if the live repo's tag-count or
  worktree-list changed during a test (the `worktree-create.bats` file already
  does exactly this leak-diff pattern — generalize it).
- Zero-pip, bash 3.2, **runs identically on macOS dev and Linux CI.**

This session already fixed 3 instances by hand (release `--dry-run` hermeticity,
the gitignored-`housekeeping/` dependency, the worktree-name collision). The
extension systematizes that so a leak fails the test instead of scribbling on
the repo.

## Options compared

| Option | True FS/git isolation | Helps Linux CI | Cost | macOS-only |
|---|---|---|---|---|
| **(a) Apple Containers** | Yes (per-VM) | **No** | macOS 26 + ASi floor; VM plumbing | **Yes** |
| **(b) In-process bats (extend `_test-isolation`)** | Fully achievable | **Yes** | Lowest — extend existing helper | No |
| **(c) Cross-platform container (Colima dev / Docker CI)** | Yes | **Yes** | Container image + daemon | No |

## Recommendation

1. **Do (b) now** — extend `_test-isolation` with a fixture-repo mode + a
   live-repo leak guard, and route the git-touching tests through it. This is the
   correct, portable, low-cost fix for #42 and directly prevents a repeat of the
   90-tag incident. Small, well-scoped build.
2. **Keep (c) on the shelf** as the escalation *only if* isolation needs later
   grow beyond filesystem/git (e.g. network or PID isolation) — because it's the
   only container option that also protects CI.
3. **Do not adopt (a) for #42.** A time-boxed Apple Containers prototype is
   defensible only as a *separate* macOS-native build/test convenience (possibly
   relevant to the mdpal-app / mock-and-mark macOS workstreams) — never as the
   answer to #42 and never as a CI dependency.

## Sources
apple/container + apple/containerization (GitHub); WWDC25 session 346 "Meet
Containerization"; GitHub Actions hosted-runners reference (nested-virt
unsupported); actions/runner-images #13505 (closed not-planned); The New Stack
Apple-vs-Docker; repo `agency/tools/lib/_test-isolation`.
